import 'dart:math' as math;
import 'package:azmode/theme.dart';
import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // ابعاد ثابت نوار و دکمه‌ی خانه. این‌ها به‌صورت ثابت نگه داشته شده‌اند
  // (نه Hard-code پراکنده در build) تا محاسبه‌ی ارتفاع کل ناحیه‌ی
  // لمس‌پذیر از روی همین مقادیر و به‌صورت دقیق انجام شود.
  static const double _barHeight = 65;
  static const double _homeButtonSize = 60;
  static const double _homeButtonBottomOffset = 25;

  @override
  Widget build(BuildContext context) {
    // باگ قبلی: دکمه‌ی خانه با Positioned(bottom: 25) و ارتفاع 60 از
    // بالای Container با ارتفاع ثابت 65 حدود 20 پیکسل بیرون می‌زد.
    // چون Stack با Clip.none بود، این 20 پیکسل به‌صورت بصری دیده
    // می‌شد، اما چون خارج از اندازه‌ی واقعی (bounding box) خودِ ویجت
    // بود، فلاتر لمس (Hit-test) را در آن ناحیه انجام نمی‌داد — یعنی
    // دکمه دیده می‌شد ولی قابل لمس نبود.
    //
    // راه‌حل: کل ارتفاعی که واقعاً باید لمس‌پذیر باشد را محاسبه
    // می‌کنیم (حداکثرِ ارتفاع خودِ نوار و ارتفاع کامل دکمه‌ی خانه با
    // احتساب فاصله‌اش از پایین)، و SizedBox بیرونی را دقیقاً به همان
    // اندازه می‌سازیم. این‌طور کل دکمه‌ی خانه داخل محدوده‌ی لمس‌پذیر
    // این ویجت قرار می‌گیرد.
    final double totalHeight = math.max(
      _barHeight,
      _homeButtonBottomOffset + _homeButtonSize,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // نوار اصلی: پس‌زمینه‌ی تیره + آیتم‌های معمولی (به جز خانه)
            Container(
              height: _barHeight,
              decoration: BoxDecoration(
                color: AppColors.primaryBlack,
                borderRadius: BorderRadius.circular(18), // گوشه‌های گرد
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    0,
                    Icons.shopping_cart_outlined,
                    Icons.shopping_cart,
                    'سبد خرید',
                  ),
                  _buildNavItem(
                    1,
                    Icons.category_outlined,
                    Icons.category,
                    'دسته‌بندی‌ها',
                  ),
                  const SizedBox(width: 30), // فضای خالی برای دکمه‌ی خانه
                  _buildNavItem(
                    3,
                    Icons.receipt_long_outlined,
                    Icons.receipt_long,
                    'پیش‌فاکتور',
                  ),
                  _buildNavItem(
                    4,
                    Icons.person_outline,
                    Icons.person,
                    'پروفایل',
                  ),
                ],
              ),
            ),
            // دکمه‌ی خانه (بیرون‌زده از بالای نوار)؛ حالا چون SizedBox
            // بیرونی به اندازه‌ی کافی بلند است، این Positioned کاملاً
            // داخل محدوده‌ی لمس‌پذیر قرار می‌گیرد.
            Positioned(
              bottom: _homeButtonBottomOffset,
              child: _buildHomeButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
                size: isSelected ? 28 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? AppColors.deepTeal : AppColors.primaryWhite,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeButton() {
    final isSelected = currentIndex == 2;
    return GestureDetector(
      onTap: () => onTap(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: _homeButtonSize,
        height: _homeButtonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.deepTeal : AppColors.primaryBlack,
          border: Border.all(
            color: isSelected ? AppColors.deepTeal : AppColors.primaryWhite,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.deepTeal.withValues(alpha: 0.5)
                  : Colors.black45,
              blurRadius: 20,
              spreadRadius: isSelected ? 4 : 2,
            ),
          ],
        ),
        child: const Icon(Icons.home, color: AppColors.primaryWhite, size: 32),
      ),
    );
  }
}
