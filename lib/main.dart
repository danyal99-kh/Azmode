import 'package:azmode/Core/api/api_client.dart';
import 'package:azmode/pages/api_product_repository.dart';
import 'package:azmode/pages/product_feed_controller.dart';
import 'package:azmode/pages/product_repository.dart';
import 'package:azmode/providers/cart_provider.dart';
import 'package:azmode/services/%20cart_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'nav.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'store_provider.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final imageCache = PaintingBinding.instance.imageCache;

  imageCache.maximumSize = 400;
  imageCache.maximumSizeBytes = 120 << 20;

  runApp(
    MultiProvider(
      providers: [
        // -------------------------
        // API
        // -------------------------

        Provider<ApiClient>(
          create: (_) {
            return ApiClient(baseUrl: 'http://127.0.0.1:8000');
          },
        ),

        // -------------------------
        // Authentication
        // -------------------------
        Provider<AuthService>(
          create: (context) {
            return AuthService(apiClient: context.read<ApiClient>());
          },
        ),

        ChangeNotifierProvider<AuthProvider>(
          create: (context) {
            return AuthProvider(authService: context.read<AuthService>());
          },
        ),

        // -------------------------
        // Existing Store
        // -------------------------
        ChangeNotifierProvider<StoreProvider>(create: (_) => StoreProvider()),

        // -------------------------
        // Product Repository
        // -------------------------
        Provider<ProductRepository>(
          create: (_) {
            return CachedProductRepository(
              ApiProductRepository(baseUrl: 'http://127.0.0.1:8000'),
            );
          },
        ),

        // -------------------------
        // Home Products
        // -------------------------
        ChangeNotifierProvider<HomeFeedController>(
          create: (context) {
            return HomeFeedController(
              repository: context.read<ProductRepository>(),
              invalidation: context.read<StoreProvider>().catalogRevision,
              basePageSize: 20,
              unfilteredLimit: StoreProvider.homeLatestProductsLimit,
            );
          },
        ),

        // -------------------------
        // Category Products
        // -------------------------
        ChangeNotifierProvider<CategoryFeedController>(
          create: (context) {
            return CategoryFeedController(
              repository: context.read<ProductRepository>(),
              invalidation: context.read<StoreProvider>().catalogRevision,
              basePageSize: 20,
            );
          },
        ),
        Provider<CartService>(
          create: (context) =>
              CartService(apiClient: context.read<ApiClient>()),
        ),

        ChangeNotifierProvider<CartProvider>(
          create: (context) =>
              CartProvider(cartService: context.read<CartService>()),
        ),
      ],

      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final authProvider = context.read<AuthProvider>();

    _router = AppRouter.createRouter(authProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      authProvider.checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'سیستم سفارش‌گیری',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [Locale('fa', 'IR')],

      locale: const Locale('fa', 'IR'),

      theme: ThemeData(useMaterial3: true),

      routerConfig: _router,

      builder: (context, child) {
        final mq = MediaQuery.of(context);

        final clampedScaler = mq.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.25,
        );

        final responsiveTheme = buildAppTheme(context);

        return MediaQuery(
          data: mq.copyWith(textScaler: clampedScaler),
          child: Theme(
            data: responsiveTheme,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
