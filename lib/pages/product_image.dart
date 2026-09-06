import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:azmode/theme.dart';
import 'package:flutter/material.dart';

/// قالب‌های از پیش تعریف‌شده برای برش عکس محصول. ادمین هنگام آپلود عکس
/// یکی از این‌ها را انتخاب می‌کند و همان قالب، در همه‌جای اپ (صفحه اصلی،
/// جزئیات محصول، سبد خرید و ...) برای آن محصول استفاده می‌شود.
enum ImageAspectRatio { square, portrait, landscape, tall }

extension ImageAspectRatioX on ImageAspectRatio {
  double get ratio {
    switch (this) {
      case ImageAspectRatio.square:
        return 1.0; // 1:1
      case ImageAspectRatio.portrait:
        return 3 / 4; // عمودی
      case ImageAspectRatio.landscape:
        return 16 / 9; // افقی و کشیده
      case ImageAspectRatio.tall:
        return 4 / 5; // کمی کشیده به سمت عمودی
    }
  }

  String get label {
    switch (this) {
      case ImageAspectRatio.square:
        return 'مربعی';
      case ImageAspectRatio.portrait:
        return 'عمودی';
      case ImageAspectRatio.landscape:
        return 'افقی (پانوراما)';
      case ImageAspectRatio.tall:
        return 'کشیده';
    }
  }

  String get ratioText {
    switch (this) {
      case ImageAspectRatio.square:
        return '1:1';
      case ImageAspectRatio.portrait:
        return '3:4';
      case ImageAspectRatio.landscape:
        return '16:9';
      case ImageAspectRatio.tall:
        return '4:5';
    }
  }

  IconData get icon {
    switch (this) {
      case ImageAspectRatio.square:
        return Icons.crop_square;
      case ImageAspectRatio.portrait:
        return Icons.crop_portrait;
      case ImageAspectRatio.landscape:
        return Icons.crop_landscape;
      case ImageAspectRatio.tall:
        return Icons.crop_5_4;
    }
  }
}

/// نام‌های ذخیره‌شده در دیتای محصول (برای تبدیل enum <-> String چون فعلاً
/// مدل به‌صورت ساده و بدون JSON کار می‌کند).
String imageAspectRatioToKey(ImageAspectRatio r) => r.name;

ImageAspectRatio imageAspectRatioFromKey(String? key) {
  return ImageAspectRatio.values.firstWhere(
    (e) => e.name == key,
    orElse: () => ImageAspectRatio.square,
  );
}

/// نوع منبع عکس محصول. به‌جای این‌که هر بار که ویجت رندر می‌شود حدس زده
/// شود («آیا این رشته با assets/ شروع می‌شود؟»)، این نوع یک‌بار — هنگام
/// ساخته یا ویرایش‌شدن محصول — مشخص و روی خود [Product] ذخیره می‌شود.
///
/// - [asset]: مسیر فایل داخل پروژه (مثلاً assets/images/x.jpg)
/// - [base64]: عکس آپلودشده توسط ادمین که به‌صورت Base64 ذخیره شده
/// - [url]: آدرس اینترنتی؛ مسیر آماده برای زمانی که عکس‌ها روی یک سرور
///   واقعی آپلود شوند (فقط کافی است imageUrl حاوی http/https باشد)
enum ProductImageSource { asset, base64, url }

/// تشخیص نوع منبع از روی مقدار خام رشته. این تابع باید فقط یک‌بار (هنگام
/// ساخت/ویرایش Product) صدا زده شود، نه در هر build() ویجت.
ProductImageSource detectImageSource(String value) {
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return ProductImageSource.url;
  }
  if (value.startsWith('assets/')) {
    return ProductImageSource.asset;
  }
  return ProductImageSource.base64;
}

/// کش ساده‌ی LRU برای بایت‌های Base64 دیکود شده. بدون این کش، هر بار که
/// ProductImage در یک ListView/GridView دوباره build می‌شود (اسکرول کردن،
/// تغییر state صفحه‌ی والد و ...)، همان رشته‌ی Base64 دوباره decode
/// می‌شد که برای کاتالوگ‌های بزرگ محصولات محسوس و سنگین است. اینجا هر
/// رشته فقط یک‌بار decode و نتیجه در حافظه نگه‌داری می‌شود؛ برای این‌که
/// حافظه بی‌رویه رشد نکند، قدیمی‌ترین آیتم‌ها وقتی تعداد از سقف بگذرد
/// حذف می‌شوند.
class Base64ImageCache {
  Base64ImageCache._();

  static const int _maxEntries = 80;
  static final LinkedHashMap<String, Uint8List> _cache =
      LinkedHashMap<String, Uint8List>();

  static Uint8List? decode(String base64Str) {
    final cached = _cache[base64Str];
    if (cached != null) {
      // جابه‌جایی به انتهای Map تا به‌عنوان «اخیراً استفاده‌شده» حساب شود
      _cache.remove(base64Str);
      _cache[base64Str] = cached;
      return cached;
    }
    try {
      final bytes = base64Decode(base64Str);
      if (_cache.length >= _maxEntries) {
        _cache.remove(_cache.keys.first); // حذف قدیمی‌ترین (LRU)
      }
      _cache[base64Str] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// در صورت نیاز به آزادسازی حافظه (مثلاً هنگام خروج از حساب کاربری).
  static void clear() => _cache.clear();
}

/// ویجت مشترک نمایش عکس محصول. این تنها جایی است که منطق «Asset یا
/// Base64 یا URL» و پلیس‌هولدر خطا پیاده‌سازی می‌شود، تا در همه‌ی صفحات
/// (خانه، جزئیات، سبد خرید، پنل ادمین) دقیقاً یک شکل و یک قالب دیده شود.
class ProductImage extends StatelessWidget {
  final String imageUrl;

  /// نوع منبع عکس. اگر داده نشود، به‌صورت fallback با [detectImageSource]
  /// حدس زده می‌شود (برای سازگاری با جاهایی که هنوز آن را پاس نمی‌دهند)،
  /// اما بهتر است همیشه از [Product.imageSource] پاس داده شود تا هیچ
  /// تشخیصی در زمان رندر لازم نباشد.
  final ProductImageSource? imageSource;

  final ImageAspectRatio? aspectRatio;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final double placeholderIconSize;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.imageSource,
    this.aspectRatio,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholderIconSize = 40,
  });

  Widget _image() {
    final source = imageSource ?? detectImageSource(imageUrl);
    switch (source) {
      case ProductImageSource.asset:
        return Image.asset(
          imageUrl,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      case ProductImageSource.url:
        // آماده برای زمانی که عکس‌ها روی یک سرور واقعی آپلود شوند؛ فعلاً
        // در دیتای پیش‌فرض اپ استفاده نمی‌شود ولی مسیر مهاجرت را باز
        // می‌گذارد بدون نیاز به تغییر جای دیگری از کد.
        return Image.network(
          imageUrl,
          fit: fit,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholder(loading: true);
          },
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      case ProductImageSource.base64:
        final bytes = Base64ImageCache.decode(imageUrl);
        if (bytes == null) return _placeholder();
        return Image.memory(
          bytes,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
    }
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      color: AppColors.outlineGray.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: placeholderIconSize * 0.6,
              height: placeholderIconSize * 0.6,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.image_not_supported,
              color: AppColors.outlineGray,
              size: placeholderIconSize,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = SizedBox.expand(child: _image());
    if (aspectRatio != null) {
      child = AspectRatio(aspectRatio: aspectRatio!.ratio, child: child);
    }
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
