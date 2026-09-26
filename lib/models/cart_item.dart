class CartItem {
  final int id;
  final int productId;
  final String productName;
  final double productPrice;
  final int productStock;
  final String? productImage;
  final int quantity;
  final String? selectedColor;
  final double totalPrice;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productStock,
    required this.productImage,
    required this.quantity,
    required this.selectedColor,
    required this.totalPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      productId: json['product'] as int,
      productName: json['product_name']?.toString() ?? '',
      productPrice: _parsePrice(json['product_price']),
      productStock: json['product_stock'] as int? ?? 0,
      productImage: json['product_image']?.toString(),
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
