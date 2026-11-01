import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const gold = Color(0xFFF2B84B);
const ink = Color(0xFF111111);
const panel = Color(0xFF202020);
final sb = Supabase.instance.client;
String get uid => sb.auth.currentUser!.id;
String err(Object e) => e.toString().replaceFirst('Exception: ', '').replaceFirst('PostgrestException(message: ', '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  runApp(const BerberimApp());
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: key);
    runApp(const BerberimApp());
  }
}

class BerberimApp extends StatelessWidget {
  const BerberimApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Berberim', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      scaffoldBackgroundColor: ink, colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
      cardTheme: const CardThemeData(color: panel),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: gold, foregroundColor: ink, minimumSize: const Size.fromHeight(48)))),
    home: const ConfigGate());
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
              return const CustomerPage();
            });
        });
    });
}

class LoadingPage extends StatelessWidget { const LoadingPage({super.key}); @override Widget build(BuildContext c)=>const Scaffold(body:Center(child:CircularProgressIndicator(color:gold))); }
class ErrorPage extends StatelessWidget { const ErrorPage({super.key,required this.message}); final String message; @override Widget build(BuildContext c)=>Scaffold(body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Text(message,textAlign:TextAlign.center)))); }
void toast(BuildContext c,String s)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s)));

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState()=>_LoginPageState(); }
class _LoginPageState extends State<LoginPage>{
 final email=TextEditingController(),pass=TextEditingController(); bool create=false,busy=false; String message='';
 Future<void> submit() async { setState(()=>busy=true); try { if(create){ if(pass.text.length<8) throw Exception('Şifre en az 8 karakter olmalı.'); await sb.auth.signUp(email:email.text.trim(),password:pass.text); } else { await sb.auth.signInWithPassword(email:email.text.trim(),password:pass.text); } }catch(e){message=err(e);} if(mounted)setState(()=>busy=false); }
 @override Widget build(BuildContext c)=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 const Icon(Icons.content_cut,color:gold,size:64),const SizedBox(height:12),const Text('Berberim',textAlign:TextAlign.center,style:TextStyle(fontSize:36,fontWeight:FontWeight.w900)),const SizedBox(height:26),
 TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-posta')),const SizedBox(height:12),
 TextField(controller:pass,obscureText:true,decoration:const InputDecoration(labelText:'Şifre')),
 if(message.isNotEmpty)Padding(padding:const EdgeInsets.all(8),child:Text(message,style:const TextStyle(color:Colors.redAccent))),
 const SizedBox(height:16),ElevatedButton(onPressed:busy?null:submit,child:Text(busy?'Bekleyin…':create?'Kayıt ol':'Giriş yap')),
 TextButton(onPressed:()=>setState(()=>create=!create),child:Text(create?'Giriş yap':'Yeni hesap oluştur'))
 ])))));
}

class ProfilePage extends StatefulWidget { const ProfilePage({super.key}); @override State<ProfilePage> createState()=>_ProfilePageState(); }
class _ProfilePageState extends State<ProfilePage>{
 final name=TextEditingController(),phone=TextEditingController(),shop=TextEditingController(),code=TextEditingController(); bool owner=false,busy=false; String message='';
 Future<void> save() async { setState(()=>busy=true); try {
 await sb.from('profiles').insert({'id':uid,'full_name':name.text.trim(),'phone':phone.text.trim()});
 if(owner){
 final b=await sb.from('businesses').insert({'owner_id':uid,'name':shop.text.trim(),'status':'pending'}).select().single();
 await sb.from('employees').insert({'business_id':b['id'],'user_id':uid,'display_name':name.text.trim()});
 for(var d=0;d<7;d++){await sb.from('business_hours').insert({'business_id':b['id'],'weekday':d,'opens_at':d==0?null:'09:00','closes_at':d==0?null:'20:00','is_closed':d==0});}
 }else{await sb.rpc('join_business_by_code',params:{'p_code':code.text.trim().toUpperCase()});}
 }catch(e){message=err(e);} if(mounted){setState(()=>busy=false);if(message.isEmpty)Navigator.of(context).pushReplacement(MaterialPageRoute(builder:(_)=>const AuthGate()));}}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Hesap bilgileri'),actions:[IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout))]),body:ListView(padding:const EdgeInsets.all(20),children:[
 SegmentedButton<bool>(segments:const [ButtonSegment(value:false,label:Text('Müşteriyim')),ButtonSegment(value:true,label:Text('İşletme sahibiyim'))],selected:{owner},onSelectionChanged:(v)=>setState(()=>owner=v.first)),
 const SizedBox(height:14),TextField(controller:name,decoration:const InputDecoration(labelText:'Ad soyad')),const SizedBox(height:10),
 TextField(controller:phone,decoration:const InputDecoration(labelText:'Telefon (isteğe bağlı)')),
 if(owner)...[const SizedBox(height:10),TextField(controller:shop,decoration:const InputDecoration(labelText:'İşletme adı'))] else ...[const SizedBox(height:10),TextField(controller:code,decoration:const InputDecoration(labelText:'İşletme katılım kodu'))],
 if(message.isNotEmpty)Text(message,style:const TextStyle(color:Colors.redAccent)),const SizedBox(height:18),
 ElevatedButton(onPressed:busy?null:save,child:Text(busy?'Kaydediliyor…':owner?'İşletme başvurusu gönder':'İşletmeye katıl')),
 const Text('İşletme başvuruları yönetici onayından sonra aktif olur.',style:TextStyle(color:Colors.white60))
 ]));
}

