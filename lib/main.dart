import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

const gold = Color(0xFFF2B84B);
const ink = Color(0xFF151515);
const panel = Color(0xFF242424);
final auth = FirebaseAuth.instance;
final db = FirebaseFirestore.instance;
final functions = FirebaseFunctions.instance;
final Set<String> _registeredTokenUsers = {};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var ready = false;
  String? error;
  if (DefaultFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      ready = true;
    } catch (e) { error = e.toString(); }
  }
  runApp(BerberimApp(firebaseReady: ready, initError: error));
}

class BerberimApp extends StatelessWidget {
  const BerberimApp({super.key, required this.firebaseReady, this.initError});
  final bool firebaseReady;
  final String? initError;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Berberim', debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
      cardTheme: const CardThemeData(color: panel),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: gold, foregroundColor: ink, minimumSize: const Size.fromHeight(48))),
    ),
    home: firebaseReady ? const AuthGate() : SetupPage(error: initError),
  );
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key, this.error});
  final String? error;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(
    padding: const EdgeInsets.all(26), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.content_cut, size: 64, color: gold),
        const SizedBox(height: 16),
        const Text('Berberim', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        const Text('Uygulama kaynak kodu hazır. Canlı hesaplar ve randevular için Firebase projesi yapılandırılmalı.',
          textAlign: TextAlign.center, style: TextStyle(height: 1.5, color: Colors.white70)),
        const SizedBox(height: 12),
        const Text('Gerekli yapılandırma: FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID ve FIREBASE_PROJECT_ID.',
          textAlign: TextAlign.center, style: TextStyle(color: gold)),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12),
          child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))),
      ]),
    ),
  )));
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: auth.authStateChanges(),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: gold)));
      }
      final user = snap.data;
      if (user == null) return const SignInPage();
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: db.collection('users').doc(user.uid).snapshots(),
        builder: (context, profile) {
          if (profile.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: gold)));
          }
          if (profile.hasError) return ErrorPage(message: 'Profil yüklenemedi: ${profile.error}');
          if (!profile.hasData || !profile.data!.exists) return ProfileSetupPage(user: user);
          final data = profile.data!.data()!;
          _registerPushToken(user.uid);
          final role = data['role'] as String? ?? 'customer';
          if (role == 'admin') return const AdminPage();
          if (role == 'barber') {
            if (data['status'] != 'approved') return PendingPage(status: data['status'] ?? 'pending');
            return BarberPage(profile: data);
          }
          return CustomerPage(profile: data);
        },
      );
    },
  );

  void _registerPushToken(String uid) {
    if (_registeredTokenUsers.contains(uid)) return;
    _registeredTokenUsers.add(uid);
    Future<void>(() async {
      try {
        await FirebaseMessaging.instance.requestPermission();
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) await functions.httpsCallable('registerDeviceToken').call({'token': token});
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
          try { await functions.httpsCallable('registerDeviceToken').call({'token': token}); } catch (_) {}
        });
      } catch (_) {
        _registeredTokenUsers.remove(uid);
      }
    });
  }
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(
    padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center))));
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override State<SignInPage> createState() => _SignInPageState();
}
class _SignInPageState extends State<SignInPage> {
  final email = TextEditingController(), password = TextEditingController();
  bool create = false, busy = false;
  String error = '';
  Future<void> submit() async {
    setState(() { busy = true; error = ''; });
    try {
      if (create) {
        if (password.text.length < 8) throw Exception('Şifre en az 8 karakter olmalı.');
        await auth.createUserWithEmailAndPassword(email: email.text.trim(), password: password.text);
      } else {
        await auth.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
      }
    } on FirebaseAuthException catch (e) {
      error = switch (e.code) {
        'email-already-in-use' => 'Bu e-posta zaten kayıtlı.',
        'invalid-email' => 'E-posta biçimi geçersiz.',
        'weak-password' => 'Şifre yeterince güçlü değil.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' => 'E-posta veya şifre hatalı.',
        _ => e.message ?? 'Giriş başarısız.',
      };
    } catch (e) { error = e.toString().replaceFirst('Exception: ', ''); }
    if (mounted) setState(() => busy = false);
  }
  @override void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.content_cut, color: gold, size: 58),
        const SizedBox(height: 10),
        const Text('Berberim', textAlign: TextAlign.center, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(create ? 'Hesabını oluştur' : 'Hesabına giriş yap', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 28),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta')),
        const SizedBox(height: 12),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre')),
        if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error, style: const TextStyle(color: Colors.redAccent))),
        const SizedBox(height: 18),
        ElevatedButton(onPressed: busy ? null : submit, child: Text(busy ? 'Lütfen bekle…' : create ? 'Kayıt ol' : 'Giriş yap')),
        TextButton(onPressed: busy ? null : () => setState(() { create = !create; error = ''; }),
          child: Text(create ? 'Zaten hesabın var mı? Giriş yap' : 'Yeni hesap oluştur')),
      ]),
    ),
  )));
}

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key, required this.user});
  final User user;
  @override State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}
