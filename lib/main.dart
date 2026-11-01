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

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Padding(
    padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.content_cut, size: 64, color: gold), SizedBox(height: 14),
      Text('Berberim', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
      SizedBox(height: 12), Text('Supabase yapılandırması bulunamadı. Uygulama derlemesi için SUPABASE_URL ve SUPABASE_ANON_KEY tanımlanmalı.', textAlign: TextAlign.center)
    ]))));
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

class BlockedPage extends StatelessWidget { const BlockedPage({super.key}); @override Widget build(BuildContext c)=>Scaffold(body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.block,color:Colors.redAccent,size:56),const SizedBox(height:16),const Text('Hesabın geçici olarak engellendi',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:12),OutlinedButton(onPressed:()=>sb.auth.signOut(),child:const Text('Çıkış yap'))])))); }
class LoadingPage extends StatelessWidget { const LoadingPage({super.key}); @override Widget build(BuildContext c)=>const Scaffold(body:Center(child:CircularProgressIndicator(color:gold))); }
class ErrorPage extends StatelessWidget { const ErrorPage({super.key,required this.message}); final String message; @override Widget build(BuildContext c)=>Scaffold(body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Text(message,textAlign:TextAlign.center)))); }
void toast(BuildContext c,String s)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s)));

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState()=>_LoginPageState(); }
class _LoginPageState extends State<LoginPage>{
 final email=TextEditingController(),pass=TextEditingController(); bool create=false,busy=false; String message=''; String accountType='customer';
 Future<void> submit() async {setState(()=>busy=true);message='';try{if(create){if(pass.text.length<8)throw Exception('Şifre en az 8 karakter olmalı.');final result=await sb.auth.signUp(email:email.text.trim(),password:pass.text,emailRedirectTo:'berberim://login-callback',data:{'account_type':accountType});if(result.session==null)message='Doğrulama e-postası gönderildi. E-postandaki bağlantıya dokun; Berberim uygulaması açılacak.';}else{await sb.auth.signInWithPassword(email:email.text.trim(),password:pass.text);}}catch(e){message=err(e);}if(mounted)setState(()=>busy=false);}
 @override Widget build(BuildContext c)=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 const Icon(Icons.content_cut,color:gold,size:64),const SizedBox(height:12),const Text('Berberim',textAlign:TextAlign.center,style:TextStyle(fontSize:36,fontWeight:FontWeight.w900)),const SizedBox(height:26),
 if(create)...[const Text('Hesap türünü seç',style:TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:8),SegmentedButton<String>(segments:const [ButtonSegment(value:'customer',label:Text('Müşteri'),icon:Icon(Icons.person_outline)),ButtonSegment(value:'business_owner',label:Text('İşletme'),icon:Icon(Icons.storefront_outlined))],selected:{accountType},onSelectionChanged:(v)=>setState(()=>accountType=v.first)),const SizedBox(height:14)],
 TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-posta')),const SizedBox(height:12),TextField(controller:pass,obscureText:true,decoration:const InputDecoration(labelText:'Şifre')),
 if(create&&accountType=='business_owner')const Padding(padding:EdgeInsets.only(top:10),child:Text('İşletme hesabı yönetici onayından sonra açılır.',style:TextStyle(color:Colors.white60))),
 if(message.isNotEmpty)Padding(padding:const EdgeInsets.all(8),child:Text(message,style:TextStyle(color:message.startsWith('Doğrulama e-postası gönderildi')?Colors.lightGreenAccent:Colors.redAccent))),
 const SizedBox(height:16),ElevatedButton(onPressed:busy?null:submit,child:Text(busy?'Bekleyin…':create?'Kayıt ol':'Giriş yap')),TextButton(onPressed:()=>setState(()=>create=!create),child:Text(create?'Giriş yap':'Yeni hesap oluştur'))
 ])))));
}

