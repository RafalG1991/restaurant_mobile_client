import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/order_provider.dart';
import 'ui/scan_page.dart';
import 'ui/menu_page.dart';
import 'ui/summary_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderProvider()..hydrate()),
      ],
      child: const PubClientApp(),
    ),
  );
}

class PubClientApp extends StatelessWidget {
  const PubClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pub Client',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => const ScanPage(),
        '/menu': (_) => const MenuPage(),
        '/summary': (_) => const SummaryPage(),
      },
    );
  }
}
