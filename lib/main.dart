import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const gold = Color(0xFFD6A64B);
const goldLight = Color(0xFFF0D18A);
const ink = Color(0xFF090A0C);
const panel = Color(0xFF14161A);
const ivory = Color(0xFFF5F2EB);
const muted = Color(0xFF9298A3);
const border = Color(0xFF2B2F36);
final sb = Supabase.instance.client;
String get uid => sb.auth.currentUser!.id;
String err(Object e) => e.toString().replaceFirst('Exception: ', '').replaceFirst('PostgrestException(message: ', '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: key);
  }
  runApp(const BerberimApp());
}

class BerberimApp extends StatelessWidget {
  const BerberimApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Berberim',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      canvasColor: ink,
      dividerColor: border,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: Color(0xFF17130B),
        secondary: goldLight,
        onSecondary: Color(0xFF17130B),
        surface: panel,
        onSurface: ivory,
        error: Color(0xFFFF6B70),
        onError: Color(0xFF25090B),
      ),
      textTheme: ThemeData.dark(useMaterial3: true).textTheme.apply(
        bodyColor: ivory,
        displayColor: ivory,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ink,
        foregroundColor: ivory,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.45,
          color: ivory,
        ),
        iconTheme: IconThemeData(color: ivory, size: 23),
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: muted),
        prefixIconColor: gold,
        suffixIconColor: muted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: gold, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFFF6B70)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFFF6B70), width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: const Color(0xFF17130B),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ivory,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: border),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: goldLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel,
        indicatorColor: const Color(0x33D6A64B),
        elevation: 0,
        height: 72,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: panel,
        modalBackgroundColor: panel,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: panel,
        headerBackgroundColor: gold,
        headerForegroundColor: const Color(0xFF17130B),
        todayForegroundColor: const WidgetStatePropertyAll(gold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF24272D),
        contentTextStyle: const TextStyle(color: ivory),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: gold),
      iconTheme: const IconThemeData(color: ivory, size: 22),
      listTileTheme: const ListTileThemeData(
        iconColor: gold,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 28,
      ),
    ),
    home: const ConfigGate(),
  );
}

class ConfigGate extends StatelessWidget {
  const ConfigGate({super.key});
  @override Widget build(BuildContext context) {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isEmpty || key.isEmpty) return const SetupPage();
    return const AuthGate();
  }
}


void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class AppPanel extends StatelessWidget {
  const AppPanel({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.margin});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    padding: padding,
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: border),
    ),
    child: child,
  );
}

class ScreenHeading extends StatelessWidget {
  const ScreenHeading({super.key, required this.title, required this.subtitle, this.eyebrow, this.icon});
  final String title;
  final String subtitle;
  final String? eyebrow;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (icon != null) Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: gold.withValues(alpha: .13), borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: gold, size: 24),
      ),
      if (icon != null) const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (eyebrow != null) Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(eyebrow!.toUpperCase(), style: const TextStyle(color: gold, fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w800)),
        ),
        Text(title, style: const TextStyle(fontSize: 25, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -.65)),
        const SizedBox(height: 7),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 13, height: 1.45)),
      ])),
    ]),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 7),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -.25))),
      if (action != null) action!,
    ]),
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(
      width: compact ? 54 : 68, height: compact ? 54 : 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 17 : 21),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [goldLight, gold]),
        boxShadow: [BoxShadow(color: gold.withValues(alpha: .17), blurRadius: 24, offset: const Offset(0, 9))],
      ),
      child: Icon(Icons.content_cut_rounded, color: ink, size: compact ? 27 : 34),
    ),
    const SizedBox(height: 12),
    const Text('BERBERİM', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: 3.2)),
    const SizedBox(height: 3),
    const Text('BAKIMININ YENİ RANDEVU NOKTASI', style: TextStyle(color: muted, fontSize: 9, letterSpacing: 1.25, fontWeight: FontWeight.w700)),
  ]);
}

class StatusTag extends StatelessWidget {
  const StatusTag(this.label, {super.key, this.color = gold});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(30), border: Border.all(color: color.withValues(alpha: .25))),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
  );
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 22),
    child: Column(children: [
      Container(width: 62, height: 62, decoration: BoxDecoration(color: gold.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: gold, size: 29)),
      const SizedBox(height: 15),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 6),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.45, fontSize: 13)),
    ]),
  );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: const TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w700)),
  );
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: AppPanel(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const BrandMark(),
        const SizedBox(height: 25),
        const StatusTag('YAPILANDIRMA GEREKLİ', color: Colors.orangeAccent),
        const SizedBox(height: 14),
        const Text('Bağlantı ayarları bulunamadı', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 9),
        const Text('Uygulamanın çalışması için derleme sırasında Supabase bağlantı değişkenleri tanımlanmalı.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.5, fontSize: 13)),
      ])),
    ))),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: sb.auth.onAuthStateChange,
    builder: (context, _) {
      if (sb.auth.currentUser == null) return const LoginPage();
      return FutureBuilder<Map<String,dynamic>?>(
        future: sb.from('profiles').select().eq('id', uid).maybeSingle(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingPage();
          if (snap.hasError) return ErrorPage(message: err(snap.error!));
          if (snap.data == null) return const ProfilePage();
          final p = snap.data!;
          if (p['is_blocked'] == true) return const BlockedPage();
          if (p['is_admin'] == true) return const AdminPage();
          return FutureBuilder<List<Map<String,dynamic>>>(
            future: sb.from('businesses').select().eq('owner_id', uid).order('created_at'),
            builder: (context, owned) {
              if (owned.connectionState != ConnectionState.done) return const LoadingPage();
              if (owned.hasError) return ErrorPage(message: err(owned.error!));
              if ((owned.data ?? []).isNotEmpty) {
                final active = (owned.data!).where((b)=>b['status']=='active').toList();
                if (active.isEmpty) return PendingPage(business: owned.data!.first);
                return BarberPage(business: active.first);
              }
              if (p['account_type']=='business_owner') return const ProfilePage();
              return const CustomerPage();
            });
        });
    });
}