class ProfilePage extends StatefulWidget { const ProfilePage({super.key}); @override State<ProfilePage> createState()=>_ProfilePageState(); }
class _ProfilePageState extends State<ProfilePage>{
 final name=TextEditingController(),phone=TextEditingController(),shop=TextEditingController(),address=TextEditingController();bool busy=false;String message='';
 Future<void> save()async{setState(()=>busy=true);message='';try{await sb.from('profiles').update({'full_name':name.text.trim(),'phone':phone.text.trim(),'account_type':'business_owner'}).eq('id',uid);await sb.rpc('create_business_application',params:{'p_name':shop.text.trim(),'p_address':address.text.trim().isEmpty?null:address.text.trim()});}catch(e){message=err(e);}if(mounted){setState(()=>busy=false);if(message.isEmpty)Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const AuthGate()),(r)=>false);}}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('İşletme başvurusu'),actions:[IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout))]),body:ListView(padding:const EdgeInsets.all(20),children:[const Icon(Icons.storefront_outlined,color:gold,size:54),const SizedBox(height:12),const Text('İşletmeni tanıtalım',style:TextStyle(fontSize:25,fontWeight:FontWeight.w900)),const Text('Başvurun yönetici tarafından incelenecek. Onaylanmadan işletme paneline erişemezsin.',style:TextStyle(color:Colors.white60)),const SizedBox(height:20),TextField(controller:name,decoration:const InputDecoration(labelText:'Ad soyad')),const SizedBox(height:10),TextField(controller:phone,decoration:const InputDecoration(labelText:'Telefon')),const SizedBox(height:10),TextField(controller:shop,decoration:const InputDecoration(labelText:'İşletme adı')),const SizedBox(height:10),TextField(controller:address,decoration:const InputDecoration(labelText:'İşletme adresi')),if(message.isNotEmpty)Text(message,style:const TextStyle(color:Colors.redAccent)),const SizedBox(height:18),ElevatedButton(onPressed:busy?null:save,child:Text(busy?'Gönderiliyor…':'Onaya gönder'))]));
}
class PendingPage extends StatelessWidget {const PendingPage({super.key,required this.business});final Map<String,dynamic> business;
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Başvuru durumu'),actions:[IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout))]),body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.hourglass_top_rounded,color:gold,size:68),const SizedBox(height:18),Text(business['status']=='rejected'?'Başvurun reddedildi':business['status']=='inactive'?'İşletmen devre dışı':'Yönetici onayı bekleniyor',style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900),textAlign:TextAlign.center),const SizedBox(height:10),Text(business['name']??'',style:const TextStyle(color:gold,fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:10),Text(business['status']=='pending'?'Başvurunu aldık. Yönetici incelemesi tamamlanınca işletme panelin açılacak.':'Başvuru durumunla ilgili yönetimle iletişime geçebilirsin.',textAlign:TextAlign.center,style:const TextStyle(color:Colors.white60)),const SizedBox(height:22),OutlinedButton.icon(onPressed:()=>Navigator.of(c).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const AuthGate()),(r)=>false),icon:const Icon(Icons.refresh),label:const Text('Durumu yenile'))]))));
}
class AdminPage extends StatefulWidget {const AdminPage({super.key});@override State<AdminPage> createState()=>_AdminPageState();}
class _AdminPageState extends State<AdminPage>{
 int tab=0;
 Future<List<Map<String,dynamic>>> load(String table)=>sb.from(table).select().order('created_at',ascending:false);
 Future<void> review(String id,String status)async{try{await sb.rpc('review_business',params:{'p_business_id':id,'p_status':status});if(mounted)setState((){});toast(context,'İşletme durumu güncellendi');}catch(e){toast(context,err(e));}}
 Future<void> block(String id,bool value)async{try{await sb.rpc('admin_set_user_blocked',params:{'p_user_id':id,'p_blocked':value});if(mounted)setState((){});}catch(e){toast(context,err(e));}}
 Widget heading(String a,String b)=>Padding(padding:const EdgeInsets.only(bottom:14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),Text(b,style:const TextStyle(color:Colors.white54))]));
 Widget dashboard()=>FutureBuilder<List<dynamic>>(future:Future.wait([load('profiles'),load('businesses'),load('appointments')]),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const LoadingPage();if(s.hasError)return ErrorPage(message:err(s.error!));final p=s.data![0] as List,b=s.data![1] as List,a=s.data![2] as List;final pending=b.where((x)=>x['status']=='pending').length;Widget tile(String label,int n,IconData i)=>Expanded(child:Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i,color:gold),const SizedBox(height:8),Text('$n',style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900)),Text(label,style:const TextStyle(color:Colors.white60))]))));return ListView(padding:const EdgeInsets.all(16),children:[heading('Genel bakış','Uygulamanın yönetim merkezi'),Row(children:[tile('Kullanıcı',p.length,Icons.people),const SizedBox(width:8),tile('İşletme',b.length,Icons.storefront)]),Row(children:[tile('Bekleyen başvuru',pending,Icons.hourglass_top),const SizedBox(width:8),tile('Randevu',a.length,Icons.calendar_month)]),const SizedBox(height:16),ListTile(leading:const Icon(Icons.pending_actions,color:gold),title:const Text('Bekleyen başvurular'),trailing:const Icon(Icons.chevron_right),onTap:()=>setState(()=>tab=1)),ListTile(leading:const Icon(Icons.people,color:gold),title:const Text('Kullanıcı yönetimi'),trailing:const Icon(Icons.chevron_right),onTap:()=>setState(()=>tab=2)),ListTile(leading:const Icon(Icons.calendar_month,color:gold),title:const Text('Randevular'),trailing:const Icon(Icons.chevron_right),onTap:()=>setState(()=>tab=3))]);});
 Widget businesses()=>FutureBuilder<List<Map<String,dynamic>>>(future:load('businesses'),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const LoadingPage();if(s.hasError)return ErrorPage(message:err(s.error!));final l=s.data??[];return ListView(padding:const EdgeInsets.all(16),children:[heading('İşletmeler','Başvuruları ve işletme durumlarını yönet'),...l.map((b)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(b['name']??'İsimsiz işletme',style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)),Text('Durum: ${b['status']} • Kod: ${b['join_code']??'—'}',style:const TextStyle(color:Colors.white60)),if((b['address']??'').toString().isNotEmpty)Text(b['address']),Wrap(spacing:8,children:[if(b['status']!='active')TextButton(onPressed:()=>review(b['id'],'active'),child:const Text('Onayla')),if(b['status']!='rejected')TextButton(onPressed:()=>review(b['id'],'rejected'),child:const Text('Reddet')),if(b['status']!='inactive')TextButton(onPressed:()=>review(b['id'],'inactive'),child:const Text('Pasife al'))])]))))]);});
 Widget users()=>FutureBuilder<List<Map<String,dynamic>>>(future:load('profiles'),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const LoadingPage();if(s.hasError)return ErrorPage(message:err(s.error!));return ListView(padding:const EdgeInsets.all(16),children:[heading('Kullanıcılar','Hesap türü ve erişim kontrolü'),...(s.data??[]).map((p)=>Card(child:ListTile(isThreeLine:true,leading:Icon(p['account_type']=='business_owner'?Icons.storefront:Icons.person,color:gold),title:Text(p['full_name']??'İsimsiz kullanıcı'),subtitle:Text('${p['email']??'E-posta yok'}\n${p['account_type']=='business_owner'?'İşletme':'Müşteri'}'),trailing:Switch(value:p['is_blocked']==true,onChanged:(v)=>block(p['id'],v)))))]);});
 Widget appointments()=>FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('appointments').select('*, businesses(name), services(name)').order('starts_at',ascending:false).limit(250),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const LoadingPage();if(s.hasError)return ErrorPage(message:err(s.error!));return ListView(padding:const EdgeInsets.all(16),children:[heading('Randevular','Son 250 randevu'),...(s.data??[]).map((a)=>Card(child:ListTile(leading:const Icon(Icons.event,color:gold),title:Text(a['services']?['name']??'Randevu'),subtitle:Text('${a['businesses']?['name']??'İşletme'} • ${a['starts_at']} • ${a['status']}'))))]);});
 @override Widget build(BuildContext c){final pages=[dashboard(),businesses(),users(),appointments()];return Scaffold(appBar:AppBar(title:const Text('Yönetim merkezi'),actions:[IconButton(onPressed:()=>setState((){}),icon:const Icon(Icons.refresh)),IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout))]),body:pages[tab],bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const [NavigationDestination(icon:Icon(Icons.dashboard_outlined),label:'Genel'),NavigationDestination(icon:Icon(Icons.storefront_outlined),label:'İşletmeler'),NavigationDestination(icon:Icon(Icons.people_outline),label:'Kullanıcılar'),NavigationDestination(icon:Icon(Icons.calendar_month_outlined),label:'Randevular')]));}
}

