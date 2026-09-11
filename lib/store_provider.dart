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

  // Notifications
  // ----------------------------------------------------------------
  // دو رویداد اصلی اعلان تولید می‌کنند:
  // 1) افزودن محصول جدید توسط ادمین → اعلان عمومی برای همه‌ی کاربران.
  // 2) تغییر وضعیت سفارش (تایید/رد) توسط ادمین → اعلان مخصوص همان
  //    کاربری که سفارش را ثبت کرده.
  final List<AppNotification> _notifications = [];

  void _pushNotification(AppNotification notification) {
    _notifications.add(notification);
  }

  /// اعلان‌های مرتبط با کاربر لاگین‌شده‌ی فعلی: اعلان‌های عمومی (بدون
  /// targetUserId) + اعلان‌های مخصوص همین کاربر. اگر کاربری لاگین نکرده
  /// باشد، فقط اعلان‌های عمومی برگردانده می‌شود.
  List<AppNotification> get myNotifications {
    final userId = _currentUser?.id;
    return _notifications
        .where((n) => n.targetUserId == null || n.targetUserId == userId)
        .toList();
  }

  int get unreadNotificationCount =>
      myNotifications.where((n) => !n.isRead).length;

  void markAllNotificationsRead() {
    bool changed = false;
    for (final n in myNotifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

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

  /// حذف یک دسته‌بندی.
  ///
  /// قبلاً محصولات همان دسته دست‌نخورده باقی می‌ماندند و با یک
  /// categoryId نامعتبر «یتیم» می‌شدند (دیگر زیر هیچ فیلتر دسته‌بندی‌ای
  /// دیده نمی‌شدند). حالا:
  /// - اگر دسته‌ی حذف‌شونده محصولی داشته باشد، آن محصولات به اولین
  ///   دسته‌ی باقی‌مانده منتقل می‌شوند (نه حذف و نه یتیم).
  /// - اگر این تنها دسته‌ی موجود در کل سیستم باشد و محصولی هم داشته
  ///   باشد، حذف انجام نمی‌شود (چون جایی برای انتقال محصولات نیست) و
  ///   false برگردانده می‌شود تا UI پیام مناسب نشان دهد.
  bool deleteCategory(String id) {
    final hasProducts = _products.any((p) => p.categoryId == id);
    final remainingCategories = _categories.where((c) => c.id != id).toList();

    if (hasProducts && remainingCategories.isEmpty) {
      return false;
    }

    if (hasProducts) {
      final fallbackId = remainingCategories.first.id;
      for (var i = 0; i < _products.length; i++) {
        if (_products[i].categoryId == id) {
          _products[i] = _products[i].copyWith(categoryId: fallbackId);
        }
      }
    }

    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
    return true;
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
    // اعلان عمومی: همه‌ی کاربران از محصول تازه‌اضافه‌شده مطلع شوند.
    _pushNotification(
      AppNotification(
        type: NotificationType.newProduct,
        title: 'محصول جدید',
        message: 'محصول «${product.name}» به فروشگاه اضافه شد.',
        date: DateTime.now(),
        relatedId: product.id,
      ),
    );
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

  /// تغییر موجودی یک محصول.
  ///
  /// [notify] پیش‌فرض true است (استفاده‌ی معمول، مثلاً از پنل انبار).
  /// وقتی این متد چند بار پشت‌سرهم داخل یک عملیات بزرگ‌تر صدا زده
  /// می‌شود (مثلاً کسر موجودی همه‌ی آیتم‌های یک سفارش در [submitOrder])،
  /// می‌توان false داد تا هر فراخوانی جداگانه UI را rebuild نکند و
  /// فراخواننده خودش یک‌بار در پایان notifyListeners() صدا بزند.
  void adjustStock(
    String productId,
    int change,
    String reason, {
    bool notify = true,
  }) {
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
        if (notify) notifyListeners();
      }
    }
  }

  // Cart
  final List<CartItem> _cart = [];
  List<CartItem> get cart => List.unmodifiable(_cart);

  void addToCart(Product product, int quantity, {String? selectedColor}) {
    final index = _cart.indexWhere(
      (item) =>
          item.product.id == product.id && item.selectedColor == selectedColor,
    );
    if (index >= 0) {
      _cart[index].quantity += quantity;
    } else {
      _cart.add(
        CartItem(
          product: product,
          quantity: quantity,
          selectedColor: selectedColor,
        ),
      );
    }
    notifyListeners();
  }

  void updateCartItemQuantity(
    String productId,
    int newQuantity, {
    String? selectedColor,
  }) {
    final index = _cart.indexWhere(
      (item) =>
          item.product.id == productId && item.selectedColor == selectedColor,
    );
    if (index >= 0) {
      if (newQuantity > 0) {
        _cart[index].quantity = newQuantity;
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeFromCart(String productId, {String? selectedColor}) {
    _cart.removeWhere(
      (item) =>
          item.product.id == productId && item.selectedColor == selectedColor,
    );
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.totalPrice);

  // Orders
  final List<Order> _orders = [];

  /// همه‌ی سفارش‌های ثبت‌شده در کل سیستم — فقط برای پنل ادمین (فاکتورها)
  /// استفاده می‌شود، چون ادمین باید سفارش‌های همه‌ی مشتری‌ها را ببیند.
  List<Order> get orders => List.unmodifiable(_orders);

  /// سفارش‌های مربوط به یک کاربر خاص.
  List<Order> ordersForUser(String userId) {
    return _orders.where((o) => o.userId == userId).toList();
  }

  /// سفارش‌های کاربر لاگین‌شده‌ی فعلی — این لیست باید در صفحه‌ی
  /// «پیش‌فاکتور» مشتری استفاده شود، نه [orders]، تا هر کاربر فقط
  /// سفارش‌های خودش را ببیند.
  List<Order> get myOrders {
    final user = _currentUser;
    if (user == null) return const [];
    return ordersForUser(user.id);
  }

  /// تغییر وضعیت سفارش توسط ادمین. علاوه بر ثبت وضعیت جدید، برای کاربری
  /// که صاحب سفارش است یک اعلان مخصوص (تایید یا رد) ساخته می‌شود تا در
  /// صفحه‌ی اعلان‌های او نمایش داده شود.
  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index < 0) return;
    final order = _orders[index];
    order.status = status;

    if (status == OrderStatus.approved) {
      _pushNotification(
        AppNotification(
          type: NotificationType.orderApproved,
          title: 'سفارش شما تایید شد',
          message:
              'سفارش شما به شماره #${order.id.substring(0, 8)} تایید و در حال آماده‌سازی است.',
          date: DateTime.now(),
          targetUserId: order.userId,
          relatedId: order.id,
        ),
      );
    } else if (status == OrderStatus.rejected) {
      _pushNotification(
        AppNotification(
          type: NotificationType.orderRejected,
          title: 'سفارش شما رد شد',
          message:
              'متاسفانه سفارش شما به شماره #${order.id.substring(0, 8)} رد شد.',
          date: DateTime.now(),
          targetUserId: order.userId,
          relatedId: order.id,
        ),
      );
    }

    notifyListeners();
  }

  /// ثبت سفارش از روی سبد خرید فعلی.
  ///
  /// به‌صورت دو مرحله‌ای انجام می‌شود تا یا کل سفارش با موفقیت ثبت شود
  /// یا هیچ موجودی‌ای کم نشود (بدون نتیجه‌ی نصفه‌نیمه):
  /// ۱) اعتبارسنجی کامل موجودی همه‌ی آیتم‌ها، قبل از هر گونه کسر.
  /// ۲) فقط اگر همه‌چیز معتبر بود، کسر واقعی موجودی برای همه‌ی آیتم‌ها.
  ///
  /// نکته برای آینده: این تفکیک «چک‌کن-بعد-اعمال‌کن» در جاوااسکریپت/
  /// دارت تک‌نخی و بدون await در وسط، عملاً اتمیک است. اما وقتی این
  /// پروژه به یک Backend/دیتابیس واقعی وصل شود (که در نقشه‌ی راه آینده
  /// هست)، همین منطق باید داخل یک تراکنش دیتابیسی با قفل مناسب (مثلاً
  /// Optimistic Locking روی ستون stock) بازنویسی شود، چون آنجا دیگر
  /// تضمین تک‌نخی بودن برقرار نیست و چند کاربر می‌توانند هم‌زمان سفارش
  /// ثبت کنند.
  String? submitOrder() {
    if (!_isAuthenticated || _currentUser == null) {
      return 'لطفاً ابتدا وارد حساب کاربری خود شوید.';
    }

    // مرحله‌ی ۱: اعتبارسنجی کامل، بدون هیچ تغییری در داده‌ها.
    for (var item in _cart) {
      final product = _products.firstWhere((p) => p.id == item.product.id);
      if (product.stock < item.quantity) {
        return 'موجودی کالا ${product.name} (رنگ: ${item.selectedColor ?? 'بدون رنگ'}) کافی نیست.';
      }
    }

    // مرحله‌ی ۲: چون مرحله‌ی ۱ بدون خطا تمام شده، حالا با اطمینان کسر
    // می‌کنیم. notify:false تا هر آیتم جداگانه UI را rebuild نکند؛
    // clearCart() در پایان یک‌بار notifyListeners() صدا می‌زند که کافی
    // است.
    for (var item in _cart) {
      adjustStock(
        item.product.id,
        -item.quantity,
        'ثبت سفارش - رنگ: ${item.selectedColor ?? 'بدون رنگ'}',
        notify: false,
      );
    }

    // مرحله‌ی ۳: سفارش با یک «عکس‌فوری» منجمد از هر محصول (copyWith)
    // ثبت می‌شود — نه رفرنس زنده به همان Object داخل _products. قبلاً
    // چون CartItem.product مستقیم به Object زنده اشاره می‌کرد، تغییرات
    // بعدی موجودی/قیمت محصول روی سفارش‌های قدیمی هم منعکس می‌شد.
    final newOrder = Order(
      userId: _currentUser!.id,
      items: _cart
          .map(
            (cartItem) => CartItem(
              product: cartItem.product.copyWith(),
              quantity: cartItem.quantity,
              selectedColor: cartItem.selectedColor,
            ),
          )
          .toList(),
      date: DateTime.now(),
    );
    _orders.add(newOrder);
    clearCart();
    return null;
  }
}
