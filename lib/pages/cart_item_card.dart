import 'package:azmode/pages/color_utils.dart';
import 'package:azmode/pages/price_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../model.dart';
import '../theme.dart';
import '../responsive.dart';
import '../store_provider.dart';
import 'product_image.dart';

/// کارت نمایش یک ردیف از سبد خرید.
class CartItemCard extends StatelessWidget {
  final CartItem item;

  const CartItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final store = context.read<StoreProvider>();
    final product = item.product;
    final rs = context.rs;
    final rr = context.rr;
    final ui = context.uiScale;

    // سایز تصویر: ریسپانسیو + uiScale
    final imgSize =
        context.responsive<double>(mobile: 84, tablet: 96, desktop: 104) *
        ui.clamp(0.95, 1.1);

    // سایز آیکون‌های اکشن (ویرایش/حذف) روی کارت
    final actionIconSize = (20.0 * ui).clamp(18.0, 24.0);

    // سایز دایره‌ی رنگ
    final colorDotSize = (12.0 * ui).clamp(10.0, 16.0);

    final colorValue = item.selectedColor != null
        ? colorFromName(item.selectedColor!)
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Padding(
          padding: EdgeInsets.all(rs.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── تصویر محصول ──
                  SizedBox(
                    width: imgSize,
                    height: imgSize,
                    child: ProductImage(
                      imageUrl: product.imageUrl,
                      imageSource: product.imageSource,
                      borderRadius: BorderRadius.circular(rr.sm),
                    ),
                  ),
                  SizedBox(width: rs.md),

                  // ── اطلاعات محصول ──
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
                            SizedBox(width: rs.xs),
                            _ActionIconButton(
                              icon: Icons.edit_outlined,
                              color: AppColors.deepTeal,
                              tooltip: 'ویرایش',
                              size: actionIconSize,
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => _EditCartItemDialog(item: item),
                              ),
                            ),
                            SizedBox(width: rs.xs),
                            _ActionIconButton(
                              icon: Icons.delete_outline,
                              color: AppColors.error,
                              tooltip: 'حذف',
                              size: actionIconSize,
                              onPressed: () => store.removeFromCart(
                                product.id,
                                selectedColor: item.selectedColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: rs.xs),
                        Text(
                          'قیمت واحد: ${formatToman(product.price)}',
                          style: context.textStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.selectedColor != null) ...[
                          SizedBox(height: rs.xs),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: colorDotSize,
                                height: colorDotSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorValue ?? AppColors.outlineGray,
                                  border: Border.all(
                                    color: AppColors.outlineGray,
                                  ),
                                ),
                              ),
                              SizedBox(width: rs.xs),
                              Flexible(
                                child: Text(
                                  'رنگ: ${item.selectedColor}',
                                  style: context.textStyles.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                height: rs.lg,
                color: AppColors.outlineGray.withValues(alpha: 0.5),
              ),

              // ── ردیف تعداد و جمع ──
              _QuantityRow(item: item, store: store),
            ],
          ),
        ),
      ),
    );
  }
}

/// ردیف تعداد + جمع کل. روی گوشی‌های باریک، اگر جا نشد، جمع به خط بعد می‌رود.
class _QuantityRow extends StatelessWidget {
  final CartItem item;
  final StoreProvider store;

  const _QuantityRow({required this.item, required this.store});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final product = item.product;
    final ui = context.uiScale;

    final qtyBoxMinWidth = (34.0 * ui).clamp(30.0, 44.0);

    final totalText = Text(
      'جمع: ${formatToman(item.totalPrice)}',
      style: context.textStyles.titleSmall?.bold.withColor(AppColors.deepTeal),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // آستانه‌ی باریک بودن: اگه عرض کمتر از 340 بود، جمع را به سطر بعد ببر
        final isNarrow = constraints.maxWidth < 340 * ui;

        final qtyControls = Row(
          mainAxisSize: MainAxisSize.min,
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
              constraints: BoxConstraints(minWidth: qtyBoxMinWidth),
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: rs.xs),
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
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: qtyControls),
              SizedBox(height: rs.sm),
              Align(alignment: Alignment.centerRight, child: totalText),
            ],
          );
        }

        return Row(
          children: [
            qtyControls,
            const Spacer(),
            Flexible(child: totalText),
          ],
        );
      },
    );
  }
}

/// دکمه‌ی آیکونی کوچک برای اکشن‌های کارت (ویرایش/حذف) با touch target مناسب.
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final ui = context.uiScale;
    final hit = (36.0 * ui).clamp(34.0, 44.0);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: hit,
          height: hit,
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}

/// دکمه‌ی گرد کوچک برای افزایش/کاهش تعداد.
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ui = context.uiScale;
    final enabled = onTap != null;
    final iconSize = (18.0 * ui).clamp(16.0, 22.0);
    final padding = (6.0 * ui).clamp(5.0, 8.0);

    return Material(
      color: enabled
          ? AppColors.deepTeal.withValues(alpha: 0.1)
          : AppColors.outlineGray.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Icon(
            icon,
            size: iconSize,
            color: enabled ? AppColors.deepTeal : AppColors.outlineGray,
          ),
        ),
      ),
    );
  }
}

/// دیالوگ ویرایش یک ردیف سبد خرید.
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
    final rs = context.rs;
    final rr = context.rr;

    return AlertDialog(
      title: Text(
        'ویرایش ${product.name}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.textStyles.titleMedium?.bold,
      ),
      content: ConstrainedBox(
        // dialogWidth خودش ریسپانسیو است
        constraints: BoxConstraints(maxWidth: dialogWidth(context)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.colors.isNotEmpty) ...[
                Text('رنگ', style: context.textStyles.bodyMedium?.bold),
                SizedBox(height: rs.sm),
                Wrap(
                  spacing: rs.sm,
                  runSpacing: rs.sm,
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
                        borderRadius: BorderRadius.circular(rr.sm),
                        side: BorderSide(
                          color: isSelected
                              ? colorValue
                              : AppColors.outlineGray,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: rs.lg),
              ],
              Text('تعداد', style: context.textStyles.bodyMedium?.bold),
              SizedBox(height: rs.sm),
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
                    padding: EdgeInsets.symmetric(horizontal: rs.md),
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
