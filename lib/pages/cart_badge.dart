import 'package:flutter/material.dart';
import 'app_bar_icon_button.dart';
import '../../theme.dart';

/// دکمه‌ی سبد خرید در AppBar.
///
/// [itemCount] عمداً از بیرون (مثلاً از `StoreProvider`) دریافت می‌شود و
/// این ویجت خودش هیچ وابستگی‌ای به Provider یا هر State Management خاصی
/// ندارد؛ این یعنی بعداً می‌توان همین ویجت را بدون تغییر، به هر منبع
/// داده‌ی دیگری (Riverpod، Bloc و ...) هم وصل کرد.
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
      // طبق نیازمندی: اگر تعداد صفر باشد، اصلاً Badge نمایش داده نشود.
      badge: itemCount > 0 ? CountBadge(count: itemCount) : null,
    );
  }
}