class BlockedPage extends StatelessWidget {
  const BlockedPage({super.key});
  @override Widget build(BuildContext c) => Scaffold(body: Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: AppPanel(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.lock_person_rounded, color: Colors.redAccent, size: 52),
      const SizedBox(height: 18),
      const Text('Hesabına geçici olarak erişilemiyor', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 9),
      const Text('Hesabın yönetim tarafından geçici olarak kısıtlandı. Detaylar için işletme yönetimiyle iletişime geçebilirsin.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.5)),
      const SizedBox(height: 22),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => sb.auth.signOut(), icon: const Icon(Icons.logout_rounded), label: const Text('Çıkış yap'))),
    ]))),
  )));
}
class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});
  @override Widget build(BuildContext c) => Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3, color: gold)),
    const SizedBox(height: 18),
    Text('Hazırlanıyor…', style: Theme.of(c).textTheme.bodyMedium?.copyWith(color: muted, fontWeight: FontWeight.w600)),
  ])));
}
class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.message});
  final String message;
  @override Widget build(BuildContext c) => Scaffold(body: Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: AppPanel(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 42),
      const SizedBox(height: 14),
      const Text('Bir sorun oluştu', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      const SizedBox(height: 9),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.45)),
    ]))),
  )));
}

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState()=>_LoginPageState(); }
class _LoginPageState extends State<LoginPage>{
 final email=TextEditingController(),pass=TextEditingController(); bool create=false,busy=false; String message=''; String accountType='customer';
 Future<void> submit() async {setState(()=>busy=true);message='';try{if(create){if(pass.text.length<8)throw Exception('Şifre en az 8 karakter olmalı.');final result=await sb.auth.signUp(email:email.text.trim(),password:pass.text,emailRedirectTo:'berberim://login-callback',data:{'account_type':accountType});if(result.session==null)message='Doğrulama e-postası gönderildi. E-postandaki bağlantıya dokun; Berberim uygulaması açılacak.';}else{await sb.auth.signInWithPassword(email:email.text.trim(),password:pass.text);}}catch(e){message=err(e);}if(mounted)setState(()=>busy=false);}
 @override Widget build(BuildContext c)=>Scaffold(
  body: Stack(children: [
   Positioned(top:-120,right:-90,child:Container(width:300,height:300,decoration:BoxDecoration(shape:BoxShape.circle,color:gold.withValues(alpha:.045)))),
   SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24,30,24,30), child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
     const BrandMark(),
     const SizedBox(height: 34),
     AppPanel(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(create ? 'Hesabını oluştur' : 'Tekrar hoş geldin', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -.5)),
      const SizedBox(height: 6),
      Text(create ? 'Berberim ile randevularını kolayca yönet.' : 'Devam etmek için hesabına giriş yap.', style: const TextStyle(color: muted, fontSize: 13)),
      if(create)...[
       const SizedBox(height: 22),
       const FieldLabel('HESAP TÜRÜ'),
       SegmentedButton<String>(
        showSelectedIcon: false,
        segments: const [
         ButtonSegment(value:'customer',label:Text('Müşteri'),icon:Icon(Icons.person_outline_rounded)),
         ButtonSegment(value:'business_owner',label:Text('İşletme'),icon:Icon(Icons.storefront_outlined)),
        ],
        selected:{accountType}, onSelectionChanged:(v)=>setState(()=>accountType=v.first),
       ),
      ],
      const SizedBox(height: 20),
      const FieldLabel('E-POSTA ADRESİ'),
      TextField(controller:email,keyboardType:TextInputType.emailAddress,autofillHints:const [AutofillHints.email],decoration:const InputDecoration(hintText:'ornek@email.com',prefixIcon:Icon(Icons.mail_outline_rounded))),
      const SizedBox(height: 16),
      const FieldLabel('ŞİFRE'),
      TextField(controller:pass,obscureText:true,autofillHints:const [AutofillHints.password],decoration:const InputDecoration(hintText:'Şifreni gir',prefixIcon:Icon(Icons.lock_outline_rounded))),
      if(create&&accountType=='business_owner')const Padding(padding:EdgeInsets.only(top:12),child:Text('İşletme hesabı yönetici onayından sonra açılır.',style:TextStyle(color:muted,fontSize:12))),
      if(message.isNotEmpty)Container(margin:const EdgeInsets.only(top:16),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:(message.startsWith('Doğrulama e-postası gönderildi')?Colors.greenAccent:Colors.redAccent).withValues(alpha:.09),borderRadius:BorderRadius.circular(13)),child:Text(message,style:TextStyle(color:message.startsWith('Doğrulama e-postası gönderildi')?Colors.greenAccent:Colors.redAccent,fontSize:12,height:1.4))),
      const SizedBox(height: 22),
      SizedBox(height:54,child:ElevatedButton(onPressed:busy?null:submit,child:busy?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:ink)):Text(create?'Hesap oluştur':'Giriş yap'))),
      const SizedBox(height: 10),
      Center(child:TextButton(onPressed:()=>setState(()=>create=!create),child:Text(create?'Zaten hesabın var mı? Giriş yap':'Hesabın yok mu? Kayıt ol'))),
     ]),
     ),
     const SizedBox(height: 20),
     const Center(child:Text('GÜVENLİ • KOLAY • KİŞİSEL',style:TextStyle(color:muted,fontSize:10,letterSpacing:1.8,fontWeight:FontWeight.w700))),
    ]),
   )))),
  ]),
 );
}