class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final name = TextEditingController(), code = TextEditingController(), phone = TextEditingController(), shop = TextEditingController();
  bool barber = false, busy = false;
  String error = '';
  Future<void> submit() async {
    if (name.text.trim().isEmpty || (barber && shop.text.trim().isEmpty) || (!barber && code.text.trim().isEmpty)) {
      setState(() => error = 'Lütfen gerekli alanları doldur.'); return;
    }
    setState(() { busy = true; error = ''; });
    try {
      final callable = functions.httpsCallable(barber ? 'applyForBarber' : 'joinWithBarberCode');
      await callable.call({
        'name': name.text.trim(), 'phone': phone.text.trim(),
        if (barber) 'shopName': shop.text.trim() else 'barberCode': code.text.trim().toUpperCase(),
      });
    } on FirebaseFunctionsException catch (e) {
      error = e.message ?? 'Kayıt tamamlanamadı.';
    } catch (e) { error = e.toString(); }
    if (mounted) setState(() => busy = false);
  }
  @override void dispose() { name.dispose(); code.dispose(); phone.dispose(); shop.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hesap bilgileri'), actions: [IconButton(onPressed: () => auth.signOut(), icon: const Icon(Icons.logout))]),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      SegmentedButton<bool>(segments: const [
        ButtonSegment(value: false, label: Text('Müşteriyim'), icon: Icon(Icons.person_outline)),
        ButtonSegment(value: true, label: Text('Berberim'), icon: Icon(Icons.storefront_outlined)),
      ], selected: {barber}, onSelectionChanged: (v) => setState(() { barber = v.first; error = ''; })),
      const SizedBox(height: 16),
      TextField(controller: name, decoration: InputDecoration(labelText: barber ? 'Yetkili adı soyadı' : 'Ad soyad')),
      if (barber) ...[
        const SizedBox(height: 12), TextField(controller: shop, decoration: const InputDecoration(labelText: 'İşletme adı')),
      ] else ...[
        const SizedBox(height: 12), TextField(controller: code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Berber işletme kodu')),
      ],
      const SizedBox(height: 12), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon (isteğe bağlı)')),
      if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error, style: const TextStyle(color: Colors.redAccent))),
      const SizedBox(height: 18),
      ElevatedButton(onPressed: busy ? null : submit, child: Text(busy ? 'Gönderiliyor…' : barber ? 'İşletme başvurusu gönder' : 'İşletme koduyla katıl')),
      const SizedBox(height: 8),
      const Text('Berber işletme başvuruları yönetici onayından sonra açılır.', style: TextStyle(color: Colors.white54)),
    ]),
  );
}

