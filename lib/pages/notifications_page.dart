import 'package:azmode/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import '../theme.dart';
import '../responsive.dart';
import '../store_provider.dart';

/// صفحه‌ی اعلان‌ها.
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
          ? const _EmptyNotifications()
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
              maxWidth: 800 * context.uiScale.clamp(0.95, 1.15),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// حالت خالی
// ═══════════════════════════════════════════════════════════════
class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

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
              Icons.notifications_none,
              size: iconSize,
              color: AppColors.outlineGray,
            ),
            SizedBox(height: rs.md),
            Text(
              'فعلاً اعلانی برای شما وجود ندارد.',
              style: context.textStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// آیتم اعلان
// ═══════════════════════════════════════════════════════════════
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final formatter = intl.DateFormat('yyyy/MM/dd HH:mm');
    final isRead = notification.isRead;
    final rs = context.rs;
    final rr = context.rr;
    final ui = context.uiScale;

    // ابعاد آواتار آیکون
    final avatarRadius = (20.0 * ui).clamp(18.0, 24.0);
    final avatarIconSize = (20.0 * ui).clamp(18.0, 24.0);

    // نقطه‌ی نخوانده
    final dotSize = (10.0 * ui).clamp(8.0, 13.0);

    return Card(
      color: isRead
          ? AppColors.primaryWhite
          : AppColors.deepTeal.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(rr.md),
        side: BorderSide(
          color: isRead
              ? AppColors.outlineGray.withValues(alpha: 0.5)
              : AppColors.deepTeal.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(rr.md),
        onTap: () {
          context.read<StoreProvider>().markNotificationRead(notification.id);
          _handleTap(context);
        },
        child: Padding(
          padding: EdgeInsets.all(rs.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: _iconBgColor(notification.type),
                child: Icon(
                  _iconFor(notification.type),
                  color: AppColors.primaryWhite,
                  size: avatarIconSize,
                ),
              ),
              SizedBox(width: rs.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: context.textStyles.bodyMedium?.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: rs.xs),
                    Text(
                      notification.message,
                      style: context.textStyles.bodySmall?.copyWith(
                        height: 1.4,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: rs.xs),
                    Text(
                      formatter.format(notification.date),
                      style: context.textStyles.bodySmall?.withColor(
                        AppColors.outlineGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Padding(
                  padding: EdgeInsets.only(top: rs.xs, right: rs.xs),
                  child: Container(
                    width: dotSize,
                    height: dotSize,
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
        context.go('/proforma'); // قبلاً: context.push('/proforma')
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
