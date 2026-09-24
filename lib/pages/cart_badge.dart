import 'package:flutter/material.dart';
import 'app_bar_icon_button.dart';
import '../../theme.dart';

/// دکمه‌ی سبد خرید در AppBar.
///
/// [itemCount] عمداً از بیرون (مثلاً از `StoreProvider`) دریافت می‌شود و
/// این ویجت خودش هیچ وابستگی‌ای به Provider یا هر State Management خاصی
/// ندارد.
///
/// این ویجت خودش ریسپانسیو است چون:
/// - از `AppBarIconButton` استفاده می‌کند که سایز لمس و آیکون را با
///   `uiScale` هماهنگ می‌کند.
/// - از `CountBadge` استفاده می‌کند که ابعاد و فونتش را با `uiScale`
///   و `fontScale` تطبیق می‌دهد.
/// بنابراین نیازی به تنظیم سایز دستی در این فایل نیست.
class CartBadge extends StatelessWidget {
  final int itemCount;
  final VoidCallback onTap;
  final Color iconColor;

  const CartBadge({
    super.key,
    required this.itemCount,
    required this.onTap,
    this.iconColor = AppColors.primaryWhite,
  });

  @override
  Widget build(BuildContext context) {
    return AppBarIconButton(
      icon: Icons.shopping_cart_outlined,
      tooltip: 'سبد خرید',
      onTap: onTap,
      iconColor: iconColor,
      // اگر تعداد صفر باشد، Badge نمایش داده نمی‌شود.
      badge: itemCount > 0 ? CountBadge(count: itemCount) : null,
    );
  }
}
