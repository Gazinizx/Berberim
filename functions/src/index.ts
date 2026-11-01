import {initializeApp} from "firebase-admin/app";
import {FieldValue, Timestamp, getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {randomBytes} from "crypto";

initializeApp();
const db = getFirestore();
const messaging = getMessaging();
const codeChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
function newCode(): string {
  const b = randomBytes(7);
  return Array.from(b, n => codeChars[n % codeChars.length]).join("");
}
function requireAuth(request: {auth?: {uid: string; token: Record<string, unknown>} | null}): string {
  if (!request.auth) throw new HttpsError("unauthenticated", "Önce giriş yapmalısın.");
  return request.auth.uid;
}
async function profile(uid: string) {
  const s = await db.doc(`users/${uid}`).get();
  if (!s.exists) throw new HttpsError("failed-precondition", "Hesap profili bulunamadı.");
  return s.data()!;
}
async function notify(uid: string, title: string, body: string, data: Record<string,string> = {}) {
  const snap = await db.doc(`users/${uid}`).get();
  const token = snap.data()?.fcmToken;
  if (typeof token === "string" && token.length > 0) {
    try { await messaging.send({token, notification: {title, body}, data}); }
    catch (e) { console.error("FCM send failed", e); }
  }
}

export const registerDeviceToken = onCall(async (request) => {
  const uid = requireAuth(request);
  const token = String(request.data?.token ?? "");
  if (token.length < 20 || token.length > 4096) throw new HttpsError("invalid-argument", "Bildirim anahtarı geçersiz.");
  await db.doc(`users/${uid}`).update({fcmToken: token, tokenUpdatedAt: FieldValue.serverTimestamp()});
  return {ok: true};
});

export const joinWithBarberCode = onCall(async (request) => {
  const uid = requireAuth(request);
  const name = String(request.data?.name ?? "").trim();
  const phone = String(request.data?.phone ?? "").trim();
  const code = String(request.data?.barberCode ?? "").trim().toUpperCase();
  if (!name || !code) throw new HttpsError("invalid-argument", "Ad ve işletme kodu gerekli.");
  const codeDoc = await db.doc(`barberCodes/${code}`).get();
  if (!codeDoc.exists) throw new HttpsError("not-found", "İşletme kodu geçersiz.");
  const barberId = String(codeDoc.data()?.barberId ?? "");
  const barber = await db.doc(`users/${barberId}`).get();
  if (!barber.exists || barber.data()?.status !== "approved") throw new HttpsError("failed-precondition", "İşletme aktif değil.");
  await db.doc(`users/${uid}`).set({
    uid, name, phone, email: request.auth?.token.email ?? "",
    role: "customer", barberId, createdAt: FieldValue.serverTimestamp(),
  });
  return {ok: true, barberId};
});

export const applyForBarber = onCall(async (request) => {
  const uid = requireAuth(request);
  const name = String(request.data?.name ?? "").trim();
  const shopName = String(request.data?.shopName ?? "").trim();
  const phone = String(request.data?.phone ?? "").trim();
  if (!name || !shopName) throw new HttpsError("invalid-argument", "Yetkili ve işletme adı gerekli.");
  const userRef = db.doc(`users/${uid}`);
  const userSnap = await userRef.get();
  if (userSnap.exists) throw new HttpsError("already-exists", "Bu hesap için profil zaten oluşturulmuş.");
  const existing = await db.collection("barberApplications").where("uid", "==", uid).limit(1).get();
  if (!existing.empty && existing.docs[0].data().status === "pending") {
    throw new HttpsError("already-exists", "Bekleyen başvurun zaten var.");
  }
  const ref = await db.collection("barberApplications").add({
    uid, name, shopName, phone, email: request.auth?.token.email ?? "",
    status: "pending", createdAt: FieldValue.serverTimestamp(),
  });
  await userRef.set({uid, name, phone, email: request.auth?.token.email ?? "", role: "barber", status: "pending", shopName,
    applicationId: ref.id, createdAt: FieldValue.serverTimestamp()});
  return {ok: true, status: "pending", applicationId: ref.id};
});

export const reviewBarberApplication = onCall(async (request) => {
  const uid = requireAuth(request);
  const admin = await profile(uid);
  if (admin.role !== "admin") throw new HttpsError("permission-denied", "Yönetici yetkisi gerekli.");
  const id = String(request.data?.applicationId ?? "");
  const decision = String(request.data?.decision ?? "");
  if (!id || !["approve", "reject"].includes(decision)) throw new HttpsError("invalid-argument", "Başvuru bilgisi geçersiz.");
  const appRef = db.doc(`barberApplications/${id}`);
  const result = await db.runTransaction(async tx => {
    const app = await tx.get(appRef);
    if (!app.exists || app.data()?.status !== "pending") throw new HttpsError("failed-precondition", "Başvuru beklemede değil.");
    const a = app.data()!;
    const userRef = db.doc(`users/${a.uid}`);
    if (decision === "reject") {
      tx.update(appRef, {status: "rejected", reviewedAt: FieldValue.serverTimestamp(), reviewedBy: uid});
      tx.update(userRef, {status: "rejected"});
      return {status: "rejected" as const, targetUid: String(a.uid)};
    }
    let code = newCode();
    let codeRef = db.doc(`barberCodes/${code}`);
    for (let i = 0; i < 5; i++) {
      const codeSnap = await tx.get(codeRef);
      if (!codeSnap.exists) break;
      code = newCode();
      codeRef = db.doc(`barberCodes/${code}`);
    }
    tx.create(codeRef, {barberId: a.uid, createdAt: FieldValue.serverTimestamp()});
    tx.update(userRef, {status: "approved", barberCode: code});
    tx.update(appRef, {status: "approved", barberCode: code, reviewedAt: FieldValue.serverTimestamp(), reviewedBy: uid});
    return {status: "approved" as const, barberCode: code, targetUid: String(a.uid)};
  });
  await notify(result.targetUid, "Berberim başvuru sonucu",
    result.status === "approved" ? "İşletmen onaylandı. İşletme kodun: " + result.barberCode : "İşletme başvurun reddedildi.");
  return {ok: true, status: result.status, ...(result.status === "approved" ? {barberCode: result.barberCode} : {})};
});

export const bookAppointment = onCall(async (request) => {
  const uid = requireAuth(request);
  const user = await profile(uid);
  if (user.role !== "customer" || !user.barberId) throw new HttpsError("permission-denied", "Müşteri hesabı gerekli.");
  const date = String(request.data?.date ?? "");
  const time = String(request.data?.time ?? "");
  const serviceId = String(request.data?.serviceId ?? "");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !/^([01]\d|2[0-3]):[0-5]\d$/.test(time) || !serviceId) {
    throw new HttpsError("invalid-argument", "Tarih, saat veya hizmet geçersiz.");
  }
  const [year, month, day] = date.split("-").map(Number);
  const [hour, minute] = time.split(":").map(Number);
  const start = new Date(year, month - 1, day, hour, minute);
  if (start.getTime() < Date.now() + 60_000) throw new HttpsError("invalid-argument", "Geçmiş bir saate randevu alınamaz.");
  const serviceRef = db.doc(`services/${serviceId}`);
  const serviceSnap = await serviceRef.get();
  if (!serviceSnap.exists) throw new HttpsError("not-found", "Hizmet bulunamadı.");
  const service = serviceSnap.data()!;
  const barberId = String(user.barberId);
  if (service.barberId !== barberId || service.isActive !== true) throw new HttpsError("permission-denied", "Bu hizmet bu işletmeye ait değil veya kapalı.");
  const minutes = Number(service.durationMinutes);
  if (!Number.isInteger(minutes) || minutes < 5 || minutes > 360) throw new HttpsError("failed-precondition", "Hizmet süresi hatalı.");
  const end = new Date(start.getTime() + minutes * 60_000);
  const lockId = `${barberId}_${start.getTime()}`;
  const lockRef = db.doc(`slotLocks/${lockId}`);
  const appointmentRef = db.collection("appointments").doc();
  await db.runTransaction(async tx => {
    const lock = await tx.get(lockRef);
    const existing = await tx.get(db.collection("appointments").where("barberId", "==", barberId));
    if (lock.exists) throw new HttpsError("already-exists", "Bu saat az önce doldu. Başka bir saat seç.");
    const collision = existing.docs.some(doc => {
      const a = doc.data();
      return a.status === "confirmed" &&
        (a.startAt as Timestamp).toMillis() < end.getTime() &&
        (a.endAt as Timestamp).toMillis() > start.getTime();
    });
    if (collision) throw new HttpsError("already-exists", "Bu saat başka bir randevuyla çakışıyor.");
    tx.create(lockRef, {barberId, customerId: uid, appointmentId: appointmentRef.id, startAt: Timestamp.fromDate(start)});
    tx.create(appointmentRef, {
      barberId, customerId: uid, serviceId, serviceName: service.name,
      price: service.price, durationMinutes: minutes,
      startAt: Timestamp.fromDate(start), endAt: Timestamp.fromDate(end),
      status: "confirmed", createdAt: FieldValue.serverTimestamp(),
    });
  });
  await notify(barberId, "Yeni randevu", `${user.name ?? "Müşteri"} • ${date} ${time}`, {appointmentId: appointmentRef.id});
  await notify(uid, "Randevun onaylandı", `${service.name} • ${date} ${time}`, {appointmentId: appointmentRef.id});
  return {ok: true, appointmentId: appointmentRef.id};
});

