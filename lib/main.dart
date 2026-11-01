import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'config.dart';

void main() => runApp(const BerberimApp());

final client = Client()
  ..setEndpoint(AppConfig.endpoint)
  ..setProject(AppConfig.projectId);
final account = Account(client);
final db = Databases(client);

const ink = Color(0xFF17231F);
const green = Color(0xFF1D7658);
const cream = Color(0xFFF6F5F0);

class BerberimApp extends StatelessWidget {
  const BerberimApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Berberim',
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(seedColor: green, surface: cream),
      appBarTheme: const AppBarTheme(backgroundColor: cream, foregroundColor: ink, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: green, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
    home: const WelcomePage());
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override State<WelcomePage> createState() => _WelcomePageState();
}
class _WelcomePageState extends State<WelcomePage> {
  bool busy = false;
  Future<void> enter(bool barber) async {
    setState(() => busy = true);
    try {
      try { await account.get(); } catch (_) { await account.createAnonymousSession(); }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => barber ? const BarberPage() : const CustomerPage()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bağlantı kurulamadı: $e')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Padding(
    padding: const EdgeInsets.all(26), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [const Spacer(), Container(width: 68,height:68,decoration: BoxDecoration(color: green,borderRadius: BorderRadius.circular(22)),
        child: const Icon(Icons.content_cut,color: Colors.white,size:34)), const SizedBox(height:28),
        const Text('Berberim',style: TextStyle(fontSize:38,fontWeight: FontWeight.w800,color:ink)),
        const SizedBox(height:8), const Text('Randevun cebinde.\nZamanın sana kalsın.',style: TextStyle(fontSize:19,color:Colors.black54,height:1.4)),
        const Spacer(), if (busy) const Center(child:CircularProgressIndicator()) else ...[
          ElevatedButton.icon(onPressed:()=>enter(false),icon:const Icon(Icons.person_outline),label:const Text('Müşteri olarak devam et')),
          const SizedBox(height:12), OutlinedButton.icon(onPressed:()=>enter(true),icon:const Icon(Icons.storefront_outlined),label:const Text('Berber paneli'),style:OutlinedButton.styleFrom(minimumSize:const Size.fromHeight(52),foregroundColor:ink,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)))),
        ], const SizedBox(height:28), const Center(child:Text('BERBERİM • RANDEVU YÖNETİMİ',style:TextStyle(fontSize:10,letterSpacing:2,color:Colors.black38))), const SizedBox(height:12)]))));
}

class BarberPage extends StatefulWidget { const BarberPage({super.key}); @override State<BarberPage> createState()=>_BarberPageState(); }
class _BarberPageState extends State<BarberPage> {
  final name=TextEditingController(), phone=TextEditingController(), address=TextEditingController();
  final service=TextEditingController(text:'Saç kesimi'), price=TextEditingController(text:'250');
  String? barberId; String? inviteCode; bool loading=false; List<models.Document> appointments=[];
  Future<void> saveBarber() async {
    if(name.text.trim().isEmpty) return;
    setState(()=>loading=true);
    try {
      final u=await account.get();
      final code='BRB${u.$id.substring(0,6).toUpperCase()}';
      final d=(await db.createDocument(databaseId:AppConfig.databaseId,collectionId:AppConfig.barbers,
        documentId:ID.unique(),data:{'userId':u.$id,'name':name.text.trim(),'phone':phone.text.trim(),
        'address':address.text.trim(),'inviteCode':code,'isActive':true}));
      barberId=d.$id; inviteCode=code;
      await db.createDocument(databaseId:AppConfig.databaseId,collectionId:AppConfig.services,documentId:ID.unique(),
        data:{'barberId':d.$id,'name':service.text.trim(),'price':double.tryParse(price.text)??0,'durationMinutes':30,'isActive':true});
      if(mounted) setState((){});
    } catch(e){ toast('Kaydedilemedi: $e'); } finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> loadAppointments() async {
    if(barberId==null)return;
    try { final r=await db.listDocuments(databaseId:AppConfig.databaseId,collectionId:AppConfig.appointments,
      queries:[Query.equal('barberId',barberId!),Query.orderAsc('startAt')]); setState(()=>appointments=r.documents.whereType<models.Document>().toList()); }
    catch(e){toast('Randevular alınamadı: $e');}
  }
  void toast(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Berber paneli',style:TextStyle(fontWeight:FontWeight.bold))),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      if(barberId==null) ...[
        const Text('İşletmeni oluştur',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:ink)),
        const SizedBox(height:6),const Text('Bilgilerini gir, müşterilerini davet et.'),
        const SizedBox(height:18), field(name,'Berber / işletme adı'),field(phone,'Telefon',keyboard:TextInputType.phone),
        field(address,'Adres'),const SizedBox(height:18),const Text('İlk hizmetin',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
        const SizedBox(height:10),field(service,'Hizmet adı'),field(price,'Ücret (TL)',keyboard:TextInputType.number),
        const SizedBox(height:18),ElevatedButton(onPressed:loading?null:saveBarber,child:Text(loading?'Kaydediliyor...':'İşletmeyi oluştur')),
      ] else ...[
        const Text('İşletmen hazır',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:ink)),
        const SizedBox(height:12),const Text('Davet kodun'),SelectableText(inviteCode??'',style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:green)),
        const SizedBox(height:8),const Text('Müşterilerin bu kodla işletmene bağlanabilir.'),
        const SizedBox(height:20),ElevatedButton(onPressed:loadAppointments,child:const Text('Randevuları yenile')),
        ...appointments.map((a)=>Card(child:ListTile(leading:const Icon(Icons.event_available,color:green),title:Text(a.data['startAt']?.toString()??'Randevu'),subtitle:Text('Durum: ${a.data['status']??'bekliyor'}'))))
      ]
    ]));
}

