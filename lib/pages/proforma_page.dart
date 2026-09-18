import 'package:azmode/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../theme.dart';
import '../responsive.dart';
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
        body: const _EmptyState(message: 'لطفا وارد حساب کاربری خود شوید.'),
      );
    }

    final orders = store.myOrders.reversed.toList();

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
          ? const _EmptyState(message: 'هیچ سفارشی تاکنون ثبت نشده است.')
          : context.centerMaxWidth(
              ListView.separated(
                padding: EdgeInsets.all(context.rs.md),
                itemCount: orders.length,
                separatorBuilder: (_, __) => SizedBox(height: context.rs.md),
                itemBuilder: (context, index) {
                  return _OrderCard(order: orders[index]);
                },
              ),
              maxWidth: 800 * context.uiScale.clamp(0.95, 1.15),
            ),
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
            // هدر: شماره سفارش + badge وضعیت
            _OrderHeader(order: order),

            SizedBox(height: rs.sm),
            Text(
              'تاریخ: ${formatter.format(order.date)}',
              style: context.textStyles.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            Divider(height: rs.lg),

            // آیتم‌های سفارش
            ...order.items.map((item) => _OrderItemRow(item: item)),

            Divider(height: rs.lg),

            // جمع کل
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('جمع کل:', style: context.textStyles.titleMedium),
                SizedBox(width: rs.sm),
                Flexible(
                  child: Text(
                    '${order.totalAmount} تومان',
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
    final ui = context.uiScale;

    final statusColor = _getStatusColor(order.status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'سفارش #${order.id.substring(0, 8)}',
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
// ردیف یک آیتم سفارش
// ═══════════════════════════════════════════════════════════════
class _OrderItemRow extends StatelessWidget {
  final CartItem item;
  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    final nameStyle = context.textStyles.bodyMedium;
    final qtyText = Text(
      '${item.product.name} (x${item.quantity})',
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      style: nameStyle,
    );

    final priceText = Text(
      '${item.totalPrice} تومان',
      style: context.textStyles.bodyMedium?.bold,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final colorName = item.selectedColor;

    return Padding(
      padding: EdgeInsets.only(bottom: rs.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // روی عرض‌های باریک، قیمت زیر نام قرار می‌گیرد
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
