import 'dart:convert';
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

/// ویجت مشترک نمایش عکس محصول. این تنها جایی است که منطق «Asset یا
/// Base64» و پلیس‌هولدر خطا پیاده‌سازی می‌شود، تا در همه‌ی صفحات (خانه،
/// جزئیات، سبد خرید، پنل ادمین) دقیقاً یک شکل و یک قالب دیده شود.
class ProductImage extends StatelessWidget {
  final String imageUrl;
  final ImageAspectRatio? aspectRatio;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final double placeholderIconSize;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.aspectRatio,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholderIconSize = 40,
  });

  Widget _image() {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    try {
      final bytes = base64Decode(imageUrl);
      return Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.outlineGray.withOpacity(0.15),
      alignment: Alignment.center,
      child: Icon(
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
