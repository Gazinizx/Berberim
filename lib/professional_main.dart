import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const gold=Color(0xFFD6A64B), goldSoft=Color(0xFFF0D18A), ink=Color(0xFF090A0C), panel=Color(0xFF14171C), panel2=Color(0xFF1B1F25), ivory=Color(0xFFF5F2EB), muted=Color(0xFF9298A3), line=Color(0xFF2B3038);
final db=Supabase.instance.client;
final Map<String,Future<dynamic>> _futureCache={};
Future<T> cached<T>(String key,Future<T> Function() load){final existing=_futureCache[key];if(existing!=null)return existing as Future<T>;final future=load();_futureCache[key]=future;return future;}
void invalidateFutureCache([String? prefix]){if(prefix==null){_futureCache.clear();return;}_futureCache.removeWhere((key,value)=>key.startsWith(prefix));}
String get userId=>db.auth.currentUser!.id;
String errorText(Object e)=>e.toString().replaceFirst('Exception: ','');
String dateText(DateTime d)=>'${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';
String dateKey(DateTime d)=>'${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
String timeText(DateTime d)=>'${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
DateTime localDate(dynamic v)=>DateTime.parse(v.toString()).toLocal();
void snack(BuildContext c,String s)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s)));

Future<void> main()async{
 WidgetsFlutterBinding.ensureInitialized();
 const url=String.fromEnvironment('SUPABASE_URL'),key=String.fromEnvironment('SUPABASE_ANON_KEY');
 if(url.isNotEmpty&&key.isNotEmpty)await Supabase.initialize(url:url,publishableKey:key);
 runApp(const BerberimApp());
}
class BerberimApp extends StatelessWidget{
 const BerberimApp({super.key});
 @override Widget build(BuildContext c)=>MaterialApp(title:'Berberim',debugShowCheckedModeBanner:false,theme:ThemeData(
  useMaterial3:true,brightness:Brightness.dark,scaffoldBackgroundColor:ink,canvasColor:ink,dividerColor:line,
  colorScheme:const ColorScheme.dark(primary:gold,onPrimary:Color(0xFF17130B),secondary:goldSoft,surface:panel,onSurface:ivory,error:Color(0xFFFF7379)),
  textTheme:ThemeData.dark(useMaterial3:true).textTheme.apply(bodyColor:ivory,displayColor:ivory),
  appBarTheme:const AppBarTheme(backgroundColor:ink,foregroundColor:ivory,centerTitle:false,elevation:0,scrolledUnderElevation:0,titleTextStyle:TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:ivory)),
  cardTheme:CardThemeData(color:panel,elevation:0,margin:const EdgeInsets.symmetric(vertical:7),clipBehavior:Clip.antiAlias,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22),side:const BorderSide(color:line))),
  inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:panel2,contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:16),labelStyle:const TextStyle(color:muted),border:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:const BorderSide(color:line)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:const BorderSide(color:line)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:const BorderSide(color:gold,width:1.5))),
  elevatedButtonTheme:ElevatedButtonThemeData(style:ElevatedButton.styleFrom(backgroundColor:gold,foregroundColor:const Color(0xFF17130B),minimumSize:const Size.fromHeight(52),elevation:0,textStyle:const TextStyle(fontWeight:FontWeight.w800),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15)))),
  outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(foregroundColor:ivory,minimumSize:const Size.fromHeight(48),side:const BorderSide(color:line),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15)))),
  navigationBarTheme:const NavigationBarThemeData(backgroundColor:panel,indicatorColor:Color(0x33D6A64B),height:72,labelTextStyle:WidgetStatePropertyAll(TextStyle(fontSize:11,fontWeight:FontWeight.w700))),
  dialogTheme:DialogThemeData(backgroundColor:panel,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22))),
 ),home:const ConfigGate());
}
class ConfigGate extends StatelessWidget{
 const ConfigGate({super.key});
 @override Widget build(BuildContext c){const u=String.fromEnvironment('SUPABASE_URL'),k=String.fromEnvironment('SUPABASE_ANON_KEY');return u.isEmpty||k.isEmpty?const Scaffold(body:Center(child:Text('Supabase yapılandırması bulunamadı.'))):const AuthGate();}
}
class AuthGate extends StatelessWidget{
 const AuthGate({super.key});
 @override Widget build(BuildContext c)=>StreamBuilder<AuthState>(stream:db.auth.onAuthStateChange,builder:(c,_){
  if(db.auth.currentUser==null)return const LoginPage();
  return FutureBuilder<Map<String,dynamic>?>(future:cached('auth_profile_$userId',()=>db.from('profiles').select().eq('id',userId).maybeSingle()),builder:(c,p){
   if(p.connectionState!=ConnectionState.done)return const Loading();
   if(p.hasError)return Fail(errorText(p.error!));
   if(p.data==null)return const BusinessApplicationPage();
   final profile=p.data!;
   if(profile['is_blocked']==true)return const Fail('Hesabın geçici olarak engellendi.');
   if(profile['is_admin']==true)return const AdminPage();
   if(profile['account_type']=='worker')return FutureBuilder<Map<String,dynamic>?>(future:cached('auth_employee_$userId',()=>db.from('employees').select('*,businesses(*)').eq('user_id',userId).eq('is_active',true).maybeSingle()),builder:(c,e){
    if(e.connectionState!=ConnectionState.done)return const Loading();
    if(e.hasError)return Fail(errorText(e.error!));
    if(e.data==null)return const Fail('Çalışan bağlantısı bulunamadı. İşletme sahibinden davet kodunu kontrol etmesini iste.');
    return WorkerPage(employee:e.data!,business:e.data!['businesses'] as Map<String,dynamic>);
   });
   return FutureBuilder<List<Map<String,dynamic>>>(future:cached('auth_businesses_$userId',()=>db.from('businesses').select().eq('owner_id',userId).order('created_at')),builder:(c,b){
    if(b.connectionState!=ConnectionState.done)return const Loading();
    if(b.hasError)return Fail(errorText(b.error!));
    if((b.data??[]).isNotEmpty){final active=b.data!.where((x)=>x['status']=='active').toList();return active.isEmpty?PendingPage(business:b.data!.first):OwnerPage(business:active.first);}
    return profile['account_type']=='business_owner'?const BusinessApplicationPage():const CustomerPage();
   });
  });
 });
}
class Loading extends StatelessWidget{const Loading({super.key});@override Widget build(BuildContext c)=>const Scaffold(body:Center(child:CircularProgressIndicator(color:gold)));}
class Fail extends StatelessWidget{const Fail(this.message,{super.key});final String message;@override Widget build(BuildContext c)=>Scaffold(body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Text(message,textAlign:TextAlign.center))));}
Widget titleBlock(String a,String b)=>Padding(padding:const EdgeInsets.only(bottom:16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontSize:27,fontWeight:FontWeight.w900,letterSpacing:-.5)),const SizedBox(height:4),Text(b,style:const TextStyle(color:muted,fontSize:13))]));
Widget cardBox(Widget child)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:child));
Widget section(String s)=>Padding(padding:const EdgeInsets.only(top:12,bottom:8),child:Text(s,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)));
Widget logout()=>IconButton(onPressed:()=>db.auth.signOut(),icon:const Icon(Icons.logout_rounded));
Widget notifications(BuildContext c)=>IconButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const NotificationsPage())),icon:const Icon(Icons.notifications_none_rounded));
Color statusColour(String s)=>s=='confirmed'?const Color(0xFF4CC38A):s=='completed'?const Color(0xFF77B6FF):s=='no_show'?const Color(0xFFFF9C66):s=='cancelled'?const Color(0xFFFF7379):gold;
String statusName(String s)=>switch(s){'confirmed'=>'Onaylandı','completed'=>'Tamamlandı','no_show'=>'Gelmedi','cancelled'=>'İptal edildi','pending'=>'Bekliyor',_=>s};
Widget statusPill(String s)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:statusColour(s).withOpacity(.13),borderRadius:BorderRadius.circular(30)),child:Text(statusName(s),style:TextStyle(color:statusColour(s),fontSize:11,fontWeight:FontWeight.w800)));
Widget tinyInfo(IconData icon,String value)=>Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:15,color:gold),const SizedBox(width:5),Text(value,style:const TextStyle(color:muted,fontSize:12))]);