class ProfilePage extends StatefulWidget { const ProfilePage({super.key}); @override State<ProfilePage> createState()=>_ProfilePageState(); }
class _ProfilePageState extends State<ProfilePage>{
 final name=TextEditingController(),phone=TextEditingController(),shop=TextEditingController(),address=TextEditingController();bool busy=false;String message='';
 Future<void> save()async{setState(()=>busy=true);message='';try{await sb.from('profiles').update({'full_name':name.text.trim(),'phone':phone.text.trim(),'account_type':'business_owner'}).eq('id',uid);await sb.rpc('create_business_application',params:{'p_name':shop.text.trim(),'p_address':address.text.trim().isEmpty?null:address.text.trim()});}catch(e){message=err(e);}if(mounted){setState(()=>busy=false);if(message.isEmpty)Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const AuthGate()),(r)=>false);}}
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:const Text('İşletme başvurusu'),actions:[IconButton(tooltip:'Çıkış yap',onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout_rounded))]),
  body:ListView(padding:const EdgeInsets.fromLTRB(20,12,20,30),children:[
   const ScreenHeading(eyebrow:'BERBERİM İŞ ORTAĞI',title:'İşletmeni tanıtalım',subtitle:'Bilgilerini paylaş, başvurunu inceleyelim. Onaydan sonra işletme panelin açılacak.',icon:Icons.storefront_rounded),
   AppPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const SectionHeading('Yetkili bilgileri'),
    const FieldLabel('AD SOYAD'),
    TextField(controller:name,decoration:const InputDecoration(hintText:'Adın ve soyadın',prefixIcon:Icon(Icons.person_outline_rounded))),
    const SizedBox(height:16),
    const FieldLabel('TELEFON'),
    TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(hintText:'05xx xxx xx xx',prefixIcon:Icon(Icons.phone_outlined))),
    const SizedBox(height:22),
    const SectionHeading('İşletme bilgileri'),
    const FieldLabel('İŞLETME ADI'),
    TextField(controller:shop,decoration:const InputDecoration(hintText:'Berber dükkanının adı',prefixIcon:Icon(Icons.storefront_outlined))),
    const SizedBox(height:16),
    const FieldLabel('ADRES (İSTEĞE BAĞLI)'),
    TextField(controller:address,maxLines:2,decoration:const InputDecoration(hintText:'Mahalle, cadde, sokak…',prefixIcon:Icon(Icons.location_on_outlined))),
    if(message.isNotEmpty)Padding(padding:const EdgeInsets.only(top:14),child:Text(message,style:const TextStyle(color:Colors.redAccent))),
    const SizedBox(height:22),
    SizedBox(height:52,child:ElevatedButton.icon(onPressed:busy?null:save,icon:const Icon(Icons.send_rounded),label:Text(busy?'Gönderiliyor…':'Başvuruyu gönder'))),
   ])),
  ]),
 );
}

class PendingPage extends StatelessWidget {const PendingPage({super.key,required this.business});final Map<String,dynamic> business;
 @override Widget build(BuildContext c){
  final status=business['status'];
  final rejected=status=='rejected', inactive=status=='inactive';
  final title=rejected?'Başvurun reddedildi':inactive?'İşletmen devre dışı':'Başvurun inceleniyor';
  final description=status=='pending'?'Başvurunu aldık. Yönetici incelemesi tamamlandığında işletme panelin otomatik olarak açılacak.':'Başvuru durumunla ilgili detaylı bilgi almak için yönetimle iletişime geçebilirsin.';
  return Scaffold(appBar:AppBar(title:const Text('Başvuru durumu'),actions:[IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout_rounded))]),body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:AppPanel(padding:const EdgeInsets.all(26),child:Column(mainAxisSize:MainAxisSize.min,children:[
   Container(width:76,height:76,decoration:BoxDecoration(color:(rejected?Colors.redAccent:gold).withValues(alpha:.12),borderRadius:BorderRadius.circular(24)),child:Icon(rejected?Icons.info_outline_rounded:inactive?Icons.pause_circle_outline_rounded:Icons.hourglass_top_rounded,color:rejected?Colors.redAccent:gold,size:38)),
   const SizedBox(height:22),
   StatusTag(rejected?'REDDEDİLDİ':inactive?'PASİF':'İNCELEMEDE',color:rejected?Colors.redAccent:gold),
   const SizedBox(height:13),
   Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w800)),
   const SizedBox(height:9),
   Text(business['name']??'',textAlign:TextAlign.center,style:const TextStyle(color:gold,fontWeight:FontWeight.w700,fontSize:16)),
   const SizedBox(height:12),
   Text(description,textAlign:TextAlign.center,style:const TextStyle(color:muted,height:1.5,fontSize:13)),
   const SizedBox(height:24),
   SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:()=>Navigator.of(c).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const AuthGate()),(r)=>false),icon:const Icon(Icons.refresh_rounded),label:const Text('Durumu yenile'))),
  ]))))));
 }
}

