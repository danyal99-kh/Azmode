import 'package:azmode/model.dart';
import 'package:flutter/foundation.dart';

class StoreProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isAdmin = false;
  String? _token;
  User? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;
  String? get token => _token;
  User? get currentUser => _currentUser;

  // لیست کاربران (شامل ادمین پیش‌فرض)
  final List<User> _users = [
    User(id: 'admin', username: 'admin', password: 'admin', isAdmin: true),
  ];

  List<User> get users => List.unmodifiable(_users);

  // ورود
  void login(String username, String password) {
    // پیدا کردن کاربر با نام کاربری
    final user = _users.firstWhere(
      (u) => u.username == username,
      orElse: () => throw Exception('کاربری با این نام پیدا نشد'),
    );

    // بررسی رمز عبور
    if (user.password != password) {
      throw Exception('رمز عبور اشتباه است');
    }

    _currentUser = user;
    _isAuthenticated = true;
    _isAdmin = user.isAdmin;
    _token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
    notifyListeners();
  }

  // خروج
  void logout() {
    _isAuthenticated = false;
    _isAdmin = false;
    _token = null;
    _currentUser = null;
    notifyListeners();
  }

  // اضافه کردن کاربر جدید (فقط توسط ادمین)
  void addUser(String username, String password, {bool isAdmin = false}) {
    // بررسی یکتا بودن نام کاربری
    if (_users.any((u) => u.username == username)) {
      throw Exception('این نام کاربری قبلاً ثبت شده است');
    }
    _users.add(
      User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        password: password,
        isAdmin: isAdmin,
      ),
    );
    notifyListeners();
  }

  // Categories
  final List<ProductCategory> _categories = [
    ProductCategory(id: 'c1', name: 'لوله سفید'),
    ProductCategory(id: 'c2', name: 'اتصالات گالوانیزه'),
    ProductCategory(id: 'c3', name: 'شیرآلات صنعتی'),
  ];
  List<ProductCategory> get categories => List.unmodifiable(_categories);

  void addCategory(String name) {
    _categories.add(ProductCategory(name: name));
    notifyListeners();
  }

  void updateCategory(String id, String newName) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _categories[index] = ProductCategory(id: id, name: newName);
      notifyListeners();
    }
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    // Also consider removing products or assigning them to a default category
    notifyListeners();
  }

  ProductCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Products
  final List<Product> _products = [
    Product(
      id: 'p1',
      name: 'لوله سفید ۲۰ میلی‌متری',
      categoryId: 'c1',
      price: 150000,
      description: 'لوله سفید با کیفیت بالا برای لوله‌کشی ساختمان.',
      imageUrl: 'assets/images/pipe_null_1785319134530.jpg',
      stock: 500,
    ),
    Product(
      id: 'p2',
      name: 'زانو ۹۰ درجه گالوانیزه',
      categoryId: 'c2',
      price: 45000,
      description: 'زانو گالوانیزه مقاوم در برابر زنگ زدگی.',
      imageUrl: 'assets/images/pipe_null_1785319134530.jpg',
      stock: 1200,
    ),
  ];
  List<Product> get products => List.unmodifiable(_products);

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Product> getProductsByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(String id, Product updatedProduct) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index >= 0) {
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // Warehouse (Stock Management)
  final List<StockMovement> _stockHistory = [];
  List<StockMovement> get stockHistory => List.unmodifiable(_stockHistory);

  List<StockMovement> getStockHistoryForProduct(String productId) {
    return _stockHistory.where((m) => m.productId == productId).toList();
  }

  void adjustStock(String productId, int change, String reason) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index >= 0) {
      final currentStock = _products[index].stock;
      final newStock = currentStock + change;
      if (newStock >= 0) {
        _products[index].stock = newStock;
        _stockHistory.add(
          StockMovement(
            productId: productId,
            quantityChange: change,
            date: DateTime.now(),
            reason: reason,
          ),
        );
        notifyListeners();
      }
    }
  }

  // Cart
  final List<CartItem> _cart = [];
  List<CartItem> get cart => List.unmodifiable(_cart);

  void addToCart(Product product, int quantity) {
    final index = _cart.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _cart[index].quantity += quantity;
    } else {
      _cart.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void updateCartItemQuantity(String productId, int newQuantity) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (newQuantity > 0) {
        _cart[index].quantity = newQuantity;
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.totalPrice);

  // Orders
  final List<Order> _orders = [];
  List<Order> get orders => List.unmodifiable(_orders);

  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index < 0) return;
    _orders[index].status = status;
    notifyListeners();
  }

  String? submitOrder() {
    // Validate stock
    for (var item in _cart) {
      final product = _products.firstWhere((p) => p.id == item.product.id);
      if (product.stock < item.quantity) {
        return 'موجودی کالا ${product.name} کافی نیست.';
      }
    }

    // Deduct stock
    for (var item in _cart) {
      adjustStock(item.product.id, -item.quantity, 'ثبت سفارش خرید');
    }

    // Create order
    final newOrder = Order(items: List.from(_cart), date: DateTime.now());
    _orders.add(newOrder);

    // Clear cart
    clearCart();

    return null; // Success
  }
}
