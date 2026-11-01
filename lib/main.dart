import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ink = Color(0xFF171717);
const panel = Color(0xFF232323);
const gold = Color(0xFFC79A56);
const muted = Color(0xFF9B9B9B);
const canvas = Color(0xFF111111);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BerberimApp());
}

class BerberimApp extends StatelessWidget {
  const BerberimApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Berberim', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      scaffoldBackgroundColor: canvas, colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
      appBarTheme: const AppBarTheme(backgroundColor: canvas, foregroundColor: Colors.white),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panel,
        labelStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: gold, foregroundColor: ink, minimumSize: const Size.fromHeight(50),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
    home: const Dashboard());
}

class Appointment {
  Appointment({required this.id, required this.name, required this.phone, required this.service,
    required this.date, required this.time, required this.price, this.done = false});
  final String id, name, phone, service, date, time;
  final int price;
  bool done;
  Map<String, dynamic> toJson() => {'id':id,'name':name,'phone':phone,'service':service,
    'date':date,'time':time,'price':price,'done':done};
  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
    id: j['id'] ?? '', name:j['name'] ?? '', phone:j['phone'] ?? '', service:j['service'] ?? 'Saç kesimi',
    date:j['date'] ?? '', time:j['time'] ?? '10:00', price:(j['price'] as num? ?? 0).toInt(), done:j['done'] == true);
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> {
  final List<Appointment> appointments = [];
  final List<String> services = ['Saç kesimi', 'Sakal tıraşı', 'Saç + Sakal', 'Çocuk tıraşı'];
  final Map<String, int> prices = {'Saç kesimi':250,'Sakal tıraşı':150,'Saç + Sakal':350,'Çocuk tıraşı':200};
  int tab = 0;
  bool loading = true;
  String businessName = 'Berberim';
  String ownerName = 'Berber';
  final prefsFuture = SharedPreferences.getInstance();

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await prefsFuture;
    final raw = p.getString('appointments_v1');
    if (raw != null) {
      try { appointments.addAll((jsonDecode(raw) as List).map((e)=>Appointment.fromJson(Map<String,dynamic>.from(e)))); } catch (_) {}
    }
    final sr = p.getStringList('services_v1');
    if (sr != null && sr.isNotEmpty) {
      services..clear()..addAll(sr);
      for (final s in services) { prices.putIfAbsent(s, ()=>200); }
    }
    businessName = p.getString('business_name') ?? 'Berberim';
    ownerName = p.getString('owner_name') ?? 'Berber';
    if (mounted) setState(()=>loading=false);
  }
  Future<void> _save() async {
    final p = await prefsFuture;
    await p.setString('appointments_v1', jsonEncode(appointments.map((e)=>e.toJson()).toList()));
    await p.setStringList('services_v1', services);
    await p.setString('business_name', businessName);
    await p.setString('owner_name', ownerName);
  }
  String get today => _date(DateTime.now());
  String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  List<Appointment> get todays => appointments.where((a)=>a.date==today).toList()..sort((a,b)=>a.time.compareTo(b.time));
  int get revenue => appointments.where((a)=>a.date==today && a.done).fold(0,(n,a)=>n+a.price);
  void _toast(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));

  @override Widget build(BuildContext context) {
    final pages = [_home(), _calendar(), _customers(), _services(), _settings()];
    return Scaffold(
      appBar: AppBar(title: Row(children:[
        Container(width:38,height:38,decoration:BoxDecoration(color:gold,borderRadius:BorderRadius.circular(12)),
          child:const Icon(Icons.content_cut,color:ink,size:22)),
        const SizedBox(width:11), Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(businessName,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:19,color:Colors.white)),
          const Text('RANDEVU YÖNETİMİ',style:TextStyle(fontSize:9,letterSpacing:2,color:gold,fontWeight:FontWeight.w700))
        ])
      ]), actions:[IconButton(tooltip:'Yeni randevu',onPressed:_newAppointment,icon:const Icon(Icons.add_circle_outline,color:gold,size:28)),const SizedBox(width:4)]),
      body: loading ? const Center(child:CircularProgressIndicator(color:gold)) : SafeArea(child:pages[tab]),
      floatingActionButton: tab==0 || tab==1 || tab==2 ? FloatingActionButton(
        onPressed:_newAppointment,backgroundColor:gold,foregroundColor:ink,child:const Icon(Icons.add)) : null,
      bottomNavigationBar: NavigationBar(backgroundColor:panel,indicatorColor:gold.withValues(alpha:.18),
        selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),
        destinations:const [
          NavigationDestination(icon:Icon(Icons.space_dashboard_outlined),selectedIcon:Icon(Icons.space_dashboard),label:'Ana Sayfa'),
          NavigationDestination(icon:Icon(Icons.calendar_month_outlined),selectedIcon:Icon(Icons.calendar_month),label:'Takvim'),
          NavigationDestination(icon:Icon(Icons.people_outline),selectedIcon:Icon(Icons.people),label:'Müşteriler'),
          NavigationDestination(icon:Icon(Icons.content_cut),selectedIcon:Icon(Icons.content_cut),label:'Hizmetler'),
          NavigationDestination(icon:Icon(Icons.tune),selectedIcon:Icon(Icons.tune),label:'Ayarlar'),
        ]),
    );
  }

  Widget _home() => ListView(padding:const EdgeInsets.fromLTRB(18,8,18,100),children:[
    Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(
      gradient:const LinearGradient(colors:[Color(0xFF33302A),Color(0xFF201F1D)],begin:Alignment.topLeft,end:Alignment.bottomRight),
      borderRadius:BorderRadius.circular(22),border:Border.all(color:gold.withValues(alpha:.35))),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('HOŞ GELDİN',style:TextStyle(color:gold,fontSize:11,letterSpacing:2,fontWeight:FontWeight.bold)),
        const SizedBox(height:8),Text(ownerName,style:const TextStyle(fontSize:27,fontWeight:FontWeight.w800)),
        const SizedBox(height:4),Text('Bugün işlerin nasıl gidiyor?',style:TextStyle(color:Colors.white.withValues(alpha:.65))),
        const SizedBox(height:22),Row(children:[
          Expanded(child:_heroMetric('RANDEVU', '${todays.length}', Icons.event_available)),
          Container(width:1,height:46,color:Colors.white24),
          Expanded(child:_heroMetric('TAMAMLANDI','${todays.where((a)=>a.done).length}',Icons.check_circle_outline)),
          Container(width:1,height:46,color:Colors.white24),
          Expanded(child:_heroMetric('KAZANÇ','${revenue}₺',Icons.payments_outlined)),
        ])
      ])),
    const SizedBox(height:24),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      const Text('Bugünkü randevular',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
      TextButton(onPressed:()=>setState(()=>tab=1),child:const Text('Tümünü gör',style:TextStyle(color:gold)))
    ]),
    if(todays.isEmpty) _empty('Bugün için randevu yok','Yeni bir randevu ekleyerek başlayabilirsin.',Icons.event_note)
    else ...todays.map(_appointmentCard),
    const SizedBox(height:18),const Text('Hızlı işlemler',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
    const SizedBox(height:12),Row(children:[
      Expanded(child:_quick('Randevu ekle',Icons.add_circle_outline,_newAppointment)),
      const SizedBox(width:10),Expanded(child:_quick('Hizmetler',Icons.content_cut,()=>setState(()=>tab=3))),
    ])
  ]);

  Widget _heroMetric(String title,String value,IconData icon)=>Padding(padding:const EdgeInsets.symmetric(horizontal:7),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Icon(icon,color:gold,size:19),const SizedBox(height:8),Text(value,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800)),
    const SizedBox(height:3),Text(title,style:const TextStyle(fontSize:9,color:muted,letterSpacing:1,fontWeight:FontWeight.bold))
  ]));
  Widget _quick(String title,IconData icon,VoidCallback action)=>InkWell(onTap:action,borderRadius:BorderRadius.circular(16),child:Container(
    padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16),border:Border.all(color:Colors.white10)),
    child:Row(children:[Icon(icon,color:gold),const SizedBox(width:10),Expanded(child:Text(title,style:const TextStyle(fontWeight:FontWeight.w700)))])));

  Widget _calendar()=>ListView(padding:const EdgeInsets.fromLTRB(18,8,18,100),children:[
    const Text('Randevu takvimi',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800)),
    const SizedBox(height:5),const Text('Kayıtlı tüm randevuların',style:TextStyle(color:muted)),
    const SizedBox(height:18),
    if(appointments.isEmpty)_empty('Henüz randevu yok','Randevu eklediğinde burada görünecek.',Icons.calendar_month)
    else ...([...appointments]..sort((a,b)=>(a.date+a.time).compareTo(b.date+b.time))).map(_appointmentCard)
  ]);

  Widget _customers(){
    final map=<String,Appointment>{};
    for(final a in appointments){map.putIfAbsent(a.phone.isEmpty?a.name:a.phone,()=>a);}
    final customers=map.values.toList()..sort((a,b)=>a.name.compareTo(b.name));
    return ListView(padding:const EdgeInsets.fromLTRB(18,8,18,100),children:[
      const Text('Müşteriler',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800)),
      const SizedBox(height:5),Text('${customers.length} kayıtlı müşteri',style:const TextStyle(color:muted)),
      const SizedBox(height:18),
      if(customers.isEmpty)_empty('Müşteri kaydı yok','İlk randevuyla müşteri listen oluşur.',Icons.people_outline)
      else ...customers.map((a)=>Container(margin:const EdgeInsets.only(bottom:10),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16)),
        child:ListTile(leading:CircleAvatar(backgroundColor:gold.withValues(alpha:.15),child:Text(a.name.isEmpty?'?':a.name[0].toUpperCase(),style:const TextStyle(color:gold,fontWeight:FontWeight.bold))),
          title:Text(a.name,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(a.phone.isEmpty?'Telefon eklenmemiş':a.phone,style:const TextStyle(color:muted)),
          trailing:Text('${appointments.where((x)=>x.phone==a.phone && x.name==a.name).length} randevu',style:const TextStyle(fontSize:11,color:gold)))))
    ]);
  }

  Widget _services()=>ListView(padding:const EdgeInsets.fromLTRB(18,8,18,100),children:[
    const Text('Hizmetler',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800)),
    const SizedBox(height:5),const Text('Hizmetlerini ve ücretlerini yönet',style:TextStyle(color:muted)),
    const SizedBox(height:18),
    ...services.map((s)=>Container(margin:const EdgeInsets.only(bottom:10),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16)),
      child:ListTile(leading:Container(width:42,height:42,decoration:BoxDecoration(color:gold.withValues(alpha:.15),borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.content_cut,color:gold)),
        title:Text(s,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${prices[s]??200} TL',style:const TextStyle(color:gold)),
        trailing:PopupMenuButton<String>(onSelected:(v){if(v=='price')_editPrice(s);if(v=='delete')_deleteService(s);},itemBuilder:(_)=>const [
          PopupMenuItem(value:'price',child:Text('Ücreti düzenle')),PopupMenuItem(value:'delete',child:Text('Hizmeti sil'))])))
    ),
    const SizedBox(height:10),ElevatedButton.icon(onPressed:_addService,icon:const Icon(Icons.add),label:const Text('Yeni hizmet ekle'))
  ]);

  Widget _settings()=>ListView(padding:const EdgeInsets.all(18),children:[
    const Text('Ayarlar',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800)),
    const SizedBox(height:5),const Text('İşletme bilgilerini düzenle',style:TextStyle(color:muted)),
    const SizedBox(height:22),_settingsField('İşletme adı',businessName,(v)=>businessName=v),
    const SizedBox(height:14),_settingsField('Berber adı',ownerName,(v)=>ownerName=v),
    const SizedBox(height:18),ElevatedButton(onPressed:()async{await _save();if(mounted){setState((){});_toast('Ayarlar kaydedildi');}},child:const Text('Değişiklikleri kaydet')),
    const SizedBox(height:24),Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16)),
      child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Icon(Icons.lock_outline,color:gold),SizedBox(width:10),Text('Yerel ve özel',style:TextStyle(fontWeight:FontWeight.w800,fontSize:17))]),
        SizedBox(height:8),Text('Bu sürüm internet bağlantısı kullanmaz. Randevular, hizmetler ve işletme bilgileri yalnızca bu cihazda saklanır.',style:TextStyle(color:muted,height:1.5))
      ])),
    const SizedBox(height:16),OutlinedButton.icon(onPressed:_exportInfo,icon:const Icon(Icons.info_outline),label:const Text('Uygulama bilgisi'))
  ]);

  Widget _settingsField(String label,String initial,ValueChanged<String> onChanged){
    final c=TextEditingController(text:initial);
    return TextField(controller:c,decoration:InputDecoration(labelText:label),onChanged:onChanged);
  }

  Widget _appointmentCard(Appointment a)=>Container(margin:const EdgeInsets.only(bottom:10),decoration:BoxDecoration(
    color:panel,borderRadius:BorderRadius.circular(17),border:Border.all(color:a.done?gold.withValues(alpha:.35):Colors.white10)),
    child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[
      Container(width:4,height:60,decoration:BoxDecoration(color:a.done?gold:Colors.white24,borderRadius:BorderRadius.circular(5))),
      const SizedBox(width:12),Container(width:48,height:48,decoration:BoxDecoration(color:gold.withValues(alpha:.14),borderRadius:BorderRadius.circular(14)),
        child:Center(child:Text(a.time,style:const TextStyle(color:gold,fontWeight:FontWeight.w800,fontSize:12)))),
      const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(a.name,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:15)),
        const SizedBox(height:4),Text('${a.service} • ${a.price} TL',style:const TextStyle(color:muted,fontSize:12)),
        const SizedBox(height:4),Text('${a.date} • ${a.phone}',style:const TextStyle(color:muted,fontSize:11))
      ])),
      PopupMenuButton<String>(onSelected:(v)async{
        if(v=='done'){setState(()=>a.done=!a.done);await _save();}
        if(v=='edit')_editAppointment(a);
        if(v=='delete')_deleteAppointment(a);
      },itemBuilder:(_)=>[
        PopupMenuItem(value:'done',child:Text(a.done?'Tamamlanmadı işaretle':'Tamamlandı işaretle')),
        const PopupMenuItem(value:'edit',child:Text('Düzenle')),
        const PopupMenuItem(value:'delete',child:Text('Sil')),
      ],icon:const Icon(Icons.more_vert,color:muted))
    ])));

  Widget _empty(String title,String subtitle,IconData icon)=>Container(padding:const EdgeInsets.symmetric(vertical:34,horizontal:20),
    decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(18)),
    child:Column(children:[Icon(icon,size:38,color:gold),const SizedBox(height:12),Text(title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:17)),
      const SizedBox(height:6),Text(subtitle,textAlign:TextAlign.center,style:const TextStyle(color:muted))]));

  Future<void> _newAppointment()=>_appointmentForm();
  Future<void> _editAppointment(Appointment a)=>_appointmentForm(existing:a);
  Future<void> _appointmentForm({Appointment? existing}) async {
    final name=TextEditingController(text:existing?.name??'');
    final phone=TextEditingController(text:existing?.phone??'');
    final price=TextEditingController(text:'${existing?.price??prices[services.first]??200}');
    String service=existing?.service??services.first;
    DateTime date=DateTime.tryParse(existing?.date??'')??DateTime.now();
    TimeOfDay time=TimeOfDay(hour:int.tryParse((existing?.time??'10:00').split(':').first)??10,minute:int.tryParse((existing?.time??'10:00').split(':').last)??0);
    final formKey=GlobalKey<FormState>();
    final result=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,backgroundColor:panel,
      shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(26))),
      builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>Padding(
        padding:EdgeInsets.fromLTRB(20,22,20,MediaQuery.of(ctx).viewInsets.bottom+22),
        child:SingleChildScrollView(child:Form(key:formKey,child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(existing==null?'Yeni randevu':'Randevuyu düzenle',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800)),
          const SizedBox(height:18),
          TextFormField(controller:name,decoration:const InputDecoration(labelText:'Müşteri adı soyadı'),validator:(v)=>v==null||v.trim().isEmpty?'Müşteri adı gerekli':null),
          const SizedBox(height:12),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Telefon (isteğe bağlı)')),
          const SizedBox(height:12),DropdownButtonFormField<String>(value:services.contains(service)?service:services.first,decoration:const InputDecoration(labelText:'Hizmet'),
            items:services.map((s)=>DropdownMenuItem(value:s,child:Text(s))).toList(),onChanged:(v){if(v!=null)refresh(()=>service=v);}),
          const SizedBox(height:12),TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Ücret (TL)')),
          const SizedBox(height:12),Row(children:[
            Expanded(child:OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:ctx,firstDate:DateTime(2020),lastDate:DateTime(2100),initialDate:date);if(d!=null)refresh(()=>date=d);},icon:const Icon(Icons.calendar_month),label:Text('${date.day.toString().padLeft(2,'0')}.${date.month.toString().padLeft(2,'0')}.${date.year}'))),
            const SizedBox(width:10),Expanded(child:OutlinedButton.icon(onPressed:()async{final t=await showTimePicker(context:ctx,initialTime:time);if(t!=null)refresh(()=>time=t);},icon:const Icon(Icons.schedule),label:Text(time.format(ctx))))
          ]),
          const SizedBox(height:18),ElevatedButton(onPressed:(){if(formKey.currentState?.validate()??false)Navigator.pop(ctx,true);},child:Text(existing==null?'Randevuyu kaydet':'Değişiklikleri kaydet'))
        ])))));
    if(result!=true)return;
    final parsed=int.tryParse(price.text.trim())??(prices[service]??200);
    setState((){
      if(existing==null){appointments.add(Appointment(id:DateTime.now().microsecondsSinceEpoch.toString(),name:name.text.trim(),phone:phone.text.trim(),service:service,date:_date(date),time:'${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}',price:parsed));}
      else {existing.name=name.text.trim();existing.phone=phone.text.trim();existing.service=service;existing.date=_date(date);existing.time='${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}';}
    });
    await _save();if(mounted)_toast(existing==null?'Randevu kaydedildi':'Randevu güncellendi');
  }

  Future<void> _deleteAppointment(Appointment a) async {
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Randevu silinsin mi?'),content:Text('${a.name} randevusu silinecek.'),actions:[
      TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Vazgeç')),TextButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Sil'))]));
    if(ok==true){setState(()=>appointments.remove(a));await _save();if(mounted)_toast('Randevu silindi');}
  }
  Future<void> _addService() async {
    final c=TextEditingController();final p=TextEditingController(text:'200');
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Yeni hizmet'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:c,decoration:const InputDecoration(labelText:'Hizmet adı')),const SizedBox(height:10),TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Ücret (TL)'))]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('İptal')),TextButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Ekle'))]));
    if(ok==true&&c.text.trim().isNotEmpty){setState(()=>services.add(c.text.trim()));prices[c.text.trim()]=int.tryParse(p.text)??200;await _save();}
  }
  Future<void> _editPrice(String s) async {
    final c=TextEditingController(text:'${prices[s]??200}');
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text('$s ücretini düzenle'),content:TextField(controller:c,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Yeni ücret (TL)')),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('İptal')),TextButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Kaydet'))]));
    if(ok==true){setState(()=>prices[s]=int.tryParse(c.text)??prices[s]??200);await _save();}
  }
  Future<void> _deleteService(String s) async {
    if(appointments.any((a)=>a.service==s)){_toast('Bu hizmete bağlı randevular var; önce randevuları düzenle.');return;}
    setState(()=>services.remove(s));prices.remove(s);await _save();
  }
  Future<void> _exportInfo() async {
    showDialog<void>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Berberim • Yerel sürüm'),content:const Text('Uygulama çevrimdışı çalışır. Veriler bu cihazdaki uygulama alanında saklanır; uygulama kaldırılırsa veriler silinebilir.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Tamam'))]));
  }
}
