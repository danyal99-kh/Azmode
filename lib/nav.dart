import 'package:azmode/pages_a/login/login_page.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'shell.dart';

import 'pages/home_page.dart';
import 'pages/categories_page.dart';
import 'pages/cart_page.dart';
import 'pages/proforma_page.dart';
import 'pages/profile_page.dart';
import 'pages/admin_page.dart';
import 'pages/product_details_page.dart';
import 'pages/notifications_page.dart';
import 'pages/all_products_page.dart';
import 'pages/all_categories_page.dart';

class AppRoutes {
  static const String login = '/login';

  static const String home = '/';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String proforma = '/proforma';
  static const String profile = '/profile';
  static const String admin = '/admin';
  static const String productDetails = '/product/:id';
  static const String notifications = '/notifications';
  static const String allProducts = '/products';
  static const String allCategories = '/categories/all';
}

class AppRouter {
  AppRouter._();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.home,

      refreshListenable: authProvider,

      redirect: (context, state) {
        final authStatus = authProvider.status;

        final isLoginPage = state.matchedLocation == AppRoutes.login;

        // هنوز وضعیت ورود مشخص نشده.
        if (authStatus == AuthStatus.initial ||
            authStatus == AuthStatus.loading) {
          return null;
        }

        // کاربر وارد نشده.
        if (authStatus == AuthStatus.unauthenticated ||
            authStatus == AuthStatus.error) {
          if (isLoginPage) {
            return null;
          }

          return AppRoutes.login;
        }

        // کاربر وارد شده و نباید دوباره Login را ببیند.
        if (authStatus == AuthStatus.authenticated) {
          if (isLoginPage) {
            return AppRoutes.home;
          }
        }

        return null;
      },

      routes: [
        // -------------------------
        // Login
        // -------------------------

        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) {
            return const LoginPage();
          },
        ),

        // -------------------------
        // Main App
        // -------------------------
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(child: child);
          },
          routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: HomePage());
              },
            ),

            GoRoute(
              path: AppRoutes.categories,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: CategoriesPage());
              },
            ),

            GoRoute(
              path: AppRoutes.allCategories,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: AllCategoriesPage());
              },
            ),

            GoRoute(
              path: AppRoutes.cart,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: CartPage());
              },
            ),

            GoRoute(
              path: AppRoutes.proforma,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: ProformaPage());
              },
            ),

            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: ProfilePage());
              },
            ),
          ],
        ),

        // -------------------------
        // Root pages
        // -------------------------
        GoRoute(
          path: AppRoutes.admin,
          builder: (context, state) {
            return const AdminPage();
          },
        ),

        GoRoute(
          path: AppRoutes.productDetails,
          builder: (context, state) {
            final id = state.pathParameters['id'];

            return ProductDetailsPage(productId: id ?? '');
          },
        ),

        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) {
            return const NotificationsPage();
          },
        ),

        GoRoute(
          path: AppRoutes.allProducts,
          builder: (context, state) {
            return const AllProductsPage();
          },
        ),
      ],
    );
  }
}
