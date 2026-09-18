import 'dart:math' as math;
import 'package:azmode/theme.dart';
import 'package:flutter/material.dart';
import '../responsive.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ui = context.uiScale;
    final fs = context.fontScale;

    // ── ابعاد ریسپانسیو ────────────────────────────────────────
    // روی گوشی کوچیک کمی جمع‌تر، روی تبلت کمی بازتر — با کلمپ محافظه‌کارانه
    final barHeight = (65.0 * ui).clamp(58.0, 74.0);
    final homeButtonSize = (60.0 * ui).clamp(54.0, 68.0);
    final homeButtonBottomOffset = (25.0 * ui).clamp(20.0, 30.0);

    // ارتفاع کل ناحیه‌ی لمس‌پذیر (باید حداقل ارتفاع نوار یا دکمه‌ی خانه با
    // احتساب آفست باشد — همان منطق نسخه‌ی قبل ولی با مقادیر ریسپانسیو)
    final totalHeight = math.max(
      barHeight,
      homeButtonBottomOffset + homeButtonSize,
    );

    // پدینگ بیرونی نوار
    final outerPadH = (10.0 * ui).clamp(8.0, 14.0);
    final outerPadV = (16.0 * ui).clamp(12.0, 20.0);

    // عرض فضای خالی وسط نوار برای دکمه‌ی خانه
    final centerGap = homeButtonSize * 0.5;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: outerPadH, vertical: outerPadV),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // ── نوار اصلی ──
            Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: AppColors.primaryBlack,
                borderRadius: BorderRadius.circular(
                  18.0 * ui.clamp(0.95, 1.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 20 * ui.clamp(0.9, 1.2),
                    offset: const Offset(0, 5),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    index: 0,
                    icon: Icons.shopping_cart_outlined,
                    selectedIcon: Icons.shopping_cart,
                    label: 'سبد خرید',
                    isSelected: currentIndex == 0,
                    onTap: onTap,
                    uiScale: ui,
                    fontScale: fs,
                  ),
                  _NavItem(
                    index: 1,
                    icon: Icons.category_outlined,
                    selectedIcon: Icons.category,
                    label: 'دسته‌بندی‌ها',
                    isSelected: currentIndex == 1,
                    onTap: onTap,
                    uiScale: ui,
                    fontScale: fs,
                  ),
                  SizedBox(width: centerGap),
                  _NavItem(
                    index: 3,
                    icon: Icons.receipt_long_outlined,
                    selectedIcon: Icons.receipt_long,
                    label: 'پیش‌فاکتور',
                    isSelected: currentIndex == 3,
                    onTap: onTap,
                    uiScale: ui,
                    fontScale: fs,
                  ),
                  _NavItem(
                    index: 4,
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'پروفایل',
                    isSelected: currentIndex == 4,
                    onTap: onTap,
                    uiScale: ui,
                    fontScale: fs,
                  ),
                ],
              ),
            ),

            // ── دکمه‌ی خانه ──
            Positioned(
              bottom: homeButtonBottomOffset,
              child: _HomeButton(
                isSelected: currentIndex == 2,
                size: homeButtonSize,
                onTap: () => onTap(2),
                uiScale: ui,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// آیتم معمولی نوار
// ═══════════════════════════════════════════════════════════════
class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final ValueChanged<int> onTap;
  final double uiScale;
  final double fontScale;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.uiScale,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    // سایز آیکون: عادی 22-24، انتخاب‌شده 26-29
    final iconSize = (22.0 * uiScale).clamp(20.0, 26.0);
    final iconSizeSelected = (26.0 * uiScale).clamp(24.0, 30.0);

    // فونت لیبل: بین 10 و 12.5
    final labelFontSize = (11.0 * fontScale).clamp(10.0, 12.5);

    // پدینگ داخلی آیتم (برای محدوده‌ی لمس)
    final vPad = (6.0 * uiScale).clamp(5.0, 8.0);
    final hPad = (10.0 * uiScale).clamp(8.0, 14.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20 * uiScale.clamp(0.95, 1.15)),
          color: isSelected
              ? AppColors.deepTeal.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isSelected ? selectedIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.deepTeal : AppColors.primaryWhite,
                size: isSelected ? iconSizeSelected : iconSize,
              ),
            ),
            SizedBox(height: (4.0 * uiScale).clamp(3.0, 5.0)),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? AppColors.deepTeal : AppColors.primaryWhite,
                fontSize: labelFontSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// دکمه‌ی خانه (بالای نوار)
// ═══════════════════════════════════════════════════════════════
class _HomeButton extends StatelessWidget {
  final bool isSelected;
  final double size;
  final VoidCallback onTap;
  final double uiScale;

  const _HomeButton({
    required this.isSelected,
    required this.size,
    required this.onTap,
    required this.uiScale,
  });

  @override
  Widget build(BuildContext context) {
    final borderWidth = (2.5 * uiScale).clamp(2.0, 3.0);
    final iconSize = (32.0 * uiScale).clamp(28.0, 36.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.deepTeal : AppColors.primaryBlack,
          border: Border.all(
            color: isSelected ? AppColors.deepTeal : AppColors.primaryWhite,
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.deepTeal.withValues(alpha: 0.5)
                  : Colors.black45,
              blurRadius: 20 * uiScale.clamp(0.9, 1.2),
              spreadRadius: isSelected ? 4 : 2,
            ),
          ],
        ),
        child: Icon(Icons.home, color: AppColors.primaryWhite, size: iconSize),
      ),
    );
  }
}
