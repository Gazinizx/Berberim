import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BerberimApp());
}

const ink = Color(0xFF171717);
const panel = Color(0xFF232323);
const gold = Color(0xFFF2B84B);

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
          colorScheme: ColorScheme.fromSeed(
            seedColor: gold,
            brightness: Brightness.dark,
          ),
          cardTheme: CardThemeData(color: panel),
        ),
        home: const StartPage(),
      );
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.content_cut, color: ink, size: 34),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Berberim',
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Randevunu kolayca oluştur.',
                      style: TextStyle(color: Colors.white70, fontSize: 17),
                    ),
                    const SizedBox(height: 28),
                    const _FeatureRow(
                      icon: Icons.storefront_outlined,
                      title: 'İşletmeye özel erişim kodu',
                    ),
                    const _FeatureRow(
                      icon: Icons.event_available_outlined,
                      title: 'Çakışmayı engelleyen randevu sistemi',
                    ),
                    const _FeatureRow(
                      icon: Icons.notifications_active_outlined,
                      title: 'Randevu ve iptal bildirimleri',
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Yeni proje iskeleti. Firebase bağlantısı ve güvenlik kuralları '
                      'yapılandırılmadan hesap veya randevu işlemleri etkinleştirilmez.',
                      style: TextStyle(color: Colors.white54, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Icon(icon, color: gold),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
          ],
        ),
      );
}
