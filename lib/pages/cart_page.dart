import 'package:azmode/pages/product_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../responsive.dart';
import '../store_provider.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final cart = store.cart;
    final imgSize = context.responsive<double>(
      mobile: 80,
      tablet: 92,
      desktop: 100,
    );

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
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return Card(
                          child: Padding(
                            padding: EdgeInsets.all(context.rs.sm),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: imgSize,
                                  height: imgSize,
                                  child: ProductImage(
                                    imageUrl: item.product.imageUrl,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                ),
                                SizedBox(width: context.rs.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: context
                                            .textStyles
                                            .titleMedium
                                            ?.bold,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: context.rs.xs),
                                      Text(
                                        '${item.product.price} تومان',
                                        style: context.textStyles.bodyMedium,
                                      ),
                                      if (item.selectedColor != null)
                                        Text(
                                          'رنگ: ${item.selectedColor}',
                                          style: context.textStyles.bodySmall,
                                        ),
                                      SizedBox(height: context.rs.sm),
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
                                                selectedColor:
                                                    item.selectedColor,
                                              );
                                            },
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style:
                                                context.textStyles.titleMedium,
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
                                                  selectedColor:
                                                      item.selectedColor,
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
                                                selectedColor:
                                                    item.selectedColor,
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
                                  '${store.cartTotal} تومان',
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
