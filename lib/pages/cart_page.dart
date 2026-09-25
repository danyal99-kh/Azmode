import 'package:azmode/pages/price_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../responsive.dart';
import '../model.dart';
import '../providers/cart_provider.dart';
import '../store_provider.dart';
import 'cart_item_card.dart';

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
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سبد خرید',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
      ),
      body: cartProvider.isLoading && cart.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cart.isEmpty
          ? _EmptyCartView(onBackHome: () => context.go('/'))
          : _CartContent(cartProvider: cartProvider, cart: cart),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// حالت خالی بودن سبد
// ═══════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════
// محتوای سبد (لیست + نوار پایین)
// ═══════════════════════════════════════════════════════════════
class _CartContent extends StatelessWidget {
  final CartProvider cartProvider;
  final List<CartItem> cart;

  const _CartContent({required this.cartProvider, required this.cart});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    return context.centerMaxWidth(
      Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(rs.md),
              itemCount: cart.length,
              separatorBuilder: (_, __) => SizedBox(height: rs.sm),
              itemBuilder: (context, index) {
                return CartItemCard(item: cart[index]);
              },
            ),
          ),
          _CartSummaryBar(cartProvider: cartProvider),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// نوار پایین: مبلغ کل + دکمه ثبت
// ═══════════════════════════════════════════════════════════════
class _CartSummaryBar extends StatelessWidget {
  final CartProvider cartProvider;

  const _CartSummaryBar({required this.cartProvider});

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
              onPressed: () => _onSubmit(context),
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

  void _onSubmit(BuildContext context) {
    final store = context.read<StoreProvider>();

    if (!store.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا وارد حساب کاربری شوید.')),
      );
      context.go('/profile');
      return;
    }

    final error = store.submitOrder();

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سفارش شما با موفقیت ثبت شد.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/proforma');
    }
  }
}
