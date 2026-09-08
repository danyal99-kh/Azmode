import 'package:flutter/material.dart';
import 'app_bar_icon_button.dart';
import '../../theme.dart';

/// دکمه‌ی اعلان‌ها در AppBar.
///
/// [hasUnread] هم مثل [CartBadge] از بیرون تعیین می‌شود (مثلاً از یک
/// `unreadNotificationCount` در StoreProvider که بزرگ‌تر از صفر است).
/// در نبود اعلان نخوانده، هیچ Badge‌ای نمایش داده نمی‌شود.
class NotificationButton extends StatelessWidget {
  final bool hasUnread;
  final VoidCallback onTap;
  final Color iconColor;

  const NotificationButton({
    super.key,
    required this.hasUnread,
    required this.onTap,
    this.iconColor = AppColors.primaryWhite,
  });

  @override
  Widget build(BuildContext context) {
    return AppBarIconButton(
      icon: Icons.notifications_outlined,
      tooltip: 'اعلان‌ها',
      onTap: onTap,
      iconColor: iconColor,
      badge: hasUnread ? const DotBadge() : null,
    );
  }
}
