import 'package:azmode/pages/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    int currentIndex = 2; // پیش‌فرض خانه
    if (location.startsWith('/cart')) {
      currentIndex = 0;
    } else if (location.startsWith('/categories')) {
      currentIndex = 1;
    } else if (location == '/' || location == '/home') {
      currentIndex = 2;
    } else if (location.startsWith('/proforma')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile') ||
        location.startsWith('/admin')) {
      currentIndex = 4;
    } else if (location.startsWith('/product/')) {
      currentIndex = 2;
    }

    return Scaffold(
      extendBody: true,
      // نکته‌ی مهم: این Scaffold بیرونیِ shell است و میزبان نوار پایین
      // (bottomNavigationBar) است. اگر resizeToAvoidBottomInset روی
      // مقدار پیش‌فرض (true) بماند، هر بار که کیبورد باز شود (مثلاً با
      // لمس فیلد جستجو در خانه، یا فرم‌های ادمین/پروفایل)، کل body این
      // Scaffold - که شامل نوار پایین هم می‌شود - به‌اندازه‌ی ارتفاع
      // کیبورد جمع و بالا کشیده می‌شود؛ در نتیجه نوار ناوبری از پایین
      // واقعی صفحه فاصله می‌گیرد و روی صفحه‌های کوچک یا landscape انگار
      // وسط صفحه معلق می‌ماند.
      //
      // با false کردن این مقدار، این Scaffold دیگر برای کیبورد جمع
      // نمی‌شود و نوار پایین همیشه در پایین واقعی صفحه ثابت می‌ماند.
      // مسئولیت جابه‌جایی محتوا برای کیبورد به عهده‌ی Scaffold داخلیِ
      // خود هر صفحه (HomePage/CartPage/ProfilePage/...) می‌ماند که
      // resizeToAvoidBottomInset آن‌ها هم‌چنان روی مقدار پیش‌فرض true
      // است، پس رفتار صحیح برای فیلدهای متنی آن صفحات حفظ می‌شود.
      resizeToAvoidBottomInset: false,
      // محتوای اصلی هر صفحه خودش مسئول محدود کردن عرض حداکثر روی
      // دسکتاپ/ویندوز است (از طریق context.centerMaxWidth).
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        // روی پنجره‌های خیلی عریض (ویندوز/دسکتاپ) نوار پایین در وسط با
        // عرض محدود نمایش داده می‌شود تا کشیده و نامتناسب نشود.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: CustomBottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/cart');
                    break;
                  case 1:
                    context.go('/categories');
                    break;
                  case 2:
                    context.go('/');
                    break;
                  case 3:
                    context.go('/proforma');
                    break;
                  case 4:
                    context.go('/profile');
                    break;
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