class PendingPage extends StatelessWidget { const PendingPage({super.key,required this.business}); final Map<String,dynamic> business;
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(actions:[IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout))]),body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
 const Icon(Icons.hourglass_top,color:gold,size:56),const SizedBox(height:16),Text(business['status']=='rejected'?'Başvuru reddedildi':'Başvurun inceleniyor',style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:10),Text(business['name']??''),const Text('Yönetici onayından sonra işletmen aktif olacaktır.')
 ]))));
}

class AdminPage extends StatefulWidget { const AdminPage({super.key}); @override State<AdminPage> createState()=>_AdminPageState(); }
class _AdminPageState extends State<AdminPage>{
 Future<List<Map<String,dynamic>>> load()=>sb.from('businesses').select().order('created_at',ascending:false);
 Future<void> review(String id,String status) async {try{await sb.rpc('review_business',params:{'p_business_id':id,'p_status':status});setState((){});}catch(e){toast(context,err(e));}}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Yönetici paneli'),actions:[IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout))]),body:FutureBuilder<List<Map<String,dynamic>>>(future:load(),builder:(c,s){if(!s.hasData)return const LoadingPage();if(s.hasError)return ErrorPage(message:err(s.error!));return ListView(padding:const EdgeInsets.all(16),children:s.data!.map((b)=>Card(child:ListTile(title:Text(b['name']),subtitle:Text('Durum: ${b['status']} • Kod: ${b['join_code']}'),trailing:PopupMenuButton<String>(onSelected:(v)=>review(b['id'],v),itemBuilder:(_)=>const [PopupMenuItem(value:'active',child:Text('Onayla')),PopupMenuItem(value:'rejected',child:Text('Reddet')),PopupMenuItem(value:'inactive',child:Text('Pasife al'))])))).toList());}));
}

class BarberPage extends StatefulWidget { const BarberPage({super.key,required this.business}); final Map<String,dynamic> business; @override State<BarberPage> createState()=>_BarberPageState(); }
class _BarberPageState extends State<BarberPage>{
 final service=TextEditingController(),price=TextEditingController(),duration=TextEditingController(text:'30'),employee=TextEditingController(),open=TextEditingController(text:'09:00'),close=TextEditingController(text:'20:00');
 bool busy=false; Future<void> refresh()async{if(mounted)setState((){});}
 Future<void> addService()async{try{await sb.from('services').insert({'business_id':widget.business['id'],'name':service.text.trim(),'price':double.parse(price.text),'duration_minutes':int.parse(duration.text)});service.clear();price.clear();refresh();}catch(e){toast(context,err(e));}}
 Future<void> addEmployee()async{try{await sb.from('employees').insert({'business_id':widget.business['id'],'display_name':employee.text.trim()});employee.clear();refresh();}catch(e){toast(context,err(e));}}
 Future<void> saveHours()async{try{for(var d=0;d<7;d++){await sb.from('business_hours').upsert({'business_id':widget.business['id'],'weekday':d,'opens_at':open.text,'closes_at':close.text,'is_closed':false},onConflict:'business_id,weekday');}toast(context,'Çalışma saatleri kaydedildi');}catch(e){toast(context,err(e));}}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.business['name']),actions:[IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout))]),body:ListView(padding:const EdgeInsets.all(16),children:[
 const Text('İşletme kodun',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),SelectableText(widget.business['join_code'],style:const TextStyle(color:gold,fontSize:24,fontWeight:FontWeight.bold)),
 const SizedBox(height:18),const Text('Çalışma saatleri',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Row(children:[Expanded(child:TextField(controller:open,decoration:const InputDecoration(labelText:'Açılış'))),const SizedBox(width:8),Expanded(child:TextField(controller:close,decoration:const InputDecoration(labelText:'Kapanış')))]),const SizedBox(height:8),OutlinedButton(onPressed:saveHours,child:const Text('Haftanın tüm günlerine uygula')),
 const SizedBox(height:18),const Text('Çalışanlar',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),TextField(controller:employee,decoration:const InputDecoration(labelText:'Çalışan adı')),const SizedBox(height:8),OutlinedButton(onPressed:addEmployee,child:const Text('Çalışan ekle')),
 FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('employees').select().eq('business_id',widget.business['id']),builder:(c,s)=>Column(children:(s.data??[]).map((e)=>ListTile(title:Text(e['display_name']),subtitle:Text(e['is_active']?'Aktif':'Pasif'))).toList())),
 const SizedBox(height:18),const Text('Hizmetler',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),TextField(controller:service,decoration:const InputDecoration(labelText:'Hizmet adı')),const SizedBox(height:8),Row(children:[Expanded(child:TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Ücret TL'))),const SizedBox(width:8),Expanded(child:TextField(controller:duration,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Süre dk')))]),const SizedBox(height:8),ElevatedButton(onPressed:addService,child:const Text('Hizmet ekle')),
 FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('services').select().eq('business_id',widget.business['id']),builder:(c,s)=>Column(children:(s.data??[]).map((e)=>ListTile(title:Text(e['name']),subtitle:Text('${e['price']} TL • ${e['duration_minutes']} dk'),trailing:Switch(value:e['is_active'],onChanged:(v)async{await sb.from('services').update({'is_active':v}).eq('id',e['id']);refresh();}))).toList())),
 const SizedBox(height:18),const Text('Randevular',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
 FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('appointments').select('*, services(name), employees(display_name)').eq('business_id',widget.business['id']).order('starts_at'),builder:(c,s)=>Column(children:(s.data??[]).map((a)=>ListTile(title:Text(a['services']?['name']??'Randevu'),subtitle:Text('${a['starts_at']} • ${a['employees']?['display_name']??''} • ${a['status']}'),trailing:a['status']=='confirmed'?IconButton(icon:const Icon(Icons.cancel),onPressed:()async{await sb.rpc('cancel_appointment',params:{'p_appointment_id':a['id']});refresh();}):null)).toList()))
 ]));
}

