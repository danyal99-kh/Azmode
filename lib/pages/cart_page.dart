import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_provider.dart';
import '../theme.dart';
import '../responsive.dart';
import 'price_utils.dart';

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
                final item = cart.items[index];

                return _CartItemCard(
                  itemId: item.id,
                  productId: item.productId,
                  quantity: item.quantity,
                  selectedColor: item.selectedColor,
                  totalPrice: item.totalPrice,
                );
              },
            ),
          ),
          _CartSummaryBar(cart: cart),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final int itemId;
  final int productId;
  final int quantity;
  final String? selectedColor;
  final double totalPrice;

  const _CartItemCard({
    required this.itemId,
    required this.productId,
    required this.quantity,
    required this.selectedColor,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(rs.md),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 48),
            SizedBox(width: rs.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'محصول #$productId',
                    style: context.textStyles.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text('تعداد: $quantity'),
                  if (selectedColor != null && selectedColor!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('رنگ: $selectedColor'),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    formatToman(totalPrice),
                    style: context.textStyles.titleMedium
                        ?.withColor(AppColors.deepTeal)
                        .bold,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () async {
                final success = await context.read<CartProvider>().removeItem(
                  itemId,
                );

                if (!context.mounted) return;

                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.read<CartProvider>().errorMessage ??
                            'حذف کالا انجام نشد.',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  final CartProvider cart;

  const _CartSummaryBar({required this.cart});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final ui = context.uiScale;

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
                    formatToman(cart.totalPrice),
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
              onPressed: () {
                context.go('/proforma');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(buttonHeight),
              ),
              child: const Text('تایید نهایی و ثبت سفارش'),
            ),
          ],
        ),
      ),
    );
  }
}