class AdminPage extends StatefulWidget {const AdminPage({super.key});@override State<AdminPage> createState()=>_AdminPageState();}
class _AdminPageState extends State<AdminPage>{
 int tab=0;
 Future<List<Map<String,dynamic>>> load(String table)=>sb.from(table).select().order('created_at',ascending:false);
 Future<void> review(String id,String status)async{try{await sb.rpc('review_business',params:{'p_business_id':id,'p_status':status});if(mounted)setState((){});toast(context,'İşletme durumu güncellendi');}catch(e){toast(context,err(e));}}
 Future<void> block(String id,bool value)async{try{await sb.rpc('admin_set_user_blocked',params:{'p_user_id':id,'p_blocked':value});if(mounted)setState((){});}catch(e){toast(context,err(e));}}
 Widget heading(String a,String b)=>ScreenHeading(title:a,subtitle:b,eyebrow:'BERBERİM YÖNETİM',icon:Icons.admin_panel_settings_rounded);
 Widget metric(String label,int n,IconData icon)=>Expanded(child:AppPanel(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Container(width:36,height:36,decoration:BoxDecoration(color:gold.withValues(alpha:.12),borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:gold,size:19)),
  const SizedBox(height:13),Text('$n',style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900,letterSpacing:-.8)),
  const SizedBox(height:3),Text(label,style:const TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w600)),
 ])));
 Widget navCard(String title,String subtitle,IconData icon,int destination)=>AppPanel(
  padding:const EdgeInsets.symmetric(horizontal:15,vertical:5),
  margin:const EdgeInsets.only(bottom:10),
  child:ListTile(contentPadding:EdgeInsets.zero,leading:Container(width:42,height:42,decoration:BoxDecoration(color:gold.withValues(alpha:.12),borderRadius:BorderRadius.circular(13)),child:Icon(icon,color:gold)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(subtitle,style:const TextStyle(color:muted,fontSize:12)),trailing:const Icon(Icons.chevron_right_rounded,color:muted),onTap:()=>setState(()=>tab=destination)),
 );
 Widget dashboard()=>FutureBuilder<List<dynamic>>(future:Future.wait([load('profiles'),load('businesses'),load('appointments')]),builder:(c,s){
  if(s.connectionState!=ConnectionState.done)return const LoadingPage();if(s.hasError)return ErrorPage(message:err(s.error!));
  final p=s.data![0] as List,b=s.data![1] as List,a=s.data![2] as List;final pending=b.where((x)=>x['status']=='pending').length;
  return ListView(padding:const EdgeInsets.fromLTRB(18,14,18,28),children:[
   heading('Genel bakış','Platformdaki kullanıcıları, işletmeleri ve randevuları tek yerden takip et.'),
   Row(children:[metric('Kullanıcı',p.length,Icons.people_alt_outlined),const SizedBox(width:10),metric('İşletme',b.length,Icons.storefront_outlined)]),
   const SizedBox(height:10),
   Row(children:[metric('Bekleyen başvuru',pending,Icons.hourglass_top_rounded),const SizedBox(width:10),metric('Randevu',a.length,Icons.calendar_month_rounded)]),
   const SizedBox(height:24),const SectionHeading('Hızlı yönetim'),
   navCard('İşletme başvuruları','Başvuruları incele ve durumlarını yönet',Icons.storefront_rounded,1),
   navCard('Kullanıcı yönetimi','Hesapları ve erişim izinlerini kontrol et',Icons.manage_accounts_rounded,2),
   navCard('Randevular','Platformdaki randevuları görüntüle',Icons.event_available_rounded,3),
  ]);
 });
 Widget businesses()=>FutureBuilder<List<Map<String,dynamic>>>(future:load('businesses'),builder:(c,s){
  if(s.connectionState!=ConnectionState.done)return const LoadingPage();if(s.hasError)return ErrorPage(message:err(s.error!));final l=s.data??[];
  return ListView(padding:const EdgeInsets.fromLTRB(18,14,18,28),children:[
   heading('İşletmeler','İşletme başvurularını ve yayın durumlarını yönet.'),
   if(l.isEmpty)const EmptyStateView(icon:Icons.storefront_outlined,title:'Henüz işletme yok',subtitle:'Yeni işletme başvuruları burada görüntülenecek.'),
   ...l.map((b)=>AppPanel(margin:const EdgeInsets.only(bottom:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Expanded(child:Text(b['name']??'İsimsiz işletme',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800))),StatusTag((b['status']??'').toString().toUpperCase(),color:b['status']=='active'?Colors.greenAccent:b['status']=='rejected'?Colors.redAccent:gold)]),
    const SizedBox(height:10),Text('Katılım kodu: ${b['join_code']??'—'}',style:const TextStyle(color:gold,fontWeight:FontWeight.w700,fontSize:12)),
    if((b['address']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:7),child:Text(b['address'],style:const TextStyle(color:muted,fontSize:12))),
    const Divider(height:24),
    Wrap(spacing:8,runSpacing:8,children:[
     if(b['status']!='active')OutlinedButton.icon(onPressed:()=>review(b['id'],'active'),icon:const Icon(Icons.check_rounded,size:16),label:const Text('Onayla')),
     if(b['status']!='rejected')TextButton.icon(onPressed:()=>review(b['id'],'rejected'),icon:const Icon(Icons.close_rounded,size:16),label:const Text('Reddet')),
     if(b['status']!='inactive')TextButton.icon(onPressed:()=>review(b['id'],'inactive'),icon:const Icon(Icons.pause_rounded,size:16),label:const Text('Pasife al')),
    ]),
   ]))),
  ]);
 });
 Widget users()=>FutureBuilder<List<Map<String,dynamic>>>(future:load('profiles'),builder:(c,s){
  if(s.connectionState!=ConnectionState.done)return const LoadingPage();if(s.hasError)return ErrorPage(message:err(s.error!));
  return ListView(padding:const EdgeInsets.fromLTRB(18,14,18,28),children:[
   heading('Kullanıcılar','Hesap türlerini görüntüle ve erişim durumlarını yönet.'),
   if((s.data??[]).isEmpty)const EmptyStateView(icon:Icons.people_outline,title:'Kullanıcı bulunamadı',subtitle:'Kayıt olan kullanıcılar burada listelenecek.'),
   ...(s.data??[]).map((p)=>AppPanel(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.symmetric(horizontal:15,vertical:8),child:Row(children:[
    CircleAvatar(backgroundColor:gold.withValues(alpha:.14),child:Icon(p['account_type']=='business_owner'?Icons.storefront_rounded:Icons.person_rounded,color:gold)),
    const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(p['full_name']??'İsimsiz kullanıcı',style:const TextStyle(fontWeight:FontWeight.w800)),
     const SizedBox(height:3),Text(p['email']??'E-posta yok',style:const TextStyle(color:muted,fontSize:11)),
     Text(p['account_type']=='business_owner'?'İşletme hesabı':'Müşteri hesabı',style:const TextStyle(color:gold,fontSize:11,fontWeight:FontWeight.w700)),
    ])),
    Column(children:[Text(p['is_blocked']==true?'Engelli':'Aktif',style:TextStyle(color:p['is_blocked']==true?Colors.redAccent:Colors.greenAccent,fontSize:10,fontWeight:FontWeight.w700)),Switch(value:p['is_blocked']==true,onChanged:(v)=>block(p['id'],v))]),
   ]))),
  ]);
 });
 Widget appointments()=>FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('appointments').select('*, businesses(name), services(name)').order('starts_at',ascending:false).limit(250),builder:(c,s){
  if(s.connectionState!=ConnectionState.done)return const LoadingPage();if(s.hasError)return ErrorPage(message:err(s.error!));
  return ListView(padding:const EdgeInsets.fromLTRB(18,14,18,28),children:[
   heading('Randevular','Platform genelindeki son 250 randevuyu görüntüle.'),
   if((s.data??[]).isEmpty)const EmptyStateView(icon:Icons.event_busy_rounded,title:'Henüz randevu yok',subtitle:'Oluşturulan randevular burada görünecek.'),
   ...(s.data??[]).map((a)=>AppPanel(margin:const EdgeInsets.only(bottom:10),child:Row(children:[
    Container(width:44,height:44,decoration:BoxDecoration(color:gold.withValues(alpha:.12),borderRadius:BorderRadius.circular(14)),child:const Icon(Icons.calendar_month_rounded,color:gold)),
    const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(a['services']?['name']??'Randevu',style:const TextStyle(fontWeight:FontWeight.w800)),
     const SizedBox(height:4),Text(a['businesses']?['name']??'İşletme',style:const TextStyle(color:muted,fontSize:12)),
     Text('${a['starts_at']} • ${a['status']}',style:const TextStyle(color:gold,fontSize:11,fontWeight:FontWeight.w600)),
    ])),
   ]))),
  ]);
 });
 @override Widget build(BuildContext c){
  final pages=[dashboard(),businesses(),users(),appointments()];
  return Scaffold(
   appBar:AppBar(title:const Text('Yönetim merkezi'),actions:[IconButton(tooltip:'Yenile',onPressed:()=>setState((){}),icon:const Icon(Icons.refresh_rounded)),IconButton(tooltip:'Çıkış yap',onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout_rounded))]),
   body:pages[tab],
   bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const [
    NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard_rounded),label:'Genel'),
    NavigationDestination(icon:Icon(Icons.storefront_outlined),selectedIcon:Icon(Icons.storefront_rounded),label:'İşletmeler'),
    NavigationDestination(icon:Icon(Icons.people_outline),selectedIcon:Icon(Icons.people_rounded),label:'Kullanıcılar'),
    NavigationDestination(icon:Icon(Icons.calendar_month_outlined),selectedIcon:Icon(Icons.calendar_month_rounded),label:'Randevular'),
   ]),
  );
 }
}

