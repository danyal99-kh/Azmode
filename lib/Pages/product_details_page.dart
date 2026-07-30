import 'package:azmode/model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../store_provider.dart';
import '../theme.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final product = store.getProductById(widget.productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'جزئیات محصول',
            style: context.textStyles.titleLarge?.withColor(
              AppColors.primaryWhite,
            ),
          ),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryWhite),
            tooltip: 'بازگشت',
          ),
        ),
        body: const Center(child: Text('محصول مورد نظر پیدا نشد.')),
      );
    }

    final maxQty = product.stock <= 0 ? 1 : product.stock;
    if (_quantity > maxQty) _quantity = maxQty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'جزئیات محصول',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryWhite),
          tooltip: 'بازگشت',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.asset(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surfaceWhite,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 56,
                              color: AppColors.outlineGray,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    product.name,
                    style: context.textStyles.titleLarge?.bold,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${product.price} تومان',
                    style: context.textStyles.titleMedium
                        ?.withColor(AppColors.deepTeal)
                        .bold,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _AvailabilityPill(product: product),
                  const SizedBox(height: AppSpacing.lg),
                  _InfoSection(
                    title: 'توضیحات',
                    child: Text(
                      product.description,
                      style: context.textStyles.bodyMedium?.copyWith(
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InfoSection(
                    title: 'مشخصات',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SpecRow(label: 'رنگ', value: product.color),
                        _SpecRow(label: 'اندازه', value: product.size),
                        _SpecRow(label: 'برند', value: product.brand),
                        _SpecRow(label: 'کد کالا', value: product.sku),
                        _SpecRow(
                          label: 'مشخصات فنی',
                          value: product.specifications,
                        ),
                      ].whereType<Widget>().toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primaryWhite,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlack.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _QuantitySelector(
                          value: _quantity,
                          max: maxQty,
                          enabled: product.isAvailable,
                          onChanged: (v) => setState(() => _quantity = v),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: product.isAvailable
                              ? () {
                                  context.read<StoreProvider>().addToCart(
                                    product,
                                    _quantity,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('به سبد خرید اضافه شد'),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('افزودن به سبد خرید'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  final Product product;

  const _AvailabilityPill({required this.product});

  @override
  Widget build(BuildContext context) {
    final isAvailable = product.isAvailable;
    final color = isAvailable ? AppColors.success : AppColors.error;
    final text = isAvailable ? 'موجود در انبار: ${product.stock}' : 'ناموجود';
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          text,
          style: context.textStyles.bodySmall?.withColor(color).bold,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.outlineGray.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.textStyles.titleMedium?.bold),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String? value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:', style: context.textStyles.bodyMedium?.bold),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value!,
              style: context.textStyles.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int value;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _QuantitySelector({
    required this.value,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canDec = enabled && value > 1;
    final canInc = enabled && value < max;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.outlineGray.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: canDec ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: AppColors.deepTeal,
              disabledColor: AppColors.outlineGray,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              tooltip: 'کم کردن',
            ),
            Text('$value', style: context.textStyles.titleMedium?.bold),
            IconButton(
              onPressed: canInc ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.deepTeal,
              disabledColor: AppColors.outlineGray,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              tooltip: 'اضافه کردن',
            ),
          ],
        ),
      ),
    );
  }
}
