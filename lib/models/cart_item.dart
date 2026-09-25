class CartItem {
  final int id;
  final int productId;
  final int quantity;
  final String? selectedColor;
  final double totalPrice;

  const CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.selectedColor,
    required this.totalPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      productId: json['product'] as int,
      quantity: json['quantity'] as int,
      selectedColor: json['selected_color']?.toString(),
      totalPrice: _parsePrice(json['total_price']),
    );
  }

  static double _parsePrice(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
