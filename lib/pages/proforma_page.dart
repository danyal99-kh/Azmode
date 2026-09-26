import '../models/proforma_item.dart';
import 'package:azmode/pages/price_utils.dart';
import 'package:azmode/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../theme.dart';
import '../responsive.dart';
import '../models/proforma.dart';
import '../providers/proforma_provider.dart';

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
      if (mounted) context.read<ProformaProvider>().loadMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
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

    final proforma = context.watch<ProformaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سفارش‌ها و پیش‌فاکتورها',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
      ),
      body: _buildBody(context, proforma),
    );
  }

  Widget _buildBody(BuildContext context, ProformaProvider proforma) {
    if (proforma.myOrdersLoading && proforma.myOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (proforma.myOrdersError != null && proforma.myOrders.isEmpty) {
      return _EmptyState(
        message: proforma.myOrdersError!,
        onRetry: () => proforma.loadMyOrders(),
      );
    }

    final orders = proforma.myOrders;

    return RefreshIndicator(
      color: AppColors.deepTeal,
      onRefresh: proforma.loadMyOrders,
      child: orders.isEmpty
          ? ListView(
              // برای این‌که RefreshIndicator حتی روی حالت خالی هم کار کند.
              children: const [
                SizedBox(height: 120),
                _EmptyState(message: 'هیچ سفارشی تاکنون ثبت نشده است.'),
              ],
            )
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
// حالت خالی / خطا
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _EmptyState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.rs.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: context.textStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: context.rs.md),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('تلاش مجدد'),
              ),
            ],
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
  final ProformaOrder order;
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
              'تاریخ: ${formatter.format(order.createdAt)}',
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
  final ProformaOrder order;
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

  String _getStatusText(ProformaStatus status) {
    switch (status) {
      case ProformaStatus.pending:
        return 'در انتظار تایید';
      case ProformaStatus.approved:
        return 'تایید شده';
      case ProformaStatus.rejected:
        return 'رد شده';
    }
  }

  Color _getStatusColor(ProformaStatus status) {
    switch (status) {
      case ProformaStatus.pending:
        return AppColors.warning;
      case ProformaStatus.approved:
        return AppColors.success;
      case ProformaStatus.rejected:
        return AppColors.error;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// ردیف یک آیتم سفارش
// ═══════════════════════════════════════════════════════════════
class _OrderItemRow extends StatelessWidget {
  final ProformaOrderItem item;
  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    final nameStyle = context.textStyles.bodyMedium;
    final qtyText = Text(
      '${item.productName} (x${item.quantity})',
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      style: nameStyle,
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
                if (colorName != null && colorName.trim().isNotEmpty)
                  Text(
                    'رنگ: $colorName',
                    style: context.textStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                    if (colorName != null && colorName.trim().isNotEmpty)
                      Text(
                        'رنگ: $colorName',
                        style: context.textStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
