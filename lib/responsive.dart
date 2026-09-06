import 'package:flutter/material.dart';

/// نقاط شکست (Breakpoints) مرکزی برای کل اپلیکیشن.
/// - Mobile:  width < 600   (گوشی)
/// - Tablet:  600 <= width < 1024 (تبلت / گوشی بزرگ افقی)
/// - Desktop: width >= 1024 (ویندوز، وب، صفحه‌های بزرگ)
class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double wide = 1440;
}

enum DeviceType { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  Size get _size => MediaQuery.sizeOf(this);
  double get screenWidth => _size.width;
  double get screenHeight => _size.height;

  DeviceType get deviceType {
    final w = screenWidth;
    if (w < AppBreakpoints.mobile) return DeviceType.mobile;
    if (w < AppBreakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// ضریب مقیاس برای فاصله‌ها و فونت‌ها؛ روی گوشی‌های خیلی کوچک کمی جمع‌تر
  /// و روی دسکتاپ/ویندوز کمی بازتر می‌شود، اما هیچ‌وقت بیش‌ازحد بزرگ نمی‌شود.
  double get uiScale {
    final w = screenWidth;
    if (w <= AppBreakpoints.mobile) {
      // بین گوشی‌های خیلی کوچک (320) تا بزرگ (600)
      return (w / 390).clamp(0.82, 1.05);
    }
    if (w <= AppBreakpoints.tablet) return 1.08;
    if (w <= AppBreakpoints.wide) return 1.15;
    return 1.2;
  }

  /// انتخاب مقدار بر اساس نوع دستگاه؛ در صورت نبود مقدار اختصاصی، به گوشی
  /// برمی‌گردد (Fallback ایمن).
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// تعداد ستون‌های گرید محصولات بر اساس عرض واقعی موجود (نه فقط عرض صفحه)،
  /// طوری که کارت‌ها روی هر عرضی (گوشی کوچک تا پنجره‌ی بزرگ ویندوز) اندازه‌ی
  /// منطقی داشته باشند.
  int gridColumnsFor(double availableWidth, {double tileMinWidth = 165}) {
    final cols = (availableWidth / tileMinWidth).floor();
    return cols.clamp(2, 6);
  }

  /// حداکثر عرض محتوا روی صفحه‌های خیلی بزرگ (دسکتاپ/ویندوز)، تا محتوا
  /// بیش‌ازحد کش نیاید و در وسط صفحه با ظاهری مرتب نمایش داده شود.
  Widget centerMaxWidth(Widget child, {double maxWidth = 1100}) {
    if (screenWidth <= maxWidth) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// فاصله‌های واکنش‌گرا؛ جایگزین AppSpacing ثابت در جاهایی که لازم است با
/// اندازه صفحه هماهنگ شوند. استفاده: context.rs.md
class RSpacing {
  final BuildContext context;
  const RSpacing(this.context);

  double get xs => 4.0 * context.uiScale;
  double get sm => 8.0 * context.uiScale;
  double get md => 16.0 * context.uiScale;
  double get lg => 24.0 * context.uiScale;
  double get xl => 32.0 * context.uiScale;
  double get xxl => 48.0 * context.uiScale;
}

extension RSpacingContext on BuildContext {
  RSpacing get rs => RSpacing(this);
}

/// عرض ایمن برای دیالوگ‌ها (فرم‌های ادمین و ...)، تا روی گوشی کوچک overflow
/// ندهند و روی دسکتاپ/ویندوز بیش‌ازحد کشیده نشوند.
double dialogWidth(BuildContext context) {
  final w = context.screenWidth;
  if (w < AppBreakpoints.mobile) return w * 0.92;
  if (w < AppBreakpoints.tablet) return 480;
  return 520;
}
