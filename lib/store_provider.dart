import 'dart:collection';

import 'package:azmode/model.dart';
import 'package:azmode/models/user.dart' as api_user;
import 'package:azmode/services/auth_service.dart';
import 'package:azmode/services/cart_service.dart';
import 'package:azmode/services/profile_service.dart';
import 'package:flutter/foundation.dart';

import 'pages/category_repository.dart';
import 'pages/packaging_type_repository.dart';

class StoreProvider extends ChangeNotifier {
  StoreProvider({
    CategoryRepository? categoryRepository,
    PackagingTypeRepository? packagingTypeRepository,
    AuthService? authService,
    ProfileService? profileService,
  }) : _categoryRepository = categoryRepository,
       _packagingTypeRepository = packagingTypeRepository,
       _authService = authService,
       _profileService = profileService;

  final AuthService? _authService;
  final ProfileService? _profileService;
  final List<PackagingType> _packagingTypes = [];
  final CategoryRepository? _categoryRepository;
  final PackagingTypeRepository? _packagingTypeRepository;

  // ── تنظیمات قابل‌تغییر Home ─────────────────────────────────────
  /// تعداد محصولاتی که در بخش «جدیدترین محصولات» صفحه اصلی نمایش داده
  /// می‌شوند. فقط همین یک خط را برای تغییر تعداد ویرایش کن.
  static const int homeLatestProductsLimit = 8;
  List<PackagingType> get packagingTypes => List.unmodifiable(_packagingTypes);

  /// تعداد دسته‌بندی‌هایی که در بخش «دسته‌بندی‌های پرکاربرد» نمایش داده
  /// می‌شوند.  // ── Catalog revision ────────────────────────────────────────
  final ValueNotifier<int> catalogRevision = ValueNotifier<int>(0);
  void _catalogChanged() => catalogRevision.value++;

  @override
  void dispose() {
    catalogRevision.dispose();
    super.dispose();
  }

  static const int homePopularCategoriesLimit = 6;