class BarberPage extends StatefulWidget { const BarberPage({super.key,required this.business}); final Map<String,dynamic> business; @override State<BarberPage> createState()=>_BarberPageState(); }
class _BarberPageState extends State<BarberPage>{
 final service=TextEditingController(),price=TextEditingController(),duration=TextEditingController(text:'30'),employee=TextEditingController(),open=TextEditingController(text:'09:00'),close=TextEditingController(text:'20:00'),breakStart=TextEditingController(text:'13:00'),breakEnd=TextEditingController(text:'14:00');
 bool busy=false; Future<void> refresh()async{if(mounted)setState((){});}
 Future<void> addService()async{try{await sb.from('services').insert({'business_id':widget.business['id'],'name':service.text.trim(),'price':double.parse(price.text),'duration_minutes':int.parse(duration.text)});service.clear();price.clear();refresh();}catch(e){toast(context,err(e));}}
 Future<void> addEmployee()async{try{await sb.from('employees').insert({'business_id':widget.business['id'],'display_name':employee.text.trim()});employee.clear();refresh();}catch(e){toast(context,err(e));}}
 Future<void> saveHours()async{try{for(var d=0;d<7;d++){await sb.from('business_hours').upsert({'business_id':widget.business['id'],'weekday':d,'opens_at':open.text,'closes_at':close.text,'is_closed':false},onConflict:'business_id,weekday');}toast(context,'Çalışma saatleri kaydedildi');}catch(e){toast(context,err(e));}}
 Future<void> saveBreaks()async{try{final a=breakStart.text.trim(),b=breakEnd.text.trim();if(a.compareTo(b)>=0)throw Exception('Mola bitişi başlangıçtan sonra olmalı');await sb.from('business_breaks').delete().eq('business_id',widget.business['id']);for(var d=1;d<7;d++){await sb.from('business_breaks').insert({'business_id':widget.business['id'],'weekday':d,'starts_at':a,'ends_at':b});}toast(context,'Mola saatleri kaydedildi');}catch(e){toast(context,err(e));}}
 Widget groupTitle(String title,String caption,IconData icon)=>Padding(padding:const EdgeInsets.only(bottom:14),child:Row(children:[
  Container(width:38,height:38,decoration:BoxDecoration(color:gold.withValues(alpha:.12),borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:gold,size:19)),
  const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800)),Text(caption,style:const TextStyle(fontSize:11,color:muted))])),
 ]));
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:Text(widget.business['name']),actions:[notificationAction(context),IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout_rounded))]),
  body:ListView(padding:const EdgeInsets.fromLTRB(18,12,18,30),children:[
   const ScreenHeading(eyebrow:'İŞLETME PANELİ',title:'İşletmeni yönet',subtitle:'Çalışma düzenini, ekibini, hizmetlerini ve randevularını tek ekrandan kontrol et.',icon:Icons.storefront_rounded),
   AppPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Icon(Icons.qr_code_rounded,color:gold,size:22),const SizedBox(width:9),const Expanded(child:Text('İşletme katılım kodu',style:TextStyle(fontWeight:FontWeight.w800))),const StatusTag('AKTİF',color:Colors.greenAccent)]),
    const SizedBox(height:12),
    Container(width:double.infinity,padding:const EdgeInsets.symmetric(vertical:17),decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(15)),child:SelectableText(widget.business['join_code']??'—',textAlign:TextAlign.center,style:const TextStyle(color:gold,fontSize:27,fontWeight:FontWeight.w900,letterSpacing:3))),
    const SizedBox(height:8),const Text('Müşterilerin bu kodla işletmene katılabilir.',style:TextStyle(color:muted,fontSize:11)),
   ])),
   const SizedBox(height:14),
   AppPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    groupTitle('Çalışma saatleri','Haftalık açılış ve kapanış saatleri',Icons.schedule_rounded),
    Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const FieldLabel('AÇILIŞ'),TextField(controller:open,decoration:const InputDecoration(hintText:'09:00'))])),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const FieldLabel('KAPANIŞ'),TextField(controller:close,decoration:const InputDecoration(hintText:'20:00'))]))]),
    const SizedBox(height:13),OutlinedButton.icon(onPressed:saveHours,icon:const Icon(Icons.calendar_month_rounded),label:const Text('Haftanın tüm günlerine uygula')),
    const Divider(height:30),
    const FieldLabel('MOLA SAATLERİ'),
    Row(children:[Expanded(child:TextField(controller:breakStart,decoration:const InputDecoration(labelText:'Başlangıç'))),const SizedBox(width:12),Expanded(child:TextField(controller:breakEnd,decoration:const InputDecoration(labelText:'Bitiş')))]),
    const SizedBox(height:12),OutlinedButton(onPressed:saveBreaks,child:const Text('Hafta içi molalarını kaydet')),
   ])),
   const SizedBox(height:14),
   AppPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    groupTitle('Çalışanlar','Ekibini oluştur ve çalışanlarını takip et',Icons.groups_rounded),
    const FieldLabel('ÇALIŞAN ADI'),
    TextField(controller:employee,decoration:const InputDecoration(hintText:'Çalışan adı',prefixIcon:Icon(Icons.person_add_alt_1_rounded))),
    const SizedBox(height:12),OutlinedButton.icon(onPressed:addEmployee,icon:const Icon(Icons.add_rounded),label:const Text('Çalışan ekle')),
    const Divider(height:28),
    FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('employees').select().eq('business_id',widget.business['id']),builder:(c,s){
     if(s.connectionState!=ConnectionState.done)return const LinearProgressIndicator();
     if(s.hasError)return Text(err(s.error!),style:const TextStyle(color:Colors.redAccent));
     if((s.data??[]).isEmpty)return const Text('Henüz çalışan eklenmedi.',style:TextStyle(color:muted,fontSize:12));
     return Column(children:(s.data??[]).map((e)=>ListTile(contentPadding:EdgeInsets.zero,leading:const CircleAvatar(backgroundColor:ink,child:Icon(Icons.person_outline,color:gold)),title:Text(e['display_name']??'Çalışan',style:const TextStyle(fontWeight:FontWeight.w700)),trailing:StatusTag(e['is_active']==true?'AKTİF':'PASİF',color:e['is_active']==true?Colors.greenAccent:muted))).toList());
    }),
   ])),
   const SizedBox(height:14),
   AppPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    groupTitle('Hizmetler','Fiyat ve hizmet süresini belirle',Icons.content_cut_rounded),
    const FieldLabel('HİZMET ADI'),TextField(controller:service,decoration:const InputDecoration(hintText:'Saç kesimi, sakal…')),
    const SizedBox(height:12),
    Row(children:[Expanded(child:TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Ücret (TL)'))),const SizedBox(width:12),Expanded(child:TextField(controller:duration,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Süre (dk)')))]),
    const SizedBox(height:12),ElevatedButton.icon(onPressed:addService,icon:const Icon(Icons.add_rounded),label:const Text('Hizmet ekle')),
    const Divider(height:28),
    FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('services').select().eq('business_id',widget.business['id']),builder:(c,s){
     if(s.connectionState!=ConnectionState.done)return const LinearProgressIndicator();
     if(s.hasError)return Text(err(s.error!),style:const TextStyle(color:Colors.redAccent));
     if((s.data??[]).isEmpty)return const Text('Henüz hizmet eklenmedi.',style:TextStyle(color:muted,fontSize:12));
     return Column(children:(s.data??[]).map((e)=>ListTile(contentPadding:EdgeInsets.zero,leading:const CircleAvatar(backgroundColor:ink,child:Icon(Icons.cut_rounded,color:gold)),title:Text(e['name']??'Hizmet',style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${e['price']} TL • ${e['duration_minutes']} dk',style:const TextStyle(color:muted,fontSize:11)),trailing:Switch(value:e['is_active']==true,onChanged:(v)async{await sb.from('services').update({'is_active':v}).eq('id',e['id']);refresh();}))).toList());
    }),
   ])),
   const SizedBox(height:14),
   AppPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    groupTitle('Randevular','Gelen randevuları görüntüle ve yönet',Icons.event_note_rounded),
    FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('appointments').select('*, services(name), employees(display_name)').eq('business_id',widget.business['id']).order('starts_at'),builder:(c,s){
     if(s.connectionState!=ConnectionState.done)return const LinearProgressIndicator();
     if(s.hasError)return Text(err(s.error!),style:const TextStyle(color:Colors.redAccent));
     if((s.data??[]).isEmpty)return const EmptyStateView(icon:Icons.event_busy_rounded,title:'Randevu bulunmuyor',subtitle:'Müşteriler randevu aldığında burada listelenecek.');
     return Column(children:(s.data??[]).map((a)=>ListTile(contentPadding:EdgeInsets.zero,leading:const CircleAvatar(backgroundColor:ink,child:Icon(Icons.event_available_rounded,color:gold)),title:Text(a['services']?['name']??'Randevu',style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${a['starts_at']} • ${a['employees']?['display_name']??''}',style:const TextStyle(color:muted,fontSize:11)),trailing:a['status']=='confirmed'?IconButton(tooltip:'İptal et',icon:const Icon(Icons.cancel_outlined,color:Colors.redAccent),onPressed:()async{await sb.rpc('cancel_appointment',params:{'p_appointment_id':a['id']});refresh();}):StatusTag((a['status']??'').toString().toUpperCase()))).toList());
    }),
   ])),
  ]),
 ); 
}

