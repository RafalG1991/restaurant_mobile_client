import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../state/order_provider.dart';
import '../theme.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _showScanner = false;
  bool _handledScan = false;

  Future<void> _handleScanWithGuests(BuildContext context, String raw) async {
    final order = context.read<OrderProvider>();

    // 1. Najpierw przypnij stolik na podstawie QR
    try {
      await order.attachTableFromQr(raw);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd skanowania: $e')),
      );
      _handledScan = false;
      return;
    }

    // 2. Dialog z wyborem liczby gości
    int guests = 1;

    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int temp = 1;
        return AlertDialog(
          title: const Text('Ilu gości przy tym stoliku?'),
          content: StatefulBuilder(
            builder: (_, setState) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: temp > 1
                      ? () => setState(() => temp--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '$temp',
                  style: const TextStyle(fontSize: 20),
                ),
                IconButton(
                  onPressed: temp < 12
                      ? () => setState(() => temp++)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, temp),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    // user kliknął "Anuluj"
    if (selected == null) {
      _handledScan = false;
      return;
    }

    guests = selected;

    // 3. Spróbuj otworzyć zamówienie z tą liczbą gości
    try {
      await order.ensureOrderOpened(customersNumber: guests);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/menu');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd przy otwieraniu zamówienia: $e')),
      );
      _handledScan = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER / BRAND
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.local_bar, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pub Manager',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Złóż zamówienie bez wzywania obsługi',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // KARTA POWITALNA
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      Text(
                        'Jak to działa?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '1. Usiądź przy stoliku.\n'
                        '2. Zeskanuj kod QR stolika.\n'
                        '3. Wybierz drinki i prześlij zamówienie.\n'
                        '4. Obsługa potwierdzi i zrealizuje zamówienie.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // PRZYCISK SKANERA
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text(
                  'Skanuj kod QR stolika',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  setState(() {
                    _showScanner = true;
                    _handledScan = false;
                  });
                },
              ),

              const SizedBox(height: 12),

              // JEŚLI JUŻ ISTNIEJE SESJA DLA STOLIKA
              if (order.tableNumber != null && order.orderId != null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.shopping_bag),
                  label: Text('Wróć do zamówienia (stolik ${order.tableNumber})'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentBlue,
                    side: const BorderSide(color: AppColors.accentBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/menu'),
                ),

              const SizedBox(height: 24),

              // SKANER W RAMCE
              if (_showScanner)
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          onDetect: (capture) async {
                            if (_handledScan) return;
                            final barcodes = capture.barcodes;
                            if (barcodes.isEmpty) return;
                            final raw = barcodes.first.rawValue;
                            if (raw == null) return;

                            _handledScan = true;
                            await _handleScanWithGuests(context, raw);
                          },
                        ),
                        // delikatna ramka na środku
                        Center(
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.9),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Ustaw kod QR stolika w ramce',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      'Gdy klikniesz „Skanuj kod QR stolika”, pojawi się podgląd kamery.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