class LoginPage extends StatefulWidget{const LoginPage({super.key});@override State<LoginPage> createState()=>_LoginPageState();}
class _LoginPageState extends State<LoginPage>{
 final email=TextEditingController(),password=TextEditingController(),invite=TextEditingController();bool create=false,busy=false,showPassword=false;String type='customer',message='';
 Future<void> submit()async{
  setState(()=>busy=true);message='';
  try{
   if(create){
    if(password.text.length<8)throw Exception('Şifre en az 8 karakter olmalı.');
    if(type=='worker'&&invite.text.trim().isEmpty)throw Exception('Çalışan davet kodunu gir.');
    final r=await db.auth.signUp(email:email.text.trim(),password:password.text,data:{'account_type':type=='business_owner'?'business_owner':'customer'});
    if(r.session==null){message='Doğrulama e-postası gönderildi. E-postanı doğrula; sonra giriş yapıp davet kodunu tekrar gir.';}
    else if(type=='worker'){await db.rpc('claim_employee_invite',params:{'p_code':invite.text.trim().toUpperCase()});await db.auth.refreshSession();}
    else{message='Hesabın oluşturuldu.';}
   }else{
    await db.auth.signInWithPassword(email:email.text.trim(),password:password.text);
    if(invite.text.trim().isNotEmpty){await db.rpc('claim_employee_invite',params:{'p_code':invite.text.trim().toUpperCase()});await db.auth.refreshSession();}
   }
  }catch(e){message=errorText(e);}
  if(mounted)setState(()=>busy=false);
 }
 @override Widget build(BuildContext c)=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(22),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  const Icon(Icons.content_cut_rounded,color:gold,size:58),const SizedBox(height:10),const Text('Berberim',textAlign:TextAlign.center,style:TextStyle(fontSize:36,fontWeight:FontWeight.w900)),const Text('Randevunun kolay yolu',textAlign:TextAlign.center,style:TextStyle(color:muted)),const SizedBox(height:28),
  if(create)SegmentedButton<String>(showSelectedIcon:false,segments:const [ButtonSegment(value:'customer',label:Text('Müşteri')),ButtonSegment(value:'worker',label:Text('Çalışan')),ButtonSegment(value:'business_owner',label:Text('İşletme'))],selected:{type},onSelectionChanged:(v)=>setState(()=>type=v.first)),
  TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-posta',prefixIcon:Icon(Icons.mail_outline))),const SizedBox(height:12),
  TextField(controller:password,obscureText:!showPassword,decoration:InputDecoration(labelText:'Şifre',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(onPressed:()=>setState(()=>showPassword=!showPassword),icon:Icon(showPassword?Icons.visibility_off:Icons.visibility)))),
  if(create&&type=='worker'||!create&&type=='worker')const SizedBox(height:12),
  if((create||!create)&&type=='worker')TextField(controller:invite,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'Çalışan davet kodu',prefixIcon:Icon(Icons.key))),
  if(!create)TextButton(onPressed:()=>setState(()=>type=type=='worker'?'customer':'worker'),child:Text(type=='worker'?'Müşteri girişi':'Çalışan davet kodum var')),
  if(create&&type=='business_owner')const Padding(padding:EdgeInsets.only(top:8),child:Text('İşletme hesabı yönetici onayından sonra açılır.',style:TextStyle(color:muted))),
  if(message.isNotEmpty)Padding(padding:const EdgeInsets.all(10),child:Text(message,style:TextStyle(color:message.startsWith('Doğrulama')||message=='Hesabın oluşturuldu.'?Colors.lightGreenAccent:const Color(0xFFFF7379)))),
  const SizedBox(height:14),ElevatedButton(onPressed:busy?null:submit,child:Text(busy?'Bekleyin…':create?'Hesap oluştur':'Giriş yap')),
  TextButton(onPressed:()=>setState(() { create=!create; message=''; invite.clear(); }),child:Text(create?'Giriş yap':'Yeni hesap oluştur'))
 ])))));
}
class BusinessApplicationPage extends StatefulWidget{const BusinessApplicationPage({super.key});@override State<BusinessApplicationPage> createState()=>_BusinessApplicationPageState();}
class _BusinessApplicationPageState extends State<BusinessApplicationPage>{
 final name=TextEditingController(),phone=TextEditingController(),shop=TextEditingController(),address=TextEditingController();bool busy=false;String message='';
 Future<void> send()async{setState(()=>busy=true);message='';try{await db.from('profiles').update({'full_name':name.text.trim(),'phone':phone.text.trim()}).eq('id',userId);await db.rpc('create_business_application',params:{'p_name':shop.text.trim(),'p_address':address.text.trim().isEmpty?null:address.text.trim()});if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const AuthGate()),(r)=>false);}catch(e){message=errorText(e);}if(mounted)setState(()=>busy=false);}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('İşletme başvurusu'),actions:[logout()]),body:ListView(padding:const EdgeInsets.all(20),children:[titleBlock('İşletmeni tanıtalım','Başvurun yönetici tarafından incelenecek.'),cardBox(Column(children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Ad soyad')),const SizedBox(height:12),TextField(controller:phone,decoration:const InputDecoration(labelText:'Telefon')),const SizedBox(height:12),TextField(controller:shop,decoration:const InputDecoration(labelText:'İşletme adı')),const SizedBox(height:12),TextField(controller:address,decoration:const InputDecoration(labelText:'Adres')),if(message.isNotEmpty)Text(message,style:const TextStyle(color:Colors.redAccent)),const SizedBox(height:12),ElevatedButton(onPressed:busy?null:send,child:Text(busy?'Gönderiliyor…':'Başvuruyu gönder'))]))]));}
class PendingPage extends StatelessWidget{const PendingPage({super.key,required this.business});final Map<String,dynamic> business;@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Başvuru durumu'),actions:[logout()]),body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.hourglass_top,color:gold,size:60),const SizedBox(height:14),Text(business['status']=='rejected'?'Başvurun reddedildi':'Yönetici onayı bekleniyor',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),Text(business['name']??'',style:const TextStyle(color:gold)),const SizedBox(height:18),OutlinedButton(onPressed:()=>Navigator.pushAndRemoveUntil(c,MaterialPageRoute(builder:(_)=>const AuthGate()),(r)=>false),child:const Text('Durumu yenile'))]))));}

class OwnerPage extends StatefulWidget{const OwnerPage({super.key,required this.business});final Map<String,dynamic> business;@override State<OwnerPage> createState()=>_OwnerPageState();}
class _OwnerPageState extends State<OwnerPage>{
 int tab=0;DateTime day=DateTime.now();String? workerFilter;
 void refresh(){invalidateFutureCache();if(mounted)setState((){});}
 Future<void> setStatus(String id,String value)async{try{await db.rpc('update_appointment_status',params:{'p_appointment_id':id,'p_status':value});refresh();}catch(e){snack(context,errorText(e));}}
 Widget appointment(Map<String,dynamic> a){
  final service=(a['services'] as Map?)??{};final worker=(a['employees'] as Map?)??{};final customer=(a['profiles'] as Map?)??{};final start=localDate(a['starts_at']);
  return cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(service['name']??'Randevu',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16))),statusPill(a['status']??'confirmed')]),const SizedBox(height:8),Wrap(spacing:14,runSpacing:8,children:[tinyInfo(Icons.schedule,'${dateText(start)} • ${timeText(start)}'),tinyInfo(Icons.person_outline,customer['full_name']??'Müşteri'),tinyInfo(Icons.content_cut,worker['display_name']??'Çalışan'),tinyInfo(Icons.payments_outlined,'${service['price']??'—'} TL')]),if((customer['phone']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:6),child:Text('Telefon: ${customer['phone']}',style:const TextStyle(color:muted,fontSize:12))),if(a['status']=='confirmed'||a['status']=='pending')Wrap(spacing:8,children:[TextButton(onPressed:()=>setStatus(a['id'],'completed'),child:const Text('Tamamlandı')),TextButton(onPressed:()=>setStatus(a['id'],'no_show'),child:const Text('Gelmedi')),TextButton(onPressed:()=>setStatus(a['id'],'cancelled'),child:const Text('İptal'))])]));
 }
 Widget home(){
  final start=DateTime(day.year,day.month,day.day),end=start.add(const Duration(days:1));
  return ListView(padding:const EdgeInsets.all(16),children:[titleBlock('Ana Sayfa','${widget.business['name']} • Günlük randevu takvimi'),Row(children:[Expanded(child:Text(dateText(day),style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800))),IconButton(onPressed:()=>setState(()=>day=day.subtract(const Duration(days:1))),icon:const Icon(Icons.chevron_left)),IconButton(onPressed:()async{final d=await showDatePicker(context:context,initialDate:day,firstDate:DateTime.now().subtract(const Duration(days:365)),lastDate:DateTime.now().add(const Duration(days:365)));if(d!=null)setState(()=>day=d);},icon:const Icon(Icons.calendar_month)),IconButton(onPressed:()=>setState(()=>day=day.add(const Duration(days:1))),icon:const Icon(Icons.chevron_right))]),
  FutureBuilder<List<Map<String,dynamic>>>(future:cached('owner_active_employees_${widget.business['id']}',()=>db.from('employees').select('id,display_name').eq('business_id',widget.business['id']).eq('is_active',true)),builder:(c,s)=>DropdownButtonFormField<String>(value:workerFilter,decoration:const InputDecoration(labelText:'Çalışan filtresi'),items:[const DropdownMenuItem<String>(value:null,child:Text('Tüm çalışanlar')),...(s.data??[]).map((e)=>DropdownMenuItem<String>(value:e['id'],child:Text(e['display_name'])))],onChanged:(v)=>setState(()=>workerFilter=v))),
  FutureBuilder<List<Map<String,dynamic>>>(future:cached('owner_appointments_${widget.business['id']}_${dateKey(day)}',()=>db.from('appointments').select('*,services(name,price),employees(display_name),profiles(full_name,phone)').eq('business_id',widget.business['id']).gte('starts_at',start.toUtc().toIso8601String()).lt('starts_at',end.toUtc().toIso8601String()).order('starts_at')),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const Loading();if(s.hasError)return Text(errorText(s.error!));final rows=(s.data??[]).where((x)=>workerFilter==null||x['employee_id']==workerFilter).toList();return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const SizedBox(height:12),Row(children:[_metric('Toplam',rows.length),_metric('Onaylı',rows.where((x)=>x['status']=='confirmed').length),_metric('Biten',rows.where((x)=>x['status']=='completed').length)]),section('Randevular'),if(rows.isEmpty)cardBox(const Text('Bu gün randevu bulunmuyor.',style:TextStyle(color:muted))),...rows.map(appointment)]);})
  ]);
 }
 Widget _metric(String label,int n)=>Expanded(child:cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('$n',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),Text(label,style:const TextStyle(color:muted,fontSize:12))])));
 Widget team(){
  final name=TextEditingController();
  return ListView(padding:const EdgeInsets.all(16),children:[titleBlock('Çalışanlar','Ekibine davet kodu oluştur.'),cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Yeni çalışan',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)),const SizedBox(height:10),TextField(controller:name,decoration:const InputDecoration(labelText:'Çalışan adı')),const SizedBox(height:10),ElevatedButton.icon(onPressed:()async{try{final code=await db.rpc('create_employee_invite',params:{'p_display_name':name.text.trim()});name.clear();if(mounted)showDialog(context:context,builder:(d)=>AlertDialog(title:const Text('Çalışan davet kodu'),content:SelectableText(code.toString(),style:const TextStyle(color:gold,fontSize:25,fontWeight:FontWeight.w900)),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Tamam'))]));refresh();}catch(e){snack(context,errorText(e));}},icon:const Icon(Icons.person_add_alt),label:const Text('Çalışan ekle ve kod oluştur'))])),
  section('Ekibin'),FutureBuilder<List<Map<String,dynamic>>>(future:cached('owner_team_${widget.business['id']}',()=>db.from('employees').select('*,employee_invites(invite_code,expires_at,claimed_at)').eq('business_id',widget.business['id']).order('created_at')),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const Loading();if(s.hasError)return Text(errorText(s.error!));final rows=s.data??[];if(rows.isEmpty)return cardBox(const Text('Henüz çalışan eklenmedi.',style:TextStyle(color:muted)));return Column(children:rows.map((e){final inv=(e['employee_invites'] as List?)??[];final last=inv.isEmpty?null:inv.last;return cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const CircleAvatar(backgroundColor:panel2,child:Icon(Icons.person,color:gold)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e['display_name']??'Çalışan',style:const TextStyle(fontWeight:FontWeight.w800)),Text(e['user_id']==null?'Hesap bağlanmadı':'Hesap bağlandı',style:const TextStyle(color:muted,fontSize:12))])),Switch(value:e['is_active']==true,onChanged:(v)async{try{await db.from('employees').update({'is_active':v}).eq('id',e['id']);refresh();}catch(x){snack(context,errorText(x));}})]),if(last!=null&&last['claimed_at']==null)Padding(padding:const EdgeInsets.only(top:10),child:SelectableText('Davet kodu: ${last['invite_code']}',style:const TextStyle(color:gold,fontWeight:FontWeight.w800))),if(last!=null&&last['claimed_at']!=null)const Padding(padding:EdgeInsets.only(top:8),child:Text('Davet kullanıldı',style:TextStyle(color:Colors.lightGreenAccent,fontSize:12)))]));}).toList());})
  ]);
 }
 Future<void> editService(Map<String,dynamic> serviceRow) async {
  final serviceName=TextEditingController(text:serviceRow['name']??'');
  final servicePrice=TextEditingController(text:serviceRow['price'].toString());
  final serviceDuration=TextEditingController(text:serviceRow['duration_minutes'].toString());
  final saved=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
   title:const Text('Hizmeti düzenle'),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:serviceName,decoration:const InputDecoration(labelText:'Hizmet adı')),
    const SizedBox(height:10),
    TextField(controller:servicePrice,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Fiyat TL')),
    const SizedBox(height:10),
    TextField(controller:serviceDuration,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Süre dakika')),
   ]),
   actions:[
    TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('Vazgeç')),
    ElevatedButton(onPressed:()async{
     try {
      await db.from('services').update({'name':serviceName.text.trim(),'price':double.parse(servicePrice.text),'duration_minutes':int.parse(serviceDuration.text)}).eq('id',serviceRow['id']);
      if(dialog.mounted)Navigator.pop(dialog,true);
     } catch(e) { if(dialog.mounted)snack(dialog,errorText(e)); }
    },child:const Text('Kaydet')),
   ],
  ));
  serviceName.dispose();servicePrice.dispose();serviceDuration.dispose();
  if(saved==true&&mounted){refresh();snack(context,'Hizmet güncellendi');}
 }
 Widget management(){
  final service=TextEditingController(),price=TextEditingController(),duration=TextEditingController(text:'30'),opening=TextEditingController(text:'09:00'),closing=TextEditingController(text:'20:00'),breakStart=TextEditingController(text:'13:00'),breakEnd=TextEditingController(text:'14:00');
  return ListView(padding:const EdgeInsets.all(16),children:[titleBlock('Yönetim','Hizmetler, fiyatlar ve işletme saatleri'),cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Çalışma saatleri',style:TextStyle(fontWeight:FontWeight.w800,fontSize:17)),Row(children:[Expanded(child:TextField(controller:opening,decoration:const InputDecoration(labelText:'Açılış'))),const SizedBox(width:10),Expanded(child:TextField(controller:closing,decoration:const InputDecoration(labelText:'Kapanış')))]),const SizedBox(height:10),ElevatedButton(onPressed:()async{try{for(var d=0;d<7;d++){await db.from('business_hours').upsert({'business_id':widget.business['id'],'weekday':d,'opens_at':opening.text,'closes_at':closing.text,'is_closed':false},onConflict:'business_id,weekday');}snack(context,'Saatler kaydedildi');}catch(e){snack(context,errorText(e));}},child:const Text('Haftanın tüm günlerine uygula')),const Divider(height:25),const Text('İşletme molası',style:TextStyle(fontWeight:FontWeight.w800)),Row(children:[Expanded(child:TextField(controller:breakStart,decoration:const InputDecoration(labelText:'Başlangıç'))),const SizedBox(width:10),Expanded(child:TextField(controller:breakEnd,decoration:const InputDecoration(labelText:'Bitiş')))]),const SizedBox(height:10),OutlinedButton(onPressed:()async{try{if(breakStart.text.compareTo(breakEnd.text)>=0)throw Exception('Mola saatlerini kontrol et');await db.from('business_breaks').delete().eq('business_id',widget.business['id']);for(var d=1;d<7;d++){await db.from('business_breaks').insert({'business_id':widget.business['id'],'weekday':d,'starts_at':breakStart.text,'ends_at':breakEnd.text});}snack(context,'Molalar kaydedildi');}catch(e){snack(context,errorText(e));}},child:const Text('Molayı kaydet'))])),
  section('Hizmet ekle'),cardBox(Column(children:[TextField(controller:service,decoration:const InputDecoration(labelText:'Hizmet adı')),const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Fiyat TL'))),const SizedBox(width:10),Expanded(child:TextField(controller:duration,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Süre dk')))]),const SizedBox(height:10),ElevatedButton(onPressed:()async{try{await db.from('services').insert({'business_id':widget.business['id'],'name':service.text.trim(),'price':double.parse(price.text),'duration_minutes':int.parse(duration.text)});service.clear();price.clear();refresh();}catch(e){snack(context,errorText(e));}},child:const Text('Hizmeti kaydet'))])),
  section('Mevcut hizmetler'),FutureBuilder<List<Map<String,dynamic>>>(future:cached('owner_services_${widget.business['id']}',()=>db.from('services').select().eq('business_id',widget.business['id']).order('created_at')),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const Loading();return Column(children:(s.data??[]).map((x)=>cardBox(SwitchListTile(value:x['is_active']==true,title:Text(x['name'],style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${x['price']} TL • ${x['duration_minutes']} dk',style:const TextStyle(color:muted)),secondary:IconButton(onPressed:()=>editService(x),icon:const Icon(Icons.edit_outlined)),onChanged:(v)async{await db.from('services').update({'is_active':v}).eq('id',x['id']);refresh();}))).toList());})
  ]);
 }
 @override Widget build(BuildContext c){return Scaffold(appBar:AppBar(title:Text(widget.business['name']??'İşletme'),actions:[notifications(c),IconButton(onPressed:refresh,icon:const Icon(Icons.refresh)),logout()]),body:tab==0?home():tab==1?team():management(),bottomNavigationBar:NavigationBar(animationDuration:Duration.zero,selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),label:'Ana Sayfa'),NavigationDestination(icon:Icon(Icons.groups_outlined),label:'Çalışanlar'),NavigationDestination(icon:Icon(Icons.tune),label:'Yönetim')]));}
}

