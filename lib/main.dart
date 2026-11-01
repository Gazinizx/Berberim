import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const gold = Color(0xFFF2B84B);
const ink = Color(0xFF151515);
const panel = Color(0xFF242424);
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: key);
  }
  runApp(const BerberimApp());
}

class BerberimApp extends StatelessWidget {
  const BerberimApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Berberim', debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
      cardTheme: const CardThemeData(color: panel),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: gold, foregroundColor: ink, minimumSize: const Size.fromHeight(48))),
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: supabase.auth.onAuthStateChange,
    builder: (context, authSnap) {
      final user = supabase.auth.currentUser;
      if (user == null) return const SignInPage();
      return FutureBuilder<Map<String,dynamic>?>(
        future: supabase.from('profiles').select().eq('id', user.id).maybeSingle(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingPage();
          if (snap.hasError) return ErrorPage(message: 'Profil okunamadı: ${snap.error}');
          final p = snap.data;
          if (p == null) return const ProfileSetupPage();
          if (p['is_admin'] == true) return const AdminPage();
          return HomePage(profile: p);
        },
      );
    },
  );
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator(color: gold)));
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
    setState(() {busy=true; error='';});
    try {
      if (create) {
        if (password.text.length < 8) throw Exception('Şifre en az 8 karakter olmalı.');
        await supabase.auth.signUp(email: email.text.trim(), password: password.text);
      } else {
        await supabase.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
    } catch(e) { error = e.toString().replaceFirst('Exception: ', ''); }
    if(mounted) setState(()=>busy=false);
  }
  @override
  void dispose(){email.dispose();password.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>Scaffold(body:Center(child:SingleChildScrollView(
    padding:const EdgeInsets.all(24), child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),
    child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Icon(Icons.content_cut,color:gold,size:62),
      const SizedBox(height:10),
      const Text('Berberim',textAlign:TextAlign.center,style:TextStyle(fontSize:36,fontWeight:FontWeight.w900)),
      const SizedBox(height:8),
      Text(create?'Hesabını oluştur':'Hesabına giriş yap',textAlign:TextAlign.center,style:const TextStyle(color:Colors.white60)),
      const SizedBox(height:26),
      TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-posta')),
      const SizedBox(height:12),
      TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Şifre')),
      if(error.isNotEmpty) Padding(padding:const EdgeInsets.only(top:12),child:Text(error,style:const TextStyle(color:Colors.redAccent))),
      const SizedBox(height:18),
      ElevatedButton(onPressed:busy?null:submit,child:Text(busy?'Bekleyin…':create?'Kayıt ol':'Giriş yap')),
      TextButton(onPressed:busy?null:()=>setState(()=>create=!create),child:Text(create?'Giriş yap':'Yeni hesap oluştur')),
    ])))));
}

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});
  @override State<ProfileSetupPage> createState()=>_ProfileSetupPageState();
}
class _ProfileSetupPageState extends State<ProfileSetupPage>{
  final name=TextEditingController(), phone=TextEditingController(), code=TextEditingController(), shop=TextEditingController(), address=TextEditingController();
  bool owner=false,busy=false; String error='';
  Future<void> submit() async {
    if(name.text.trim().isEmpty || (owner && shop.text.trim().isEmpty) || (!owner && code.text.trim().isEmpty)){
      setState(()=>error='Gerekli alanları doldur.');return;
    }
    setState(()=>busy=true);
    try{
      await supabase.from('profiles').update({'full_name':name.text.trim(),'phone':phone.text.trim()}).eq('id',supabase.auth.currentUser!.id);
      if(owner){
        await supabase.rpc('create_business',params:{'p_name':shop.text.trim(),'p_address':address.text.trim()});
      }else{
        await supabase.rpc('join_business_by_code',params:{'p_code':code.text.trim().toUpperCase()});
      }
    }catch(e){error=e.toString();}
    if(mounted)setState(()=>busy=false);
  }
  @override void dispose(){name.dispose();phone.dispose();code.dispose();shop.dispose();address.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Hesap bilgileri'),actions:[IconButton(onPressed:()=>supabase.auth.signOut(),icon:const Icon(Icons.logout))]),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      SegmentedButton<bool>(segments:const[
        ButtonSegment(value:false,label:Text('Müşteriyim'),icon:Icon(Icons.person_outline)),
        ButtonSegment(value:true,label:Text('İşletme sahibiyim'),icon:Icon(Icons.storefront_outlined)),
      ],selected:{owner},onSelectionChanged:(v)=>setState(()=>owner=v.first)),
      const SizedBox(height:16),
      TextField(controller:name,decoration:const InputDecoration(labelText:'Ad soyad')),
      const SizedBox(height:12),
      TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Telefon (isteğe bağlı)')),
      if(owner)...[
        const SizedBox(height:12),TextField(controller:shop,decoration:const InputDecoration(labelText:'İşletme adı')),
        const SizedBox(height:12),TextField(controller:address,decoration:const InputDecoration(labelText:'Adres (isteğe bağlı)')),
      ]else...[
        const SizedBox(height:12),TextField(controller:code,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'İşletme katılım kodu')),
      ],
      if(error.isNotEmpty)Padding(padding:const EdgeInsets.only(top:12),child:Text(error,style:const TextStyle(color:Colors.redAccent))),
      const SizedBox(height:18),
      ElevatedButton(onPressed:busy?null:submit,child:Text(busy?'Gönderiliyor…':owner?'İşletme başvurusu gönder':'İşletmeye katıl')),
      const SizedBox(height:8),
      const Text('İşletme başvuruları yönetici onayından sonra aktif olur.',style:TextStyle(color:Colors.white54)),
    ]));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key,required this.profile});
  final Map<String,dynamic> profile;
  @override State<HomePage> createState()=>_HomePageState();
}
class _HomePageState extends State<HomePage>{
  String? selectedBusiness;
  Future<List<Map<String,dynamic>>> getBusinesses() async {
    final uid=supabase.auth.currentUser!.id;
    final owned=await supabase.from('businesses').select().eq('owner_id',uid);
    final memberships=await supabase.from('business_memberships').select('business_id').eq('customer_id',uid);
    final ids=memberships.map((e)=>e['business_id'] as String).toList();
    final joined=ids.isEmpty? <Map<String,dynamic>>[] : await supabase.from('businesses').select().inFilter('id',ids);
    final all=<String,Map<String,dynamic>>{};
    for(final b in [...owned,...joined]){all[b['id'] as String]=b;}
    return all.values.toList();
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Berberim'),actions:[IconButton(onPressed:()=>supabase.auth.signOut(),icon:const Icon(Icons.logout))]),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:getBusinesses(),builder:(context,snap){
      if(snap.connectionState==ConnectionState.waiting)return const LoadingPage();
      if(snap.hasError)return ErrorPage(message:'İşletmeler yüklenemedi: ${snap.error}');
      final businesses=snap.data??[];
      if(businesses.isEmpty)return const ProfileSetupPage();
      final active=businesses.where((b)=>b['status']=='active').toList();
      final pending=businesses.where((b)=>b['status']=='pending').toList();
      if(active.isEmpty)return Center(child:Text(pending.isNotEmpty?'İşletme başvurun yönetici onayında.':'Henüz aktif işletme yok.'));
      final current=active.firstWhere((b)=>b['id']==selectedBusiness,orElse:()=>active.first);
      selectedBusiness=current['id'] as String;
      final isOwner=current['owner_id']==supabase.auth.currentUser!.id;
      return ListView(padding:const EdgeInsets.all(16),children:[
        if(active.length>1)DropdownButtonFormField<String>(value:selectedBusiness,decoration:const InputDecoration(labelText:'İşletme seç'),
          items:active.map((b)=>DropdownMenuItem(value:b['id'] as String,child:Text(b['name'] as String))).toList(),
          onChanged:(v)=>setState(()=>selectedBusiness=v)),
        Text(current['name'] as String,style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold)),
        if(isOwner)Text('Katılım kodu: ${current['join_code']}',style:const TextStyle(color:gold)),
        if(isOwner)OwnerTools(business:current),
        if(!isOwner)CustomerTools(business:current),
      ]);
    }),
  );
}

