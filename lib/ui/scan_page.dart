import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../state/order_provider.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Scan table QR')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) async {
                if (_handled) return;
                final barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;
                final raw = barcodes.first.rawValue;
                if (raw == null) return;

                _handled = true;
                try {
                  await order.attachTableFromQr(raw);
                  await order.ensureOrderOpened(customersNumber: 1);
                  if (mounted) Navigator.pushReplacementNamed(context, '/menu');
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                  _handled = false;
                }
              },
            ),
          ),
          if (order.tableNumber != null && order.orderId != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_bag),
                label: Text('Go to menu (table ${order.tableNumber})'),
                onPressed: () => Navigator.pushReplacementNamed(context, '/menu'),
              ),
            ),
        ],
      ),
    );
  }
}
