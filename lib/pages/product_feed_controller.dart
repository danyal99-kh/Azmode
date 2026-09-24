import 'dart:async';
import 'package:azmode/pages/paged_list_controller.dart';
import 'package:azmode/pages/paged_result.dart';
import 'package:azmode/pages/product_query.dart';
import 'package:azmode/pages/product_repository.dart';
import 'package:flutter/foundation.dart';

import '../model.dart';

/// State یک «فید محصولات»: Query فعلی + لیست صفحه‌بندی‌شده.
///
/// - تغییر Query (جستجو/دسته/مرتب‌سازی/فیلتر) → لیست از صفحه‌ی ۱ و
///   درخواست‌های قبلی باطل می‌شوند (Race Condition ندارد).
/// - جستجو Debounce دارد.
/// - UI هیچ‌وقت مستقیماً با Repository/API صحبت نمی‌کند.
class ProductFeedController extends PagedListController<Product> {
  ProductFeedController({
    required ProductRepository repository,
    Listenable? invalidation,
    ProductQuery initialQuery = const ProductQuery(),
    this.basePageSize = 20,
    this.unfilteredLimit,
    this.searchDebounce = const Duration(milliseconds: 350),
    super.requestTimeout,
  }) : _repository = repository,
       _invalidation = invalidation,
       _query = initialQuery {
    _invalidation?.addListener(_onCatalogInvalidated);
  }

  final ProductRepository _repository;
  final Listenable? _invalidation;

  /// اندازه‌ی هر صفحه در حالت فیلتر/جستجو/لیست کامل.
  final int basePageSize;

  /// اگر مقدار داشته باشد و Query پیش‌فرض باشد (بدون فیلتر)، فقط همین
  /// تعداد اول نمایش داده می‌شود و Pagination انجام نمی‌شود
  /// (مثل «جدیدترین محصولات» صفحه‌ی اصلی).
  final int? unfilteredLimit;

  final Duration searchDebounce;

  ProductQuery _query;
  Timer? _debounce;
  Timer? _invalidateTimer;

  ProductQuery get query => _query;
  bool get isFiltering => !_query.isDefault;

  @override
  int get pageSize => (unfilteredLimit != null && _query.isDefault)
      ? unfilteredLimit!
      : basePageSize;

  @override
  int? get maxItems => _query.isDefault ? unfilteredLimit : null;

  @override
  String idOf(Product item) => item.id;

  @override
  Future<PagedResult<Product>> fetchPage(PageRequest request) =>
      _repository.fetchProducts(_query, request);

  // ── تغییر Query ───────────────────────────────────────────────

  /// جستجو با Debounce. پاک‌کردن متن فوراً اعمال می‌شود.
  void setSearch(String text, {bool clearCategory = false}) {
    _debounce?.cancel();
    final next = _query.copyWith(search: text, clearCategory: clearCategory);
    if (next == _query) return; // مثلاً فقط فاصله اضافه شد
    if (normalizeFa(text).isEmpty) {
      _apply(next);
      return;
    }
    _debounce = Timer(searchDebounce, () => _apply(next));
  }

  void setCategory(String? categoryId, {bool clearSearch = false}) {
    _debounce?.cancel();
    _apply(
      _query.copyWith(
        categoryId: categoryId,
        clearCategory: categoryId == null,
        search: clearSearch ? '' : null,
      ),
    );
  }

  void setSort(ProductSort sort) {
    _debounce?.cancel();
    _apply(_query.copyWith(sort: sort));
  }

  void setStockFilter(StockFilter stock) {
    _debounce?.cancel();
    _apply(_query.copyWith(stock: stock));
  }

  void setPriceRange({double? min, double? max}) {
    _debounce?.cancel();
    _apply(
      _query.copyWith(
        minPrice: min,
        maxPrice: max,
        clearPrice: min == null && max == null,
      ),
    );
  }

  void _apply(ProductQuery next) {
    if (next == _query) return;
    _query = next;
    savedScrollOffset = 0;
    unawaited(reload(clearItems: true));
  }

  // ── Refresh / Invalidation ────────────────────────────────────

  @override
  Future<void> refresh() {
    _repository.invalidate(); // Pull-to-Refresh باید از Cache رد شود
    return super.refresh();
  }

  /// از StoreProvider.catalogRevision صدا زده می‌شود (تغییر محصول/موجودی).
  /// - اگر صفحه‌ای همین الان این فید را نمایش می‌دهد → بعد از یک وقفه‌ی
  ///   کوتاه (تجمیع تغییرات پشت‌سرهم) بی‌صدا Refresh می‌شود.
  /// - وگرنه فقط «قدیمی» علامت می‌خورد و دفعه‌ی بعدی که صفحه باز شد
  ///   (ensureLoaded) بازخوانی می‌شود.
  void _onCatalogInvalidated() {
    _repository.invalidate();
    if (!started) return;
    if (hasListeners) {
      _invalidateTimer?.cancel();
      _invalidateTimer = Timer(const Duration(milliseconds: 400), () {
        unawaited(refresh());
      });
    } else {
      markStale();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _invalidateTimer?.cancel();
    _invalidation?.removeListener(_onCatalogInvalidated);
    super.dispose();
  }
}

/// نمونه‌های جدا برای Provider (Provider بر اساس نوع دقیق پیدا می‌کند).
class HomeFeedController extends ProductFeedController {
  HomeFeedController({
    required super.repository,
    super.invalidation,
    super.basePageSize,
    super.unfilteredLimit,
  });
}

class CategoryFeedController extends ProductFeedController {
  CategoryFeedController({
    required super.repository,
    super.invalidation,
    super.basePageSize,
  });
}
