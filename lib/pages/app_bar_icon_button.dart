import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../responsive.dart';

/// دکمه‌ی آیکونی مشترک برای اکشن‌های AppBar (سبد خرید، اعلان‌ها، پروفایل).
///
/// - Touch Target استاندارد و یکسان، ریسپانسیو برای گوشی تا ویندوز
///   (روی گوشی حداقل 44، روی دسکتاپ کمی بزرگ‌تر برای کلیک راحت‌تر با ماوس)
/// - Badge اختیاری روی گوشه‌ی آیکون
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color iconColor;
  final Widget? badge;
  final double? size;

  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.iconColor = AppColors.primaryWhite,
    this.badge,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final ui = context.uiScale;

    // سایز آیکون: پیش‌فرض بر اساس نوع دستگاه
    final iconSize =
        size ??
        context.responsive<double>(mobile: 22, tablet: 24, desktop: 24) *
            ui.clamp(0.95, 1.1);

    // Touch target: روی گوشی حداقل 44، روی دسکتاپ بزرگتر
    final hitSize =
        context.responsive<double>(mobile: 44, tablet: 46, desktop: 48) *
        ui.clamp(0.98, 1.08);

    // موقعیت badge (روی گوشی‌های کوچیک کمی نزدیک‌تر به مرکز)
    final badgeTop = hitSize * 0.09;
    final badgeRight = hitSize * 0.09;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: hitSize,
            height: hitSize,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: iconColor, size: iconSize),
                if (badge != null)
                  Positioned(top: badgeTop, right: badgeRight, child: badge!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge عددی کوچک (برای سبد خرید). بیشتر از ۹۹ → «99+».
class CountBadge extends StatelessWidget {
  final int count;
  const CountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final ui = context.uiScale;
    final fs = context.fontScale;

    final text = count > 99 ? '99+' : '$count';

    // حداقل ابعاد و پدینگ بر اساس uiScale
    final minSize = 16.0 * ui.clamp(0.95, 1.15);
    final hPad = 4.0 * ui.clamp(0.95, 1.2);
    final fontSize = (9.0 * fs).clamp(8.5, 11.5);

    return Container(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      padding: EdgeInsets.symmetric(horizontal: hPad),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primaryBlack,
          width: 1.2 * ui.clamp(0.95, 1.2),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.primaryWhite,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
}

/// نقطه‌ی کوچک برای Badge اعلان‌های نخوانده.
class DotBadge extends StatelessWidget {
  const DotBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.uiScale;
    final size = 10.0 * ui.clamp(0.9, 1.2);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.warning,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryBlack,
          width: 1.2 * ui.clamp(0.95, 1.2),
        ),
      ),
    );
  }
}
