import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:azmode/theme.dart';
import 'package:flutter/material.dart';
import '../responsive.dart';

/// قالب‌های از پیش تعریف‌شده برای برش عکس محصول.
enum ImageAspectRatio { square, portrait, landscape, tall }

extension ImageAspectRatioX on ImageAspectRatio {
  double get ratio {
    switch (this) {
      case ImageAspectRatio.square:
        return 1.0;
      case ImageAspectRatio.portrait:
        return 3 / 4;
      case ImageAspectRatio.landscape:
        return 16 / 9;
      case ImageAspectRatio.tall:
        return 4 / 5;
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

String imageAspectRatioToKey(ImageAspectRatio r) => r.name;

ImageAspectRatio imageAspectRatioFromKey(String? key) {
  return ImageAspectRatio.values.firstWhere(
    (e) => e.name == key,
    orElse: () => ImageAspectRatio.square,
  );
}

/// نوع منبع عکس محصول.
enum ProductImageSource { asset, base64, url }

ProductImageSource detectImageSource(String value) {
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return ProductImageSource.url;
  }
  if (value.startsWith('assets/')) {
    return ProductImageSource.asset;
  }
  return ProductImageSource.base64;
}

/// کش ساده‌ی LRU برای بایت‌های Base64 دیکود شده.
class Base64ImageCache {
  Base64ImageCache._();

  static const int _maxEntries = 80;
  static final LinkedHashMap<String, Uint8List> _cache =
      LinkedHashMap<String, Uint8List>();

  static Uint8List? decode(String base64Str) {
    final cached = _cache[base64Str];
    if (cached != null) {
      _cache.remove(base64Str);
      _cache[base64Str] = cached;
      return cached;
    }
    try {
      final bytes = base64Decode(base64Str);
      if (_cache.length >= _maxEntries) {
        _cache.remove(_cache.keys.first);
      }
      _cache[base64Str] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  static void clear() => _cache.clear();
}

/// ویجت مشترک نمایش عکس محصول.
class ProductImage extends StatelessWidget {
  final String imageUrl;
  final ProductImageSource? imageSource;
  final ImageAspectRatio? aspectRatio;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  /// سایز آیکون placeholder. اگر پاس داده نشود، مقدار پیش‌فرض ریسپانسیو
  /// بر اساس نوع دستگاه و uiScale محاسبه می‌شود.
  final double? placeholderIconSize;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.imageSource,
    this.aspectRatio,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholderIconSize,
  });

  Widget _image(BuildContext context, double iconSize) {
    final source = imageSource ?? detectImageSource(imageUrl);
    switch (source) {
      case ProductImageSource.asset:
        return Image.asset(
          imageUrl,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(context, iconSize),
        );
      case ProductImageSource.url:
        return Image.network(
          imageUrl,
          fit: fit,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholder(context, iconSize, loading: true);
          },
          errorBuilder: (_, __, ___) => _placeholder(context, iconSize),
        );
      case ProductImageSource.base64:
        final bytes = Base64ImageCache.decode(imageUrl);
        if (bytes == null) return _placeholder(context, iconSize);
        return Image.memory(
          bytes,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _placeholder(context, iconSize),
        );
    }
  }

  Widget _placeholder(
    BuildContext context,
    double iconSize, {
    bool loading = false,
  }) {
    final ui = context.uiScale;
    final strokeWidth = (2.0 * ui).clamp(1.5, 3.0);

    return Container(
      color: AppColors.outlineGray.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: iconSize * 0.6,
              height: iconSize * 0.6,
              child: CircularProgressIndicator(strokeWidth: strokeWidth),
            )
          : Icon(
              Icons.image_not_supported,
              color: AppColors.outlineGray,
              size: iconSize,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // سایز آیکون placeholder — ریسپانسیو
    final iconSize =
        placeholderIconSize ??
        context.responsive<double>(mobile: 40, tablet: 44, desktop: 48) *
            context.uiScale.clamp(0.95, 1.1);

    Widget child = SizedBox.expand(child: _image(context, iconSize));
    if (aspectRatio != null) {
      child = AspectRatio(aspectRatio: aspectRatio!.ratio, child: child);
    }
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
