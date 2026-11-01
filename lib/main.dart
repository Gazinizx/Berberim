import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const gold = Color(0xFFFF7A1A);
const ink = Color(0xFF0B0B0E);
const panel = Color(0xFF19191F);
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
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Berberim', debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark).copyWith(
        primary: gold, secondary: const Color(0xFFFFA45C), surface: panel,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ink, foregroundColor: Colors.white, centerTitle: false,
        elevation: 0, scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: panel, elevation: 0, margin: const EdgeInsets.symmetric(vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF303037), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: const Color(0xFF17171C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        labelStyle: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w500),
        prefixIconColor: gold,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF303037)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: gold, foregroundColor: ink, minimumSize: const Size.fromHeight(54),
        elevation: 0, textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: Color(0xFF3A3A42)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
        foregroundColor: gold, textStyle: const TextStyle(fontWeight: FontWeight.w700),
      )),
      dividerTheme: const DividerThemeData(color: Color(0xFF303037), thickness: 1),
    ),
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
 await sb.from('profiles').update({'full_name':name.text.trim(),'phone':phone.text.trim()}).eq('id',uid);
 if(owner){
 await sb.rpc('create_business_application',params:{'p_name':shop.text.trim(),'p_address':null});
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
 const Icon(Icons.hourglass_top,color:gold,size:56),const SizedBox(height:16),Text(business['status']=='rejected'?'Başvuru reddedildi':'Başvurun inceleniyor',style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:10),Text(business['name']??''),const Text('Yönetici onayından sonra işletmen aktif olacaktır.'),
 const SizedBox(height:18),ElevatedButton(onPressed:()=>Navigator.of(c).pushReplacement(MaterialPageRoute(builder:(_)=>const AuthGate())),child:const Text('Durumu yenile'))
 ]))));
}

class AdminPage extends StatefulWidget { const AdminPage({super.key}); @override State<AdminPage> createState()=>_AdminPageState(); }
class _AdminPageState extends State<AdminPage>{
 Future<List<Map<String,dynamic>>> load()=>sb.from('businesses').select().order('created_at',ascending:false);
 Future<void> review(String id,String status) async {try{await sb.rpc('review_business',params:{'p_business_id':id,'p_status':status});setState((){});}catch(e){toast(context,err(e));}}
 Future<void> block(String id,bool value) async {try{await sb.rpc('admin_set_user_blocked',params:{'p_user_id':id,'p_blocked':value});setState((){});}catch(e){toast(context,err(e));}}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Yönetici paneli'),actions:[IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout))]),body:ListView(padding:const EdgeInsets.all(16),children:[
 const Text('İşletme başvuruları',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
 FutureBuilder<List<Map<String,dynamic>>>(future:load(),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const LoadingPage();if(s.hasError)return ErrorPage(message:err(s.error!));return Column(children:(s.data??[]).map((b)=>Card(child:ListTile(title:Text(b['name']),subtitle:Text('Durum: ${b['status']} • Kod: ${b['join_code']}'),trailing:PopupMenuButton<String>(onSelected:(v)=>review(b['id'],v),itemBuilder:(_)=>const [PopupMenuItem(value:'active',child:Text('Onayla')),PopupMenuItem(value:'rejected',child:Text('Reddet')),PopupMenuItem(value:'inactive',child:Text('Pasife al'))])))).toList());}),
 const SizedBox(height:22),const Text('Kullanıcılar',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
 FutureBuilder<List<Map<String,dynamic>>>(future:sb.from('profiles').select().order('created_at',ascending:false),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const LoadingPage();if(s.hasError)return ErrorPage(message:err(s.error!));return Column(children:(s.data??[]).map((p)=>ListTile(title:Text((p['full_name']??'İsimsiz kullanıcı').toString()),subtitle:Text(p['id'].toString()),trailing:Switch(value:p['is_blocked']==true,onChanged:(v)=>block(p['id'],v)))).toList());})
 ]));
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
