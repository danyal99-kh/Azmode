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
  //
  // برای جلوگیری از رشد بی‌رویه‌ی حافظه (چون فعلاً همه چیز in-memory
  // است و هیچ‌وقت پاک نمی‌شد)، سقفی برای تعداد کل اعلان‌های نگه‌داشته‌
  // شده در نظر گرفته شده؛ وقتی از این سقف بیشتر شود، قدیمی‌ترین‌ها
  // (از ابتدای لیست) حذف می‌شوند.
  static const int _maxNotifications = 200;
  final List<AppNotification> _notifications = [];

  void _pushNotification(AppNotification notification) {
    _notifications.add(notification);
    if (_notifications.length > _maxNotifications) {
      _notifications.removeRange(0, _notifications.length - _maxNotifications);
    }
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

  /// حذف یک اعلان مشخص — برای حذف با کشیدن (Swipe/Dismissible) در UI.
  void deleteNotification(String id) {
    final lengthBefore = _notifications.length;
    _notifications.removeWhere((n) => n.id == id);
    if (_notifications.length != lengthBefore) {
      notifyListeners();
    }
  }

  // لیست کاربران (شامل ادمین پیش‌فرض)
  final List<User> _users = [
    User(
      id: 'admin',
      username: 'admin',
      password: 'admin',
      isAdmin: true,
      fullName: 'مدیر سیستم',
      phone: '-',
    ),
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
  void addUser(
    String username,
    String password, {
    required String fullName,
    required String phone,
    bool isAdmin = false,
  }) {
    if (_users.any((u) => u.username == username)) {
      throw Exception('این نام کاربری قبلاً ثبت شده است');
    }
    _users.add(
      User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        password: password,
        fullName: fullName,
        phone: phone,
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
    _registerPackagingType(product.packagingType);
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
      _registerPackagingType(updatedProduct.packagingType);
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    // اگر همین محصول توی سبد خرید بود، باید از اونجا هم حذف بشه؛
    // وگرنه هنگام ثبت سفارش به یک محصول ناموجود در _products اشاره
    // می‌کند و submitOrder کرش می‌کند.
    _cart.removeWhere((item) => item.product.id == id);
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

  /// ویرایش یک ردیف سبد خرید (تغییر رنگ و/یا تعداد).
  ///
  /// چون هر ترکیب محصول+رنگ یک ردیف مستقل در سبده، اگر کاربر رنگ رو
  /// عوض کنه و رنگ جدید از قبل یک ردیف دیگه برای همون محصول داشته
  /// باشه، این دو ردیف با هم ادغام می‌شن (نه دو ردیف تکراری). اگر
  /// [newQuantity] صفر یا کمتر باشه، ردیف کلاً حذف می‌شه.
  void editCartItem(
    String productId, {
    required String? oldColor,
    String? newColor,
    required int newQuantity,
  }) {
    final oldIndex = _cart.indexWhere(
      (item) => item.product.id == productId && item.selectedColor == oldColor,
    );
    if (oldIndex < 0) return;

    if (newQuantity <= 0) {
      _cart.removeAt(oldIndex);
      notifyListeners();
      return;
    }

    if (newColor == oldColor) {
      _cart[oldIndex].quantity = newQuantity;
      notifyListeners();
      return;
    }

    final product = _cart[oldIndex].product;
    final mergeIndex = _cart.indexWhere(
      (item) => item.product.id == productId && item.selectedColor == newColor,
    );

    _cart.removeAt(oldIndex);
    if (mergeIndex >= 0) {
      final targetIndex = mergeIndex > oldIndex ? mergeIndex - 1 : mergeIndex;
      _cart[targetIndex].quantity += newQuantity;
    } else {
      _cart.add(
        CartItem(
          product: product,
          quantity: newQuantity,
          selectedColor: newColor,
        ),
      );
    }
    notifyListeners();
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
    //
    // نکته‌ی مهم: چون یک محصول می‌تواند با چند رنگ مختلف در چند ردیف
    // جداگانه‌ی سبد خرید باشد (هر ترکیب محصول+رنگ یک CartItem مستقل
    // است)، ولی همه‌ی این ردیف‌ها از یک موجودی مشترک (product.stock)
    // کسر می‌شوند، اعتبارسنجی باید بر اساس مجموع تعداد درخواستی هر
    // محصول در کل سبد باشد — نه هر ردیف به‌تنهایی.
    final Map<String, int> requestedTotalsByProduct = {};
    for (var item in _cart) {
      requestedTotalsByProduct[item.product.id] =
          (requestedTotalsByProduct[item.product.id] ?? 0) + item.quantity;
    }

    for (final entry in requestedTotalsByProduct.entries) {
      Product? product;
      try {
        product = _products.firstWhere((p) => p.id == entry.key);
      } catch (_) {
        product = null;
      }
      if (product == null) {
        final name = _cart
            .firstWhere((i) => i.product.id == entry.key)
            .product
            .name;
        return 'محصول «$name» دیگر در فروشگاه موجود نیست. لطفاً آن را از سبد خرید حذف کنید.';
      }
      if (product.stock < entry.value) {
        return 'موجودی کالا ${product.name} کافی نیست (درخواست: ${entry.value}، موجود: ${product.stock}).';
      }
    }

    // مرحله‌ی ۲: چون مرحله‌ی ۱ بدون خطا تمام شده، حالا با اطمینان کسر
    // می‌کنیم. کسر همچنان ردیف‌به‌ردیف انجام می‌شود تا هر رنگ در
    // تاریخچه‌ی انبار جداگانه ثبت شود؛ چون مجموع کل ردیف‌های هر محصول
    // از قبل در مرحله‌ی ۱ تایید شده، اینجا دیگر هیچ کسری منفی نمی‌شود.
    for (var item in _cart) {
      adjustStock(
        item.product.id,
        -item.quantity,
        'ثبت سفارش - رنگ: ${item.selectedColor ?? 'بدون رنگ'}',
        notify: false,
      );
    }

    // مرحله‌ی ۳: سفارش با یک «عکس‌فوری» منجمد از هر محصول (copyWith)
    // ثبت می‌شود — نه رفرنس زنده به همان Object داخل _products.
    final newOrder = Order(
      userId: _currentUser!.id,
      customerName: _currentUser!.fullName,
      customerPhone: _currentUser!.phone,
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
  } // انواع بسته‌بندی که تاکنون توسط ادمین تایپ شده‌اند. این لیست مستقل از

  // محصولات نگه‌داری می‌شود تا دفعه‌ی بعد که ادمین می‌خواهد یک نوع
  // بسته‌بندی را روی محصولی دیگر بگذارد، فقط از این لیست انتخاب کند و
  // لازم نباشد دوباره تایپش کند؛ فقط برای نوع کاملاً جدید تایپ لازم است.
  final List<String> _packagingTypes = [
    'شاخه‌ای',
    'کارتونی',
    'متری',
    'بسته‌بندی ۶ عددی',
  ];
  List<String> get packagingTypes => List.unmodifiable(_packagingTypes);

  /// افزودن یک نوع بسته‌بندی جدید به لیست (اگر از قبل موجود نباشد).
  void addPackagingType(String type) {
    final trimmed = type.trim();
    if (trimmed.isEmpty || _packagingTypes.contains(trimmed)) return;
    _packagingTypes.add(trimmed);
    notifyListeners();
  }

  // اگر محصولی با یک نوع بسته‌بندی جدید ذخیره شود (مثلاً از طریق فرم)
  // ولی ادمین دکمه‌ی «افزودن» را نزده باشد، این تابع مطمئن می‌شود که آن
  // نوع در لیست عمومی هم ثبت می‌شود.
  void _registerPackagingType(String? type) {
    final trimmed = type?.trim();
    if (trimmed != null &&
        trimmed.isNotEmpty &&
        !_packagingTypes.contains(trimmed)) {
      _packagingTypes.add(trimmed);
    }
  }

  /// ویرایش نام و شماره تماس کاربر لاگین‌شده‌ی فعلی. چون این اطلاعات در
  /// هر سفارش جدید به‌صورت عکس‌فوری ذخیره می‌شود، این ویرایش فقط روی
  /// سفارش‌های بعدی اثر می‌گذارد؛ سفارش‌های قبلی دست‌نخورده می‌مانند.
  void updateCurrentUserProfile({
    required String fullName,
    required String phone,
  }) {
    final user = _currentUser;
    if (user == null) return;
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index < 0) return;
    final updated = User(
      id: user.id,
      username: user.username,
      password: user.password,
      isAdmin: user.isAdmin,
      fullName: fullName,
      phone: phone,
    );
    _users[index] = updated;
    _currentUser = updated;
    notifyListeners();
  }
}
