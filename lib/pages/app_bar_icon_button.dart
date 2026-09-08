import 'package:flutter/material.dart';
import '../../theme.dart';

/// دکمه‌ی آیکونی مشترک برای اکشن‌های AppBar (سبد خرید، اعلان‌ها، پروفایل).
///
/// مسئولیت این ویجت فقط دو چیز است:
/// 1) فراهم کردن یک Touch Target استاندارد و یکسان (44x44) برای همه‌ی
///    دکمه‌های اکشن، تا در گوشی و تبلت هم به‌راحتی قابل لمس باشند.
/// 2) نمایش یک Badge اختیاری روی گوشه‌ی آیکون، بدون این‌که این منطق در
///    هر دکمه (سبد خرید، اعلان‌ها و ...) جداگانه تکرار شود.
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color iconColor;
  final Widget? badge;
  final double size;

  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.iconColor = AppColors.primaryWhite,
    this.badge,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: iconColor, size: size),
                if (badge != null) Positioned(top: 4, right: 4, child: badge!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge عددی کوچک (برای سبد خرید). اگر تعداد بیش از ۹۹ باشد به‌صورت
/// «99+» نمایش داده می‌شود تا Layout بهم نریزد و عدد از دایره بیرون نزند.
class CountBadge extends StatelessWidget {
  final int count;
  const CountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primaryBlack, width: 1.2),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryWhite,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
    );
  }
}

/// نقطه‌ی کوچک برای Badge اعلان‌های نخوانده (بدون عدد؛ فقط نشان‌دهنده‌ی
/// وجود حداقل یک اعلان خوانده‌نشده است).
class DotBadge extends StatelessWidget {
  const DotBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.warning,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryBlack, width: 1.2),
      ),
    );
  }
}