class WorkerPage extends StatefulWidget{const WorkerPage({super.key,required this.employee,required this.business});final Map<String,dynamic> employee,business;@override State<WorkerPage> createState()=>_WorkerPageState();}
class _WorkerPageState extends State<WorkerPage>{
 int tab=0;DateTime day=DateTime.now();final opening=TextEditingController(text:'09:00'),closing=TextEditingController(text:'18:00'),breakStart=TextEditingController(text:'13:00'),breakEnd=TextEditingController(text:'14:00');
 void refresh(){if(mounted)setState((){});}
 Future<void> status(String id,String value)async{try{await db.rpc('update_appointment_status',params:{'p_appointment_id':id,'p_status':value});refresh();}catch(e){snack(context,errorText(e));}}
 Widget schedule(){final start=DateTime(day.year,day.month,day.day),end=start.add(const Duration(days:1));return ListView(padding:const EdgeInsets.all(16),children:[titleBlock('Takvimim','${widget.business['name']} • Sana ait randevular'),Row(children:[Expanded(child:Text(dateText(day),style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800))),IconButton(onPressed:()=>setState(()=>day=day.subtract(const Duration(days:1))),icon:const Icon(Icons.chevron_left)),IconButton(onPressed:()async{final d=await showDatePicker(context:context,initialDate:day,firstDate:DateTime.now().subtract(const Duration(days:365)),lastDate:DateTime.now().add(const Duration(days:365)));if(d!=null)setState(()=>day=d);},icon:const Icon(Icons.calendar_month)),IconButton(onPressed:()=>setState(()=>day=day.add(const Duration(days:1))),icon:const Icon(Icons.chevron_right))]),FutureBuilder<List<Map<String,dynamic>>>(future:cached('worker_appointments_${widget.employee['id']}_${dateKey(day)}',()=>db.from('appointments').select('*,services(name,price),profiles(full_name,phone)').eq('employee_id',widget.employee['id']).gte('starts_at',start.toUtc().toIso8601String()).lt('starts_at',end.toUtc().toIso8601String()).order('starts_at')),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const Loading();if(s.hasError)return Text(errorText(s.error!));final rows=s.data??[];if(rows.isEmpty)return cardBox(const Text('Bu gün randevun yok.',style:TextStyle(color:muted)));return Column(children:rows.map((a){final service=(a['services'] as Map?)??{};final customer=(a['profiles'] as Map?)??{};final dt=localDate(a['starts_at']);return cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(service['name']??'Randevu',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16))),statusPill(a['status'])]),const SizedBox(height:8),tinyInfo(Icons.schedule,'${timeText(dt)} • ${dateText(dt)}'),const SizedBox(height:6),tinyInfo(Icons.person_outline,customer['full_name']??'Müşteri'),if((customer['phone']??'').toString().isNotEmpty)Text('Telefon: ${customer['phone']}',style:const TextStyle(color:muted,fontSize:12)),if(a['status']=='confirmed')Wrap(children:[TextButton(onPressed:()=>status(a['id'],'completed'),child:const Text('Tamamlandı')),TextButton(onPressed:()=>status(a['id'],'no_show'),child:const Text('Gelmedi'))]) ]));}).toList());})]);}
 Widget availability() {
  final eid=widget.employee['id'];
  return FutureBuilder<List<Map<String,dynamic>>>(
   future:cached('worker_timeoff_$eid',()=>db.from('employee_time_off').select().eq('employee_id',eid).gte('ends_at',DateTime.now().toUtc().toIso8601String()).order('starts_at')),
   builder:(context,snapshot) {
    final rows=snapshot.data??[];
    return ListView(
     padding:const EdgeInsets.all(16),
     children:<Widget>[
      titleBlock('Çalışma saatlerim','Kendi uygunluk ve izinlerini düzenle'),
      cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       const Text('Haftalık çalışma saatleri',style:TextStyle(fontWeight:FontWeight.w800,fontSize:17)),
       const Text('Özel saat tanımlanmayan günler işletmenin genel saatlerini kullanır.',style:TextStyle(color:muted,fontSize:12)),
       const SizedBox(height:10),
       Row(children:[
        Expanded(child:TextField(controller:opening,decoration:const InputDecoration(labelText:'Başlangıç'))),
        const SizedBox(width:10),
        Expanded(child:TextField(controller:closing,decoration:const InputDecoration(labelText:'Bitiş'))),
       ]),
       const SizedBox(height:10),
       ElevatedButton(onPressed:()async {
        try {
         for(var d=0;d<7;d++){
          await db.from('employee_hours').upsert({'employee_id':eid,'weekday':d,'opens_at':opening.text,'closes_at':closing.text,'is_closed':false},onConflict:'employee_id,weekday');
         }
         if(mounted)snack(context,'Çalışma saatlerin kaydedildi');
        } catch(e) { if(mounted)snack(context,errorText(e)); }
       },child:const Text('Her güne uygula')),
       const Divider(height:25),
       const Text('Kişisel mola',style:TextStyle(fontWeight:FontWeight.w800)),
       Row(children:[
        Expanded(child:TextField(controller:breakStart,decoration:const InputDecoration(labelText:'Başlangıç'))),
        const SizedBox(width:10),
        Expanded(child:TextField(controller:breakEnd,decoration:const InputDecoration(labelText:'Bitiş'))),
       ]),
       const SizedBox(height:10),
       OutlinedButton(onPressed:()async {
        try {
         if(breakStart.text.compareTo(breakEnd.text)>=0)throw Exception('Mola saatlerini kontrol et');
         await db.from('employee_breaks').delete().eq('employee_id',eid);
         for(var d=1;d<7;d++){
          await db.from('employee_breaks').insert({'employee_id':eid,'weekday':d,'starts_at':breakStart.text,'ends_at':breakEnd.text});
         }
         if(mounted)snack(context,'Molaların kaydedildi');
        } catch(e) { if(mounted)snack(context,errorText(e)); }
       },child:const Text('Molayı haftaya uygula')),
      ])),
      cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       const Text('İzin ekle',style:TextStyle(fontWeight:FontWeight.w800)),
       const SizedBox(height:8),
       OutlinedButton.icon(onPressed:()async {
        final d=await showDatePicker(context:context,initialDate:DateTime.now().add(const Duration(days:1)),firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:365)));
        if(d==null||!mounted)return;
        try {
         final from=DateTime(d.year,d.month,d.day),to=from.add(const Duration(days:1));
         await db.from('employee_time_off').insert({'employee_id':eid,'starts_at':from.toUtc().toIso8601String(),'ends_at':to.toUtc().toIso8601String(),'note':'Tam gün izin'});
         refresh();
        } catch(e) { if(mounted)snack(context,errorText(e)); }
       },icon:const Icon(Icons.event_busy),label:const Text('Tam gün izin ekle')),
      ])),
      if(snapshot.hasError)Text(errorText(snapshot.error!)),
      if(snapshot.connectionState==ConnectionState.done&&rows.isNotEmpty)
       ...rows.map((x)=>ListTile(
        leading:const Icon(Icons.event_busy,color:gold),
        title:Text(dateText(localDate(x['starts_at']))),
        subtitle:Text(x['note']??'İzin'),
        trailing:IconButton(onPressed:()async {
         try { await db.from('employee_time_off').delete().eq('id',x['id']); refresh(); }
         catch(e) { if(mounted)snack(context,errorText(e)); }
        },icon:const Icon(Icons.delete_outline)),
       )),
     ],
    );
   },
  );
 }
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.employee['display_name']??'Çalışan paneli'),actions:[notifications(c),logout()]),body:tab==0?schedule():availability(),bottomNavigationBar:NavigationBar(animationDuration:Duration.zero,selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const [NavigationDestination(icon:Icon(Icons.calendar_month_outlined),label:'Takvimim'),NavigationDestination(icon:Icon(Icons.schedule),label:'Çalışma saatlerim')]));
}

