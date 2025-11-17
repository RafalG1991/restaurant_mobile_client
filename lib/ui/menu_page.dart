import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/order_provider.dart';
import '../models/menu_item.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  void initState() {
    super.initState();
    final order = context.read<OrderProvider>();
    if (order.menu.isEmpty) {
      order.loadMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Menu — table ${order.tableNumber ?? "-"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.pushNamed(context, '/summary'),
          ),
        ],
      ),
      body: order.loading && order.menu.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : order.error != null
              ? Center(child: Text('Error: ${order.error}'))
              : ListView.separated(
                  itemCount: order.menu.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final MenuItem m = order.menu[i];
                    return ListTile(
                      title: Text(m.name),
                      subtitle: Text(m.description ?? ''),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${m.price.toStringAsFixed(2)} zł'),
                          const SizedBox(height: 6),
                          OutlinedButton(
                            onPressed: () => order.addToBasket(m),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: _BasketBar(),
    );
  }
}

class _BasketBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();
    final total = order.basketTotal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
      ),
      child: Row(
        children: [
          Expanded(child: Text('Basket: ${order.basket.length} items — ${total.toStringAsFixed(2)} zł')),
          FilledButton.icon(
            onPressed: order.basket.isEmpty
                ? null
                : () async {
                    try {
                      await order.submitBasket();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Items sent to the order!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
            icon: const Icon(Icons.send),
            label: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
