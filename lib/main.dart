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
