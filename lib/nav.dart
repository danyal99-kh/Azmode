import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'shell.dart';
import 'pages/home_page.dart';
import 'pages/categories_page.dart';
import 'pages/cart_page.dart';
import 'pages/proforma_page.dart';
import 'pages/profile_page.dart';
import 'pages/admin_page.dart';
import 'pages/product_details_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String proforma = '/proforma';
  static const String profile = '/profile';
  static const String admin = '/admin';
  static const String productDetails = '/product/:id';
}

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: AppRoutes.categories,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CategoriesPage()),
          ),
          GoRoute(
            path: AppRoutes.cart,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CartPage()),
          ),
          GoRoute(
            path: AppRoutes.proforma,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProformaPage()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.admin,
        builder: (context, state) => const AdminPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.productDetails,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return ProductDetailsPage(productId: id ?? '');
        },
      ),
    ],
  );
}
