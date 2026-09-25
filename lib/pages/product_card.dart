import 'package:azmode/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../model.dart';
import '../responsive.dart';
import '../theme.dart';
import 'price_utils.dart';
import 'product_image.dart';

/// اندازه‌های وابسته به عرض کارت — یک‌بار در LayoutBuilder محاسبه و به
/// زیر‌ویجت‌ها داده می‌شود (نه در هر زیرویجت جداگانه).
class _CardMetrics {
  final double width;
  final double nameSize;
  final double priceSize;
  final double metaSize;
  final double stockSize;
  final double buttonFontSize;
  final double pad;
  final double gap;
  final double buttonHeight;

  factory _CardMetrics.fromWidth(double width) {
    final scale = (width / 180.0).clamp(0.70, 1.40);
    return _CardMetrics._(
      width: width,
      nameSize: (13.5 * scale).clamp(10.5, 16.0),
      priceSize: (13.0 * scale).clamp(10.0, 15.0),
      metaSize: (10.5 * scale).clamp(9.0, 12.0),
      stockSize: (11.0 * scale).clamp(9.0, 12.5),
      buttonFontSize: (12.0 * scale).clamp(10.0, 13.5),
      pad: (8.0 * scale).clamp(5.0, 11.0),
      gap: (2.5 * scale).clamp(2.0, 4.0),
      buttonHeight: (30.0 * scale).clamp(25.0, 38.0),
    );
  }

  const _CardMetrics._({
    required this.width,
    required this.nameSize,
    required this.priceSize,
    required this.metaSize,
    required this.stockSize,
    required this.buttonFontSize,
    required this.pad,
    required this.gap,
    required this.buttonHeight,
  });
}

/// کارت محصول برای Grid.
///
/// - هیچ Provider ای را watch نمی‌کند (فقط برای «افزودن به سبد» read
///   می‌کند)، پس تغییر سبد/اعلان/کاربر باعث Rebuild کارت‌ها نمی‌شود.
/// - عکس با Thumbnail و با اندازه‌ی دیکود متناسب با عرض کارت لود می‌شود.
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final rr = context.rr;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rr.lg)),
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final m = _CardMetrics.fromWidth(constraints.maxWidth);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 4,
                  child: _CardImage(
                    product: product,
                    metrics: m,
                    radius: rr.lg,
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: _CardInfo(product: product, metrics: m, radius: rr.md),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final Product product;
  final _CardMetrics metrics;
  final double radius;

  const _CardImage({
    required this.product,
    required this.metrics,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final packaging = product.packagingType?.name.trim();
    return Stack(
      fit: StackFit.expand,
      children: [
        ProductImage(
          imageUrl: product.gridImageUrl, // Thumbnail (نه عکس اصلی)
          decodeWidth: metrics.width,
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
          fit: BoxFit.cover,
        ),
        if (packaging != null && packaging.isNotEmpty)
          Positioned(
            top: metrics.pad * 0.5,
            right: metrics.pad * 0.5,
            child: _PackagingTag(text: packaging, fontSize: metrics.metaSize),
          ),
      ],
    );
  }
}

class _CardInfo extends StatelessWidget {
  final Product product;
  final _CardMetrics metrics;
  final double radius;

  const _CardInfo({
    required this.product,
    required this.metrics,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final brand = product.brand?.trim();
    final sku = product.sku?.trim();
    final metaLine = [
      if (brand != null && brand.isNotEmpty) brand,
      if (sku != null && sku.isNotEmpty) 'کد: $sku',
    ].join(' • ');

    return Padding(
      padding: EdgeInsets.all(metrics.pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            product.name,
            style: TextStyle(
              fontSize: metrics.nameSize,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
          ),
          if (metaLine.isNotEmpty)
            Text(
              metaLine,
              style: TextStyle(
                fontSize: metrics.metaSize,
                color: AppColors.outlineGray,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              formatToman(product.price),
              style: TextStyle(
                fontSize: metrics.priceSize,
                fontWeight: FontWeight.bold,
                color: AppColors.deepTeal,
                height: 1.1,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  product.isAvailable ? 'قابل سفارش' : 'ناموجود',
                  style: TextStyle(
                    fontSize: metrics.stockSize,
                    color: product.isAvailable
                        ? AppColors.success
                        : AppColors.error,
                    height: 1.1,
                  ),
                ),
              ),
              SizedBox(height: metrics.gap),
              _AddToCartButton(
                product: product,
                metrics: metrics,
                radius: radius,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  final Product product;
  final _CardMetrics metrics;
  final double radius;

  const _AddToCartButton({
    required this.product,
    required this.metrics,
    required this.radius,
  });

  Future<void> _onPressed(BuildContext context) async {
    final cartProvider = context.read<CartProvider>();

    final success = await cartProvider.addToCart(
      productId: int.parse(product.id),
      quantity: 1,
    );

    if (!context.mounted) return;

    final message = success
        ? 'به سبد خرید اضافه شد'
        : (cartProvider.errorMessage ?? 'افزودن به سبد خرید انجام نشد.');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: success ? null : AppColors.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: metrics.buttonHeight,
      child: ElevatedButton(
        onPressed: product.isAvailable ? () => _onPressed(context) : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: metrics.pad * 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'افزودن به سبد',
            style: TextStyle(
              fontSize: metrics.buttonFontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryWhite,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _PackagingTag extends StatelessWidget {
  final String text;
  final double fontSize;
  const _PackagingTag({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.primaryWhite,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
