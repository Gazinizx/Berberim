import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

function serverKey(): string {
  const encoded = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (encoded) {
    try {
      const parsed = JSON.parse(encoded);
      if (typeof parsed.default === "string") return parsed.default;
    } catch { /* use legacy injected key below */ }
  }
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
}

function phoneDigits(value: string): string {
  let digits = value.replace(/\\D/g, "");
  if (digits.startsWith("90") && digits.length === 12) digits = digits.slice(2);
  if (digits.startsWith("0") && digits.length === 11) digits = digits.slice(1);
  return digits;
}

function usernamePart(value: string): string {
  return value.normalize("NFC").trim().toLocaleLowerCase("tr-TR")
    .replace(/\\s+/gu, "")
    .replace(/[^\\p{L}\\p{N}._-]/gu, "");
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const key = serverKey();
    if (!url || !key) return json({ error: "Sunucu yapılandırması eksik" }, 503);

    const admin = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
    const token = (request.headers.get("Authorization") ?? "").replace(/^Bearer\\s+/i, "").trim();
    if (!token) return json({ error: "Oturum gerekli" }, 401);

    const { data: authData, error: authError } = await admin.auth.getUser(token);
    const caller = authData.user;
    if (authError || !caller) return json({ error: "Oturum doğrulanamadı" }, 401);

    const { data: callerProfile, error: callerProfileError } = await admin
      .from("profiles").select("is_admin,is_blocked").eq("id", caller.id).maybeSingle();
    if (callerProfileError) throw callerProfileError;
    if (!callerProfile || callerProfile.is_blocked === true) return json({ error: "Bu işlem için yetkiniz yok" }, 403);

    const body = await request.json().catch(() => ({}));
    const action = typeof body.action === "string" ? body.action : "";

    if (action === "create_employee") {
      const businessId = typeof body.business_id === "string" ? body.business_id : "";
      const displayName = typeof body.display_name === "string" ? body.display_name.trim() : "";
      const password = typeof body.password === "string" ? body.password : "";
      if (!businessId || displayName.length < 2 || displayName.length > 80) {
        return json({ error: "İşletme ve geçerli çalışan adı gerekli" }, 400);
      }
      if (password.length < 8 || password.length > 72) {
        return json({ error: "Çalışan şifresi 8-72 karakter arasında olmalı" }, 400);
      }

      const { data: business, error: businessError } = await admin.from("businesses")
        .select("id,name").eq("id", businessId).eq("owner_id", caller.id)
        .eq("status", "active").maybeSingle();
      if (businessError) throw businessError;
      if (!business) return json({ error: "Bu işletme üzerinde çalışan oluşturma yetkiniz yok" }, 403);

      const loginUsername = usernamePart(String(business.name)) + "@" + usernamePart(displayName);
      if (!loginUsername.includes("@") || loginUsername.startsWith("@") || loginUsername.endsWith("@") || loginUsername.length > 100) {
        return json({ error: "İşletme veya çalışan adı kullanıcı adı oluşturmak için uygun değil" }, 400);
      }

      const authEmail = crypto.randomUUID().replaceAll("-", "") + "@staff.berberim.app";
      const { data: created, error: createError } = await admin.auth.admin.createUser({
        email: authEmail,
        password,
        email_confirm: true,
        user_metadata: {
          full_name: displayName,
          first_name: displayName,
          last_name: "",
          account_type: "customer",
        },
      });
      if (createError || !created.user) {
        return json({ error: createError?.message ?? "Çalışan oturumu oluşturulamadı" }, 400);
      }

      let employeeId = "";
      try {
        const { data: employee, error: employeeError } = await admin.from("employees")
          .insert({ business_id: business.id, user_id: created.user.id, display_name: displayName, login_username: loginUsername, is_active: true })
          .select("id").single();
        if (employeeError) throw employeeError;
        employeeId = employee.id;

        const { error: mappingError } = await admin.from("employee_login_accounts")
          .insert({ employee_id: employeeId, login_username: loginUsername, auth_email: authEmail });
        if (mappingError) throw mappingError;
      } catch (error) {
        if (employeeId) await admin.from("employees").delete().eq("id", employeeId);
        await admin.auth.admin.deleteUser(created.user.id);
        throw error;
      }

      return json({ ok: true, employee_id: employeeId, login_username: loginUsername });
    }

    if (action === "reset_password") {
      if ((caller.email ?? "").toLowerCase() !== "gazitasdemir46@gmail.com" || callerProfile.is_admin !== true) {
        return json({ error: "Şifre sıfırlama yalnızca ana yöneticiye açıktır" }, 403);
      }
      const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
      const phone = typeof body.phone === "string" ? body.phone.trim() : "";
      const password = typeof body.password === "string" ? body.password : "";
      if (!email.includes("@") || !phone || password.length < 8 || password.length > 72) {
        return json({ error: "E-posta, telefon ve 8-72 karakterlik yeni şifre gerekli" }, 400);
      }
      const { data: target, error: targetError } = await admin.from("profiles")
        .select("id,phone").eq("email", email).maybeSingle();
      if (targetError) throw targetError;
      if (!target || phoneDigits(String(target.phone ?? "")) !== phoneDigits(phone) ||
          phoneDigits(phone).length !== 10 || !phoneDigits(phone).startsWith("5")) {
        return json({ error: "E-posta ve telefon bilgileri eşleşmedi" }, 400);
      }

      const { error: passwordError } = await admin.auth.admin.updateUserById(target.id, { password });
      if (passwordError) return json({ error: "Şifre güncellenemedi: " + passwordError.message }, 400);
      return json({ ok: true });
    }

    return json({ error: "Geçersiz işlem" }, 400);
  } catch (error) {
    console.error("Berberim account-admin failed:", error);
    return json({ error: "İşlem tamamlanamadı. Bilgileri ve yetkileri kontrol et." }, 500);
  }
});