class PendingPage extends StatelessWidget {
  const PendingPage({super.key, required this.status});
  final String status;
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(
    padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.hourglass_top, size: 58, color: gold), const SizedBox(height: 18),
      Text(status == 'rejected' ? 'Başvurun reddedildi' : 'Başvurun inceleniyor',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      const Text('İşletmen, yönetici onayından sonra aktif olacaktır.', textAlign: TextAlign.center),
      const SizedBox(height: 20), OutlinedButton(onPressed: () => auth.signOut(), child: const Text('Çıkış yap')),
    ]),
  )));
}

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key, required this.profile});
  final Map<String, dynamic> profile;
  @override State<CustomerPage> createState() => _CustomerPageState();
}
class _CustomerPageState extends State<CustomerPage> {
  DateTime day = DateTime.now();
  String? serviceId, message;
  bool busy = false;
  String dateKey(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  Future<void> book(String time) async {
    if (serviceId == null) { setState(() => message = 'Önce hizmet seç.'); return; }
    setState(() { busy = true; message = null; });
    try {
      final parts = time.split(':').map(int.parse).toList();
      final localStart = DateTime(day.year, day.month, day.day, parts[0], parts[1]);
      await functions.httpsCallable('bookAppointment').call({'date': dateKey(day), 'time': time, 'startAtMillis': localStart.millisecondsSinceEpoch, 'serviceId': serviceId});
      if (mounted) setState(() => message = 'Randevun onaylandı.');
    } on FirebaseFunctionsException catch (e) {
      if (mounted) setState(() => message = e.message ?? 'Randevu oluşturulamadı.');
    } catch (e) { if (mounted) setState(() => message = e.toString()); }
    if (mounted) setState(() => busy = false);
  }
  @override Widget build(BuildContext context) {
    final barberId = widget.profile['barberId'] as String? ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Berberim'), actions: [IconButton(onPressed: () => auth.signOut(), icon: const Icon(Icons.logout))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Randevu oluştur', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('services').where('barberId', isEqualTo: barberId).where('isActive', isEqualTo: true).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return Text('Hizmetler yüklenemedi: ${snap.error}');
            if (!snap.hasData) return const LinearProgressIndicator();
            final docs = snap.data!.docs;
            if (docs.isEmpty) return const Text('Bu işletmede henüz hizmet eklenmemiş.');
            serviceId ??= docs.first.id;
            return DropdownButtonFormField<String>(
              value: docs.any((d) => d.id == serviceId) ? serviceId : docs.first.id,
              decoration: const InputDecoration(labelText: 'Hizmet seç'),
              items: docs.map((d) => DropdownMenuItem(value: d.id,
                child: Text('${d.data()['name']} • ${d.data()['price']} TL (${d.data()['durationMinutes']} dk)'))).toList(),
              onChanged: (v) => setState(() => serviceId = v),
            );
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () async {
          final picked = await showDatePicker(context: context, initialDate: day,
            firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
          if (picked != null) setState(() => day = picked);
        }, icon: const Icon(Icons.calendar_month), label: Text(dateKey(day))),
        if (message != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(message!, style: const TextStyle(color: gold))),
        const SizedBox(height: 8), const Text('Saat seç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(22, (i) {
          final minutes = 9 * 60 + i * 30;
          final time = '${(minutes ~/ 60).toString().padLeft(2,'0')}:${(minutes % 60).toString().padLeft(2,'0')}';
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: OutlinedButton(
            onPressed: busy ? null : () => book(time), child: Text(busy ? 'İşleniyor…' : time)));
        }),
        const SizedBox(height: 12),
        const Text('Saat çakışmaları sunucu tarafında kontrol edilir.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 20), const Text('Randevularım', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('appointments').where('customerId', isEqualTo: auth.currentUser!.uid).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return Text('Randevular yüklenemedi: ${snap.error}');
            if (!snap.hasData) return const LinearProgressIndicator();
            final docs = snap.data!.docs..sort((a,b) => (a.data()['startAt'] as Timestamp).compareTo(b.data()['startAt'] as Timestamp));
            if (docs.isEmpty) return const Text('Henüz randevu yok.');
            return Column(children: docs.map((d) {
              final a = d.data();
              return Card(child: ListTile(
                title: Text('${a['serviceName']} • ${a['status']}'),
                subtitle: Text((a['startAt'] as Timestamp).toDate().toLocal().toString()),
                trailing: a['status'] == 'confirmed' ? IconButton(icon: const Icon(Icons.cancel_outlined), onPressed: () async {
                  try { await functions.httpsCallable('cancelAppointment').call({'appointmentId': d.id}); }
                  catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
                }) : null,
              ));
            }).toList());
          },
        ),
      ]),
    );
  }
}

