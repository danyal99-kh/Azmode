import 'package:uuid/uuid.dart';

const uuid = Uuid();

class ProductCategory {
  final String id;
  final String name;

  ProductCategory({String? id, required this.name}) : id = id ?? uuid.v4();
}

class Product {
  final String id;
  final String name;
  final String categoryId;
  final double price;
  final String description;
  final String imageUrl;

  // Optional fields
  final String? color;
  final String? size;
  final String? brand;
  final String? sku;
  final String? specifications;

  // Inventory
  int stock;

  Product({
    String? id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.color,
    this.size,
    this.brand,
    this.sku,
    this.specifications,
    this.stock = 0,
  }) : id = id ?? uuid.v4();

  bool get isAvailable => stock > 0;
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

enum OrderStatus { pending, approved, rejected }

class Order {
  final String id;
  final List<CartItem> items;
  final DateTime date;
  OrderStatus status;

  Order({
    String? id,
    required this.items,
    required this.date,
    this.status = OrderStatus.pending,
  }) : id = id ?? uuid.v4();

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);
}

class StockMovement {
  final String id;
  final String productId;
  final int quantityChange; // positive for addition, negative for deduction
  final DateTime date;
  final String reason;

  StockMovement({
    String? id,
    required this.productId,
    required this.quantityChange,
    required this.date,
    required this.reason,
  }) : id = id ?? uuid.v4();
}
