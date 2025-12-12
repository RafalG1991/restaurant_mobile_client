import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/order_provider.dart';
import 'ui/scan_page.dart';
import 'ui/menu_page.dart';
import 'ui/summary_page.dart';
import 'theme.dart';  

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
      title: 'Pub Manager – Klient',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 4,
          centerTitle: true,
        ),
        cardColor: AppColors.surface,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
      routes: {
        '/': (_) => const ScanPage(),  
        '/menu': (_) => const MenuPage(),
        '/summary': (_) => const SummaryPage(),
      },
    );
  }
}