class CustomerPage extends StatefulWidget { const CustomerPage({super.key}); @override State<CustomerPage> createState()=>_CustomerPageState(); }
class _CustomerPageState extends State<CustomerPage> {
  final code=TextEditingController(), name=TextEditingController(), phone=TextEditingController();
  List<models.Document> services=[]; String? barberId, barberName, selectedService; DateTime day=DateTime.now().add(const Duration(days:1));
  bool busy=false;
  void toast(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  Future<void> connect() async {
    setState(()=>busy=true);
    try {
      final r=await db.listDocuments(databaseId:AppConfig.databaseId,collectionId:AppConfig.barbers,queries:[Query.equal('inviteCode',code.text.trim()),Query.limit(1)]);
      if(r.documents.isEmpty){toast('Davet kodu bulunamadı');return;}
      final b=r.documents.first; final u=await account.get();
      barberId=b.$id; barberName=b.data['name']?.toString()??'Berberim';
      await db.createDocument(databaseId:AppConfig.databaseId,collectionId:AppConfig.customers,documentId:ID.unique(),
        data:{'userId':u.$id,'barberId':barberId,'name':name.text.trim(),'phone':phone.text.trim()});
      final s=await db.listDocuments(databaseId:AppConfig.databaseId,collectionId:AppConfig.services,
        queries:[Query.equal('barberId',barberId!),Query.equal('isActive',true)]);
      setState(()=>services=s.documents.whereType<models.Document>().toList());
    } catch(e){toast('İşlem tamamlanamadı: $e');} finally{setState(()=>busy=false);}
  }
  Future<void> book() async {
    if(selectedService==null||barberId==null)return;
    final svc=services.firstWhere((x)=>x.$id==selectedService);
    final start=DateTime(day.year,day.month,day.day,10);
    final end=start.add(Duration(minutes:(svc.data['durationMinutes'] as num?)?.toInt()??30));
    setState(()=>busy=true);
    try {
      final u=await account.get();
      final c=await db.listDocuments(databaseId:AppConfig.databaseId,collectionId:AppConfig.customers,
        queries:[Query.equal('userId',u.$id),Query.equal('barberId',barberId!),Query.limit(1)]);
      if(c.documents.isEmpty){toast('Müşteri kaydı bulunamadı');return;}
      await db.createDocument(databaseId:AppConfig.databaseId,collectionId:AppConfig.appointments,documentId:ID.unique(),
        data:{'barberId':barberId,'customerId':c.documents.first.$id,'serviceId':selectedService,
        'startAt':start.toUtc().toIso8601String(),'endAt':end.toUtc().toIso8601String(),'status':'pending','note':''});
      toast('Randevu talebin oluşturuldu');
    } catch(e){toast('Randevu oluşturulamadı: $e');} finally{setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Randevu al',style:TextStyle(fontWeight:FontWeight.bold))),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      if(barberId==null)...[
        const Text('Berberine bağlan',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:ink)),
        const SizedBox(height:8),const Text('Berberinden aldığın davet kodunu gir.'),
        const SizedBox(height:16),field(name,'Adın soyadın'),field(phone,'Telefon',keyboard:TextInputType.phone),field(code,'Davet kodu'),
        ElevatedButton(onPressed:busy?null:connect,child:Text(busy?'Bağlanıyor...':'Berberime bağlan')),
      ]else...[
        Text(barberName??'Berberim',style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:ink)),
        const SizedBox(height:8),const Text('Hizmet seç ve randevu talebini oluştur.'),
        const SizedBox(height:18),DropdownButtonFormField<String>(initialValue:selectedService,decoration:const InputDecoration(labelText:'Hizmet seç'),
          items:services.map((s)=>DropdownMenuItem(value:s.$id,child:Text('${s.data['name']} • ${s.data['price']} TL'))).toList(),onChanged:(v)=>setState(()=>selectedService=v)),
        const SizedBox(height:14),OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:context,firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:90)),initialDate:day);if(d!=null)setState(()=>day=d);},
          icon:const Icon(Icons.calendar_month),label:Text('${day.day.toString().padLeft(2,'0')}.${day.month.toString().padLeft(2,'0')}.${day.year}')),
        const SizedBox(height:12),ElevatedButton(onPressed:busy?null:book,child:Text(busy?'İşleniyor...':'10:00 için randevu talep et')),
        const SizedBox(height:8),const Text('Not: İlk sürümde saat seçimi temel düzeydedir; çalışma saatleri ve uygun saat takvimi sonraki adımda bağlanacaktır.',style:TextStyle(color:Colors.black54,fontSize:12))
      ]
    ]));
}

Widget field(TextEditingController c,String label,{TextInputType? keyboard})=>Padding(padding:const EdgeInsets.only(bottom:12),
  child:TextField(controller:c,keyboardType:keyboard,decoration:InputDecoration(labelText:label)));
