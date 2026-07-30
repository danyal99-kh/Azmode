import 'package:azmode/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../theme.dart';
import '../store_provider.dart';

class ProformaPage extends StatelessWidget {
  const ProformaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();

    if (!store.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'پیش‌فاکتورها',
            style: context.textStyles.titleLarge?.withColor(
              AppColors.primaryWhite,
            ),
          ),
        ),
        body: const Center(child: Text('لطفا وارد حساب کاربری خود شوید.')),
      );
    }

    final orders = store.orders.reversed.toList(); // Newest first

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سفارش‌ها و پیش‌فاکتورها',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
      ),
      body: orders.isEmpty
          ? const Center(child: Text('هیچ سفارشی تاکنون ثبت نشده است.'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final order = orders[index];
                final formatter = intl.DateFormat('yyyy/MM/dd HH:mm');

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'سفارش #${order.id.substring(0, 8)}',
                              style: context.textStyles.titleMedium?.bold,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  order.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Text(
                                _getStatusText(order.status),
                                style: context.textStyles.bodySmall
                                    ?.withColor(_getStatusColor(order.status))
                                    .bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'تاریخ: ${formatter.format(order.date)}',
                          style: context.textStyles.bodyMedium,
                        ),
                        const Divider(height: AppSpacing.lg),
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.product.name} (x${item.quantity})',
                                  ),
                                ),
                                Text('${item.totalPrice} تومان'),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'جمع کل:',
                              style: context.textStyles.titleMedium,
                            ),
                            Text(
                              '${order.totalAmount} تومان',
                              style: context.textStyles.titleMedium?.bold
                                  .withColor(AppColors.deepTeal),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'در انتظار تایید'; // pending
      case OrderStatus.approved:
        return 'تایید شده'; // approved
      case OrderStatus.rejected:
        return 'رد شده'; // rejected
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.approved:
        return AppColors.success;
      case OrderStatus.rejected:
        return AppColors.error;
    }
  }
}
