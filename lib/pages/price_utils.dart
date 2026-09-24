import 'package:intl/intl.dart' as intl;

/// فرمت‌کننده‌ی مشترک قیمت — عدد را با جداکننده‌ی سه‌رقمی (٬) و پسوند
/// «تومان» نمایش می‌دهد. با اعداد لاتین (نه فارسی) کار می‌کند تا در
/// تمام دستگاه‌ها یک‌شکل دیده شود.
///
/// مثال: formatToman(150000) → "150,000 تومان"
final _priceFormat = intl.NumberFormat('#,##0', 'en_US');

String formatToman(num amount) {
  return '${_priceFormat.format(amount)} تومان';
}

/// همان فرمت، بدون پسوند «تومان» — برای جاهایی که خودت می‌خوای متن
/// اضافه‌ای قبل/بعدش بذاری.
String formatPrice(num amount) {
  return _priceFormat.format(amount);
}
