class OrderItem {
  final int id;
  final int orderId;
  final int? productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? selectedColor;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.selectedColor,
  });

  double get totalPrice => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      orderId: json['order'] as int,
      productId: json['product'] as int?,
      productName: json['product_name_snapshot']?.toString() ?? '',
      unitPrice: _parsePrice(json['unit_price_snapshot']),
      quantity: json['quantity'] as int,
      selectedColor: json['selected_color']?.toString(),
    );
  }

  static double _parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

enum OrderStatus { pending, approved, rejected }

class Order {
  final int id;
  final int userId;
  final String customerName;
  final String customerPhone;
  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  double get totalAmount =>
      items.fold(0, (total, item) => total + item.totalPrice);

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      userId: json['user'] as int,
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      status: _parseStatus(json['status']?.toString()),
      createdAt: DateTime.parse(json['created_at'].toString()),
      items: (json['items'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                OrderItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  static OrderStatus _parseStatus(String? value) {
    switch (value) {
      case 'approved':
        return OrderStatus.approved;
      case 'rejected':
        return OrderStatus.rejected;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }
}
