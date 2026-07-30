import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../store_provider.dart';

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
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'سبد خرید شما خالی است',
                    style: context.textStyles.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('بازگشت به خانه'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                child: Image.asset(
                                  item.product.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    color: AppColors.surfaceWhite,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: AppColors.outlineGray,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style:
                                          context.textStyles.titleMedium?.bold,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '${item.product.price} تومان',
                                      style: context.textStyles.bodyMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: AppColors.deepTeal,
                                          ),
                                          onPressed: () {
                                            store.updateCartItemQuantity(
                                              item.product.id,
                                              item.quantity - 1,
                                            );
                                          },
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: context.textStyles.titleMedium,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: AppColors.deepTeal,
                                          ),
                                          onPressed: () {
                                            if (item.quantity <
                                                item.product.stock) {
                                              store.updateCartItemQuantity(
                                                item.product.id,
                                                item.quantity + 1,
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'موجودی کالا کافی نیست.',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.error,
                                          ),
                                          onPressed: () {
                                            store.removeFromCart(
                                              item.product.id,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
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
                            Text(
                              '${store.cartTotal} تومان',
                              style: context.textStyles.titleLarge
                                  ?.withColor(AppColors.deepTeal)
                                  .bold,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
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
                                  content: Text('سفارش شما با موفقیت ثبت شد.'),
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
    );
  }
}
