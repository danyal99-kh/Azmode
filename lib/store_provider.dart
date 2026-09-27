import 'dart:collection';

import 'package:azmode/model.dart';
import 'package:flutter/foundation.dart';

import 'pages/api_banner_repository.dart';
import 'pages/api_warehouse_repository.dart';
import 'pages/category_repository.dart';
import 'pages/notification_repository.dart';
import 'pages/packaging_type_repository.dart';
import 'pages/product_repository.dart';
import 'pages/product_query.dart';
import 'pages/paged_result.dart';

class StoreProvider extends ChangeNotifier {
  StoreProvider({
    CategoryRepository? categoryRepository,
    PackagingTypeRepository? packagingTypeRepository,
    ProductRepository? productRepository,
    ApiBannerRepository? bannerRepository,
    ApiWarehouseRepository? warehouseRepository,
    NotificationRepository? notificationRepository,
  }) : _categoryRepository = categoryRepository,
       _packagingTypeRepository = packagingTypeRepository,
       _productRepository = productRepository,
       _bannerRepository = bannerRepository,
       _warehouseRepository = warehouseRepository,
       _notificationRepository = notificationRepository;

  final CategoryRepository? _categoryRepository;
  final PackagingTypeRepository? _packagingTypeRepository;
  final ProductRepository? _productRepository;
  final ApiBannerRepository? _bannerRepository;
  final ApiWarehouseRepository? _warehouseRepository;
  final NotificationRepository? _notificationRepository;

  static const int homeLatestProductsLimit = 8;

  final ValueNotifier<int> catalogRevision = ValueNotifier<int>(0);
  void _catalogChanged() => catalogRevision.value++;

  @override
  void dispose() {
    catalogRevision.dispose();
    super.dispose();
  }

  static const int homePopularCategoriesLimit = 6;

  // ── Loading States ──────────────────────────────────────────────
  bool _isLoadingCategories = false;
  bool get isLoadingCategories => _isLoadingCategories;

  String? _categoriesError;
  String? get categoriesError => _categoriesError;

  bool _isLoadingPackagingTypes = false;
  bool get isLoadingPackagingTypes => _isLoadingPackagingTypes;

  String? _packagingTypesError;
  String? get packagingTypesError => _packagingTypesError;

  bool _isLoadingBanners = false;
  bool get isLoadingBanners => _isLoadingBanners;

  String? _bannersError;
  String? get bannersError => _bannersError;

  bool _isLoadingProducts = false;
  bool get isLoadingProducts => _isLoadingProducts;

  String? _productsError;
  String? get productsError => _productsError;

  bool _isLoadingStockHistory = false;
  bool get isLoadingStockHistory => _isLoadingStockHistory;

  bool _isAdjustingStock = false;
  bool get isAdjustingStock => _isAdjustingStock;

  bool _isLoadingNotifications = false;
  bool get isLoadingNotifications => _isLoadingNotifications;

  // ── Refresh (Pull to Refresh) ──────────────────────────────────
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  /// بارگذاری مجدد همه اطلاعات از Backend.
  Future<void> refreshStore() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      await Future.wait([
        _loadCategoriesFromApi(),
        _loadPackagingTypesFromApi(),
        _loadBannersFromApi(),
        _loadStockHistoryFromApi(),
      ]);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // ── Categories ─────────────────────────────────────────────────
  final List<ProductCategory> _categories = [];
  List<ProductCategory> get categories => List.unmodifiable(_categories);

  List<ProductCategory> get popularCategories =>
      _categories.take(homePopularCategoriesLimit).toList();

  /// وضعیت loading برای عملیات CRUD دسته‌بندی‌ها
  bool _isCategoryCrudLoading = false;
  bool get isCategoryCrudLoading => _isCategoryCrudLoading;

  Future<void> loadCategories() => _loadCategoriesFromApi();