class OwnerTools extends StatefulWidget{
  const OwnerTools({super.key,required this.business}); final Map<String,dynamic> business;
  @override State<OwnerTools> createState()=>_OwnerToolsState();
}
class _OwnerToolsState extends State<OwnerTools>{
  final employee=TextEditingController(),service=TextEditingController(),price=TextEditingController(),duration=TextEditingController(text:'30');
  String notice='';
  Future<void> addEmployee()async{try{await supabase.from('employees').insert({'business_id':widget.business['id'],'display_name':employee.text.trim()});employee.clear();setState(()=>notice='Çalışan eklendi.');}catch(e){setState(()=>notice=e.toString());}}
  Future<void> addService()async{final p=double.tryParse(price.text),d=int.tryParse(duration.text);if(service.text.trim().isEmpty||p==null||d==null){setState(()=>notice='Hizmet bilgileri geçersiz.');return;}try{await supabase.from('services').insert({'business_id':widget.business['id'],'name':service.text.trim(),'price':p,'duration_minutes':d});service.clear();price.clear();setState(()=>notice='Hizmet eklendi.');}catch(e){setState(()=>notice=e.toString());}}
  Future<void> saveHours()async{try{final rows=<Map<String,dynamic>>[];for(var day=0;day<7;day++){rows.add({'business_id':widget.business['id'],'weekday':day,'opens_at':'09:00','closes_at':'20:00','is_closed':day==0});}await supabase.from('business_hours').upsert(rows,onConflict:'business_id,weekday');setState(()=>notice='Çalışma saatleri kaydedildi (Pazar kapalı, diğer günler 09:00–20:00).');}catch(e){setState(()=>notice=e.toString());}}
  @override void dispose(){employee.dispose();service.dispose();price.dispose();duration.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const SizedBox(height:16),const Text('Çalışanlar',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
    TextField(controller:employee,decoration:const InputDecoration(labelText:'Çalışan adı')),
    const SizedBox(height:8),ElevatedButton(onPressed:addEmployee,child:const Text('Çalışan ekle')),
    StreamBuilder<List<Map<String,dynamic>>>(stream:supabase.from('employees').stream(primaryKey:['id']).eq('business_id',widget.business['id']),builder:(c,s){if(!s.hasData)return const SizedBox.shrink();return Column(children:s.data!.map((e)=>ListTile(title:Text(e['display_name'] as String))).toList());}),
    const Divider(height:28),const Text('Hizmetler',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
    TextField(controller:service,decoration:const InputDecoration(labelText:'Hizmet adı')),
    const SizedBox(height:8),Row(children:[Expanded(child:TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Ücret (TL)'))),const SizedBox(width:8),Expanded(child:TextField(controller:duration,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Süre (dk)')))]),
    const SizedBox(height:8),ElevatedButton(onPressed:addService,child:const Text('Hizmet ekle')),
    StreamBuilder<List<Map<String,dynamic>>>(stream:supabase.from('services').stream(primaryKey:['id']).eq('business_id',widget.business['id']),builder:(c,s){if(!s.hasData)return const SizedBox.shrink();return Column(children:s.data!.map((e)=>ListTile(title:Text(e['name'] as String),subtitle:Text('${e['price']} TL • ${e['duration_minutes']} dk'))).toList());}),
    const Divider(height:28),const Text('Çalışma saatleri',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
    const Text('Şimdilik varsayılan saatler: Pazartesi–Cumartesi 09:00–20:00, Pazar kapalı.'),
    ElevatedButton(onPressed:saveHours,child:const Text('Varsayılan saatleri kaydet')),
    if(notice.isNotEmpty)Padding(padding:const EdgeInsets.all(8),child:Text(notice,style:const TextStyle(color:gold))),
  ]);
}

