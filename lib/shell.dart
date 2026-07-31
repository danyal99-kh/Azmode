import 'package:azmode/Pages/custom_bottom_nav.dart';
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
      body: child,
      bottomNavigationBar: CustomBottomNavigationBar(
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
    );
  }
}
