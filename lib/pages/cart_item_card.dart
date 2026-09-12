import 'package:azmode/pages/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../model.dart';
import '../theme.dart';
import '../responsive.dart';
import '../store_provider.dart';
import 'product_image.dart';

/// کارت نمایش یک ردیف از سبد خرید.
///
/// این ویجت هیچ state واقعی‌ای نداره — همه چیز از StoreProvider خونده
/// و روش اعمال می‌شه. لمس روی تصویر یا نام محصول کاربر رو مستقیماً به
/// همون صفحه‌ی جزئیات محصول (`/product/:id`) می‌بره؛ هیچ نمایش جزئیات
/// تکراری‌ای اینجا ساخته نشده.
class CartItemCard extends StatelessWidget {
  final CartItem item;

  const CartItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final store = context.read<StoreProvider>();
    final product = item.product;
    final imgSize = context.responsive<double>(
      mobile: 84,
      tablet: 96,
      desktop: 104,
    );
    final colorValue = item.selectedColor != null
        ? colorFromName(item.selectedColor!)
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Padding(
          padding: EdgeInsets.all(context.rs.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: imgSize,
                    height: imgSize,
                    child: ProductImage(
                      imageUrl: product.imageUrl,
                      imageSource: product.imageSource,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  SizedBox(width: context.rs.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: context.textStyles.titleMedium?.bold,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: AppColors.deepTeal,
                              ),
                              tooltip: 'ویرایش',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => _EditCartItemDialog(item: item),
                              ),
                            ),
                            SizedBox(width: context.rs.xs),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppColors.error,
                              ),
                              tooltip: 'حذف',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => store.removeFromCart(
                                product.id,
                                selectedColor: item.selectedColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.rs.xs),
                        Text(
                          'قیمت واحد: ${product.price} تومان',
                          style: context.textStyles.bodySmall,
                        ),
                        if (item.selectedColor != null) ...[
                          SizedBox(height: context.rs.xs),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorValue ?? AppColors.outlineGray,
                                  border: Border.all(
                                    color: AppColors.outlineGray,
                                  ),
                                ),
                              ),
                              SizedBox(width: context.rs.xs),
                              Text(
                                'رنگ: ${item.selectedColor}',
                                style: context.textStyles.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                height: context.rs.lg,
                color: AppColors.outlineGray.withValues(alpha: 0.5),
              ),
              Row(
                children: [
                  _QtyButton(
                    icon: Icons.remove,
                    onTap: () => store.updateCartItemQuantity(
                      product.id,
                      item.quantity - 1,
                      selectedColor: item.selectedColor,
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 34),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: context.rs.xs),
                    child: Text(
                      '${item.quantity}',
                      style: context.textStyles.titleMedium?.bold,
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.add,
                    onTap: item.quantity < product.stock
                        ? () => store.updateCartItemQuantity(
                            product.id,
                            item.quantity + 1,
                            selectedColor: item.selectedColor,
                          )
                        : null,
                  ),
                  const Spacer(),
                  Text(
                    'جمع: ${item.totalPrice.toStringAsFixed(0)} تومان',
                    style: context.textStyles.titleSmall?.bold.withColor(
                      AppColors.deepTeal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// دکمه‌ی گرد کوچک برای افزایش/کاهش تعداد؛ وقتی [onTap] نال باشه
/// (مثلاً به سقف موجودی رسیده یا تعداد ۱ است) به‌صورت غیرفعال و
/// خاکستری دیده می‌شه.
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? AppColors.deepTeal.withValues(alpha: 0.1)
          : AppColors.outlineGray.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.deepTeal : AppColors.outlineGray,
          ),
        ),
      ),
    );
  }
}

/// دیالوگ ویرایش یک ردیف سبد خرید: تغییر رنگ (در صورت وجود رنگ‌های
/// قابل انتخاب برای این محصول) و تعداد. ذخیره‌ی نهایی از طریق
/// [StoreProvider.editCartItem] انجام می‌شه که خودش مسئول ادغام با یک
/// ردیف مشابه (اگر رنگ جدید از قبل در سبد بود) است.
class _EditCartItemDialog extends StatefulWidget {
  final CartItem item;
  const _EditCartItemDialog({required this.item});

  @override
  State<_EditCartItemDialog> createState() => _EditCartItemDialogState();
}

class _EditCartItemDialogState extends State<_EditCartItemDialog> {
  late int _quantity;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
    _selectedColor = widget.item.selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.item.product;
    final maxQty = product.stock <= 0 ? 1 : product.stock;

    return AlertDialog(
      title: Text('ویرایش ${product.name}'),
      content: SizedBox(
        width: dialogWidth(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.colors.isNotEmpty) ...[
              Text('رنگ', style: context.textStyles.bodyMedium?.bold),
              SizedBox(height: context.rs.sm),
              Wrap(
                spacing: context.rs.sm,
                runSpacing: context.rs.sm,
                children: product.colors.map((color) {
                  final isSelected = color == _selectedColor;
                  final colorValue = colorFromName(color) ?? Colors.grey;
                  return ChoiceChip(
                    label: Text(color),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedColor = color),
                    selectedColor: colorValue.withValues(alpha: 0.25),
                    backgroundColor: AppColors.surfaceWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? colorValue : AppColors.outlineGray,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: context.rs.lg),
            ],
            Text('تعداد', style: context.textStyles.bodyMedium?.bold),
            SizedBox(height: context.rs.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.rs.md),
                  child: Text(
                    '$_quantity',
                    style: context.textStyles.titleLarge?.bold,
                  ),
                ),
                _QtyButton(
                  icon: Icons.add,
                  onTap: _quantity < maxQty
                      ? () => setState(() => _quantity++)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<StoreProvider>().editCartItem(
              product.id,
              oldColor: widget.item.selectedColor,
              newColor: _selectedColor,
              newQuantity: _quantity,
            );
            Navigator.pop(context);
          },
          child: const Text('ذخیره'),
        ),
      ],
    );
  }
}
