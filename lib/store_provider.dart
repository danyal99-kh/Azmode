import 'dart:collection';

import 'package:azmode/model.dart';
import 'package:flutter/foundation.dart';

import 'pages/category_repository.dart';
import 'pages/packaging_type_repository.dart';

class StoreProvider extends ChangeNotifier {
  StoreProvider({
    CategoryRepository? categoryRepository,
    PackagingTypeRepository? packagingTypeRepository,
  }) : _categoryRepository = categoryRepository,
       _packagingTypeRepository = packagingTypeRepository;

  final List<PackagingType> _packagingTypes = [];
  final CategoryRepository? _categoryRepository;
  final PackagingTypeRepository? _packagingTypeRepository;

  static const int homeLatestProductsLimit = 8;
  List<PackagingType> get packagingTypes => List.unmodifiable(_packagingTypes);

  final ValueNotifier<int> catalogRevision = ValueNotifier<int>(0);
  void _catalogChanged() => catalogRevision.value++;

  @override
  void dispose() {
    catalogRevision.dispose();
    super.dispose();
  }

  static const int homePopularCategoriesLimit = 6;

  // ── Refresh (Pull to Refresh) ──────────────────────────────────
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

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

  // ── Notifications (کاملاً محلی — طبق تصمیم، به بک‌اند وصل نمی‌شود) ──
  static const int _maxNotifications = 200;
  final List<AppNotification> _notifications = [];

  void _pushNotification(AppNotification notification) {
    _notifications.add(notification);
    if (_notifications.length > _maxNotifications) {
      _notifications.removeRange(0, _notifications.length - _maxNotifications);
    }
  }

  /// چون اطلاعات کاربر لاگین‌شده دیگر اینجا نگه‌داری نمی‌شود (به
  /// AuthProvider منتقل شده)، شناسه‌ی کاربر باید از بیرون پاس داده شود.
  List<AppNotification> notificationsFor(String? userId) {
    return _notifications
        .where((n) => n.targetUserId == null || n.targetUserId == userId)
        .toList();
  }

  int unreadNotificationCountFor(String? userId) =>
      notificationsFor(userId).where((n) => !n.isRead).length;

  void markAllNotificationsRead(String? userId) {
    bool changed = false;
    for (final n in notificationsFor(userId)) {
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
    if (hasProducts && remainingCategories.isEmpty) return false;

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

  // ── اعلان محلی تغییر وضعیت سفارش ───────────────────────────
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
    if (trimmed.isEmpty || _packagingTypes.any((item) => item.name == trimmed))
      return;
    _packagingTypes.add(PackagingType(name: trimmed));
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
