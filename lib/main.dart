import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'nav.dart';
import 'store_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => StoreProvider())],
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
      supportedLocales: const [
        Locale('fa', 'IR'), // Persian
      ],
      locale: const Locale('fa', 'IR'), // Default locale

      theme: appTheme,
      routerConfig: AppRouter.router,

      // این builder اندازه‌ی متن سیستم‌عامل (مثلاً تنظیمات دسترسی‌پذیری در
      // ویندوز یا اندروید) را در یک بازه‌ی امن محدود می‌کند، تا فونت خیلی
      // بزرگ باعث بهم‌ریختگی و overflow در چیدمان‌ها نشود، ولی همچنان کمی
      // بزرگ‌نمایی برای دسترسی‌پذیری امکان‌پذیر بماند.
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.25,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}