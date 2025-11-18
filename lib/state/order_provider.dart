import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../services/api_client.dart';

class OrderProvider extends ChangeNotifier {
  final _api = ApiClient();

  int? tableNumber;
  int? orderId;
  String? orderStatus; // 'OPEN', 'PENDING', 'REJECTED', ...
  List<MenuItem> menu = [];
  final List<BasketItem> basket = [];

  bool loading = false;
  String? error;

  Future<void> hydrate() async {
    final sp = await SharedPreferences.getInstance();
    tableNumber = sp.getInt('tableNumber');
    orderId = sp.getInt('orderId');
    notifyListeners();
  }

  Future<void> persist() async {
    final sp = await SharedPreferences.getInstance();
    if (tableNumber != null) sp.setInt('tableNumber', tableNumber!);
    if (orderId != null) sp.setInt('orderId', orderId!);
  }

  void clearSession() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('tableNumber');
    await sp.remove('orderId');
    tableNumber = null;
    orderId = null;
    basket.clear();
    notifyListeners();
  }

  Future<void> attachTableFromQr(String payload) async {
    // akceptuj czyste "5" albo JSON {"tableNumber":5}
    int parsed;
    try {
      parsed = int.parse(payload.trim());
    } catch (_) {
      try {
        final m = jsonDecode(payload) as Map<String, dynamic>;
        parsed = (m['tableNumber'] as num).toInt();
      } catch (e) {
        throw Exception('QR invalid: $payload');
      }
    }
    tableNumber = parsed;
    await persist();
    notifyListeners();
  }

  Future<void> ensureOrderOpened({int customersNumber = 1}) async {
  if (tableNumber == null) {
    throw Exception('No tableNumber');
  }

  loading = true;
  error = null;
  notifyListeners();

  try {
    final res = await _api.openOrder(tableNumber!, customersNumber: customersNumber);

    if (!res.ok) {
      error = res.error;
      orderStatus = null;
      orderId = null;
    } else {
      orderId = res.orderId;         // możesz nawet go nie używać, ale niech będzie
      orderStatus = res.status;      // najczęściej 'PENDING'
    }

    await persist();
  } catch (e) {
    error = e.toString();
  } finally {
    loading = false;
    notifyListeners();
  }
}

  Future<void> loadMenu() async {
    loading = true; error = null; notifyListeners();
    try {
      menu = await _api.getMenu();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  void addToBasket(MenuItem item, {int qty = 1}) {
    final index = basket.indexWhere((b) => b.id == item.id);
    if (index >= 0) {
      basket[index].quantity += qty;
    } else {
      basket.add(BasketItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: qty,
      ));
    }
    notifyListeners();
  }

  void changeQty(BasketItem item, int delta) {
  item.quantity += delta;
  if (item.quantity <= 0) {
    basket.remove(item);
  }
  notifyListeners();
}

void removeFromBasket(BasketItem item) {
  basket.remove(item);
  notifyListeners();
}

  double get basketTotal => basket.fold(0.0, (p, e) => p + e.price * e.quantity);

  Future<void> submitBasket() async {
    if (tableNumber == null) {
      throw Exception('No tableNumber');
    }
    if (basket.isEmpty) return;

    // 1. upewnij się, że status jest aktualny
    await refreshOrderStatus();

    if (orderStatus != 'OPEN') {
      throw Exception('Order not confirmed by staff yet.');
    }

    final items = basket.map((e) => {
      'id': e.id,
      'quantity': e.quantity,
    }).toList();

    loading = true;
    error = null;
    notifyListeners();

    try {
      await _api.addItems(
        tableNumber: tableNumber!,
        items: items,
      );
      basket.clear();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> fetchOrderDetails() async {
    if (tableNumber == null) {
      throw Exception('No tableNumber');
    }
    return await _api.showOrderByTable(tableNumber!);
    }

  Future<void> refreshOrderStatus() async {
    if (tableNumber == null) return;

    try {
      final status = await _api.getClientOrderStatus(tableNumber!);
      orderStatus = status;  // może być null (brak zamówienia)
      notifyListeners();
    } catch (e) {
      // można np. zapisać error, ale nie blokuj na siłę
      error = e.toString();
      notifyListeners();
    }
  }

}