class BarberPage extends StatefulWidget { const BarberPage({super.key,required this.business}); final Map<String,dynamic> business; @override State<BarberPage> createState()=>_BarberPageState(); }
class _BarberPageState extends State<BarberPage>{
 final service=TextEditingController(),price=TextEditingController(),duration=TextEditingController(text:'30'),employee=TextEditingController(),open=TextEditingController(text:'09:00'),close=TextEditingController(text:'20:00'),breakStart=TextEditingController(text:'13:00'),breakEnd=TextEditingController(text:'14:00');
 bool busy=false; Future<void> refresh()async{if(mounted)setState((){});}
 Future<void> addService()async{try{await sb.from('services').insert({'business_id':widget.business['id'],'name':service.text.trim(),'price':double.parse(price.text),'duration_minutes':int.parse(duration.text)});service.clear();price.clear();refresh();}catch(e){toast(context,err(e));}}
 Future<void> addEmployee()async{try{await sb.from('employees').insert({'business_id':widget.business['id'],'display_name':employee.text.trim()});employee.clear();refresh();}catch(e){toast(context,err(e));}}
 Future<void> saveHours()async{try{for(var d=0;d<7;d++){await sb.from('business_hours').upsert({'business_id':widget.business['id'],'weekday':d,'opens_at':open.text,'closes_at':close.text,'is_closed':false},onConflict:'business_id,weekday');}toast(context,'Çalışma saatleri kaydedildi');}catch(e){toast(context,err(e));}}
 Future<void> saveBreaks()async{try{final a=breakStart.text.trim(),b=breakEnd.text.trim();if(a.compareTo(b)>=0)throw Exception('Mola bitişi başlangıçtan sonra olmalı');await sb.from('business_breaks').delete().eq('business_id',widget.business['id']);for(var d=1;d<7;d++){await sb.from('business_breaks').insert({'business_id':widget.business['id'],'weekday':d,'starts_at':a,'ends_at':b});}toast(context,'Mola saatleri kaydedildi');}catch(e){toast(context,err(e));}}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.business['name']),actions:[notificationAction(context),IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout))]),body:ListView(padding:const EdgeInsets.all(16),children:[
 const Text('İşletme kodun',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),SelectableText(widget.business['join_code'],style:const TextStyle(color:gold,fontSize:24,fontWeight:FontWeight.bold)),
 const SizedBox(height:18),const Text('Çalışma saatleri',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Row(children:[Expanded(child:TextField(controller:open,decoration:const InputDecoration(labelText:'Açılış'))),const SizedBox(width:8),Expanded(child:TextField(controller:close,decoration:const InputDecoration(labelText:'Kapanış')))]),const SizedBox(height:8),OutlinedButton(onPressed:saveHours,child:const Text('Haftanın tüm günlerine uygula')),
 const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:breakStart,decoration:const InputDecoration(labelText:'Mola başlangıcı'))),const SizedBox(width:8),Expanded(child:TextField(controller:breakEnd,decoration:const InputDecoration(labelText:'Mola bitişi')))]),OutlinedButton(onPressed:saveBreaks,child:const Text('Hafta içi mola saatlerini kaydet')),
 const SizedBox(height:18),const Text('Çalışanlar',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),TextField(controller:employee,decoration:const InputDecoration(labelText:'Çalışan adı')),const SizedBox(height:8),OutlinedButton(onPressed:addEmployee,child:const Text('Çalışan ekle')),
 FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('employees').select().eq('business_id',widget.business['id']),builder:(c,s)=>Column(children:(s.data??[]).map((e)=>ListTile(title:Text(e['display_name']),subtitle:Text(e['is_active']?'Aktif':'Pasif'))).toList())),
 const SizedBox(height:18),const Text('Hizmetler',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),TextField(controller:service,decoration:const InputDecoration(labelText:'Hizmet adı')),const SizedBox(height:8),Row(children:[Expanded(child:TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Ücret TL'))),const SizedBox(width:8),Expanded(child:TextField(controller:duration,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Süre dk')))]),const SizedBox(height:8),ElevatedButton(onPressed:addService,child:const Text('Hizmet ekle')),
 FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('services').select().eq('business_id',widget.business['id']),builder:(c,s)=>Column(children:(s.data??[]).map((e)=>ListTile(title:Text(e['name']),subtitle:Text('${e['price']} TL • ${e['duration_minutes']} dk'),trailing:Switch(value:e['is_active'],onChanged:(v)async{await sb.from('services').update({'is_active':v}).eq('id',e['id']);refresh();}))).toList())),
 const SizedBox(height:18),const Text('Randevular',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
 FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('appointments').select('*, services(name), employees(display_name)').eq('business_id',widget.business['id']).order('starts_at'),builder:(c,s)=>Column(children:(s.data??[]).map((a)=>ListTile(title:Text(a['services']?['name']??'Randevu'),subtitle:Text('${a['starts_at']} • ${a['employees']?['display_name']??''} • ${a['status']}'),trailing:a['status']=='confirmed'?IconButton(icon:const Icon(Icons.cancel),onPressed:()async{await sb.rpc('cancel_appointment',params:{'p_appointment_id':a['id']});refresh();}):null)).toList()))
 ]));
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
 if(rows.isEmpty)return const Center(child:Text('Henüz bildirimin yok.'));
 return ListView(children:rows.map((n)=>ListTile(leading:Icon(n['read_at']==null?Icons.notifications_active:Icons.notifications_none,color:n['read_at']==null?gold:Colors.white38),title:Text(n['title']),subtitle:Text('${n['body']}\\n${n['created_at']}'),isThreeLine:true,onTap:()async{if(n['read_at']==null){await sb.from('notifications').update({'read_at':DateTime.now().toUtc().toIso8601String()}).eq('id',n['id']);setState((){});}})).toList());
 }));}

