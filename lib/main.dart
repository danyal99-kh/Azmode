import 'package:azmode/Core/api/api_client.dart';
import 'package:azmode/models/proforma.dart';
import 'package:azmode/pages/api_category_repository.dart';
import 'package:azmode/pages/api_packaging_type_repository.dart';
import 'package:azmode/pages/api_product_repository.dart';
import 'package:azmode/pages/product_feed_controller.dart';
import 'package:azmode/pages/product_repository.dart';
import 'package:azmode/providers/auth_provider.dart';
import 'package:azmode/providers/cart_provider.dart';
import 'package:azmode/providers/proforma_provider.dart';
import 'package:azmode/services/auth_service.dart';
import 'package:azmode/services/cart_service.dart';
import 'package:azmode/services/profile_service.dart';
import 'package:azmode/services/proforma_service.dart';
import 'package:azmode/store_provider.dart';
import 'package:azmode/theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'nav.dart';

const String baseUrl = 'http://127.0.0.1:8000';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 400;
  imageCache.maximumSizeBytes = 120 << 20;

  runApp(
    MultiProvider(
      providers: [
        // ── API ──────────────────────────────────────────────
        Provider<ApiClient>(create: (_) => ApiClient(baseUrl: baseUrl)),

        // ── Authentication + Profile (منبع واحد: AuthProvider) ──
        Provider<AuthService>(
          create: (ctx) => AuthService(apiClient: ctx.read<ApiClient>()),
        ),
        Provider<ProfileService>(
          create: (ctx) => ProfileService(apiClient: ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) => AuthProvider(
            authService: ctx.read<AuthService>(),
            profileService: ctx.read<ProfileService>(),
          ),
        ),

        // ── Store / Catalog (بدون هیچ منطق auth) ──────────────
        ChangeNotifierProvider<StoreProvider>(
          create: (ctx) =>
              StoreProvider(
                  categoryRepository: ApiCategoryRepository(baseUrl: baseUrl),
                  packagingTypeRepository: ApiPackagingTypeRepository(
                    baseUrl: baseUrl,
                  ),
                )
                ..loadCategories()
                ..loadPackagingTypes(),
        ),
        // ── Cart ───────────────────────────────────────────────
        Provider<CartService>(
          create: (ctx) => CartService(apiClient: ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (ctx) => CartProvider(cartService: ctx.read<CartService>()),
        ),

        // ── Orders / Proforma (منبع واحد: ProformaProvider) ───
        Provider<ProformaService>(
          create: (ctx) => ProformaService(apiClient: ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider<ProformaProvider>(
          create: (ctx) => ProformaProvider(
            service: ctx.read<ProformaService>(),
            onStatusChanged: (order, previousStatus) {
              ctx.read<StoreProvider>().pushOrderStatusNotification(
                orderId: order.id,
                targetUserId: order.userId?.toString(),
                approved: order.status == ProformaStatus.approved,
              );
            },
          ),
        ),

        // ── Products ───────────────────────────────────────────
        Provider<ProductRepository>(
          create: (_) =>
              CachedProductRepository(ApiProductRepository(baseUrl: baseUrl)),
        ),
        ChangeNotifierProvider<HomeFeedController>(
          create: (ctx) => HomeFeedController(
            repository: ctx.read<ProductRepository>(),
            invalidation: ctx.read<StoreProvider>().catalogRevision,
            basePageSize: 20,
            unfilteredLimit: StoreProvider.homeLatestProductsLimit,
          ),
        ),

        ChangeNotifierProvider<CategoryFeedController>(
          create: (ctx) => CategoryFeedController(
            repository: ctx.read<ProductRepository>(),
            invalidation: ctx.read<StoreProvider>().catalogRevision,
            basePageSize: 20,
          ),
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
      if (!mounted) return;
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
