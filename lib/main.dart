import 'package:azmode/pages/product_feed_controller.dart';
import 'package:azmode/pages/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme.dart';
import 'nav.dart';
import 'store_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // سقف حافظه‌ی عکس‌های دیکود‌شده. (پیش‌فرض فلاتر ۱۰۰MB / ۱۰۰۰ عکس است؛
  // چون حالا عکس‌ها با اندازه‌ی کوچک دیکود می‌شوند تعداد کمتر و سقف
  // بایت مشخص‌تر کافی و امن‌تر است.)
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 400;
  imageCache.maximumSizeBytes = 120 << 20; // 120MB

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoreProvider()),

        // ── لایه‌ی داده ──────────────────────────────────────────
        // فعلاً Local (شبیه‌ساز Backend). وقتی API آماده شد فقط همین
        // یک خط عوض می‌شود: CachedProductRepository(ApiProductRepository(...))
        Provider<ProductRepository>(
          create: (ctx) {
            final store = ctx.read<StoreProvider>();
            return CachedProductRepository(
              LocalProductRepository(source: () => store.products),
            );
          },
        ),

        // ── فیدهای محصولات (در سطح اپ؛ با تعویض تب از بین نمی‌روند) ──
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

      // تم اولیه (فقط اسکلت؛ تم واقعی در builder تزریق می‌شود)
      theme: ThemeData(useMaterial3: true),

      routerConfig: AppRouter.router,

      builder: (context, child) {
        final mq = MediaQuery.of(context);

        // محدود کردن بزرگ‌نمایی سیستم (دسترسی‌پذیری)
        final clampedScaler = mq.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.25,
        );

        // ساخت تم ریسپانسیو بر اساس عرض فعلی (گوشی/تبلت/دسکتاپ/ویندوز)
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