class CustomerTools extends StatefulWidget{
  const CustomerTools({super.key,required this.business});final Map<String,dynamic> business;
  @override State<CustomerTools> createState()=>_CustomerToolsState();
}
class _CustomerToolsState extends State<CustomerTools>{
  String? employeeId,serviceId;DateTime day=DateTime.now();String notice='';
  Future<void> book()async{
    if(employeeId==null||serviceId==null){setState(()=>notice='Çalışan ve hizmet seçmelisin.');return;}
    final local=DateTime(day.year,day.month,day.day,10);
    try{await supabase.rpc('book_appointment',params:{'p_business_id':widget.business['id'],'p_employee_id':employeeId,'p_service_id':serviceId,'p_starts_at':local.toUtc().toIso8601String()});setState(()=>notice='Randevun onaylandı.');}
    catch(e){setState(()=>notice=e.toString());}
  }
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const SizedBox(height:16),const Text('Randevu oluştur',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
    StreamBuilder<List<Map<String,dynamic>>>(stream:supabase.from('employees').stream(primaryKey:['id']).eq('business_id',widget.business['id']).eq('is_active',true),builder:(c,s){
      final rows=s.data??[];return DropdownButtonFormField<String>(value:rows.any((e)=>e['id']==employeeId)?employeeId:null,decoration:const InputDecoration(labelText:'Çalışan seç'),items:rows.map((e)=>DropdownMenuItem(value:e['id'] as String,child:Text(e['display_name'] as String))).toList(),onChanged:(v)=>setState(()=>employeeId=v));}),
    const SizedBox(height:10),
    StreamBuilder<List<Map<String,dynamic>>>(stream:supabase.from('services').stream(primaryKey:['id']).eq('business_id',widget.business['id']).eq('is_active',true),builder:(c,s){
      final rows=s.data??[];return DropdownButtonFormField<String>(value:rows.any((e)=>e['id']==serviceId)?serviceId:null,decoration:const InputDecoration(labelText:'Hizmet seç'),items:rows.map((e)=>DropdownMenuItem(value:e['id'] as String,child:Text('${e['name']} • ${e['price']} TL / ${e['duration_minutes']} dk'))).toList(),onChanged:(v)=>setState(()=>serviceId=v));}),
    const SizedBox(height:10),OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:context,initialDate:day,firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:90)));if(d!=null)setState(()=>day=d);},icon:const Icon(Icons.calendar_month),label:Text('${day.day.toString().padLeft(2,'0')}.${day.month.toString().padLeft(2,'0')}.${day.year}')),
    const Text('Şimdilik randevu saati 10:00 olarak ayarlanır.',style:TextStyle(color:Colors.white54)),
    ElevatedButton(onPressed:book,child:const Text('10:00 için randevu al')),
    if(notice.isNotEmpty)Text(notice,style:const TextStyle(color:gold)),
    const Divider(height:28),const Text('Randevularım',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
    StreamBuilder<List<Map<String,dynamic>>>(stream:supabase.from('appointments').stream(primaryKey:['id']).eq('customer_id',supabase.auth.currentUser!.id),builder:(c,s){
      if(s.hasError)return Text('Randevular yüklenemedi: ${s.error}');final rows=s.data??[];return Column(children:rows.map((a)=>ListTile(title:Text('${a['starts_at']} • ${a['status']}'),trailing:a['status']=='confirmed'?IconButton(icon:const Icon(Icons.cancel_outlined),onPressed:()async{try{await supabase.rpc('cancel_appointment',params:{'p_appointment_id':a['id']});}catch(e){setState(()=>notice=e.toString());}}):null)).toList());}),
  ]);
}

class AdminPage extends StatelessWidget{
  const AdminPage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Yönetici')),body:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('İşletme başvuruları',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    StreamBuilder<List<Map<String,dynamic>>>(stream:supabase.from('businesses').stream(primaryKey:['id']).eq('status','pending'),builder:(c,s){
      if(s.hasError)return Text('Başvurular okunamadı: ${s.error}');if(!s.hasData)return const LoadingPage();
      return Column(children:s.data!.map((b)=>Card(child:ListTile(title:Text(b['name'] as String),subtitle:Text(b['address']??''),trailing:Wrap(children:[
        IconButton(icon:const Icon(Icons.check,color:Colors.green),onPressed:()async{await supabase.rpc('admin_review_business',params:{'p_business_id':b['id'],'p_decision':'active'});}),
        IconButton(icon:const Icon(Icons.close,color:Colors.red),onPressed:()async{await supabase.rpc('admin_review_business',params:{'p_business_id':b['id'],'p_decision':'rejected'});}),
      ])))).toList());}),
    const SizedBox(height:20),OutlinedButton(onPressed:()=>supabase.auth.signOut(),child:const Text('Çıkış yap')),
  ]));
}