class CustomerPage extends StatefulWidget { const CustomerPage({super.key}); @override State<CustomerPage> createState()=>_CustomerPageState(); }
class _CustomerPageState extends State<CustomerPage>{
 String? businessId,employeeId,serviceId; DateTime day=DateTime.now().add(const Duration(days:1)); bool busy=false;
 String date(DateTime d)=>'${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
 Future<void> book()async{if(businessId==null||employeeId==null||serviceId==null)return;setState(()=>busy=true);try{final local=DateTime(day.year,day.month,day.day,10);await sb.rpc('book_appointment',params:{'p_business_id':businessId,'p_employee_id':employeeId,'p_service_id':serviceId,'p_starts_at':local.toUtc().toIso8601String()});toast(context,'Randevun onaylandı');}catch(e){toast(context,err(e));}if(mounted)setState(()=>busy=false);}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Berberim'),actions:[IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout))]),body:FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('business_memberships').select('business_id, businesses(id,name)').eq('customer_id',uid),builder:(c,m){if(!m.hasData)return const LoadingPage();final businesses=(m.data??[]).map((x)=>x['businesses']).whereType<Map<String,dynamic>>().toList();return ListView(padding:const EdgeInsets.all(16),children:[
 const Text('Randevu oluştur',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800)),const SizedBox(height:12),
 if(businesses.isEmpty)const Text('Henüz bir işletmeye katılmadın. Profilinden işletme koduyla katılabilirsin.'),
 DropdownButtonFormField<String>(value:businessId,decoration:const InputDecoration(labelText:'İşletme seç'),items:businesses.map((b)=>DropdownMenuItem(value:b['id'] as String,child:Text(b['name']))).toList(),onChanged:(v)=>setState(()=>businessId=v)),
 if(businessId!=null)FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('employees').select().eq('business_id',businessId!).eq('is_active',true),builder:(c,s)=>DropdownButtonFormField<String>(value:employeeId,decoration:const InputDecoration(labelText:'Berber seç'),items:(s.data??[]).map((e)=>DropdownMenuItem(value:e['id'] as String,child:Text(e['display_name']))).toList(),onChanged:(v)=>setState(()=>employeeId=v))),
 if(businessId!=null)FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('services').select().eq('business_id',businessId!).eq('is_active',true),builder:(c,s)=>DropdownButtonFormField<String>(value:serviceId,decoration:const InputDecoration(labelText:'Hizmet seç'),items:(s.data??[]).map((e)=>DropdownMenuItem(value:e['id'] as String,child:Text('${e['name']} • ${e['price']} TL / ${e['duration_minutes']} dk'))).toList(),onChanged:(v)=>setState(()=>serviceId=v))),
 OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:c,initialDate:day,firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:90)));if(d!=null)setState(()=>day=d);},icon:const Icon(Icons.calendar_month),label:Text(date(day))),
 ElevatedButton(onPressed:busy?null:book,child:Text(busy?'İşleniyor…':'10:00 için randevu al')),
 const SizedBox(height:20),const Text('Randevularım',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
 FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('appointments').select('*, businesses(name), services(name), employees(display_name)').eq('customer_id',uid).order('starts_at',ascending:false),builder:(c,s)=>Column(children:(s.data??[]).map((a)=>Card(child:ListTile(title:Text(a['services']?['name']??'Randevu'),subtitle:Text('${a['businesses']?['name']??''} • ${a['starts_at']} • ${a['status']}'),trailing:a['status']=='confirmed'?IconButton(icon:const Icon(Icons.cancel_outlined),onPressed:()async{await sb.rpc('cancel_appointment',params:{'p_appointment_id':a['id']});setState((){});}):null))).toList()))
 ]);}));
}
