import 'package:azmode/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import '../theme.dart';
import '../responsive.dart';
import '../store_provider.dart';

/// صفحه‌ی اعلان‌ها.
///
/// دو نوع اعلان اصلی اینجا نمایش داده می‌شود:
/// 1) محصول جدید — وقتی ادمین محصولی اضافه می‌کند، برای همه‌ی کاربران
///    (و حتی کاربر مهمان) قابل مشاهده است.
/// 2) وضعیت سفارش — وقتی ادمین یک سفارش را تایید یا رد می‌کند، فقط برای
///    همان کاربری که صاحب سفارش است نمایش داده می‌شود.
///
/// لمس هر اعلان آن را «خوانده‌شده» می‌کند و در صورت امکان کاربر را به
/// صفحه‌ی مرتبط (جزئیات محصول یا پیش‌فاکتورها) هدایت می‌کند.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final notifications = store.myNotifications.reversed.toList();
    final hasUnread = notifications.any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اعلان‌ها',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryWhite),
          tooltip: 'بازگشت',
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () => store.markAllNotificationsRead(),
              child: const Text(
                'خواندن همه',
                style: TextStyle(color: AppColors.primaryWhite),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: AppColors.outlineGray,
                  ),
                  SizedBox(height: context.rs.md),
                  Text(
                    'فعلاً اعلانی برای شما وجود ندارد.',
                    style: context.textStyles.titleMedium,
                  ),
                ],
              ),
            )
          : context.centerMaxWidth(
              ListView.separated(
                padding: EdgeInsets.all(context.rs.md),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => SizedBox(height: context.rs.sm),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return _NotificationTile(notification: n);
                },
              ),
              maxWidth: 800,
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final formatter = intl.DateFormat('yyyy/MM/dd HH:mm');
    final isRead = notification.isRead;

    return Card(
      color: isRead
          ? AppColors.primaryWhite
          : AppColors.deepTeal.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isRead
              ? AppColors.outlineGray.withOpacity(0.5)
              : AppColors.deepTeal.withOpacity(0.35),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          context.read<StoreProvider>().markNotificationRead(notification.id);
          _handleTap(context);
        },
        child: Padding(
          padding: EdgeInsets.all(context.rs.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _iconBgColor(notification.type),
                child: Icon(
                  _iconFor(notification.type),
                  color: AppColors.primaryWhite,
                  size: 20,
                ),
              ),
              SizedBox(width: context.rs.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: context.textStyles.bodyMedium?.bold,
                    ),
                    SizedBox(height: context.rs.xs),
                    Text(
                      notification.message,
                      style: context.textStyles.bodySmall?.copyWith(
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: context.rs.xs),
                    Text(
                      formatter.format(notification.date),
                      style: context.textStyles.bodySmall?.withColor(
                        AppColors.outlineGray,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.deepTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    switch (notification.type) {
      case NotificationType.newProduct:
        if (notification.relatedId != null) {
          context.push('/product/${notification.relatedId}');
        }
        break;
      case NotificationType.orderApproved:
      case NotificationType.orderRejected:
        context.push('/proforma');
        break;
      case NotificationType.general:
        break;
    }
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.newProduct:
        return Icons.new_releases_outlined;
      case NotificationType.orderApproved:
        return Icons.check_circle_outline;
      case NotificationType.orderRejected:
        return Icons.cancel_outlined;
      case NotificationType.general:
        return Icons.notifications_outlined;
    }
  }

  Color _iconBgColor(NotificationType type) {
    switch (type) {
      case NotificationType.newProduct:
        return AppColors.deepTeal;
      case NotificationType.orderApproved:
        return AppColors.success;
      case NotificationType.orderRejected:
        return AppColors.error;
      case NotificationType.general:
        return AppColors.darkGray;
    }
  }
}
