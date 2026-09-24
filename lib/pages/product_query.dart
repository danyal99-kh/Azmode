import 'package:flutter/foundation.dart';

enum ProductSort { newest, priceAsc, priceDesc, nameAsc, popular }

enum StockFilter { all, inStock, outOfStock }

const _arabicIndicDigits =
    '\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669';
const _persianDigits =
    '\u06F0\u06F1\u06F2\u06F3\u06F4\u06F5\u06F6\u06F7\u06F8\u06F9';

/// یکسان‌سازی متن فارسی برای جستجو:
/// - «ي/ى» عربی → «ی»، «ك» عربی → «ک»
/// - ارقام فارسی/عربی → لاتین
/// - حذف نیم‌فاصله (تا «نقره‌ای» و «نقرهای» یکی حساب شوند)
/// - حروف کوچک، فاصله‌های اضافه حذف
String normalizeFa(String input) {
  final out = StringBuffer();
  for (final rune in input.trim().toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    if (ch == '\u200c' || ch == '\u200e' || ch == '\u200f') continue;
    if (ch == '\u064A' || ch == '\u0649') {
      out.write('\u06CC');
      continue;
    }
    if (ch == '\u0643') {
      out.write('\u06A9');
      continue;
    }
    final a = _arabicIndicDigits.indexOf(ch);
    if (a >= 0) {
      out.write(a);
      continue;
    }
    final p = _persianDigits.indexOf(ch);
    if (p >= 0) {
      out.write(p);
      continue;
    }
    out.write(ch);
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ');
}

/// همه‌ی شرط‌های فیلتر/مرتب‌سازی یک لیست محصول در یک شیء Immutable.
/// همین شیء مستقیماً به Query Parameterهای API نگاشت می‌شود.
@immutable
class ProductQuery {
  final String search;
  final String? categoryId;
  final ProductSort sort;
  final StockFilter stock;
  final double? minPrice;
  final double? maxPrice;

  const ProductQuery({
    this.search = '',
    this.categoryId,
    this.sort = ProductSort.newest,
    this.stock = StockFilter.all,
    this.minPrice,
    this.maxPrice,
  });

  ProductQuery copyWith({
    String? search,
    String? categoryId,
    bool clearCategory = false,
    ProductSort? sort,
    StockFilter? stock,
    double? minPrice,
    double? maxPrice,
    bool clearPrice = false,
  }) {
    return ProductQuery(
      search: search ?? this.search,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      sort: sort ?? this.sort,
      stock: stock ?? this.stock,
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
    );
  }

  /// بدون هیچ فیلتر/جستجو، مرتب‌سازی پیش‌فرض.
  bool get isDefault =>
      normalizeFa(search).isEmpty &&
      categoryId == null &&
      sort == ProductSort.newest &&
      stock == StockFilter.all &&
      minPrice == null &&
      maxPrice == null;

  /// کلید یکتا برای Cache و مقایسه.
  String get cacheKey =>
      'q=${normalizeFa(search)}|c=${categoryId ?? ''}|s=${sort.name}'
      '|st=${stock.name}|min=${minPrice ?? ''}|max=${maxPrice ?? ''}';

  /// نمونه‌ی نگاشت به Query Parameter برای API واقعی.
  Map<String, String> toQueryParameters() => {
    if (normalizeFa(search).isNotEmpty) 'q': search.trim(),
    if (categoryId != null) 'category': categoryId!,
    'sort': switch (sort) {
      ProductSort.newest => 'newest',
      ProductSort.priceAsc => 'price_asc',
      ProductSort.priceDesc => 'price_desc',
      ProductSort.nameAsc => 'name',
      ProductSort.popular => 'popular',
    },
    if (stock == StockFilter.inStock) 'in_stock': 'true',
    if (stock == StockFilter.outOfStock) 'in_stock': 'false',
    if (minPrice != null) 'min_price': '$minPrice',
    if (maxPrice != null) 'max_price': '$maxPrice',
  };

  @override
  bool operator ==(Object other) =>
      other is ProductQuery && other.cacheKey == cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;
}