class CustomerPage extends StatefulWidget{const CustomerPage({super.key});@override State<CustomerPage> createState()=>_CustomerPageState();}
class _CustomerPageState extends State<CustomerPage>{
 int tab=0;final code=TextEditingController(),fullName=TextEditingController(),phone=TextEditingController();String? employeeId,serviceId;DateTime day=DateTime.now().add(const Duration(days:1));DateTime? slot;bool busy=false;
 Future<List<Map<String,dynamic>>> membership()=>cached('customer_membership_$userId',()=>db.from('business_memberships').select('business_id,businesses(id,name,address,status)').eq('customer_id',userId));
 Future<void> join()async{setState(()=>busy=true);try{await db.rpc('join_business_by_code',params:{'p_code':code.text.trim().toUpperCase()});invalidateFutureCache('customer_');code.clear();setState(() { employeeId=null; serviceId=null; slot=null; });snack(context,'İşletmeye bağlandın');}catch(e){snack(context,errorText(e));}if(mounted)setState(()=>busy=false);}
 Future<void> leave()async{final yes=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('Berberinden ayrıl?'),content:const Text('İşletme bağlantın kaldırılacak. Geçmiş randevuların silinmeyecek.'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Vazgeç')),ElevatedButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Ayrıl'))]));if(yes!=true)return;try{await db.rpc('leave_business');invalidateFutureCache('customer_');setState(() { employeeId=null; serviceId=null; slot=null; });snack(context,'İşletme bağlantısı kaldırıldı');}catch(e){snack(context,errorText(e));}}
 Future<void> book(String bid)async{if(employeeId==null||serviceId==null||slot==null)return;setState(()=>busy=true);try{await db.rpc('book_appointment',params:{'p_business_id':bid,'p_employee_id':employeeId,'p_service_id':serviceId,'p_starts_at':slot!.toUtc().toIso8601String()});invalidateFutureCache('customer_');invalidateFutureCache('slots_');snack(context,'Randevun oluşturuldu');setState(() { slot=null; tab=1; });}catch(e){snack(context,errorText(e));}if(mounted)setState(()=>busy=false);}
 Widget joinPanel()=>cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.storefront_outlined,color:gold,size:30),const SizedBox(height:8),const Text('Berberine bağlan',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),const Text('İşletme kodunu bir kez girmen yeterli.',style:TextStyle(color:muted,fontSize:13)),const SizedBox(height:12),TextField(controller:code,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'İşletme kodu',prefixIcon:Icon(Icons.key))),const SizedBox(height:10),ElevatedButton(onPressed:busy?null:join,child:Text(busy?'Bağlanıyor…':'İşletmeye bağlan'))]));
 Widget home(Map<String,dynamic>? b){
  if(b==null)return ListView(padding:const EdgeInsets.all(16),children:[titleBlock('Hoş geldin','Randevu oluşturmak için berberine bağlan.'),joinPanel()]);
  final bid=b['id'].toString();
  return ListView(padding:const EdgeInsets.all(16),children:[titleBlock('Merhaba','Randevunu birkaç adımda oluştur.'),cardBox(Row(children:[const CircleAvatar(radius:25,backgroundColor:panel2,child:Icon(Icons.content_cut,color:gold)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(b['name']??'Berberim',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17)),Text(b['address']??'Bağlı işletmen',style:const TextStyle(color:muted,fontSize:12))])),const Icon(Icons.verified,color:gold)])),section('Randevu oluştur'),cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  const Text('1. Çalışanını seç',style:TextStyle(fontWeight:FontWeight.w800)),
  FutureBuilder<List<Map<String,dynamic>>>(future:cached('customer_employees_$bid',()=>db.from('employees').select('id,display_name').eq('business_id',bid).eq('is_active',true).order('display_name')),builder:(c,s)=>DropdownButtonFormField<String>(value:employeeId,decoration:const InputDecoration(labelText:'Berber / çalışan'),items:(s.data??[]).map((x)=>DropdownMenuItem(value:x['id'] as String,child:Text(x['display_name']))).toList(),onChanged:(v)=>setState(() { employeeId=v; slot=null; }))),
  const SizedBox(height:12),const Text('2. Hizmetini seç',style:TextStyle(fontWeight:FontWeight.w800)),
  FutureBuilder<List<Map<String,dynamic>>>(future:cached('customer_services_$bid',()=>db.from('services').select('id,name,price,duration_minutes').eq('business_id',bid).eq('is_active',true).order('name')),builder:(c,s)=>DropdownButtonFormField<String>(value:serviceId,decoration:const InputDecoration(labelText:'Hizmet'),items:(s.data??[]).map((x)=>DropdownMenuItem(value:x['id'] as String,child:Text('${x['name']} • ${x['price']} TL / ${x['duration_minutes']} dk'))).toList(),onChanged:(v)=>setState(() { serviceId=v; slot=null; }))),
  const SizedBox(height:12),const Text('3. Tarih seç',style:TextStyle(fontWeight:FontWeight.w800)),
  OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:context,initialDate:day,firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:90)));if(d!=null)setState(() { day=d; slot=null; });},icon:const Icon(Icons.calendar_month),label:Text(dateText(day))),
  if(employeeId!=null&&serviceId!=null)...[
   const SizedBox(height:8),const Text('4. Uygun saatler',style:TextStyle(fontWeight:FontWeight.w800)),
   FutureBuilder<List<dynamic>>(future:cached('slots_${employeeId}_${serviceId}_${dateKey(day)}',()=>db.rpc('get_available_slots',params:{'p_employee_id':employeeId,'p_service_id':serviceId,'p_day':dateKey(day)})),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const Padding(padding:EdgeInsets.all(14),child:Center(child:CircularProgressIndicator()));if(s.hasError)return Text(errorText(s.error!),style:const TextStyle(color:Colors.redAccent));final times=(s.data??[]).map((x)=>localDate((x as Map)['slot_start'])).toList();if(times.isEmpty)return const Padding(padding:EdgeInsets.symmetric(vertical:12),child:Text('Bu tarihte uygun saat bulunmuyor.',style:TextStyle(color:muted)));return Wrap(spacing:8,runSpacing:8,children:times.map((t)=>ChoiceChip(label:Text(timeText(t)),selected:slot==t,selectedColor:gold,onSelected:(_)=>setState(()=>slot=t))).toList());}),
  ],
  const SizedBox(height:14),ElevatedButton(onPressed:busy||slot==null?null:()=>book(bid),child:Text(busy?'Randevu oluşturuluyor…':'Randevuyu onayla'))
 ]))]);
 }
 Future<void> reschedule(Map<String,dynamic> a) async {
  final d=await showDatePicker(context:context,initialDate:DateTime.now().add(const Duration(days:1)),firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:90)));
  if(d==null||!mounted)return;
  try {
   final raw=await db.rpc('get_available_slots',params:{'p_employee_id':a['employee_id'],'p_service_id':a['service_id'],'p_day':dateKey(d)});
   final times=(raw as List).map((x)=>localDate((x as Map)['slot_start'])).toList();
   if(times.isEmpty){if(mounted)snack(context,'Bu tarihte uygun saat yok.');return;}
   final chips=times.map<Widget>((t) {
    return ActionChip(label:Text(timeText(t)),onPressed:()=>Navigator.pop(context,t));
   }).toList();
   final chosen=await showDialog<DateTime>(
    context:context,
    builder:(dialog)=>AlertDialog(
     title:Text('Yeni saat • ${dateText(d)}'),
     content:SingleChildScrollView(child:Wrap(spacing:8,runSpacing:8,children:chips)),
     actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Vazgeç'))],
    ),
   );
   if(chosen==null||!mounted)return;
   await db.rpc('reschedule_appointment',params:{'p_appointment_id':a['id'],'p_starts_at':chosen.toUtc().toIso8601String()});invalidateFutureCache('customer_');
   if(mounted){setState((){});snack(context,'Randevunun saati değiştirildi');}
  } catch(e) { if(mounted)snack(context,errorText(e)); }
 }
 Future<void> reviewAppointment(Map<String,dynamic> a) async {
  int rating=5;
  final comment=TextEditingController();
  final saved=await showDialog<bool>(context:context,builder:(dialog)=>StatefulBuilder(builder:(dialog,setDialog)=>AlertDialog(
   title:const Text('Berberi değerlendir'),
   content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('Deneyimine kaç yıldız verirsin?',style:TextStyle(color:muted)),
    const SizedBox(height:10),
    SegmentedButton<int>(showSelectedIcon:false,segments:List.generate(5,(i)=>ButtonSegment<int>(value:i+1,label:Text('${i+1}'))),selected:{rating},onSelectionChanged:(v)=>setDialog(()=>rating=v.first)),
    const SizedBox(height:12),
    TextField(controller:comment,maxLines:3,maxLength:500,decoration:const InputDecoration(labelText:'Yorumun (isteğe bağlı)')),
   ]),
   actions:[
    TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('Vazgeç')),
    ElevatedButton(onPressed:()async{try{await db.rpc('submit_business_review',params:{'p_appointment_id':a['id'],'p_rating':rating,'p_comment':comment.text.trim()});invalidateFutureCache('customer_');if(dialog.mounted)Navigator.pop(dialog,true);}catch(e){if(dialog.mounted)snack(dialog,errorText(e));}},child:const Text('Değerlendirmeyi gönder')),
   ],
  )));
  comment.dispose();
  if(saved==true&&mounted){setState((){});snack(context,'Değerlendirmen kaydedildi');}
 }
 void repeatBooking(Map<String,dynamic> a){
  setState((){employeeId=a['employee_id'];serviceId=a['service_id'];day=DateTime.now().add(const Duration(days:1));slot=null;tab=0;});
 }
 Widget appointments()=>ListView(padding:const EdgeInsets.all(16),children:[
  titleBlock('Randevularım','Yaklaşan ve geçmiş randevuların'),
  FutureBuilder<List<Map<String,dynamic>>>(future:cached('customer_appointments_$userId',()=>db.from('appointments').select('*,businesses(name),services(name,price),employees(display_name),business_reviews(rating,comment)').eq('customer_id',userId).order('starts_at',ascending:false).limit(100)),builder:(c,s){
   if(s.connectionState!=ConnectionState.done)return const Loading();
   if(s.hasError)return Text(errorText(s.error!));
   final rows=s.data??[];
   if(rows.isEmpty)return cardBox(const Text('Henüz randevun bulunmuyor.',style:TextStyle(color:muted)));
   return Column(children:rows.map((a){
    final service=(a['services'] as Map?)??{};
    final business=(a['businesses'] as Map?)??{};
    final worker=(a['employees'] as Map?)??{};
    final start=localDate(a['starts_at']);
    final reviews=(a['business_reviews'] as List?)??[];
    final review=reviews.isEmpty?null:reviews.first;
    return cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Row(children:[Expanded(child:Text(service['name']??'Randevu',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16))),statusPill(a['status'])]),
     const SizedBox(height:8),
     Text(business['name']??'',style:const TextStyle(color:gold,fontWeight:FontWeight.w700)),
     const SizedBox(height:5),
     tinyInfo(Icons.calendar_month,'${dateText(start)} • ${timeText(start)}'),
     const SizedBox(height:4),
     tinyInfo(Icons.person_outline,worker['display_name']??'Çalışan'),
     if(a['status']=='confirmed')Wrap(spacing:8,runSpacing:6,children:[
      TextButton.icon(onPressed:()=>reschedule(a),icon:const Icon(Icons.edit_calendar),label:const Text('Saati değiştir')),
      TextButton.icon(onPressed:()async{try{await db.rpc('cancel_appointment',params:{'p_appointment_id':a['id']});invalidateFutureCache('customer_');if(mounted)setState((){});}catch(e){if(mounted)snack(context,errorText(e));}},icon:const Icon(Icons.cancel_outlined),label:const Text('İptal et')),
     ]),
     if(a['status']=='completed'&&review==null)TextButton.icon(onPressed:()=>reviewAppointment(a),icon:const Icon(Icons.star_outline),label:const Text('Berberi değerlendir')),
     if(review!=null)Padding(padding:const EdgeInsets.only(top:8),child:Text('Puanın: ${''.padRight((review['rating'] as num).toInt(),'★')}${review['comment']==null?'':' • ${review['comment']}'}',style:const TextStyle(color:gold,fontSize:12,fontWeight:FontWeight.w700))),
     if(a['status']=='completed'||a['status']=='cancelled'||a['status']=='no_show')Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()=>repeatBooking(a),icon:const Icon(Icons.replay),label:const Text('Tekrar randevu al'))),
    ]));
   }).toList());
  }),
 ]);
 Widget profile(bool connected)=>FutureBuilder<Map<String,dynamic>?>(future:cached('customer_profile_$userId',()=>db.from('profiles').select().eq('id',userId).maybeSingle()),builder:(c,s){
  if(s.connectionState!=ConnectionState.done)return const Loading();
  final p=s.data??{};
  if(fullName.text.isEmpty)fullName.text=p['full_name']??'';
  if(phone.text.isEmpty)phone.text=p['phone']??'';
  return ListView(padding:const EdgeInsets.all(16),children:[
   titleBlock('Profilim','Hesap bilgilerin ve berber bağlantın'),
   cardBox(Column(children:[
    const CircleAvatar(radius:28,backgroundColor:panel2,child:Icon(Icons.person_outline,color:gold,size:28)),
    const SizedBox(height:12),
    TextField(controller:fullName,decoration:const InputDecoration(labelText:'Ad soyad')),
    const SizedBox(height:10),
    TextField(controller:phone,decoration:const InputDecoration(labelText:'Telefon')),
    const SizedBox(height:12),
    ElevatedButton(onPressed:()async{
     try { await db.from('profiles').update({'full_name':fullName.text.trim(),'phone':phone.text.trim()}).eq('id',userId);invalidateFutureCache('customer_profile_'); if(mounted)snack(context,'Profilin güncellendi'); }
     catch(e) { if(mounted)snack(context,errorText(e)); }
    },child:const Text('Bilgilerimi kaydet')),
   ])),
   if(connected)cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('İşletme bağlantısı',style:TextStyle(fontWeight:FontWeight.w800)),
    const SizedBox(height:5),
    const Text('Berberinden ayrılırsan yeni işletme kodu girebilirsin. Geçmiş randevuların korunur.',style:TextStyle(color:muted,fontSize:12)),
    const SizedBox(height:10),
    OutlinedButton.icon(onPressed:leave,icon:const Icon(Icons.link_off),label:const Text('Berberimden ayrıl')),
   ])),
   OutlinedButton.icon(onPressed:()=>db.auth.signOut(),icon:const Icon(Icons.logout),label:const Text('Çıkış yap')),
  ]);
 });
 @override Widget build(BuildContext c)=>FutureBuilder<List<Map<String,dynamic>>>(future:membership(),builder:(c,m){if(m.connectionState!=ConnectionState.done)return const Loading();if(m.hasError)return Fail(errorText(m.error!));final rows=m.data??[];final b=rows.isEmpty?null:rows.first['businesses'] as Map<String,dynamic>?;return Scaffold(appBar:AppBar(title:const Text('Berberim'),actions:[notifications(c),IconButton(onPressed:(){invalidateFutureCache('customer_');setState((){});},icon:const Icon(Icons.refresh))]),body:tab==0?home(b):tab==1?appointments():profile(b!=null),bottomNavigationBar:NavigationBar(animationDuration:Duration.zero,selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),label:'Ana Sayfa'),NavigationDestination(icon:Icon(Icons.calendar_month_outlined),label:'Randevularım'),NavigationDestination(icon:Icon(Icons.person_outline),label:'Profilim')]));});
}

