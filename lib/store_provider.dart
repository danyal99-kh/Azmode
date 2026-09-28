import 'dart:collection';

import 'package:azmode/model.dart';
import 'package:flutter/foundation.dart';

import 'pages/category_repository.dart';
import 'pages/packaging_type_repository.dart';
import 'pages/product_repository.dart';
import 'pages/product_query.dart';
import 'pages/paged_result.dart';
import 'pages/api_warehouse_repository.dart';

class StoreProvider extends ChangeNotifier {
  StoreProvider({
    CategoryRepository? categoryRepository,
    PackagingTypeRepository? packagingTypeRepository,
    ProductRepository? productRepository,
    ApiWarehouseRepository? warehouseRepository,
  }) : _categoryRepository = categoryRepository,
       _packagingTypeRepository = packagingTypeRepository,
       _productRepository = productRepository,
       _warehouseRepository = warehouseRepository;

  final CategoryRepository? _categoryRepository;
  final PackagingTypeRepository? _packagingTypeRepository;
  final ProductRepository? _productRepository;
  final ApiWarehouseRepository? _warehouseRepository;

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

  bool _isLoadingProducts = false;
  bool get isLoadingProducts => _isLoadingProducts;

  String? _productsError;
  String? get productsError => _productsError;

  bool _isAdjustingStock = false;
  bool get isAdjustingStock => _isAdjustingStock;

  // ── Refresh (Pull to Refresh) ──────────────────────────────────
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  Future<void> refreshStore() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      await Future.wait([
        _loadCategoriesFromApi(),
        _loadPackagingTypesFromApi(),
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

  Future<void> loadProducts() => _loadProductsFromApi();

  Future<void> _loadProductsFromApi() async {
    final repo = _productRepository;
    if (repo == null) return;

    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
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

  bool _isProductCrudLoading = false;
  bool get isProductCrudLoading => _isProductCrudLoading;

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
      _catalogChanged();
      notifyListeners();
    } finally {
      _isProductCrudLoading = false;
      notifyListeners();
    }
  }

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

  /// ثبت تغییر موجودی در Backend.
  ///
  /// موجودی می‌تواند منفی شود - هیچ شرطی برای جلوگیری از منفی شدن
  /// وجود ندارد.
  ///
  /// در صورت موفقیت، مقدار new_stock از response Backend برمی‌گردد
  /// و در UI نمایش داده می‌شود.
  Future<int> adjustStock(
    String productId,
    int change,
    String reason,
  ) async {
    final repository = _warehouseRepository;
    if (repository == null) {
      throw StateError(
        'WarehouseRepository is not configured. Cannot adjust stock.',
      );
    }

    _isAdjustingStock = true;
    notifyListeners();

    try {
      final newStock = await repository.adjustStock(
        productId: productId,
        change: change,
        reason: reason,
      );

      // موجودی محصول را از response Backend به‌روزرسانی می‌کنیم
      final productIndex = _products.indexWhere((p) => p.id == productId);
      if (productIndex >= 0) {
        _products[productIndex].stock = newStock;
      }

      _catalogChanged();
      return newStock;
    } finally {
      _isAdjustingStock = false;
      notifyListeners();
    }
  }
}
