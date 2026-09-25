import 'package:azmode/models/order.dart';
import 'package:azmode/pages/price_utils.dart';
import 'package:azmode/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;

import '../responsive.dart';
import '../theme.dart';

class ProformaPage extends StatefulWidget {
  const ProformaPage({super.key});

  @override
  State<ProformaPage> createState() => _ProformaPageState();
}

class _ProformaPageState extends State<ProformaPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سفارش‌ها و پیش‌فاکتورها',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
      ),
      body: _buildBody(context, orderProvider),
    );
  }

  Widget _buildBody(BuildContext context, OrderProvider orderProvider) {
    if (orderProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orderProvider.status == OrderStatusState.error) {
      return _ErrorState(
        message: orderProvider.errorMessage ?? 'دریافت سفارش‌ها انجام نشد.',
        onRetry: () {
          context.read<OrderProvider>().loadMyOrders();
        },
      );
    }

    final orders = orderProvider.orders.reversed.toList();

    if (orders.isEmpty) {
      return const _EmptyState(message: 'هیچ سفارشی تاکنون ثبت نشده است.');
    }

    return context.centerMaxWidth(
      ListView.separated(
        padding: EdgeInsets.all(context.rs.md),
        itemCount: orders.length,
        separatorBuilder: (_, __) => SizedBox(height: context.rs.md),
        itemBuilder: (context, index) {
          return _OrderCard(order: orders[index]);
        },
      ),
      maxWidth: 800 * context.uiScale.clamp(0.95, 1.15),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// حالت خالی
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.rs.xl),
        child: Text(
          message,
          style: context.textStyles.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// حالت خطا
// ═══════════════════════════════════════════════════════════════

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.rs.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            SizedBox(height: context.rs.md),
            Text(
              message,
              style: context.textStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.rs.lg),
            ElevatedButton(onPressed: onRetry, child: const Text('تلاش مجدد')),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// کارت سفارش
// ═══════════════════════════════════════════════════════════════

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final formatter = intl.DateFormat('yyyy/MM/dd HH:mm');

    return Card(
      child: Padding(
        padding: EdgeInsets.all(rs.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrderHeader(order: order),

            SizedBox(height: rs.sm),

            Text(
              'تاریخ: ${formatter.format(order.createdAt.toLocal())}',
              style: context.textStyles.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.outlineGray,
                ),
                SizedBox(width: context.rs.xs),
                Expanded(
                  child: Text(
                    order.customerName,
                    style: context.textStyles.bodyMedium?.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: context.rs.xs),

            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: AppColors.outlineGray,
                ),
                SizedBox(width: context.rs.xs),
                SelectableText(
                  order.customerPhone,
                  style: context.textStyles.bodyMedium,
                ),
              ],
            ),

            Divider(height: rs.lg),

            ...order.items.map((item) => _OrderItemRow(item: item)),

            Divider(height: rs.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('جمع کل:', style: context.textStyles.titleMedium),
                SizedBox(width: rs.sm),
                Flexible(
                  child: Text(
                    formatToman(order.totalAmount),
                    style: context.textStyles.titleMedium?.bold.withColor(
                      AppColors.deepTeal,
                    ),
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// هدر کارت سفارش
// ═══════════════════════════════════════════════════════════════

class _OrderHeader extends StatelessWidget {
  final Order order;

  const _OrderHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final rr = context.rr;

    final statusColor = _getStatusColor(order.status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'سفارش #${order.id}',
            style: context.textStyles.titleMedium?.bold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        SizedBox(width: rs.sm),

        Container(
          padding: EdgeInsets.symmetric(
            horizontal: rs.sm,
            vertical: (rs.xs * 0.8).clamp(3.0, 6.0),
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(rr.sm),
          ),
          child: Text(
            _getStatusText(order.status),
            style: context.textStyles.bodySmall?.withColor(statusColor).bold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'در انتظار تایید';

      case OrderStatus.approved:
        return 'تایید شده';

      case OrderStatus.rejected:
        return 'رد شده';
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

// ═══════════════════════════════════════════════════════════════
// ردیف آیتم سفارش
// ═══════════════════════════════════════════════════════════════

class _OrderItemRow extends StatelessWidget {
  final OrderItem item;

  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    final qtyText = Text(
      '${item.productName} (x${item.quantity})',
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      style: context.textStyles.bodyMedium,
    );

    final priceText = Text(
      formatToman(item.totalPrice),
      style: context.textStyles.bodyMedium?.bold,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final colorName = item.selectedColor;

    return Padding(
      padding: EdgeInsets.only(bottom: rs.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 320 * context.uiScale;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                qtyText,

                if (colorName != null) _ColorLine(colorName: colorName, rs: rs),

                SizedBox(height: rs.xs),

                priceText,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    qtyText,

                    if (colorName != null)
                      _ColorLine(colorName: colorName, rs: rs),
                  ],
                ),
              ),

              SizedBox(width: rs.sm),

              priceText,
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// خط نمایش رنگ
// ═══════════════════════════════════════════════════════════════

class _ColorLine extends StatelessWidget {
  final String colorName;
  final RSpacing rs;

  const _ColorLine({required this.colorName, required this.rs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: rs.xs * 0.5),
      child: Text(
        'رنگ: $colorName',
        style: context.textStyles.bodySmall?.copyWith(
          color: _getColorFromName(colorName),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color? _getColorFromName(String colorName) {
    final colors = {
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

    return colors[colorName];
  }
}
