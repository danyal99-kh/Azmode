import 'package:flutter/material.dart';

/// نقاط شکست (Breakpoints) مرکزی
/// - Mobile:  width < 600
/// - Tablet:  600 <= width < 1024
/// - Desktop: width >= 1024 (ویندوز، وب، لپ‌تاپ بزرگ)
class AppBreakpoints {
  static const double mobileSmall = 360;
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double wide = 1440;
}

enum DeviceType { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  Size get _size => MediaQuery.sizeOf(this);
  double get screenWidth => _size.width;
  double get screenHeight => _size.height;
  bool get isLandscape => _size.width > _size.height;

  DeviceType get deviceType {
    final w = screenWidth;
    if (w < AppBreakpoints.mobile) return DeviceType.mobile;
    if (w < AppBreakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// ضریب مقیاس برای فاصله‌ها، رادیوس و آیکون‌ها
  double get uiScale {
    final w = screenWidth;
    if (w < AppBreakpoints.mobileSmall) return 0.85;
    if (w < AppBreakpoints.mobile) return (w / 390).clamp(0.9, 1.05);
    if (w < AppBreakpoints.tablet) return 1.08;
    if (w < AppBreakpoints.wide) return 1.15;
    return 1.2;
  }

  /// ضریب مقیاس فونت‌ها (محافظه‌کارانه‌تر از uiScale)
  double get fontScale {
    final w = screenWidth;
    if (w < AppBreakpoints.mobileSmall) return 0.9;
    if (w < AppBreakpoints.mobile) return (w / 390).clamp(0.95, 1.05);
    if (w < AppBreakpoints.tablet) return 1.06;
    if (w < AppBreakpoints.wide) return 1.12;
    return 1.16;
  }

  /// انتخاب مقدار بر اساس نوع دستگاه
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

  /// تعداد ستون‌های گرید بر اساس عرض واقعی موجود
  int gridColumnsFor(double availableWidth, {double tileMinWidth = 165}) {
    final cols = (availableWidth / tileMinWidth).floor();
    return cols.clamp(2, 6);
  }

  /// پدینگ افقی استاندارد صفحه
  double get horizontalPadding =>
      responsive<double>(mobile: 16, tablet: 24, desktop: 32) * uiScale;

  /// حداکثر عرض محتوا روی دسکتاپ/ویندوز
  double get contentMaxWidth =>
      responsive<double>(mobile: double.infinity, tablet: 900, desktop: 1200);

  /// وسط‌چین کردن محتوا روی صفحه‌های بزرگ
  Widget centerMaxWidth(Widget child, {double? maxWidth}) {
    final mw = maxWidth ?? contentMaxWidth;
    if (mw == double.infinity || screenWidth <= mw) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: mw),
        child: child,
      ),
    );
  }
}

/// فاصله‌های ریسپانسیو — استفاده: context.rs.md
class RSpacing {
  final BuildContext context;
  const RSpacing(this.context);

  double get xs => 4.0 * context.uiScale;
  double get sm => 8.0 * context.uiScale;
  double get md => 16.0 * context.uiScale;
  double get lg => 24.0 * context.uiScale;
  double get xl => 32.0 * context.uiScale;
  double get xxl => 48.0 * context.uiScale;
  double get xxxl => 64.0 * context.uiScale;

  EdgeInsets get pagePadding =>
      EdgeInsets.symmetric(horizontal: context.horizontalPadding);
  EdgeInsets get pagePaddingAll => EdgeInsets.all(context.horizontalPadding);
}

/// رادیوس‌های ریسپانسیو — استفاده: context.rr.md
class RRadius {
  final BuildContext context;
  const RRadius(this.context);

  double get sm => 8.0 * context.uiScale;
  double get md => 12.0 * context.uiScale;
  double get lg => 16.0 * context.uiScale;
  double get xl => 24.0 * context.uiScale;
  double get pill => 999;
}

extension RSpacingContext on BuildContext {
  RSpacing get rs => RSpacing(this);
  RRadius get rr => RRadius(this);
}

/// عرض ایمن دیالوگ‌ها
double dialogWidth(BuildContext context) {
  final w = context.screenWidth;
  if (w < AppBreakpoints.mobile) return w * 0.92;
  if (w < AppBreakpoints.tablet) return 480;
  return 560;
}