  bool _isAuthenticated = false;
  bool _isAdmin = false;
  User? _currentUser;
  bool _isAuthLoading = false;
  String? _authError;

  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;
  User? get currentUser => _currentUser;
  bool get isAuthLoading => _isAuthLoading;
  String? get authError => _authError;
  // ── Refresh (Pull to Refresh) ──────────────────────────────────
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  /// بازخوانی کلی اطلاعات فروشگاه (محصولات، دسته‌بندی‌ها، موجودی،
  /// قیمت‌ها، اعلان‌ها). فعلاً چون Backend واقعی وصل نیست، این متد فقط
  /// یک تاخیر مصنوعی ایجاد کرده و UI را دوباره Rebuild می‌کند؛ اما
  /// دقیقاً همین امضا (`Future<void> refreshStore()`) باید بعداً برای
  /// فراخوانی واقعی API‌ها استفاده شود — بدون این‌که `HomePage` نیاز به
  /// تغییر داشته باشد. اگر عملیات خطا بدهد، یک Exception با پیام
  /// مناسب برای نمایش در UI پرتاب می‌شود (و برنامه Crash نمی‌کند، چون
  /// UI آن را در try/catch مدیریت می‌کند).
  Future<void> refreshStore() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 700));
    } catch (e) {
      throw Exception('بروزرسانی اطلاعات با خطا مواجه شد. دوباره تلاش کنید.');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // ── Notifications ────────────────────────────────────────────
  static const int _maxNotifications = 200;
  final List<AppNotification> _notifications = [];

  void _pushNotification(AppNotification notification) {
    _notifications.add(notification);
    if (_notifications.length > _maxNotifications) {
      _notifications.removeRange(0, _notifications.length - _maxNotifications);
    }
  }

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

  void deleteNotification(String id) {
    final lengthBefore = _notifications.length;
    _notifications.removeWhere((n) => n.id == id);
    if (_notifications.length != lengthBefore) {
      notifyListeners();
    }
  }

  // ── Users ────────────────────────────────────────────────────

  Future<void> login(String username, String password) async {
    final service = _authService;
    if (service == null) {
      throw Exception('سرویس احراز هویت پیکربندی نشده است.');
    }
    _isAuthLoading = true;
    _authError = null;
    notifyListeners();
    try {
      final apiUser = await service.login(
        username: username,
        password: password,
      );
      _applyAuthenticatedUser(apiUser); // ← بدون as User
    } catch (e) {
      _authError = e.toString();
      rethrow;
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreSession() async {
    final service = _authService;
    if (service == null) return;
    if (!await service.isLoggedIn()) return;
    try {
      final apiUser = await service.getCurrentUser();
      _applyAuthenticatedUser(apiUser); // ← بدون as User
      notifyListeners();
    } catch (_) {
      await service.logout();
    }
  }

  void _applyAuthenticatedUser(api_user.User apiUser) {
    _currentUser = User(
      id: apiUser.id.toString(),
      username: apiUser.username,
      password: '',
      isAdmin: apiUser.isAdmin,
      fullName: apiUser.fullName,
      phone: apiUser.phone,
    );
    _isAuthenticated = true;
    _isAdmin = apiUser.isAdmin;
  }

  Future<void> logout() async {
    await _authService?.logout();
    _isAuthenticated = false;
    _isAdmin = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> addUser(
    String username,
    String password, {
    required String fullName,
    required String phone,
    bool isAdmin = false,
  }) async {
    final service = _profileService;
    if (service == null) {
      throw Exception('سرویس پروفایل پیکربندی نشده است.');
    }
    await service.createUser(
      username: username,
      password: password,
      fullName: fullName,
      phone: phone,
      isAdmin: isAdmin,
    );
  }

  Future<void> loadCategories() async {
    final repository = _categoryRepository;
    if (repository == null) return;

    final categories = await repository.fetchCategories();

    _categories
      ..clear()
      ..addAll(categories);

    notifyListeners();
  }

  Future<void> loadPackagingTypes() async {
    final repository = _packagingTypeRepository;
    if (repository == null) return;

    final packagingTypes = await repository.fetchPackagingTypes();

    _packagingTypes
      ..clear()
      ..addAll(packagingTypes);

    notifyListeners();
  }

  // ── Categories ───────────────────────────────────────────────
  final List<ProductCategory> _categories = [
    ProductCategory(id: 'c1', name: 'لوله سفید'),
    ProductCategory(id: 'c2', name: 'اتصالات گالوانیزه'),
    ProductCategory(id: 'c3', name: 'شیرآلات صنعتی'),
  ];
  List<ProductCategory> get categories => List.unmodifiable(_categories);

  /// دسته‌بندی‌های «پرکاربرد» برای بخش Home. فعلاً چون هیچ معیار واقعی
  /// (مثلاً تعداد فروش) در دسترس نیست، ساده‌ترین و امن‌ترین انتخاب،
  /// گرفتن ابتدای لیست دسته‌بندی‌هاست. وقتی Backend معیار واقعی
  /// (پرفروش‌ترین/پربازدیدترین) فراهم کند، فقط کافی است همین Getter
  /// جایگزین شود؛ UI (`HomePage`) بدون تغییر باقی می‌ماند.
  List<ProductCategory> get popularCategories =>
      _categories.take(homePopularCategoriesLimit).toList();

  void addCategory(String name, {String? imageUrl}) {
    _categories.add(
      ProductCategory(
        name: name,
        imageUrl: (imageUrl != null && imageUrl.trim().isNotEmpty)
            ? imageUrl
            : null,
      ),
    );
    notifyListeners();
  }

  void updateCategory(
    String id,
    String newName, {
    String? imageUrl,
    bool clearImage = false,
  }) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index >= 0) {
      final existing = _categories[index];
      _categories[index] = ProductCategory(
        id: id,
        name: newName,
        imageUrl: clearImage ? null : (imageUrl ?? existing.imageUrl),
      );
      notifyListeners();
    }
  }

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
        _catalogChanged();
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

  // ── Recently viewed ─────────────────────────────────────────
  static const int _maxRecentlyViewed = 20;
  final List<String> _recentlyViewedIds = [];

  List<String> get recentlyViewedIds => List.unmodifiable(_recentlyViewedIds);

  List<Product> get recentlyViewedProducts {
    return _recentlyViewedIds
        .map((id) => getProductById(id))
        .whereType<Product>()
        .toList();
  }

  void markProductViewed(String productId) {
    if (getProductById(productId) == null) return;
    _recentlyViewedIds.remove(productId);
    _recentlyViewedIds.insert(0, productId);
    if (_recentlyViewedIds.length > _maxRecentlyViewed) {
      _recentlyViewedIds.removeRange(
        _maxRecentlyViewed,
        _recentlyViewedIds.length,
      );
    }
    notifyListeners();
  }

  // ── Products ─────────────────────────────────────────────────
  final List<Product> _products = [
    Product(
      id: 'p1',
      name: 'لوله سفید ۲۰ میلی‌متری',
      categoryId: 'c1',
      price: 150000,
      description: 'لوله سفید با کیفیت بالا برای لوله‌کشی ساختمان.',
      imageUrl: 'assets/images/pipe_null_1785319134530.jpg',
      stock: 500,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Product(
      id: 'p2',
      name: 'زانو ۹۰ درجه گالوانیزه',
      categoryId: 'c2',
      price: 45000,
      description: 'زانو گالوانیزه مقاوم در برابر زنگ زدگی.',
      imageUrl: 'assets/images/pipe_null_1785319134530.jpg',
      stock: 1200,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];
  late final UnmodifiableListView<Product> _productsView =
      UnmodifiableListView<Product>(_products);
  List<Product> get products => _productsView;

  /// جدیدترین محصولات، مرتب‌شده بر اساس `createdAt` (نزولی) و محدود به
  /// `homeLatestProductsLimit`. منطق Sort/Limit عمداً اینجاست، نه در
  /// `HomePage`، تا وقتی این داده از یک API واقعی (که خودش می‌تواند
  /// مرتب‌سازی و صفحه‌بندی را انجام دهد) بیاید، فقط پیاده‌سازی داخل این
  /// Getter عوض شود.
  List<Product> get latestProducts {
    final sorted = [..._products]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(homeLatestProductsLimit).toList();
  }

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
    _pushNotification(
      AppNotification(
        type: NotificationType.newProduct,
        title: 'محصول جدید',
        message: 'محصول «${product.name}» به فروشگاه اضافه شد.',
        date: DateTime.now(),
        relatedId: product.id,
      ),
    );
    _catalogChanged();
    notifyListeners();
  }

  void updateProduct(String id, Product updatedProduct) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index >= 0) {
      _products[index] = updatedProduct;
      _catalogChanged();
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    _cart.removeWhere((item) => item.product.id == id);
    _catalogChanged();
    notifyListeners();
  }

  // ── Warehouse ────────────────────────────────────────────────
  final List<StockMovement> _stockHistory = [];
  List<StockMovement> get stockHistory => List.unmodifiable(_stockHistory);

  List<StockMovement> getStockHistoryForProduct(String productId) {
    return _stockHistory.where((m) => m.productId == productId).toList();
  }

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
        _catalogChanged();
        if (notify) notifyListeners();
      }
    }
  }

  // ── Cart ─────────────────────────────────────────────────────
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

  // ── Orders ───────────────────────────────────────────────────
  // ── اعلان محلی تغییر وضعیت سفارش ───────────────────────────
  /// خودِ داده‌ی سفارش‌ها دیگر اینجا نگه‌داری نمی‌شود (به
  /// `ProformaProvider` منتقل شده)؛ این متد فقط یک اعلان محلی برای
  /// کاربرِ صاحب سفارش می‌سازد و از `ProformaProvider.onStatusChanged`
  /// صدا زده می‌شود.
  void pushOrderStatusNotification({
    required int orderId,
    String? targetUserId,
    required bool approved,
  }) {
    _pushNotification(
      AppNotification(
        type: approved
            ? NotificationType.orderApproved
            : NotificationType.orderRejected,
        title: approved ? 'سفارش شما تایید شد' : 'سفارش شما رد شد',
        message: approved
            ? 'سفارش شما به شماره #$orderId تایید و در حال آماده‌سازی است.'
            : 'متاسفانه سفارش شما به شماره #$orderId رد شد.',
        date: DateTime.now(),
        targetUserId: targetUserId,
        relatedId: orderId.toString(),
      ),
    );
  }

  void addPackagingType(String type) {
    final trimmed = type.trim();

    if (trimmed.isEmpty ||
        _packagingTypes.any((item) => item.name == trimmed)) {
      return;
    }

    _packagingTypes.add(PackagingType(name: trimmed));

    notifyListeners();
  }

  void _registerPackagingType(String? type) {
    final trimmed = type?.trim();

    if (trimmed != null &&
        trimmed.isNotEmpty &&
        !_packagingTypes.any((item) => item.name == trimmed)) {
      _packagingTypes.add(PackagingType(name: trimmed));
    }
  }

  Future<void> updateCurrentUserProfile({
    required String fullName,
    required String phone,
  }) async {
    final service = _profileService;
    final user = _currentUser;
    if (service == null || user == null) return;

    final apiUser = await service.updateProfile(
      fullName: fullName,
      phone: phone,
    );

    _currentUser = User(
      id: user.id,
      username: user.username,
      password: '',
      isAdmin: apiUser.isAdmin,
      fullName: apiUser.fullName,
      phone: apiUser.phone,
    );
    notifyListeners();
  }

  // ── Banners ──────────────────────────────────────────────────
  final List<PromoBanner> _banners = [
    PromoBanner(
      id: 'b1',
      title: 'تخفیف ویژه محصولات لوله',
      description: 'تا ۲۰٪ تخفیف روی خرید عمده لوله سفید',
      imageUrl: 'assets/images/pipe_null_1785319134530.jpg',
      sortOrder: 0,
      targetType: BannerTargetType.category,
      targetId: 'c1',
      subtitle: '',
      style: PromoBannerStyle.teal,
    ),
  ];
  List<PromoBanner> get banners => List.unmodifiable(_banners);

  /// بنرهای قابل‌نمایش در Home: فعال + داخل بازه‌ی تاریخ + مرتب‌شده بر
  /// اساس `sortOrder`.
  List<PromoBanner> get activeBanners {
    final active = _banners
        .where((b) => b.isActive && b.isCurrentlyInDateRange)
        .toList();
    active.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return active;
  }

  void addBanner(PromoBanner banner) {
    _banners.add(banner);
    notifyListeners();
  }

  void updateBanner(String id, PromoBanner updated) {
    final index = _banners.indexWhere((b) => b.id == id);
    if (index >= 0) {
      _banners[index] = updated;
      notifyListeners();
    }
  }

  void deleteBanner(String id) {
    _banners.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  void toggleBannerActive(String id) {
    final index = _banners.indexWhere((b) => b.id == id);
    if (index >= 0) {
      _banners[index].isActive = !_banners[index].isActive;
      notifyListeners();
    }
  }

  void moveBannerUp(String id) {
    final ordered = [..._banners]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final idx = ordered.indexWhere((b) => b.id == id);
    if (idx > 0) {
      final tmp = ordered[idx].sortOrder;
      ordered[idx].sortOrder = ordered[idx - 1].sortOrder;
      ordered[idx - 1].sortOrder = tmp;
      notifyListeners();
    }
  }

  void moveBannerDown(String id) {
    final ordered = [..._banners]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final idx = ordered.indexWhere((b) => b.id == id);
    if (idx >= 0 && idx < ordered.length - 1) {
      final tmp = ordered[idx].sortOrder;
      ordered[idx].sortOrder = ordered[idx + 1].sortOrder;
      ordered[idx + 1].sortOrder = tmp;
      notifyListeners();
    }
  }
}