class BarberPage extends StatefulWidget {
  const BarberPage({super.key, required this.profile});
  final Map<String, dynamic> profile;
  @override State<BarberPage> createState() => _BarberPageState();
}
class _BarberPageState extends State<BarberPage> {
  final serviceName = TextEditingController(), price = TextEditingController(), duration = TextEditingController(text: '30');
  final opening = TextEditingController(text: '09:00'), closing = TextEditingController(text: '20:00');
  String? notice;
  Future<void> addService() async {
    final name = serviceName.text.trim(), p = int.tryParse(price.text), mins = int.tryParse(duration.text);
    if (name.isEmpty || p == null || p < 0 || mins == null || mins < 5 || mins > 360) {
      setState(() => notice = 'Hizmet adı, geçerli ücret ve 5–360 dakika süre gir.'); return;
    }
    try {
      await db.collection('services').add({'barberId': auth.currentUser!.uid, 'name': name, 'price': p,
        'durationMinutes': mins, 'isActive': true, 'createdAt': FieldValue.serverTimestamp()});
      serviceName.clear(); price.clear(); duration.text = '30';
      setState(() => notice = 'Hizmet eklendi.');
    } catch (e) { setState(() => notice = 'Hizmet eklenemedi: $e'); }
  }
  Future<void> saveHours() async {
    try {
      await functions.httpsCallable('updateBusinessHours').call({'opening': opening.text.trim(), 'closing': closing.text.trim()});
      if (mounted) setState(() => notice = 'Çalışma saatleri kaydedildi.');
    } on FirebaseFunctionsException catch (e) {
      if (mounted) setState(() => notice = e.message ?? 'Saatler kaydedilemedi.');
    }
  }
  @override void dispose() { serviceName.dispose(); price.dispose(); duration.dispose(); opening.dispose(); closing.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.profile['shopName'] ?? 'Berber paneli'), actions: [IconButton(onPressed: () => auth.signOut(), icon: const Icon(Icons.logout))]),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('İşletme paneli', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      SelectableText('İşletme kodu: ${widget.profile['barberCode'] ?? 'Kod hazırlanıyor'}',
        style: const TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 18), const Text('Çalışma saatleri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(controller: opening, decoration: const InputDecoration(labelText: 'Açılış (SS:DD)'))),
        const SizedBox(width: 10),
        Expanded(child: TextField(controller: closing, decoration: const InputDecoration(labelText: 'Kapanış (SS:DD)'))),
      ]),
      const SizedBox(height: 10), OutlinedButton(onPressed: saveHours, child: const Text('Çalışma saatlerini kaydet')),
      const SizedBox(height: 18), const Text('Hizmet yönetimi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10), TextField(controller: serviceName, decoration: const InputDecoration(labelText: 'Hizmet adı')),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ücret (TL)'))),
        const SizedBox(width: 10),
        Expanded(child: TextField(controller: duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Süre (dk)'))),
      ]),
      const SizedBox(height: 10), ElevatedButton(onPressed: addService, child: const Text('Hizmet ekle')),
      if (notice != null) Padding(padding: const EdgeInsets.all(8), child: Text(notice!, style: const TextStyle(color: gold))),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('services').where('barberId', isEqualTo: auth.currentUser!.uid).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Text('Hizmetler yüklenemedi: ${snap.error}');
          if (!snap.hasData) return const LinearProgressIndicator();
          return Column(children: snap.data!.docs.map((d) => Card(child: ListTile(
            title: Text(d.data()['name'] ?? ''), subtitle: Text('${d.data()['price']} TL • ${d.data()['durationMinutes']} dk'),
            trailing: Switch(value: d.data()['isActive'] == true, onChanged: (v) => d.reference.update({'isActive': v})),
          ))).toList());
        },
      ),
      const SizedBox(height: 18), const Text('Randevular', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('appointments').where('barberId', isEqualTo: auth.currentUser!.uid).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Text('Randevular yüklenemedi: ${snap.error}');
          if (!snap.hasData) return const LinearProgressIndicator();
          if (snap.data!.docs.isEmpty) return const Text('Henüz randevu yok.');
          return Column(children: snap.data!.docs.map((d) {
            final a = d.data();
            return Card(child: ListTile(
              title: Text('${a['serviceName']} • ${a['status']}'),
              subtitle: Text((a['startAt'] as Timestamp).toDate().toLocal().toString()),
              trailing: a['status'] == 'confirmed' ? IconButton(icon: const Icon(Icons.cancel_outlined),
                onPressed: () async { try { await functions.httpsCallable('cancelAppointment').call({'appointmentId': d.id}); }
                  catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } }) : null,
            ));
          }).toList());
        },
      ),
    ]),
  );
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yönetici paneli'), actions: [IconButton(onPressed: () => auth.signOut(), icon: const Icon(Icons.logout))]),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('barberApplications').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Başvurular yüklenemedi: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: gold));
        if (snap.data!.docs.isEmpty) return const Center(child: Text('Bekleyen başvuru yok.'));
        return ListView(padding: const EdgeInsets.all(16), children: snap.data!.docs.map((d) {
          final a = d.data();
          return Card(child: ListTile(
            title: Text(a['shopName'] ?? 'İsimsiz işletme'),
            subtitle: Text('${a['name'] ?? ''} • ${a['email'] ?? ''}'),
            trailing: PopupMenuButton<String>(onSelected: (v) async {
              try { await functions.httpsCallable('reviewBarberApplication').call({'applicationId': d.id, 'decision': v}); }
              catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
            }, itemBuilder: (_) => const [
              PopupMenuItem(value: 'approve', child: Text('Onayla')),
              PopupMenuItem(value: 'reject', child: Text('Reddet')),
            ]),
          ));
        }).toList());
      },
    ),
  );
}