class AdminPage extends StatefulWidget{const AdminPage({super.key});@override State<AdminPage> createState()=>_AdminPageState();}
class _AdminPageState extends State<AdminPage>{
 int tab=0;Future<List<Map<String,dynamic>>> load(String t)=>cached('admin_$t',()=>db.from(t).select().order('created_at',ascending:false));
 Future<void> review(String id,String status)async{try{await db.rpc('review_business',params:{'p_business_id':id,'p_status':status});invalidateFutureCache('admin_');setState((){});}catch(e){snack(context,errorText(e));}}
 Future<void> block(String id,bool v)async{try{await db.rpc('admin_set_user_blocked',params:{'p_user_id':id,'p_blocked':v});invalidateFutureCache('admin_');setState((){});}catch(e){snack(context,errorText(e));}}
 @override Widget build(BuildContext c){final pages=[
  FutureBuilder<List<dynamic>>(future:Future.wait([load('profiles'),load('businesses'),load('appointments')]),builder:(c,s){if(!s.hasData)return const Loading();if(s.hasError)return Fail(errorText(s.error!));final p=s.data![0],b=s.data![1],a=s.data![2];return ListView(padding:const EdgeInsets.all(16),children:[titleBlock('Genel bakış','Yönetim merkezi'),Row(children:[Expanded(child:cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${p.length}',style:const TextStyle(fontSize:27,fontWeight:FontWeight.w900)),const Text('Kullanıcı',style:TextStyle(color:muted))]))),const SizedBox(width:8),Expanded(child:cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${b.length}',style:const TextStyle(fontSize:27,fontWeight:FontWeight.w900)),const Text('İşletme',style:TextStyle(color:muted))])))]),cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${a.length}',style:const TextStyle(fontSize:27,fontWeight:FontWeight.w900)),const Text('Randevu',style:TextStyle(color:muted))]))]);}),
  FutureBuilder<List<Map<String,dynamic>>>(future:load('businesses'),builder:(c,s){if(!s.hasData)return const Loading();return ListView(padding:const EdgeInsets.all(16),children:[titleBlock('İşletmeler','Başvuruları ve durumları yönet'),...(s.data??[]).map((b)=>cardBox(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(b['name']??'İsimsiz',style:const TextStyle(fontWeight:FontWeight.w800)),Text('${b['status']} • ${b['join_code']??'—'}',style:const TextStyle(color:muted)),Wrap(children:[TextButton(onPressed:()=>review(b['id'],'active'),child:const Text('Onayla')),TextButton(onPressed:()=>review(b['id'],'rejected'),child:const Text('Reddet')),TextButton(onPressed:()=>review(b['id'],'inactive'),child:const Text('Pasife al'))])])))]);}),
  FutureBuilder<List<Map<String,dynamic>>>(future:load('profiles'),builder:(c,s){if(!s.hasData)return const Loading();return ListView(padding:const EdgeInsets.all(16),children:[titleBlock('Kullanıcılar','Hesap ve erişim yönetimi'),...(s.data??[]).map((p)=>cardBox(SwitchListTile(value:p['is_blocked']==true,title:Text(p['full_name']??'İsimsiz'),subtitle:Text('${p['email']??''} • ${p['account_type']}'),onChanged:(v)=>block(p['id'],v))))]);}),
  FutureBuilder<List<Map<String,dynamic>>>(future:cached('admin_appointments',()=>db.from('appointments').select('*,businesses(name),services(name)').order('starts_at',ascending:false).limit(250)),builder:(c,s){if(!s.hasData)return const Loading();return ListView(padding:const EdgeInsets.all(16),children:[titleBlock('Randevular','Son 250 randevu'),...(s.data??[]).map((a)=>cardBox(ListTile(title:Text(a['services']?['name']??'Randevu'),subtitle:Text('${a['businesses']?['name']??''} • ${a['starts_at']} • ${statusName(a['status'])}'))))]);})
 ];return Scaffold(appBar:AppBar(title:const Text('Yönetim merkezi'),actions:[IconButton(onPressed:(){invalidateFutureCache('admin_');setState((){});},icon:const Icon(Icons.refresh)),logout()]),body:pages[tab],bottomNavigationBar:NavigationBar(animationDuration:Duration.zero,selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const [NavigationDestination(icon:Icon(Icons.dashboard_outlined),label:'Genel'),NavigationDestination(icon:Icon(Icons.storefront_outlined),label:'İşletmeler'),NavigationDestination(icon:Icon(Icons.people_outline),label:'Kullanıcılar'),NavigationDestination(icon:Icon(Icons.calendar_month_outlined),label:'Randevular')]));}
}
class NotificationsPage extends StatefulWidget{const NotificationsPage({super.key});@override State<NotificationsPage> createState()=>_NotificationsPageState();}
class _NotificationsPageState extends State<NotificationsPage>{@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Bildirimler')),body:FutureBuilder<List<Map<String,dynamic>>>(future:cached('notifications_$userId',()=>db.from('notifications').select().eq('user_id',userId).order('created_at',ascending:false).limit(100)),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const Loading();if(s.hasError)return Fail(errorText(s.error!));final rows=s.data??[];if(rows.isEmpty)return const Center(child:Text('Henüz bildirimin yok.',style:TextStyle(color:muted)));return ListView(children:rows.map((n)=>ListTile(leading:Icon(n['read_at']==null?Icons.notifications_active:Icons.notifications_none,color:gold),title:Text(n['title']),subtitle:Text('${n['body']}\\n${n['created_at']}'),isThreeLine:true,onTap:()async{if(n['read_at']==null){await db.from('notifications').update({'read_at':DateTime.now().toUtc().toIso8601String()}).eq('id',n['id']);invalidateFutureCache('notifications_');setState((){});}})).toList());}));}
