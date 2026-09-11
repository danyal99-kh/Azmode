import 'package:azmode/model.dart';
import 'package:azmode/pages/product_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../store_provider.dart';
import '../theme.dart';
import '../responsive.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _quantity = 1;
  final TextEditingController _quantityController = TextEditingController();
  String? _selectedColor;
  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // به‌روزرسانی تعداد از TextField با دریافت maxQty به‌عنوان پارامتر
  void _updateQuantityFromText(String value, int maxQty) {
    if (value.isEmpty) {
      setState(() => _quantity = 1);
      return;
    }
    final int? newQty = int.tryParse(value);
    if (newQty != null) {
      if (newQty < 1) {
        setState(() {
          _quantity = 1;
          _quantityController.text = '1';
        });
      } else if (newQty > maxQty) {
        setState(() {
          _quantity = maxQty;
          _quantityController.text = maxQty.toString();
        });
      } else {
        setState(() => _quantity = newQty);
      }
    } else {
      _quantityController.text = _quantity.toString();
    }
  }

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
    // اگر موجودی محصول (مثلاً توسط ادمین در یک تب دیگر) کمتر از تعدادی
    // شده باشد که کاربر قبلاً انتخاب کرده بود، مقدار _quantity کلمپ
    // می‌شود. قبلاً فقط همین مقدار عددی داخلی به‌روز می‌شد ولی متنی که
    // واقعاً داخل TextField دیده می‌شد (_quantityController.text) دست‌
    // نخورده می‌ماند — یعنی چیزی که کاربر روی صفحه می‌دید با مقداری که
    // واقعاً برای «افزودن به سبد» استفاده می‌شد یکی نبود. حالا هر دو با
    // هم هماهنگ نگه داشته می‌شوند. به‌روزرسانی خودِ controller.text به
    // بعد از پایان build موکول شده (addPostFrameCallback) تا هیچ تغییر
    // stateای در حین build اتفاق نیفتد.
    if (_quantity > maxQty) {
      _quantity = maxQty;
      final syncedText = maxQty.toString();
      if (_quantityController.text != syncedText) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _quantityController.text = syncedText;
          }
        });
      }
    }
    final totalPrice = product.price * _quantity;
    final isWide = !context.isMobile; // تبلت یا دسکتاپ/ویندوز

    // همان قالبی که ادمین هنگام آپلود عکس انتخاب کرده - دقیقاً همان چیزی
    // که در صفحه اصلی هم برای این محصول نمایش داده می‌شود.
    final imageBlock = ProductImage(
      imageUrl: product.imageUrl,
      imageSource: product.imageSource,
      aspectRatio: product.imageAspectRatio,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    );

    final infoBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(product.name, style: context.textStyles.titleLarge?.bold),
        SizedBox(height: context.rs.xs),
        // قیمت واحد
        Text(
          '${product.price} تومان',
          style: context.textStyles.titleMedium
              ?.withColor(AppColors.deepTeal)
              .bold,
        ),
        SizedBox(height: context.rs.sm),
        _AvailabilityPill(product: product),
        SizedBox(height: context.rs.lg),
        _InfoSection(
          title: 'توضیحات',
          child: Text(
            product.description,
            style: context.textStyles.bodyMedium?.copyWith(height: 1.55),
          ),
        ),
        SizedBox(height: context.rs.md),
        if (product.colors.isNotEmpty) ...[
          SizedBox(height: context.rs.sm),
          _ColorSelector(
            colors: product.colors,
            selectedColor: _selectedColor,
            onColorSelected: (color) => setState(() => _selectedColor = color),
          ),
          SizedBox(height: context.rs.sm),
        ],
        _InfoSection(
          title: 'مشخصات',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SpecRow(label: 'رنگ', value: product.color),
              _SpecRow(label: 'اندازه', value: product.size),
              _SpecRow(label: 'برند', value: product.brand),
              _SpecRow(label: 'کد کالا', value: product.sku),
              _SpecRow(label: 'مشخصات فنی', value: product.specifications),
            ].whereType<Widget>().toList(),
          ),
        ),
        SizedBox(height: context.rs.sm),
      ],
    );

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
              padding: EdgeInsets.all(context.rs.md),
              child: context.centerMaxWidth(
                isWide
                    // روی تبلت/دسکتاپ: تصویر و اطلاعات کنار هم
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: imageBlock),
                          SizedBox(width: context.rs.lg),
                          Expanded(flex: 6, child: infoBlock),
                        ],
                      )
                    // روی گوشی: تصویر بالا، اطلاعات پایین
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          imageBlock,
                          SizedBox(height: context.rs.md),
                          infoBlock,
                        ],
                      ),
                maxWidth: 900,
              ),
            ),
          ),
          // Footer شامل مجموع قیمت، انتخابگر تعداد و دکمه
          Container(
            padding: EdgeInsets.all(context.rs.lg),
            decoration: BoxDecoration(
              color: AppColors.primaryWhite,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlack.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: context.centerMaxWidth(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // باکس مجموع قیمت
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: context.rs.sm,
                        horizontal: context.rs.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.deepTeal.withOpacity(0.3),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'مجموع قیمت: ${totalPrice.toStringAsFixed(0)} تومان',
                          textAlign: TextAlign.center,
                          style: context.textStyles.titleMedium?.bold.withColor(
                            AppColors.deepTeal,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: context.rs.md),
                    // ردیف انتخابگر تعداد و دکمه
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _QuantitySelector(
                            value: _quantity,
                            max: maxQty,
                            enabled: product.isAvailable,
                            controller: _quantityController,
                            onChanged: (v) {
                              setState(() => _quantity = v);
                              _quantityController.text = v.toString();
                            },
                            onTextChanged: (v) =>
                                _updateQuantityFromText(v, maxQty),
                          ),
                        ),
                        SizedBox(width: context.rs.md),
                        Expanded(
                          flex: 6,
                          child: ElevatedButton(
                            onPressed: product.isAvailable
                                ? () {
                                    if (product.colors.isNotEmpty &&
                                        _selectedColor == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'لطفاً یک رنگ را انتخاب کنید.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    context.read<StoreProvider>().addToCart(
                                      product,
                                      _quantity,
                                      selectedColor: _selectedColor,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('به سبد خرید اضافه شد'),
                                      ),
                                    );
                                  }
                                : null,
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('افزودن به سبد خرید'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                maxWidth: 900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== ویجت‌های کمکی ==========

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
        padding: EdgeInsets.symmetric(horizontal: context.rs.sm, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withOpacity(0.25)),
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
        border: Border.all(color: AppColors.outlineGray.withOpacity(0.35)),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.rs.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.textStyles.titleMedium?.bold),
            SizedBox(height: context.rs.sm),
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
      padding: EdgeInsets.only(bottom: context.rs.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:', style: context.textStyles.bodyMedium?.bold),
          ),
          SizedBox(width: context.rs.sm),
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
  final TextEditingController controller;
  final ValueChanged<int> onChanged;
  final ValueChanged<String> onTextChanged;

  const _QuantitySelector({
    required this.value,
    required this.max,
    required this.enabled,
    required this.controller,
    required this.onChanged,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canDec = enabled && value > 1;
    final canInc = enabled && value < max;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineGray.withOpacity(0.35)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.rs.sm, vertical: 6),
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
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            SizedBox(
              width: 45,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                enabled: enabled,
                style: context.textStyles.titleMedium?.bold,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: onTextChanged,
              ),
            ),
            IconButton(
              onPressed: canInc ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.deepTeal,
              disabledColor: AppColors.outlineGray,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              tooltip: 'اضافه کردن',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSelector extends StatelessWidget {
  final List<String> colors;
  final String? selectedColor;
  final ValueChanged<String> onColorSelected;

  const _ColorSelector({
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  Color? _getColorFromName(String colorName) {
    final colorMap = {
      'قرمز': Colors.red,
      'سبز': Colors.green,
      'آبی': Colors.blue,
      'زرد': Colors.yellow,
      'مشکی': Colors.black,
      'سفید': Colors.white,
      'نارنجی': Colors.orange,
      'بنفش': Colors.purple,
      'صورتی': Colors.pink,
      'طوسی': Colors.grey,
      'نقره‌ای': Colors.grey.shade400,
      'طلایی': Colors.amber,
      'قهوه‌ای': Colors.brown,
    };
    return colorMap[colorName];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('انتخاب رنگ:', style: context.textStyles.bodyMedium?.bold),
        SizedBox(height: context.rs.sm),
        Wrap(
          spacing: context.rs.sm,
          runSpacing: context.rs.sm,
          children: colors.map((color) {
            final isSelected = color == selectedColor;
            final colorValue = _getColorFromName(color) ?? Colors.grey;
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rs.md,
                  vertical: context.rs.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorValue.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? colorValue : AppColors.outlineGray,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  color,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: isSelected ? colorValue : AppColors.primaryBlack,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