Widget notificationAction(BuildContext context)=>IconButton(
 onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const NotificationsPage())),
 icon:const Icon(Icons.notifications_none));

class NotificationsPage extends StatefulWidget { const NotificationsPage({super.key}); @override State<NotificationsPage> createState()=>_NotificationsPageState(); }
class _NotificationsPageState extends State<NotificationsPage>{
 Future<List<Map<String,dynamic>>> load()=>sb.from('notifications').select().eq('user_id',uid).order('created_at',ascending:false).limit(100);
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Bildirimler')),body:FutureBuilder<List<Map<String,dynamic>>>(future:load(),builder:(c,s){
  if(s.connectionState!=ConnectionState.done)return const LoadingPage();
  if(s.hasError)return ErrorPage(message:err(s.error!));
  final rows=s.data??[];
  if(rows.isEmpty)return const Center(child:EmptyStateView(icon:Icons.notifications_none_rounded,title:'Henüz bildirimin yok',subtitle:'Randevu ve hesap güncellemelerin burada görünecek.'));
  return ListView(padding:const EdgeInsets.fromLTRB(18,12,18,28),children:[
   const ScreenHeading(eyebrow:'GÜNCELLEMELER',title:'Bildirimlerin',subtitle:'Randevuların ve hesabınla ilgili son gelişmeler.'),
   ...rows.map((n)=>AppPanel(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(14),child:InkWell(
    borderRadius:BorderRadius.circular(14),
    onTap:()async{if(n['read_at']==null){await sb.from('notifications').update({'read_at':DateTime.now().toUtc().toIso8601String()}).eq('id',n['id']);setState((){});}},
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Container(width:42,height:42,decoration:BoxDecoration(color:(n['read_at']==null?gold:muted).withValues(alpha:.12),borderRadius:BorderRadius.circular(13)),child:Icon(n['read_at']==null?Icons.notifications_active_rounded:Icons.notifications_none_rounded,color:n['read_at']==null?gold:muted)),
     const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text(n['title']??'Bildirim',style:const TextStyle(fontWeight:FontWeight.w800))),if(n['read_at']==null)const StatusTag('YENİ')]),
      const SizedBox(height:5),Text(n['body']??'',style:const TextStyle(color:muted,fontSize:12,height:1.4)),
      const SizedBox(height:7),Text(n['created_at']??'',style:const TextStyle(color:gold,fontSize:10,fontWeight:FontWeight.w600)),
     ])),
    ]),
   ))),
  ]);
 }));
}

