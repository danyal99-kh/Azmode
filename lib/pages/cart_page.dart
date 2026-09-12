import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../responsive.dart';
import '../store_provider.dart';
import 'cart_item_card.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final cart = store.cart;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سبد خرید',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.remove_shopping_cart,
                    size: 80,
                    color: AppColors.outlineGray,
                  ),
                  SizedBox(height: context.rs.md),
                  Text(
                    'سبد خرید شما خالی است',
                    style: context.textStyles.titleMedium,
                  ),
                  SizedBox(height: context.rs.md),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('بازگشت به خانه'),
                  ),
                ],
              ),
            )
          : context.centerMaxWidth(
              Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.all(context.rs.md),
                      itemCount: cart.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: context.rs.sm),
                      itemBuilder: (context, index) =>
                          CartItemCard(item: cart[index]),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(context.rs.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primaryWhite,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlack.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'مبلغ کل:',
                                style: context.textStyles.titleMedium,
                              ),
                              Flexible(
                                child: Text(
                                  '${store.cartTotal.toStringAsFixed(0)} تومان',
                                  style: context.textStyles.titleLarge
                                      ?.withColor(AppColors.deepTeal)
                                      .bold,
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.rs.md),
                          ElevatedButton(
                            onPressed: () {
                              if (!store.isAuthenticated) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'لطفاً ابتدا وارد حساب کاربری شوید.',
                                    ),
                                  ),
                                );
                                context.go('/profile');
                                return;
                              }
                              final error = store.submitOrder();
                              if (error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'سفارش شما با موفقیت ثبت شد.',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                context.go('/proforma');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: const Text('تایید نهایی و ثبت سفارش'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