class CustomerPage extends StatefulWidget { const CustomerPage({super.key}); @override State<CustomerPage> createState()=>_CustomerPageState(); }
class _CustomerPageState extends State<CustomerPage>{
 final joinCode=TextEditingController(); String? businessId,employeeId,serviceId; String selectedTime='10:00'; DateTime day=DateTime.now().add(const Duration(days:1)); bool busy=false;
 Future<void> joinBusiness()async{try{await sb.rpc('join_business_by_code',params:{'p_code':joinCode.text.trim().toUpperCase()});joinCode.clear();setState((){});toast(context,'İşletmeye katıldın');}catch(e){toast(context,err(e));}}
 String date(DateTime d)=>'${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
 Future<void> book()async{if(businessId==null||employeeId==null||serviceId==null)return;setState(()=>busy=true);try{final parts=selectedTime.split(':').map(int.parse).toList(); final local=DateTime(day.year,day.month,day.day,parts[0],parts[1]);await sb.rpc('book_appointment',params:{'p_business_id':businessId,'p_employee_id':employeeId,'p_service_id':serviceId,'p_starts_at':local.toUtc().toIso8601String()});toast(context,'Randevun onaylandı');}catch(e){toast(context,err(e));}if(mounted)setState(()=>busy=false);}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Berberim'),actions:[notificationAction(context),IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout))]),body:FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('business_memberships').select('business_id, businesses(id,name)').eq('customer_id',uid),builder:(c,m){if(!m.hasData)return const LoadingPage();final businesses=(m.data??[]).map((x)=>x['businesses']).whereType<Map<String,dynamic>>().toList();return ListView(padding:const EdgeInsets.all(16),children:[
 const Text('Randevu oluştur',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800)),const SizedBox(height:12),
 TextField(controller:joinCode,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'Yeni işletme katılım kodu')),const SizedBox(height:8),OutlinedButton(onPressed:joinBusiness,child:const Text('İşletmeye katıl')),
 if(businesses.isEmpty)const Text('Henüz bir işletmeye katılmadın.'),
 DropdownButtonFormField<String>(value:businessId,decoration:const InputDecoration(labelText:'İşletme seç'),items:businesses.map((b)=>DropdownMenuItem(value:b['id'] as String,child:Text(b['name']))).toList(),onChanged:(v)=>setState(()=>businessId=v)),
 if(businessId!=null)FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('employees').select().eq('business_id',businessId!).eq('is_active',true),builder:(c,s)=>DropdownButtonFormField<String>(value:employeeId,decoration:const InputDecoration(labelText:'Berber seç'),items:(s.data??[]).map((e)=>DropdownMenuItem(value:e['id'] as String,child:Text(e['display_name']))).toList(),onChanged:(v)=>setState(()=>employeeId=v))),
 if(businessId!=null)FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('services').select().eq('business_id',businessId!).eq('is_active',true),builder:(c,s)=>DropdownButtonFormField<String>(value:serviceId,decoration:const InputDecoration(labelText:'Hizmet seç'),items:(s.data??[]).map((e)=>DropdownMenuItem(value:e['id'] as String,child:Text('${e['name']} • ${e['price']} TL / ${e['duration_minutes']} dk'))).toList(),onChanged:(v)=>setState(()=>serviceId=v))),
 OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:c,initialDate:day,firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:90)));if(d!=null)setState(()=>day=d);},icon:const Icon(Icons.calendar_month),label:Text(date(day))),
 DropdownButtonFormField<String>(value:selectedTime,decoration:const InputDecoration(labelText:'Saat seç'),items:List.generate(22,(i){final mins=9*60+i*30;final t='${(mins~/60).toString().padLeft(2,'0')}:${(mins%60).toString().padLeft(2,'0')}';return DropdownMenuItem(value:t,child:Text(t));}),onChanged:(v)=>setState(()=>selectedTime=v??'10:00')),
 ElevatedButton(onPressed:busy?null:book,child:Text(busy?'İşleniyor…':'Randevu al')),
 const SizedBox(height:20),const Text('Randevularım',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
 FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('appointments').select('*, businesses(name), services(name), employees(display_name)').eq('customer_id',uid).order('starts_at',ascending:false),builder:(c,s)=>Column(children:(s.data??[]).map((a)=>Card(child:ListTile(title:Text(a['services']?['name']??'Randevu'),subtitle:Text('${a['businesses']?['name']??''} • ${a['starts_at']} • ${a['status']}'),trailing:a['status']=='confirmed'?IconButton(icon:const Icon(Icons.cancel_outlined),onPressed:()async{await sb.rpc('cancel_appointment',params:{'p_appointment_id':a['id']});setState((){});}):null))).toList()))
 ]);}));
}
