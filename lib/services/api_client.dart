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

  Future<void> sendSignal(int tableNumber, String type) async {
    final r = await http.post(
      Uri.parse('${AppConfig.apiBase}/order/client/signal'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tableNumber': tableNumber,
        'type': type, // "WAITER" | "CUTLERY" | "CLEANING"
      }),
    );
    if (r.statusCode >= 400) {
      throw Exception('Signal failed: ${r.statusCode} ${r.body}');
    }
  }

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

    if (r.statusCode == 409) {
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    if (data['error'] == 'too many guests') {
      throw Exception(
        'Za dużo gości na ten stolik (max ${data['max_capacity']}).',
      );
    }
    }

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
        'id': tableNumber,     
        'choice': drinkId,     
        'quantity': quantity, 
      }),
    );

    if (r.statusCode >= 400) {
      throw Exception('Dodawanie pozycji nie powiodło się: ${r.statusCode} ${r.body}');
    }

    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final added = body['added'] as String?;

    if (added == null) {
      throw Exception('Nieprawidłowa odpowiedź serwera (brak pola "added").');
    }

    if (added != 'ok') {
      if (added.startsWith('error: ingredient') && added.contains('insufficient')) {
        String niceMessage =
            'Nie można zrealizować zamówienia – za mało składników. Zmodyfikuj zamówienie lub zapytaj obsługę.';

        try {
          final afterKeyword = added.split('ingredient').last.trim();
          final ingredientName = afterKeyword.replaceAll('insufficient', '').trim();
          if (ingredientName.isNotEmpty) {
            niceMessage =
                'Nie można zrealizować zamówienia – za mało składników dla drinków z: $ingredientName. '
                'Zmień zamówienie lub zapytaj obsługę.';
          }
        } catch (_) {
        }

        throw Exception(niceMessage);
      }
      throw Exception(added);
    }
  }
}

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
    return null;
  }
  if (r.statusCode >= 400) {
    throw Exception('Status check failed: ${r.statusCode}');
  }

  final body = jsonDecode(r.body) as Map<String, dynamic>;
  if (body['hasOrder'] != true) return null;
  return body['status']?.toString(); 
}
}
