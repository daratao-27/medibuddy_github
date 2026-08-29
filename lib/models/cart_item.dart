class CartItem {
  final String name;
  final int quantity;
  final double pricePerUnit;
  final String image;
  final int packSize;

  const CartItem({
    required this.name,
    required this.quantity,
    required this.pricePerUnit,
    required this.image,
    this.packSize = 1,
  });

  double get subtotal => quantity * pricePerUnit;
  int get totalUnits => quantity * packSize;
}
