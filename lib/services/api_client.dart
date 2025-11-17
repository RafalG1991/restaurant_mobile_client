import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/menu_item.dart';

class ApiClient {
  final _base = AppConfig.apiBase;

  Future<Map<String, dynamic>> getActive(int tableNumber) async {
    final r = await http.get(Uri.parse('$_base/order/active/$tableNumber'));
    if (r.statusCode >= 400) {
      throw Exception('Active check failed: ${r.statusCode}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<int> openOrder(int tableNumber, {int customersNumber = 1}) async {
    final r = await http.post(
      Uri.parse('$_base/order/open'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tableNumber': tableNumber, 'customersNumber': customersNumber}),
    );
    if (r.statusCode >= 400) throw Exception('Open order failed: ${r.statusCode}');
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final id = body['orderId'] ?? body['order_id'];
    if (id == null) throw Exception('No orderId in response');
    return (id as num).toInt();
  }

  Future<List<MenuItem>> getMenu() async {
    final r = await http.get(Uri.parse('$_base/order/menu'));
    if (r.statusCode >= 400) throw Exception('Menu fetch failed: ${r.statusCode}');
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (body['menu'] as List).map((e) => MenuItem.fromJson(e)).toList();
    return list;
  }

  /// Dopasuj payload do swojego backendu jeśli inny
  Future<void> addItems({required int id, required String choice, required int quantity}) async {
    final r = await http.post(
      Uri.parse('$_base/order/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id, 'choice': choice, 'quantity': quantity}),
    );
    if (r.statusCode >= 400) {
      throw Exception('Add items failed: ${r.statusCode} ${r.body}');
    }
  }

  Future<Map<String, dynamic>> showOrder(int orderIdOrTableNumber, {bool byId = true}) async {
    final url = byId ? '$_base/order/show/id/$orderIdOrTableNumber' : '$_base/order/show/$orderIdOrTableNumber';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode >= 400) throw Exception('Show order failed: ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
