// lib/ui/menu_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/order_provider.dart';
import '../models/menu_item.dart';
import '../theme.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  Timer? _timer;

@override
void initState() {
  super.initState();
  final order = context.read<OrderProvider>();
  if (order.menu.isEmpty) {
    order.loadMenu();
  }

  _timer = Timer.periodic(const Duration(seconds: 5), (t) async {
    if (!mounted) {
      t.cancel();
      return;
    }
    final p = context.read<OrderProvider>();

    if (p.orderStatus == 'OPEN' || p.orderStatus == 'REJECTED') {
      t.cancel();
      return;
    }

    await p.refreshOrderStatus();
  });
}

@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();

    final isPending = order.orderStatus != null && order.orderStatus != 'OPEN';
    final isRejected = order.orderStatus == 'REJECTED';

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
      body: Column(
        children: [
          if (isRejected)
            Container(
              width: double.infinity,
              color: Colors.red.withOpacity(0.2),
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Zamówienie zostało odrzucone przez obsługę. Skontaktuj się z kelnerem.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent),
              ),
            )
          else if (isPending)
            Container(
              width: double.infinity,
              color: Colors.orange.withOpacity(0.2),
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Twoje zamówienie czeka na potwierdzenie przez obsługę...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange),
              ),
            ),
          Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    if (!isPending)
    OutlinedButton.icon(
      onPressed: () async {
        try {
          await order.callHelp('WAITER');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kelner został powiadomiony')),
            );
          }
        } catch (_) {}
      },
      icon: const Icon(Icons.notifications),
      label: const Text('Kelner'),
    ),
    if (!isPending)
    OutlinedButton.icon(
      onPressed: () async {
        try {
          await order.callHelp('CUTLERY');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Poproszono o sztućce')),
            );
          }
        } catch (_) {}
      },
      icon: const Icon(Icons.restaurant),
      label: const Text('Sztućce'),
    ),
    if (!isPending)
    OutlinedButton.icon(
      onPressed: () async {
        try {
          await order.callHelp('CLEANING');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Poproszono o sprzątanie')),
            );
          }
        } catch (_) {}
      },
      icon: const Icon(Icons.cleaning_services),
      label: const Text('Sprzątanie'),
    ),
  ],
),
          Expanded(
            child: order.loading && order.menu.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : order.error != null && order.menu.isEmpty
                    ? Center(child: Text('Error: ${order.error}'))
                    : ListView.separated(
                        itemCount: order.menu.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final MenuItem m = order.menu[i];
                          return ListTile(
                            tileColor: AppColors.surface,
                            title: Text(
                              m.name,
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                            subtitle: m.description != null && m.description!.isNotEmpty
                                ? Text(
                                    m.description!,
                                    style: const TextStyle(color: AppColors.textMuted),
                                  )
                                : null,
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min, // KLUCZOWE
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${m.price.toStringAsFixed(2)} zł',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: (isRejected || isPending)
                                      ? null
                                      : () => order.addToBasket(m),
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _BasketBar(
        isPending: isPending,
        isRejected: isRejected,
      ),
    );
  }
}

class _BasketBar extends StatelessWidget {
  final bool isPending;
  final bool isRejected;

  const _BasketBar({
    required this.isPending,
    required this.isRejected,
  });

  void _showBasketDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Consumer<OrderProvider>(
          builder: (_, order, __) {
            final total = order.basketTotal;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const Text(
                    'Twój koszyk',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (order.basket.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Koszyk jest pusty.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: order.basket.length,
                        itemBuilder: (_, i) {
                          final item = order.basket[i];
                          return ListTile(
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${item.price.toStringAsFixed(2)} zł',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                            leading: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.redAccent,
                              onPressed: (isPending || isRejected)
                                  ? null
                                  : () => order.removeFromBasket(item),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: (isPending || isRejected)
                                      ? null
                                      : () => order.changeQty(item, -1),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: (isPending || isRejected)
                                      ? null
                                      : () => order.changeQty(item, 1),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Razem: ${total.toStringAsFixed(2)} zł',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();
    final total = order.basketTotal;

    final canSend =
        !isPending && !isRejected && order.basket.isNotEmpty;

    String statusText;
    if (isRejected) {
      statusText = 'Zamówienie odrzucone';
    } else if (isPending) {
      statusText = 'Czeka na potwierdzenie';
    } else {
      statusText = 'Gotowe do wysłania';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showBasketDetails(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Basket: ${order.basket.length} items — ${total.toStringAsFixed(2)} zł',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isRejected
                            ? Colors.redAccent
                            : (isPending
                                ? Colors.orange
                                : AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
  onPressed: canSend
      ? () async {
          try {
            await order.submitBasket();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pozycje zostały dodane do zamówienia.'),
                ),
              );
            }
          } catch (e) {
            if (!context.mounted) return;

            final msg = e.toString();
            String friendly = msg;
            if (msg.contains('za mało składników') ||
                msg.contains('Nie można zrealizować zamówienia')) {
              friendly = msg; 
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(friendly)),
            );
          }
        }
      : null,
  icon: const Icon(Icons.send),
  label: const Text('Send'),
),
          ],
        ),
      ),
    );
  }
}