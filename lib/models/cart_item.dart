class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String image;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.image = '',
  });

  double get totalPrice => price * quantity;
}