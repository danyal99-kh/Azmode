import 'dart:collection';
import 'dart:math' as math;
import '../model.dart';
import 'paged_result.dart';
import 'product_query.dart';

/// تنها نقطه‌ی دسترسی UI/State به داده‌ی محصولات.
///
/// وقتی Backend واقعی آماده شد، فقط یک پیاده‌سازی جدید
/// (مثلاً `ApiProductRepository`) ساخته و در main.dart جایگزین
/// `LocalProductRepository` می‌شود؛ هیچ Widget یا Controller ای تغییر نمی‌کند.
abstract class ProductRepository {
  Future<PagedResult<Product>> fetchProducts(
    ProductQuery query,
    PageRequest request,
  );

  Future<Product?> fetchProduct(String id);

  /// همه‌ی Cache ها را باطل می‌کند (Pull-to-Refresh، تغییر موجودی و ...).
  void invalidate();
}

// ═══════════════════════════════════════════════════════════════
// پیاده‌سازی موقت: کار Backend را روی لیست داخل حافظه شبیه‌سازی می‌کند
// (فیلتر، مرتب‌سازی، صفحه‌بندی). فقط تا زمان اتصال API واقعی.
// ═══════════════════════════════════════════════════════════════
class LocalProductRepository implements ProductRepository {
  LocalProductRepository({
    required this.source,
    this.latency = const Duration(milliseconds: 250),
  });

  final List<Product> Function() source;

  /// تاخیر مصنوعی شبکه. برای تست‌ها `Duration.zero` بدهید.
  final Duration latency;

  static const int _maxCachedQueries = 6;

  // نتیجه‌ی فیلتر+مرتب‌سازی هر Query — تا با هر صفحه دوباره روی همه‌ی
  // محصولات محاسبه نشود.
  final LinkedHashMap<String, List<Product>> _results =
      LinkedHashMap<String, List<Product>>();

  // متن نرمال‌شده‌ی هر محصول برای جستجو (یک‌بار محاسبه می‌شود).
  final Expando<String> _haystacks = Expando<String>('product-haystack');

  @override
  Future<PagedResult<Product>> fetchProducts(
    ProductQuery query,
    PageRequest request,
  ) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    final all = _resolve(query);
    final start = (request.page - 1) * request.pageSize;
    if (start < 0 || start >= all.length) {
      return PagedResult<Product>(
        items: const [],
        hasMore: false,
        total: all.length,
      );
    }
    final end = math.min(start + request.pageSize, all.length);
    return PagedResult<Product>(
      items: all.sublist(start, end),
      hasMore: end < all.length,
      total: all.length,
    );
  }

  @override
  Future<Product?> fetchProduct(String id) async {
    for (final p in source()) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  void invalidate() => _results.clear();

  List<Product> _resolve(ProductQuery q) {
    final key = q.cacheKey;
    final cached = _results.remove(key);
    if (cached != null) {
      _results[key] = cached; // LRU
      return cached;
    }

    final tokens = normalizeFa(
      q.search,
    ).split(' ').where((t) => t.isNotEmpty).toList();

    final list = <Product>[];
    for (final p in source()) {
      if (q.categoryId != null && p.categoryId != q.categoryId) continue;
      if (q.stock == StockFilter.inStock && !p.isAvailable) continue;
      if (q.stock == StockFilter.outOfStock && p.isAvailable) continue;
      if (q.minPrice != null && p.price < q.minPrice!) continue;
      if (q.maxPrice != null && p.price > q.maxPrice!) continue;
      if (tokens.isNotEmpty) {
        final hay = _haystack(p);
        if (!tokens.every((t) => hay.contains(t))) continue;
      }
      list.add(p);
    }
    list.sort(_comparator(q.sort));

    _results[key] = list;
    while (_results.length > _maxCachedQueries) {
      _results.remove(_results.keys.first);
    }
    return list;
  }

  String _haystack(Product p) {
    return _haystacks[p] ??= normalizeFa(
      '${p.name} ${p.brand ?? ''} ${p.sku ?? ''} ${p.description}',
    );
  }

  // مرتب‌سازی پایدار: در تساوی، با id مرتب می‌شود تا Pagination
  // بین صفحه‌ها آیتم تکراری/گم‌شده نسازد.
  int Function(Product, Product) _comparator(ProductSort sort) {
    int Function(Product, Product) base;
    switch (sort) {
      case ProductSort.priceAsc:
        base = (a, b) => a.price.compareTo(b.price);
      case ProductSort.priceDesc:
        base = (a, b) => b.price.compareTo(a.price);
      case ProductSort.nameAsc:
        base = (a, b) => a.name.compareTo(b.name);
      case ProductSort.newest:
      case ProductSort.popular: // داده‌ی «محبوبیت» هنوز وجود ندارد
        base = (a, b) => b.createdAt.compareTo(a.createdAt);
    }
    return (a, b) {
      final c = base(a, b);
      return c != 0 ? c : a.id.compareTo(b.id);
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// Decorator: Cache کوتاه‌مدت + جلوگیری از درخواست همزمان تکراری
// روی هر ProductRepository ای (Local یا API) قابل استفاده است.
// ═══════════════════════════════════════════════════════════════
class CachedProductRepository implements ProductRepository {
  CachedProductRepository(
    this._inner, {
    this.ttl = const Duration(seconds: 60),
    this.maxEntries = 60,
  });

  final ProductRepository _inner;
  final Duration ttl;
  final int maxEntries;

  final LinkedHashMap<String, _CacheEntry> _cache =
      LinkedHashMap<String, _CacheEntry>();
  final Map<String, Future<PagedResult<Product>>> _inFlight = {};

  // با هر invalidate عوض می‌شود تا پاسخِ درخواستِ قدیمی (که هنوز در راه
  // بود) دوباره داده‌ی کهنه را داخل Cache ننویسد.
  int _epoch = 0;

  @override
  Future<PagedResult<Product>> fetchProducts(
    ProductQuery query,
    PageRequest request,
  ) {
    final key =
        '${query.cacheKey}|p${request.page}|c${request.cursor ?? ''}'
        '|n${request.pageSize}';

    final hit = _cache.remove(key);
    if (hit != null && DateTime.now().difference(hit.storedAt) < ttl) {
      _cache[key] = hit; // LRU
      return Future<PagedResult<Product>>.value(hit.result);
    }

    // اگر همین درخواست همین الان در راه است، همان را برگردان.
    final pending = _inFlight[key];
    if (pending != null) return pending;

    final epoch = _epoch;
    final future = _inner
        .fetchProducts(query, request)
        .then((result) {
          if (epoch == _epoch) {
            _cache[key] = _CacheEntry(result, DateTime.now());
            while (_cache.length > maxEntries) {
              _cache.remove(_cache.keys.first);
            }
          }
          return result;
        })
        .whenComplete(() {
          if (epoch == _epoch) _inFlight.remove(key);
        });
    _inFlight[key] = future;
    return future;
  }

  @override
  Future<Product?> fetchProduct(String id) => _inner.fetchProduct(id);

  @override
  void invalidate() {
    _epoch++;
    _cache.clear();
    _inFlight.clear();
    _inner.invalidate();
  }
}

class _CacheEntry {
  final PagedResult<Product> result;
  final DateTime storedAt;
  const _CacheEntry(this.result, this.storedAt);
}
