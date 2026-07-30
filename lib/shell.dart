import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // GoRouter uses the path to determine index
    final String location = GoRouterState.of(context).uri.path;

    int currentIndex = 2; // Default to Home
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
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
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
        backgroundColor: AppColors.primaryBlack,
        indicatorColor: AppColors.deepTeal.withValues(alpha: 0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.primaryWhite,
            ),
            selectedIcon: Icon(Icons.shopping_cart, color: AppColors.deepTeal),
            label: 'سبد خرید',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined, color: AppColors.primaryWhite),
            selectedIcon: Icon(Icons.category, color: AppColors.deepTeal),
            label: 'دسته‌بندی‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.primaryWhite),
            selectedIcon: Icon(Icons.home, color: AppColors.deepTeal),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primaryWhite,
            ),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.deepTeal),
            label: 'پیش‌فاکتور',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppColors.primaryWhite),
            selectedIcon: Icon(Icons.person, color: AppColors.deepTeal),
            label: 'پروفایل',
          ),
        ],
      ),
    );
  }
}