export const cancelAppointment = onCall(async (request) => {
  const uid = requireAuth(request);
  const id = String(request.data?.appointmentId ?? "");
  if (!id) throw new HttpsError("invalid-argument", "Randevu numarası gerekli.");
  const appointmentRef = db.doc(`appointments/${id}`);
  let result: {barberId:string; customerId:string} | undefined;
  await db.runTransaction(async tx => {
    const snap = await tx.get(appointmentRef);
    if (!snap.exists) throw new HttpsError("not-found", "Randevu bulunamadı.");
    const a = snap.data()!;
    const user = await profile(uid);
    if (a.customerId !== uid && (user.role !== "barber" || a.barberId !== uid) && user.role !== "admin") {
      throw new HttpsError("permission-denied", "Bu randevuyu iptal etme yetkin yok.");
    }
    if (a.status !== "confirmed") throw new HttpsError("failed-precondition", "Randevu zaten iptal edilmiş veya tamamlanmış.");
    const lockRef = db.doc(`slotLocks/${a.barberId}_${a.startAt.toMillis()}`);
    tx.update(appointmentRef, {status: "cancelled", cancelledAt: FieldValue.serverTimestamp(), cancelledBy: uid});
    tx.delete(lockRef);
    result = {barberId: a.barberId, customerId: a.customerId};
  });
  if (result) {
    await notify(result.barberId, "Randevu iptal edildi", "Bir randevu iptal edildi.", {appointmentId: id});
    await notify(result.customerId, "Randevu iptal edildi", "Randevunun durumu güncellendi.", {appointmentId: id});
  }
  return {ok: true};
});
