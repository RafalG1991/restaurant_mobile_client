class MenuItem {
  final int id;
  final String name;
  final double price;
  final String? description;

  MenuItem({required this.id, required this.name, required this.price, this.description});

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['drink_id'] as int,
        name: j['drink_name'] as String,
        price: (j['price'] as num).toDouble(),
        description: j['description'] as String?,
      );
}
