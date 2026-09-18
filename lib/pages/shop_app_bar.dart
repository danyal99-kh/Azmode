import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../responsive.dart';
import 'shop_search_bar.dart';
import 'cart_badge.dart';
import 'notification_button.dart';
import 'profile_avatar_button.dart';

@immutable
class ShopAppBarConfig {
  final String storeName;
  final Widget? logo;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback onSearchTap;
  final int cartItemCount;
  final VoidCallback onCartTap;
  final bool hasUnreadNotifications;
  final VoidCallback onNotificationTap;
  final bool isLoggedIn;
  final String? currentUserName;
  final VoidCallback onProfileTap;

  const ShopAppBarConfig({
    required this.storeName,
    this.logo,
    this.searchController,
    this.onSearchChanged,
    required this.onSearchTap,
    required this.cartItemCount,
    required this.onCartTap,
    required this.hasUnreadNotifications,
    required this.onNotificationTap,
    required this.isLoggedIn,
    this.currentUserName,
    required this.onProfileTap,
  });
}

/// AppBar فروشگاهی، به‌صورت یک Sliver.
class ShopAppBar extends StatelessWidget {
  final ShopAppBarConfig config;

  const ShopAppBar({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final ui = context.uiScale;

    // ارتفاع‌ها: ریسپانسیو — روی گوشی کوچک جمع‌تر، روی دسکتاپ بازتر
    final topRowHeight = (58.0 * ui).clamp(52.0, 68.0);
    final searchRowHeight = (62.0 * ui).clamp(56.0, 74.0);

    // آیکون جستجوی جمع‌شده (ردیف بالا هنگام اسکرول)
    final collapsedIconSize = (24.0 * ui).clamp(21.0, 28.0);
    final collapsedIconPadding = (10.0 * ui).clamp(8.0, 14.0);
    final collapsedBorderRadius = (22.0 * ui).clamp(20.0, 28.0);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _ShopAppBarDelegate(
        config: config,
        topPadding: MediaQuery.paddingOf(context).top,
        topRowHeight: topRowHeight,
        searchRowHeight: searchRowHeight,
        collapsedIconSize: collapsedIconSize,
        collapsedIconPadding: collapsedIconPadding,
        collapsedBorderRadius: collapsedBorderRadius,
      ),
    );
  }
}

class _ShopAppBarDelegate extends SliverPersistentHeaderDelegate {
  final ShopAppBarConfig config;
  final double topPadding;
  final double topRowHeight;
  final double searchRowHeight;
  final double collapsedIconSize;
  final double collapsedIconPadding;
  final double collapsedBorderRadius;

  _ShopAppBarDelegate({
    required this.config,
    required this.topPadding,
    required this.topRowHeight,
    required this.searchRowHeight,
    required this.collapsedIconSize,
    required this.collapsedIconPadding,
    required this.collapsedBorderRadius,
  });

  @override
  double get maxExtent => topPadding + topRowHeight + searchRowHeight;

  @override
  double get minExtent => topPadding + topRowHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double collapseRange = maxExtent - minExtent;
    final double t = collapseRange <= 0
        ? 0.0
        : (shrinkOffset / collapseRange).clamp(0.0, 1.0);

    final double currentSearchRowHeight = searchRowHeight * (1 - t);
    final double searchOpacity = (1 - (t * 1.6)).clamp(0.0, 1.0);

    return Material(
      color:
          Theme.of(context).appBarTheme.backgroundColor ??
          AppColors.primaryBlack,
      elevation: t > 0.02 ? 4 : 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: topRowHeight,
              child: _TopActionsRow(
                config: config,
                collapseProgress: t,
                collapsedIconSize: collapsedIconSize,
                collapsedIconPadding: collapsedIconPadding,
                collapsedBorderRadius: collapsedBorderRadius,
              ),
            ),
            ClipRect(
              child: SizedBox(
                height: currentSearchRowHeight,
                child: OverflowBox(
                  minHeight: searchRowHeight,
                  maxHeight: searchRowHeight,
                  alignment: Alignment.topCenter,
                  child: Opacity(
                    opacity: searchOpacity,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.rs.md,
                        0,
                        context.rs.md,
                        context.rs.sm,
                      ),
                      child: ShopSearchBar(
                        controller: config.searchController,
                        onChanged: config.onSearchChanged,
                        onTap: config.onSearchTap,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ShopAppBarDelegate oldDelegate) => true;
}

class _TopActionsRow extends StatelessWidget {
  final ShopAppBarConfig config;
  final double collapseProgress;
  final double collapsedIconSize;
  final double collapsedIconPadding;
  final double collapsedBorderRadius;

  const _TopActionsRow({
    required this.config,
    required this.collapseProgress,
    required this.collapsedIconSize,
    required this.collapsedIconPadding,
    required this.collapsedBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final double logoOpacity = (1 - collapseProgress * 2).clamp(0.0, 1.0);
    final double iconOpacity = ((collapseProgress - 0.5) * 2).clamp(0.0, 1.0);
    final bool showLogo = collapseProgress < 0.5;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rs.md),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                IgnorePointer(
                  ignoring: !showLogo,
                  child: Opacity(
                    opacity: logoOpacity,
                    child: _StoreLogo(config: config),
                  ),
                ),
                IgnorePointer(
                  ignoring: showLogo,
                  child: Opacity(
                    opacity: iconOpacity,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        collapsedBorderRadius,
                      ),
                      onTap: config.onSearchTap,
                      child: Padding(
                        padding: EdgeInsets.all(collapsedIconPadding),
                        child: Icon(
                          Icons.search,
                          color: AppColors.primaryWhite,
                          size: collapsedIconSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          CartBadge(itemCount: config.cartItemCount, onTap: config.onCartTap),
          NotificationButton(
            hasUnread: config.hasUnreadNotifications,
            onTap: config.onNotificationTap,
          ),
          ProfileAvatarButton(
            isLoggedIn: config.isLoggedIn,
            displayName: config.currentUserName,
            onTap: config.onProfileTap,
          ),
        ],
      ),
    );
  }
}

class _StoreLogo extends StatelessWidget {
  final ShopAppBarConfig config;
  const _StoreLogo({required this.config});

  @override
  Widget build(BuildContext context) {
    if (config.logo != null) return config.logo!;
    return Text(
      config.storeName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.textStyles.titleLarge?.withColor(AppColors.primaryWhite),
    );
  }
}
