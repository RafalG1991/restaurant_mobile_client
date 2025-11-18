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
  Map<String, dynamic>? _data;
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
        _data = res;
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

    final orders = (_data?['order'] as List?) ?? const [];
    final hasOrder = orders.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Stolik ${p.tableNumber ?? "-"}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Błąd: $_error'))
              : !hasOrder
                  ? const Center(
                      child: Text(
                        'Brak otwartego zamówienia dla tego stolika.',
                        style: TextStyle(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildOrderCard(orders.first as Map<String, dynamic>),
                    ),
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['order_id'];
    final tableNumber = order['table_number'];
    final customers = order['customers_number'];
    final itemsStr = (order['items'] ?? '') as String;
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;

    // rozbij string "Gin Tonic x2, Mojito x1" na listę
    final List<String> itemsList = itemsStr.isEmpty
        ? []
        : itemsStr.split(',').map((s) => s.trim()).toList();

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Zamówienie #$orderId',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stolik: $tableNumber   •   Gości: $customers',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pozycje:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (itemsList.isEmpty)
              const Text(
                'Brak pozycji w zamówieniu.',
                style: TextStyle(color: AppColors.textMuted),
              )
            else
              ...itemsList.map(
                (line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '• $line',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Razem: ${total.toStringAsFixed(2)} zł',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