class CustomerPage extends StatefulWidget { const CustomerPage({super.key}); @override State<CustomerPage> createState()=>_CustomerPageState(); }
class _CustomerPageState extends State<CustomerPage>{
 final joinCode=TextEditingController(); String? businessId,employeeId,serviceId; String selectedTime='10:00'; DateTime day=DateTime.now().add(const Duration(days:1)); bool busy=false;
 Future<void> joinBusiness()async{try{await sb.rpc('join_business_by_code',params:{'p_code':joinCode.text.trim().toUpperCase()});joinCode.clear();setState((){});toast(context,'İşletmeye katıldın');}catch(e){toast(context,err(e));}}
 String date(DateTime d)=>'${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
 Future<void> book()async{if(businessId==null||employeeId==null||serviceId==null)return;setState(()=>busy=true);try{final parts=selectedTime.split(':').map(int.parse).toList(); final local=DateTime(day.year,day.month,day.day,parts[0],parts[1]);await sb.rpc('book_appointment',params:{'p_business_id':businessId,'p_employee_id':employeeId,'p_service_id':serviceId,'p_starts_at':local.toUtc().toIso8601String()});toast(context,'Randevun onaylandı');}catch(e){toast(context,err(e));}if(mounted)setState(()=>busy=false);}
 Widget selectField(String label,Widget child)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[FieldLabel(label),child]);
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:const Text('Berberim'),actions:[notificationAction(context),IconButton(tooltip:'Çıkış yap',onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout_rounded))]),
  body:FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('business_memberships').select('business_id, businesses(id,name)').eq('customer_id',uid),builder:(c,m){
   if(m.connectionState!=ConnectionState.done)return const LoadingPage();
   if(m.hasError)return ErrorPage(message:err(m.error!));
   final businesses=(m.data??[]).map((x)=>x['businesses']).whereType<Map<String,dynamic>>().toList();
   return ListView(padding:const EdgeInsets.fromLTRB(18,12,18,30),children:[
    const ScreenHeading(eyebrow:'KİŞİSEL BAKIM',title:'Randevunu planla',subtitle:'Favori işletmeni seç, hizmetini belirle ve sana uygun zamanı ayır.',icon:Icons.calendar_month_rounded),
    AppPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     Row(children:[const Expanded(child:SectionHeading('İşletmene katıl')),StatusTag('${businesses.length} İŞLETME')]),
     const Text('İşletmenin sana verdiği katılım kodunu gir.',style:TextStyle(color:muted,fontSize:12)),
     const SizedBox(height:13),
     Row(children:[
      Expanded(child:TextField(controller:joinCode,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(hintText:'ÖRN. BERBER123',prefixIcon:Icon(Icons.key_rounded)))),
      const SizedBox(width:10),
      SizedBox(height:54,width:58,child:ElevatedButton(onPressed:joinBusiness,style:ElevatedButton.styleFrom(padding:EdgeInsets.zero),child:const Icon(Icons.arrow_forward_rounded))),
     ]),
     if(businesses.isEmpty)const Padding(padding:EdgeInsets.only(top:12),child:Text('Henüz bir işletmeye katılmadın.',style:TextStyle(color:muted,fontSize:12))),
    ])),
    const SizedBox(height:14),
    AppPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     const SectionHeading('Randevu detayları'),
     selectField('İŞLETME',DropdownButtonFormField<String>(value:businessId,decoration:const InputDecoration(hintText:'İşletme seç',prefixIcon:Icon(Icons.storefront_outlined)),items:businesses.map((b)=>DropdownMenuItem(value:b['id'] as String,child:Text(b['name']))).toList(),onChanged:(v)=>setState(()=>businessId=v))),
     if(businessId!=null)...[
      const SizedBox(height:16),
      selectField('BERBER',FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('employees').select().eq('business_id',businessId!).eq('is_active',true),builder:(c,s)=>DropdownButtonFormField<String>(value:employeeId,decoration:const InputDecoration(hintText:'Berber seç',prefixIcon:Icon(Icons.person_outline_rounded)),items:(s.data??[]).map((e)=>DropdownMenuItem(value:e['id'] as String,child:Text(e['display_name']))).toList(),onChanged:(v)=>setState(()=>employeeId=v)))),
      const SizedBox(height:16),
      selectField('HİZMET',FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('services').select().eq('business_id',businessId!).eq('is_active',true),builder:(c,s)=>DropdownButtonFormField<String>(value:serviceId,decoration:const InputDecoration(hintText:'Hizmet seç',prefixIcon:Icon(Icons.content_cut_rounded)),items:(s.data??[]).map((e)=>DropdownMenuItem(value:e['id'] as String,child:Text('${e['name']} • ${e['price']} TL / ${e['duration_minutes']} dk'))).toList(),onChanged:(v)=>setState(()=>serviceId=v)))),
     ],
     const SizedBox(height:18),
     const FieldLabel('TARİH VE SAAT'),
     Row(children:[
      Expanded(child:OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:c,initialDate:day,firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:90)));if(d!=null)setState(()=>day=d);},icon:const Icon(Icons.calendar_today_rounded),label:Text(date(day)))),
      const SizedBox(width:10),
      Expanded(child:DropdownButtonFormField<String>(value:selectedTime,decoration:const InputDecoration(prefixIcon:Icon(Icons.schedule_rounded)),items:List.generate(22,(i){final mins=9*60+i*30;final t='${(mins~/60).toString().padLeft(2,'0')}:${(mins%60).toString().padLeft(2,'0')}';return DropdownMenuItem(value:t,child:Text(t));}),onChanged:(v)=>setState(()=>selectedTime=v??'10:00'))),
     ]),
     const SizedBox(height:20),
     SizedBox(height:54,child:ElevatedButton.icon(onPressed:busy?null:book,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:ink)):const Icon(Icons.check_circle_outline_rounded),label:Text(busy?'Randevu oluşturuluyor…':'Randevunu oluştur'))),
    ])),
    const SizedBox(height:24),
    const SectionHeading('Randevularım'),
    FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('appointments').select('*, businesses(name), services(name), employees(display_name)').eq('customer_id',uid).order('starts_at',ascending:false),builder:(c,s){
     if(s.connectionState!=ConnectionState.done)return const LinearProgressIndicator();
     if(s.hasError)return Text(err(s.error!),style:const TextStyle(color:Colors.redAccent));
     if((s.data??[]).isEmpty)return const AppPanel(child:EmptyStateView(icon:Icons.event_available_rounded,title:'Henüz randevun yok',subtitle:'İlk randevunu oluşturduğunda burada görüntüleyebilirsin.'));
     return Column(children:(s.data??[]).map((a)=>AppPanel(margin:const EdgeInsets.only(bottom:10),child:Row(children:[
      Container(width:44,height:44,decoration:BoxDecoration(color:gold.withValues(alpha:.12),borderRadius:BorderRadius.circular(14)),child:const Icon(Icons.content_cut_rounded,color:gold)),
      const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Text(a['services']?['name']??'Randevu',style:const TextStyle(fontWeight:FontWeight.w800)),
       const SizedBox(height:4),Text(a['businesses']?['name']??'',style:const TextStyle(color:muted,fontSize:12)),
       Text('${a['starts_at']} • ${a['employees']?['display_name']??''}',style:const TextStyle(color:gold,fontSize:10,fontWeight:FontWeight.w600)),
      ])),
      if(a['status']=='confirmed')IconButton(tooltip:'Randevuyu iptal et',icon:const Icon(Icons.cancel_outlined,color:Colors.redAccent),onPressed:()async{await sb.rpc('cancel_appointment',params:{'p_appointment_id':a['id']});setState((){});}) else StatusTag((a['status']??'').toString().toUpperCase()),
     ]))).toList());
    }),
   ]);
  }),
 );
}