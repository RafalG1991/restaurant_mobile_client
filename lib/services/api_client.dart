import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/menu_item.dart';

class OpenOrderResult {
  final bool ok;
  final int? orderId;
  final String? status;
  final String? error;

  OpenOrderResult({
    required this.ok,
    this.orderId,
    this.status,
    this.error,
  });
}

class ApiClient {
  final _base = AppConfig.apiBase;

   Future<OpenOrderResult> openOrder(int tableNumber, {int customersNumber = 1}) async {
    final r = await http.post(
      Uri.parse('$_base/order/client/open'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tableNumber': tableNumber,
        'customersNumber': customersNumber,
      }),
    );

    final body = r.body.isNotEmpty
        ? jsonDecode(r.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (r.statusCode >= 400) {
      return OpenOrderResult(
        ok: false,
        error: body['error']?.toString() ?? 'Open order failed (${r.statusCode})',
      );
    }

    final idRaw = body['order_id'] ?? body['orderId'];
    return OpenOrderResult(
      ok: true,
      orderId: idRaw == null ? null : (idRaw as num).toInt(),
      status: body['status']?.toString() ?? 'PENDING',
    );
  }

  Future<List<MenuItem>> getMenu() async {
    final r = await http.get(Uri.parse('$_base/order/menu'));
    if (r.statusCode >= 400) throw Exception('Menu fetch failed: ${r.statusCode}');
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (body['menu'] as List).map((e) => MenuItem.fromJson(e)).toList();
    return list;
  }

  /// DOSTOSOWANE DO TWOJEGO BACKENDU:
  /// POST /order/add
  /// body: { id: table_id, choice: drink_id, quantity }
  ///
  /// Zakładam, że id stolika (table_id) == numer stolika (tableNumber).
  Future<void> addItems({
    required int tableNumber,
    required List<Map<String, dynamic>> items,
  }) async {
    for (final item in items) {
      final drinkId = item['id'];
      final quantity = item['quantity'];
      final r = await http.post(
        Uri.parse('$_base/order/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': tableNumber,     // u Ciebie backend: id -> table_id
          'choice': drinkId,     // id drinka
          'quantity': quantity,  // ilość
        }),
      );
      if (r.statusCode >= 400) {
        throw Exception('Add item failed: ${r.statusCode} ${r.body}');
      }
      final body = jsonDecode(r.body);
      if (body['added'] != 'ok') {
        throw Exception('Add item error: ${body['error'] ?? body}');
      }
    }
  }

  /// DOSTOSOWANE DO BACKENDU:
  /// GET /order/show/<tableNumber>
  Future<Map<String, dynamic>> showOrderByTable(int tableNumber) async {
  final r = await http.get(Uri.parse('$_base/order/show/$tableNumber'));
  if (r.statusCode >= 400) {
    throw Exception('Show order failed: ${r.statusCode}');
  }
  return jsonDecode(r.body) as Map<String, dynamic>;
}

  Future<String?> getClientOrderStatus(int tableNumber) async {
  final r = await http.get(
    Uri.parse('$_base/order/client/status/$tableNumber'),
  );

  if (r.statusCode == 404) {
    return null; // brak zamówienia
  }
  if (r.statusCode >= 400) {
    throw Exception('Status check failed: ${r.statusCode}');
  }

  final body = jsonDecode(r.body) as Map<String, dynamic>;
  if (body['hasOrder'] != true) return null;
  return body['status']?.toString(); // 'OPEN' / 'PENDING' / 'REJECTED'
}
}
