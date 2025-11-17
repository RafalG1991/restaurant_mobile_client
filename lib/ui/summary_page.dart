import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/order_provider.dart';

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
    if (p.orderId == null && p.tableNumber == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      // dopasuj do swojego backendu: byId = true jeśli masz endpoint po orderId
      final res = await p._api.showOrder(p.orderId ?? p.tableNumber!, byId: p.orderId != null);
      setState(() { _orderDetails = res; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Your order')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _orderDetails == null
                  ? const Center(child: Text('No order'))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Order #${_orderDetails!['orderId'] ?? '-'} — table ${p.tableNumber ?? '-'}',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              itemCount: (_orderDetails!['order'] as List?)?.length ?? 0,
                              itemBuilder: (_, i) {
                                final it = (_orderDetails!['order'] as List)[i] as Map<String, dynamic>;
                                final name = it['drink_name'] ?? it['name'] ?? 'Item';
                                final qty = it['quantity'] ?? 1;
                                final price = (it['price'] as num?)?.toDouble() ?? 0.0;
                                return ListTile(
                                  title: Text(name),
                                  trailing: Text('$qty × ${price.toStringAsFixed(2)} zł'),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back to menu'),
                          ),
                        ],
                      ),
                    ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: OutlinedButton.icon(
            onPressed: () {
              p.clearSession();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Leave table / new scan'),
          ),
        ),
      ),
    );
  }
}
