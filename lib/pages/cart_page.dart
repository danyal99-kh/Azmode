import 'package:azmode/providers/auth_provider.dart';
import 'package:azmode/providers/cart_provider.dart';
import 'package:azmode/providers/proforma_provider.dart';
import 'package:azmode/responsive.dart';
import 'package:azmode/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import 'price_utils.dart';
import 'product_image.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<CartProvider>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سبد خرید',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
      ),
      body: _buildBody(context, cart),
    );
  }

  Widget _buildBody(BuildContext context, CartProvider cart) {
    if (cart.isLoading || cart.status == CartStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cart.status == CartStatus.error) {
      return _ErrorCartView(
        message: cart.errorMessage ?? 'خطا در دریافت سبد خرید.',
        onRetry: () {
          context.read<CartProvider>().loadCart();
        },
      );
    }

    if (cart.isEmpty) {
      return _EmptyCartView(onBackHome: () => context.go('/'));
    }

    return _CartContent(cart: cart);
  }
}

class _EmptyCartView extends StatelessWidget {
  final VoidCallback onBackHome;

  const _EmptyCartView({required this.onBackHome});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final ui = context.uiScale;

    final iconSize =
        context.responsive<double>(mobile: 80, tablet: 96, desktop: 112) *
        ui.clamp(0.9, 1.15);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: rs.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.remove_shopping_cart,
              size: iconSize,
              color: AppColors.outlineGray,
            ),
            SizedBox(height: rs.md),
            Text(
              'سبد خرید شما خالی است',
              style: context.textStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: rs.md),
            ElevatedButton(
              onPressed: onBackHome,
              child: const Text('بازگشت به خانه'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCartView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCartView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartContent extends StatelessWidget {
  final CartProvider cart;

  const _CartContent({required this.cart});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    return context.centerMaxWidth(
      Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(rs.md),
              itemCount: cart.items.length,
              separatorBuilder: (_, _) => SizedBox(height: rs.sm),
              itemBuilder: (context, index) {
                return _CartItemCard(item: cart.items[index]);
              },
            ),
          ),
          _CartSummaryBar(cartProvider: cart),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;

  const _CartItemCard({required this.item});

  Future<void> _updateQuantity(BuildContext context, int quantity) async {
    if (quantity < 1 || quantity > item.productStock) {
      return;
    }

    final success = await context.read<CartProvider>().updateQuantity(
      cartItemId: item.id,
      quantity: quantity,
    );

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<CartProvider>().errorMessage ??
                'تغییر تعداد کالا انجام نشد.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _removeItem(BuildContext context) async {
    final success = await context.read<CartProvider>().removeItem(item.id);

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<CartProvider>().errorMessage ?? 'حذف کالا انجام نشد.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final ui = context.uiScale;

    final imageSize = context.responsive<double>(
      mobile: 90,
      tablet: 110,
      desktop: 120,
    );

    final canIncrease = item.quantity < item.productStock;
    final canDecrease = item.quantity > 1;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/product/${item.productId}');
        },
        child: Padding(
          padding: EdgeInsets.all(rs.md),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: ProductImage(
                      imageUrl: item.productImage ?? '',
                      decodeWidth: imageSize,
                      borderRadius: BorderRadius.circular(
                        12 * ui.clamp(0.9, 1.1),
                      ),
                    ),
                  ),
                  SizedBox(width: rs.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: context.textStyles.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: rs.sm),
                        Text(
                          'قیمت واحد: ${formatToman(item.productPrice)}',
                          style: context.textStyles.bodyMedium,
                        ),
                        SizedBox(height: rs.xs),
                        Text(
                          'موجودی: ${item.productStock}',
                          style: context.textStyles.bodySmall?.withColor(
                            AppColors.outlineGray,
                          ),
                        ),
                        if (item.selectedColor != null &&
                            item.selectedColor!.isNotEmpty) ...[
                          SizedBox(height: rs.xs),
                          Text(
                            'رنگ: ${item.selectedColor}',
                            style: context.textStyles.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'حذف',
                    onPressed: () => _removeItem(context),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              SizedBox(height: rs.md),
              const Divider(),
              SizedBox(height: rs.sm),
              Row(
                children: [
                  Text('تعداد', style: context.textStyles.titleSmall),
                  SizedBox(width: rs.sm),
                  IconButton(
                    tooltip: 'کاهش تعداد',
                    onPressed: canDecrease
                        ? () => _updateQuantity(context, item.quantity - 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 42),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.quantity}',
                      style: context.textStyles.titleMedium?.bold,
                    ),
                  ),
                  IconButton(
                    tooltip: 'افزایش تعداد',
                    onPressed: canIncrease
                        ? () => _updateQuantity(context, item.quantity + 1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'مبلغ',
                        style: context.textStyles.bodySmall?.withColor(
                          AppColors.outlineGray,
                        ),
                      ),
                      Text(
                        formatToman(item.totalPrice),
                        style: context.textStyles.titleMedium
                            ?.withColor(AppColors.deepTeal)
                            .bold,
                      ),
                    ],
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

class _CartSummaryBar extends StatelessWidget {
  final CartProvider cartProvider;

  const _CartSummaryBar({required this.cartProvider});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final ui = context.uiScale;
    final submitting = context.watch<ProformaProvider>().submitting;

    final buttonHeight = (50.0 * ui).clamp(46.0, 58.0);

    return Container(
      padding: EdgeInsets.all(rs.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlack.withValues(alpha: 0.05),
            blurRadius: 10 * ui.clamp(0.9, 1.2),
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('مبلغ کل:', style: context.textStyles.titleMedium),
                SizedBox(width: rs.sm),
                Flexible(
                  child: Text(
                    formatToman(cartProvider.totalPrice),
                    style: context.textStyles.titleLarge
                        ?.withColor(AppColors.deepTeal)
                        .bold,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: rs.md),
            ElevatedButton(
              onPressed: submitting ? null : () => _onSubmit(context),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(buttonHeight),
              ),
              child: submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryWhite,
                      ),
                    )
                  : const Text('تایید نهایی و ثبت سفارش'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit(BuildContext context) async {
    final auth = context.read<AuthProvider>();

    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا وارد حساب کاربری شوید.')),
      );
      context.go('/login');
      return;
    }

    final error = await context.read<ProformaProvider>().submitOrder();

    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    // سبد خرید سمت سرور توسط SubmitOrderView پاک شده؛ همان را در UI بازتاب بده.
    await context.read<CartProvider>().loadCart();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سفارش شما با موفقیت ثبت شد.'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go('/proforma');
  }
}
