import 'package:flutter/material.dart';

/// نگاشت نام رنگ (فارسی) به مقدار [Color] واقعی، برای نمایش دایره‌ی
/// رنگ یا رنگی‌کردن متن در جاهایی که رنگ محصول به‌صورت متن ذخیره شده
/// (سبد خرید، جزئیات محصول، فاکتورها و ...).
///
/// جایگزین چند نسخه‌ی تکراری همین منطق که قبلاً در فایل‌های مختلف
/// (proforma_page، product_details_page، admin_page) جداگانه تعریف
/// شده بودند.
Color? colorFromName(String colorName) {
  const colors = {
    'قرمز': Colors.red,
    'سبز': Colors.green,
    'آبی': Colors.blue,
    'زرد': Colors.yellow,
    'مشکی': Colors.black,
    'سفید': Colors.white,
    'نارنجی': Colors.orange,
    'بنفش': Colors.purple,
    'صورتی': Colors.pink,
    'طوسی': Colors.grey,
    'نقره‌ای': Colors.grey,
    'طلایی': Colors.amber,
    'قهوه‌ای': Colors.brown,
  };
  return colors[colorName];
}