  Future<void> _loadCategoriesFromApi() async {
    final repository = _categoryRepository;
    if (repository == null) return;

    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();

    try {
      final categories = await repository.fetchCategories();
      _categories
        ..clear()
        ..addAll(categories);
    } catch (e) {
      _categoriesError = e.toString();
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  /// ساخت دسته‌بندی جدید از طریق API.
  ///
  /// در صورت موفقیت، دسته‌بندی ساخته‌شده به لیست اضافه می‌شود.
  /// در صورت خطا، Exception پرتاب می‌شود و UI باید آن را نمایش دهد.
  Future<void> addCategory(String name, {String? imageBase64}) async {
    final repo = _categoryRepository;
    if (repo == null) {
      throw StateError(
        'CategoryRepository is not configured. Cannot create category.',
      );
    }

    _isCategoryCrudLoading = true;
    notifyListeners();

    try {
      final created = await repo.createCategory(name, imageBase64: imageBase64);
      _categories.add(created);
      _catalogChanged();
      notifyListeners();
    } finally {
      _isCategoryCrudLoading = false;
      notifyListeners();
    }
  }

  /// ویرایش دسته‌بندی از طریق API.
  ///
  /// در صورت موفقیت، دسته‌بندی به‌روزرسانی‌شده جایگزین می‌شود.
  /// در صورت خطا، Exception پرتاب می‌شود و UI باید آن را نمایش دهد.
  Future<void> updateCategory(
    String id,
    String newName, {
    String? imageBase64,
    bool clearImage = false,
  }) async {
    final repo = _categoryRepository;
    if (repo == null) {
      throw StateError(
        'CategoryRepository is not configured. Cannot update category.',
      );
    }

    _isCategoryCrudLoading = true;
    notifyListeners();

    try {
      final updated = await repo.updateCategory(
        id,
        newName,
        imageBase64: imageBase64,
        clearImage: clearImage,
      );
      final index = _categories.indexWhere((c) => c.id == id);
      if (index >= 0) {
        _categories[index] = updated;
      }
      _catalogChanged();
      notifyListeners();
    } finally {
      _isCategoryCrudLoading = false;
      notifyListeners();
    }
  }

  /// حذف دسته‌بندی از طریق API.
  ///
  /// در صورت موفقیت، دسته‌بندی از لیست حذف می‌شود.
  /// در صورت خطا، Exception پرتاب می‌شود و UI باید آن را نمایش دهد.
  ///
  /// نکته: اگر دسته‌بندی محصولات داشته باشد، backend با خطا 400/403 پاسخ
  /// می‌دهد (on_delete=PROTECT). UI باید این خطا را نمایش دهد.
  Future<void> deleteCategory(String id) async {
    final repo = _categoryRepository;
    if (repo == null) {
      throw StateError(
        'CategoryRepository is not configured. Cannot delete category.',
      );
    }

    _isCategoryCrudLoading = true;
    notifyListeners();

    try {
      await repo.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      _catalogChanged();
      notifyListeners();
    } finally {
      _isCategoryCrudLoading = false;
      notifyListeners();
    }
  }

  ProductCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // ── Packaging Types ────────────────────────────────────────────
  final List<PackagingType> _packagingTypes = [];
  List<PackagingType> get packagingTypes => List.unmodifiable(_packagingTypes);

  bool _isPackagingTypeCrudLoading = false;
  bool get isPackagingTypeCrudLoading => _isPackagingTypeCrudLoading;

  Future<void> loadPackagingTypes() => _loadPackagingTypesFromApi();

  Future<void> _loadPackagingTypesFromApi() async {
    final repository = _packagingTypeRepository;
    if (repository == null) return;

    _isLoadingPackagingTypes = true;
    _packagingTypesError = null;
    notifyListeners();

    try {
      final packagingTypes = await repository.fetchPackagingTypes();
      _packagingTypes
        ..clear()
        ..addAll(packagingTypes);
    } catch (e) {
      _packagingTypesError = e.toString();
    } finally {
      _isLoadingPackagingTypes = false;
      notifyListeners();
    }
  }

  /// ساخت نوع بسته‌بندی جدید از طریق API.
  Future<void> addPackagingType(String type) async {
    final repo = _packagingTypeRepository;
    if (repo == null) {
      throw StateError(
        'PackagingTypeRepository is not configured. Cannot create packaging type.',
      );
    }

    _isPackagingTypeCrudLoading = true;
    notifyListeners();

    try {
      final created = await repo.createPackagingType(type);
      _packagingTypes.add(created);
      notifyListeners();
    } finally {
      _isPackagingTypeCrudLoading = false;
      notifyListeners();
    }
  }

  /// ویرایش نوع بسته‌بندی از طریق API.
  Future<void> updatePackagingType(String id, String newName) async {
    final repo = _packagingTypeRepository;
    if (repo == null) {
      throw StateError(
        'PackagingTypeRepository is not configured. Cannot update packaging type.',
      );
    }

    _isPackagingTypeCrudLoading = true;
    notifyListeners();

    try {
      final updated = await repo.updatePackagingType(id, newName);
      final index = _packagingTypes.indexWhere((p) => p.id == id);
      if (index >= 0) {
        _packagingTypes[index] = updated;
      }
      notifyListeners();
    } finally {
      _isPackagingTypeCrudLoading = false;
      notifyListeners();
    }
  }

  /// حذف نوع بسته‌بندی از طریق API.
  Future<void> deletePackagingType(String id) async {
    final repo = _packagingTypeRepository;
    if (repo == null) {
      throw StateError(
        'PackagingTypeRepository is not configured. Cannot delete packaging type.',
      );
    }

    _isPackagingTypeCrudLoading = true;
    notifyListeners();

    try {
      await repo.deletePackagingType(id);
      _packagingTypes.removeWhere((p) => p.id == id);
      notifyListeners();
    } finally {
      _isPackagingTypeCrudLoading = false;
      notifyListeners();
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
  final List<Product> _products = [];
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

  /// بارگذاری محصولات از API.
  Future<void> loadProducts() => _loadProductsFromApi();

  Future<void> _loadProductsFromApi() async {
    final repo = _productRepository;
    if (repo == null) return;

    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      // برای لیست کامل محصولات از pagination استفاده می‌کنیم
      final result = await repo.fetchProducts(
        const ProductQuery(),
        const PageRequest(page: 1, pageSize: 1000),
      );
      _products
        ..clear()
        ..addAll(result.items);
      _catalogChanged();
    } catch (e) {
      _productsError = e.toString();
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// وضعیت loading برای عملیات CRUD محصولات
  bool _isProductCrudLoading = false;
  bool get isProductCrudLoading => _isProductCrudLoading;

  /// ساخت محصول جدید از طریق API.
  ///
  /// در صورت موفقیت، محصول ساخته‌شده به لیست اضافه می‌شود.
  /// در صورت خطا، Exception پرتاب می‌شود و UI باید آن را نمایش دهد.
  Future<void> addProduct(Product product) async {
    final repo = _productRepository;
    if (repo == null) {
      throw StateError(
        'ProductRepository is not configured. Cannot create product.',
      );
    }

    _isProductCrudLoading = true;
    notifyListeners();

    try {
      final created = await repo.createProduct(product);
      _products.add(created);
      _pushNotification(
        AppNotification(
          type: NotificationType.newProduct,
          title: 'محصول جدید',
          message: 'محصول «${created.name}» به فروشگاه اضافه شد.',
          date: DateTime.now(),
          relatedId: created.id,
        ),
      );
      _catalogChanged();
      notifyListeners();
    } finally {
      _isProductCrudLoading = false;
      notifyListeners();
    }
  }

  /// ویرایش محصول از طریق API.
  ///
  /// در صورت موفقیت، محصول به‌روزرسانی‌شده جایگزین می‌شود.
  /// در صورت خطا، Exception پرتاب می‌شود و UI باید آن را نمایش دهد.
  Future<void> updateProduct(String id, Product updatedProduct) async {
    final repo = _productRepository;
    if (repo == null) {
      throw StateError(
        'ProductRepository is not configured. Cannot update product.',
      );
    }

    _isProductCrudLoading = true;
    notifyListeners();

    try {
      final updated = await repo.updateProduct(id, updatedProduct);
      final index = _products.indexWhere((p) => p.id == id);
      if (index >= 0) {
        _products[index] = updated;
      }
      _catalogChanged();
      notifyListeners();
    } finally {
      _isProductCrudLoading = false;
      notifyListeners();
    }
  }

  /// حذف محصول از طریق API.
  ///
  /// در صورت موفقیت، محصول از لیست حذف می‌شود.
  /// در صورت خطا، Exception پرتاب می‌شود و UI باید آن را نمایش دهد.
  Future<void> deleteProduct(String id) async {
    final repo = _productRepository;
    if (repo == null) {
      throw StateError(
        'ProductRepository is not configured. Cannot delete product.',
      );
    }

    _isProductCrudLoading = true;
    notifyListeners();

    try {
      await repo.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _catalogChanged();
      notifyListeners();
    } finally {
      _isProductCrudLoading = false;
      notifyListeners();
    }
  }

  // ── Warehouse / Stock ─────────────────────────────────────────
  final List<StockMovement> _stockHistory = [];
  List<StockMovement> get stockHistory => List.unmodifiable(_stockHistory);

  List<StockMovement> getStockHistoryForProduct(String productId) {
    return _stockHistory.where((m) => m.productId == productId).toList();
  }

  /// بارگذاری تاریخچه موجودی از Backend.
  Future<void> loadStockHistory() => _loadStockHistoryFromApi();

  Future<void> _loadStockHistoryFromApi() async {
    final repository = _warehouseRepository;
    if (repository == null) return;

    _isLoadingStockHistory = true;
    notifyListeners();

    try {
      final history = await repository.fetchStockHistory();
      _stockHistory
        ..clear()
        ..addAll(history);
    } catch (_) {
      // خطا بی‌صدا نادیده گرفته می‌شود - فقط UI را notify می‌کنیم
    } finally {
      _isLoadingStockHistory = false;
      notifyListeners();
    }
  }

  /// ثبت تغییر موجودی در Backend.
  ///
  /// موجودی می‌تواند منفی شود - هیچ شرطی برای جلوگیری از منفی شدن
  /// وجود ندارد.
  ///
  /// در صورت موفقیت، تاریخچه از Backend به‌روزرسانی می‌شود.
  Future<void> adjustStock(
    String productId,
    int change,
    String reason, {
    bool notify = true,
  }) async {
    final repository = _warehouseRepository;
    if (repository == null) {
      throw StateError(
        'WarehouseRepository is not configured. Cannot adjust stock.',
      );
    }

    _isAdjustingStock = true;
    if (notify) notifyListeners();

    try {
      final updatedHistory = await repository.adjustStock(
        productId: productId,
        change: change,
        reason: reason,
      );

      // تاریخچه را از پاسخ Backend به‌روزرسانی می‌کنیم
      _stockHistory
        ..clear()
        ..addAll(updatedHistory);

      // موجودی محصول را از تاریخچه محاسبه می‌کنیم
      final productIndex = _products.indexWhere((p) => p.id == productId);
      if (productIndex >= 0) {
        final totalChange = updatedHistory
            .where((m) => m.productId == productId)
            .fold<int>(0, (sum, m) => sum + m.quantityChange);
        _products[productIndex].stock = totalChange;
      }

      _catalogChanged();
    } finally {
      _isAdjustingStock = false;
      if (notify) notifyListeners();
    }
  }

  // ── Banners ──────────────────────────────────────────────────
  final List<PromoBanner> _banners = [];
  List<PromoBanner> get banners => List.unmodifiable(_banners);

  List<PromoBanner> get activeBanners {
    final active = _banners
        .where((b) => b.isActive && b.isCurrentlyInDateRange)
        .toList();
    active.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return active;
  }

  Future<void> loadBanners() => _loadBannersFromApi();

  Future<void> _loadBannersFromApi() async {
    final repository = _bannerRepository;
    if (repository == null) return;

    _isLoadingBanners = true;
    _bannersError = null;
    notifyListeners();

    try {
      final banners = await repository.fetchBanners();
      _banners
        ..clear()
        ..addAll(banners);
    } catch (e) {
      _bannersError = e.toString();
    } finally {
      _isLoadingBanners = false;
      notifyListeners();
    }
  }

  bool _isBannerCrudLoading = false;
  bool get isBannerCrudLoading => _isBannerCrudLoading;

  /// ساخت بنر جدید از طریق API.
  Future<void> addBanner(PromoBanner banner) async {
    final repo = _bannerRepository;
    if (repo == null) {
      throw StateError(
        'BannerRepository is not configured. Cannot create banner.',
      );
    }

    _isBannerCrudLoading = true;
    notifyListeners();

    try {
      final created = await repo.createBanner(banner);
      _banners.add(created);
      notifyListeners();
    } finally {
      _isBannerCrudLoading = false;
      notifyListeners();
    }
  }

  /// ویرایش بنر از طریق API.
  Future<void> updateBanner(String id, PromoBanner updated) async {
    final repo = _bannerRepository;
    if (repo == null) {
      throw StateError(
        'BannerRepository is not configured. Cannot update banner.',
      );
    }

    _isBannerCrudLoading = true;
    notifyListeners();

    try {
      final result = await repo.updateBanner(id, updated);
      final index = _banners.indexWhere((b) => b.id == id);
      if (index >= 0) {
        _banners[index] = result;
      }
      notifyListeners();
    } finally {
      _isBannerCrudLoading = false;
      notifyListeners();
    }
  }

  /// حذف بنر از طریق API.
  Future<void> deleteBanner(String id) async {
    final repo = _bannerRepository;
    if (repo == null) {
      throw StateError(
        'BannerRepository is not configured. Cannot delete banner.',
      );
    }

    _isBannerCrudLoading = true;
    notifyListeners();

    try {
      await repo.deleteBanner(id);
      _banners.removeWhere((b) => b.id == id);
      notifyListeners();
    } finally {
      _isBannerCrudLoading = false;
      notifyListeners();
    }
  }

  /// تغییر وضعیت فعال/غیرفعال بنر در Backend.
  Future<void> toggleBannerActive(String id) async {
    final repo = _bannerRepository;
    if (repo == null) {
      throw StateError(
        'BannerRepository is not configured. Cannot toggle banner.',
      );
    }

    final index = _banners.indexWhere((b) => b.id == id);
    if (index < 0) return;

    final banner = _banners[index];
    final newActive = !banner.isActive;

    _isBannerCrudLoading = true;
    notifyListeners();

    try {
      final updated = await repo.updateBanner(
        id,
        banner.copyWith(isActive: newActive),
      );
      _banners[index] = updated;
      notifyListeners();
    } finally {
      _isBannerCrudLoading = false;
      notifyListeners();
    }
  }

  /// تغییر ترتیب بنر در Backend.
  Future<void> moveBanner(String id, int newSortOrder) async {
    final repo = _bannerRepository;
    if (repo == null) {
      throw StateError(
        'BannerRepository is not configured. Cannot move banner.',
      );
    }

    _isBannerCrudLoading = true;
    notifyListeners();

    try {
      await repo.reorderBanner(id, newSortOrder);
      final index = _banners.indexWhere((b) => b.id == id);
      if (index >= 0) {
        _banners[index].sortOrder = newSortOrder;
      }
      notifyListeners();
    } finally {
      _isBannerCrudLoading = false;
      notifyListeners();
    }
  }

  ///  Compatibility: moveBannerUp / moveBannerDown
  Future<void> moveBannerUp(String id) async {
    final ordered = [..._banners]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final idx = ordered.indexWhere((b) => b.id == id);
    if (idx > 0) {
      await moveBanner(id, ordered[idx - 1].sortOrder);
    }
  }

  ///  Compatibility: moveBannerDown
  Future<void> moveBannerDown(String id) async {
    final ordered = [..._banners]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final idx = ordered.indexWhere((b) => b.id == id);
    if (idx >= 0 && idx < ordered.length - 1) {
      await moveBanner(id, ordered[idx + 1].sortOrder);
    }
  }

  // ── Notifications ─────────────────────────────────────────────
  static const int _maxNotifications = 200;
  final List<AppNotification> _notifications = [];

  void _pushNotification(AppNotification notification) {
    _notifications.add(notification);
    if (_notifications.length > _maxNotifications) {
      _notifications.removeRange(0, _notifications.length - _maxNotifications);
    }
  }

  /// بارگذاری اعلان‌ها از Backend.
  Future<void> loadNotifications() async {
    final repository = _notificationRepository;
    if (repository == null) return;

    _isLoadingNotifications = true;
    notifyListeners();

    try {
      final notifications = await repository.fetchNotifications();
      _notifications
        ..clear()
        ..addAll(notifications);
    } catch (_) {
      // خطا بی‌صدا نادیده گرفته می‌شود
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  List<AppNotification> notificationsFor(String? userId) {
    return _notifications
        .where((n) => n.targetUserId == null || n.targetUserId == userId)
        .toList();
  }

  int unreadNotificationCountFor(String? userId) =>
      notificationsFor(userId).where((n) => !n.isRead).length;

  Future<void> markAllNotificationsRead(String? userId) async {
    for (final n in notificationsFor(userId)) {
      n.isRead = true;
    }
    notifyListeners();

    final repository = _notificationRepository;
    if (repository != null) {
      try {
        await repository.markAllAsRead();
      } catch (_) {
        // خطا بی‌صدا نادیده گرفته می‌شود
      }
    }
  }

  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();

      final repository = _notificationRepository;
      if (repository != null) {
        try {
          await repository.markAsRead(id);
        } catch (_) {
          // خطا بی‌صدا نادیده گرفته می‌شود
        }
      }
    }
  }

  Future<void> deleteNotification(String id) async {
    final lengthBefore = _notifications.length;
    _notifications.removeWhere((n) => n.id == id);
    if (_notifications.length != lengthBefore) {
      notifyListeners();

      final repository = _notificationRepository;
      if (repository != null) {
        try {
          await repository.deleteNotification(id);
        } catch (_) {
          // خطا بی‌صدا نادیده گرفته می‌شود
        }
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
}
