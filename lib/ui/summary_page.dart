import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/order_provider.dart';
import '../theme.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  Map<String, dynamic>? _orderDetails;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = context.read<OrderProvider>();

    if (p.tableNumber == null) {
      setState(() {
        _error = 'Brak przypisanego stolika.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await p.fetchOrderDetails();
      setState(() {
        _orderDetails = res;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Stolik ${p.tableNumber ?? "-"}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Błąd: $_error'))
              : _orderDetails == null
                  ? const Center(child: Text('Brak danych zamówienia'))
                  : _buildContent(context, p),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Wróć do menu'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  p.clearSession();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Opuść stolik / Nowy skan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, OrderProvider p) {
    final items = (_orderDetails!['order'] as List?) ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Stan zamówienia:',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Brak pozycji w zamówieniu.'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final it = items[i] as Map<String, dynamic>;

                      final name = (it['drink_name'] ??
                              it['name'] ??
                              it['choice'] ??
                              'Pozycja')
                          .toString();

                      final qtyRaw =
                          it['quantity'] ?? it['qty'] ?? it['amount'] ?? 1;
                      final qty = (qtyRaw as num).toInt();

                      final priceRaw =
                          it['price'] ?? it['drink_price'] ?? it['unit_price'] ?? 0;
                      final price = (priceRaw as num).toDouble();

                      return ListTile(
                        title: Text(
                          name,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          'x$qty',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        trailing: Text(
                          '${price.toStringAsFixed(2)} zł',
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
