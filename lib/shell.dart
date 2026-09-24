import 'package:azmode/pages/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../store_provider.dart';
import '../theme.dart';
import 'responsive.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // وضعیت باز/بسته بودن ریل — قابل تغییر توسط کاربر
  bool _railExpanded = true;

  int _currentIndexFromLocation(String location) {
    if (location.startsWith('/cart')) return 0;
    if (location.startsWith('/categories')) return 1;
    if (location == '/' || location == '/home') return 2;
    if (location.startsWith('/proforma')) return 3;
    if (location.startsWith('/profile') || location.startsWith('/admin')) {
      return 4;
    }
    if (location.startsWith('/product/')) return 2;
    return 2;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/cart');
        break;
      case 1:
        context.go('/categories');
        break;
      case 2:
        context.go('/');
        break;
      case 3:
        context.go('/proforma');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final int currentIndex = _currentIndexFromLocation(location);

    if (context.isDesktop) {
      return _buildDesktopLayout(context, currentIndex);
    }
    return _buildMobileLayout(context, currentIndex);
  }

  // ═════════════════════════════════════════════════════════════
  // چیدمان دسکتاپ/ویندوز
  // ═════════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(BuildContext context, int currentIndex) {
    return Scaffold(
      body: Row(
        children: [
          _AdvancedNavigationRail(
            currentIndex: currentIndex,
            expanded: _railExpanded,
            onToggleExpand: () =>
                setState(() => _railExpanded = !_railExpanded),
            onTap: (i) => _onTap(context, i),
          ),
          Expanded(child: context.centerMaxWidth(widget.child)),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, int currentIndex) {
    final maxWidth = context.responsive<double>(mobile: 640, tablet: 720);

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: widget.child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Align(
          heightFactor: 1,
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: CustomBottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) => _onTap(context, index),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ریل ناوبری پیشرفته (دسکتاپ/ویندوز)
// ═══════════════════════════════════════════════════════════════
class _AdvancedNavigationRail extends StatelessWidget {
  final int currentIndex;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<int> onTap;

  const _AdvancedNavigationRail({
    required this.currentIndex,
    required this.expanded,
    required this.onToggleExpand,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final ui = context.uiScale;
    final fs = context.fontScale;

    // تعداد آیتم‌های سبد برای Badge
    final cartItemCount = store.cart.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final hasUnreadNotifs = store.unreadNotificationCount > 0;

    // ── آیتم‌های اصلی ──
    final mainItems = <_RailItemData>[
      _RailItemData(
        icon: Icons.shopping_cart_outlined,
        selectedIcon: Icons.shopping_cart,
        label: 'سبد خرید',
        badge: cartItemCount > 0 ? _RailBadgeData(count: cartItemCount) : null,
      ),
      _RailItemData(
        icon: Icons.grid_view_outlined,
        selectedIcon: Icons.grid_view_rounded,
        label: 'دسته‌بندی‌ها',
      ),
      _RailItemData(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'خانه',
      ),
      _RailItemData(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: 'پیش‌فاکتور',
      ),
      _RailItemData(
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications_rounded,
        label: 'اعلان‌ها',
        badge: hasUnreadNotifs ? const _RailBadgeData(dot: true) : null,
        onCustomTap: () => context.push('/notifications'),
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: expanded ? 240 * ui : 76 * ui,
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12 * ui.clamp(0.9, 1.3),
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── هدر: لوگو (کلیک‌پذیر) + دکمه toggle ──
          _RailHeader(
            expanded: expanded,
            onToggleExpand: onToggleExpand,
            ui: ui,
            fs: fs,
          ),

          Divider(
            color: AppColors.primaryWhite.withValues(alpha: 0.08),
            height: 1,
          ),

          // ── آیتم‌های اصلی ──
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 12 * ui.clamp(0.9, 1.2)),
              children: [
                for (var i = 0; i < mainItems.length; i++)
                  _RailItem(
                    data: mainItems[i],
                    selected: currentIndex == i,
                    expanded: expanded,
                    ui: ui,
                    fs: fs,
                    onTap: () {
                      if (mainItems[i].onCustomTap != null) {
                        mainItems[i].onCustomTap!();
                      } else {
                        onTap(i);
                      }
                    },
                  ),
              ],
            ),
          ),

          Divider(
            color: AppColors.primaryWhite.withValues(alpha: 0.08),
            height: 1,
          ),

          // ── بخش پروفایل پایین ──
          _RailProfileSection(
            expanded: expanded,
            ui: ui,
            fs: fs,
            isSelected: currentIndex == 4,
            isLoggedIn: store.isAuthenticated,
            userName: store.currentUser?.username,
            isAdmin: store.isAdmin,
            onTap: () => onTap(4),
          ),

          SizedBox(height: 8 * ui.clamp(0.9, 1.2)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// هدر ریل: لوگو (کلیک‌پذیر برای toggle) + دکمه‌ی toggle
// ═══════════════════════════════════════════════════════════════
class _RailHeader extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggleExpand;
  final double ui;
  final double fs;

  const _RailHeader({
    required this.expanded,
    required this.onToggleExpand,
    required this.ui,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    final pad = (16.0 * ui).clamp(12.0, 20.0);

    // ═══════════════════════════════════════════════════════════
    // حالت باز: لوگو (کلیک‌پذیر) + نام + دکمه جمع کردن
    // ═══════════════════════════════════════════════════════════
    if (expanded) {
      return Padding(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, pad * 0.75),
        child: Row(
          children: [
            _RailLogo(ui: ui, onTap: onToggleExpand, tooltip: 'جمع کردن منو'),
            SizedBox(width: 10 * ui),
            Expanded(
              child: Text(
                'آزموده',
                style: TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: (15 * fs).clamp(13, 18),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _IconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'جمع کردن منو',
              onTap: onToggleExpand,
              ui: ui,
            ),
          ],
        ),
      );
    }

    // ═══════════════════════════════════════════════════════════
    // حالت بسته: لوگو بالا + دکمه باز کردن زیرش (عمودی، وسط‌چین)
    // هر دو کلیک‌پذیر
    // ═══════════════════════════════════════════════════════════
    return Padding(
      padding: EdgeInsets.symmetric(vertical: pad * 0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RailLogo(ui: ui, onTap: onToggleExpand, tooltip: 'باز کردن منو'),
          SizedBox(height: 10 * ui),
          _IconButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'باز کردن منو',
            onTap: onToggleExpand,
            ui: ui,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// لوگو — با hover و کلیک‌پذیری
// ═══════════════════════════════════════════════════════════════
class _RailLogo extends StatefulWidget {
  final double ui;
  final VoidCallback? onTap;
  final String? tooltip;

  const _RailLogo({required this.ui, this.onTap, this.tooltip});

  @override
  State<_RailLogo> createState() => _RailLogoState();
}

class _RailLogoState extends State<_RailLogo> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final ui = widget.ui;

    final logo = MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32 * ui,
          height: 32 * ui,
          decoration: BoxDecoration(
            color: _hovering && widget.onTap != null
                ? AppColors.deepTeal.withValues(alpha: 0.35)
                : AppColors.deepTeal.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10 * ui),
            border: _hovering && widget.onTap != null
                ? Border.all(
                    color: AppColors.deepTeal.withValues(alpha: 0.6),
                    width: 1.5,
                  )
                : null,
          ),
          child: Icon(
            Icons.storefront_rounded,
            color: AppColors.deepTeal,
            size: 20 * ui,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: logo);
    }
    return logo;
  }
}

// ═══════════════════════════════════════════════════════════════
// آیتم منو
// ═══════════════════════════════════════════════════════════════
class _RailItem extends StatefulWidget {
  final _RailItemData data;
  final bool selected;
  final bool expanded;
  final double ui;
  final double fs;
  final VoidCallback onTap;

  const _RailItem({
    required this.data,
    required this.selected,
    required this.expanded,
    required this.ui,
    required this.fs,
    required this.onTap,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final ui = widget.ui;
    final selected = widget.selected;
    final expanded = widget.expanded;

    final hPad = (10.0 * ui).clamp(8.0, 14.0);
    final vPad = (10.0 * ui).clamp(8.0, 14.0);
    final iconSize = (22.0 * ui).clamp(20.0, 26.0);
    final radius = (12.0 * ui).clamp(10.0, 16.0);

    final bgColor = selected
        ? AppColors.deepTeal.withValues(alpha: 0.15)
        : _hovering
        ? AppColors.primaryWhite.withValues(alpha: 0.05)
        : Colors.transparent;

    final fgColor = selected
        ? AppColors.deepTeal
        : _hovering
        ? AppColors.primaryWhite
        : AppColors.primaryWhite.withValues(alpha: 0.75);

    final child = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: 2 * ui.clamp(0.9, 1.2),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(radius),
              border: selected
                  ? BorderDirectional(
                      start: BorderSide(
                        color: AppColors.deepTeal,
                        width: (3 * ui).clamp(2.5, 4),
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        selected ? widget.data.selectedIcon : widget.data.icon,
                        key: ValueKey(selected),
                        color: fgColor,
                        size: iconSize,
                      ),
                    ),
                    if (widget.data.badge != null)
                      Positioned(
                        top: -3 * ui,
                        right: -4 * ui,
                        child: _RailBadge(data: widget.data.badge!, ui: ui),
                      ),
                  ],
                ),
                if (expanded) ...[
                  SizedBox(width: 12 * ui),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        color: fgColor,
                        fontSize: (14 * widget.fs).clamp(12.5, 16),
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                      child: Text(
                        widget.data.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return expanded
        ? child
        : Tooltip(
            message: widget.data.label,
            waitDuration: const Duration(milliseconds: 400),
            child: child,
          );
  }
}

// ═══════════════════════════════════════════════════════════════
// بخش پروفایل پایین ریل
// ═══════════════════════════════════════════════════════════════
class _RailProfileSection extends StatefulWidget {
  final bool expanded;
  final double ui;
  final double fs;
  final bool isSelected;
  final bool isLoggedIn;
  final String? userName;
  final bool isAdmin;
  final VoidCallback onTap;

  const _RailProfileSection({
    required this.expanded,
    required this.ui,
    required this.fs,
    required this.isSelected,
    required this.isLoggedIn,
    required this.userName,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  State<_RailProfileSection> createState() => _RailProfileSectionState();
}

class _RailProfileSectionState extends State<_RailProfileSection> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final ui = widget.ui;
    final expanded = widget.expanded;
    final isSelected = widget.isSelected;

    final hPad = (10.0 * ui).clamp(8.0, 14.0);
    final vPad = (10.0 * ui).clamp(8.0, 14.0);

    final bgColor = isSelected
        ? AppColors.deepTeal.withValues(alpha: 0.15)
        : _hovering
        ? AppColors.primaryWhite.withValues(alpha: 0.05)
        : Colors.transparent;

    final textColor = isSelected
        ? AppColors.deepTeal
        : AppColors.primaryWhite.withValues(alpha: 0.85);

    final displayName = widget.isLoggedIn
        ? (widget.userName ?? 'کاربر')
        : 'ورود / ثبت‌نام';

    final subtitle = widget.isLoggedIn
        ? (widget.isAdmin ? 'مدیر سیستم' : 'مشتری')
        : 'حساب کاربری';

    final initial = widget.isLoggedIn && widget.userName != null
        ? widget.userName!.trim().isNotEmpty
              ? widget.userName!.trim()[0].toUpperCase()
              : '?'
        : null;

    final child = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: 2 * ui.clamp(0.9, 1.2),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(
                (12.0 * ui).clamp(10.0, 16.0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32 * ui,
                  height: 32 * ui,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isLoggedIn
                        ? AppColors.deepTeal
                        : AppColors.primaryWhite.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.deepTeal
                          : AppColors.primaryWhite.withValues(alpha: 0.2),
                      width: 1.5 * ui.clamp(0.9, 1.5),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: widget.isLoggedIn && initial != null
                      ? Text(
                          initial,
                          style: TextStyle(
                            color: AppColors.primaryWhite,
                            fontSize: (13 * widget.fs).clamp(11, 15),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Icon(
                          Icons.person_outline_rounded,
                          color: textColor,
                          size: 18 * ui,
                        ),
                ),
                if (expanded) ...[
                  SizedBox(width: 12 * ui),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            color: textColor,
                            fontSize: (13 * widget.fs).clamp(11.5, 15),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.primaryWhite.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: (11 * widget.fs).clamp(9.5, 12.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return expanded
        ? child
        : Tooltip(
            message: displayName,
            waitDuration: const Duration(milliseconds: 400),
            child: child,
          );
  }
}

// ═══════════════════════════════════════════════════════════════
// Badge آیتم‌ها
// ═══════════════════════════════════════════════════════════════
class _RailBadge extends StatelessWidget {
  final _RailBadgeData data;
  final double ui;

  const _RailBadge({required this.data, required this.ui});

  @override
  Widget build(BuildContext context) {
    if (data.dot) {
      return Container(
        width: 9 * ui,
        height: 9 * ui,
        decoration: BoxDecoration(
          color: AppColors.warning,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryBlack,
            width: 1.5 * ui.clamp(0.9, 1.5),
          ),
        ),
      );
    }

    final count = data.count ?? 0;
    final text = count > 99 ? '99+' : '$count';

    return Container(
      constraints: BoxConstraints(minWidth: 18 * ui, minHeight: 18 * ui),
      padding: EdgeInsets.symmetric(horizontal: 4 * ui),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primaryBlack,
          width: 1.5 * ui.clamp(0.9, 1.5),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.primaryWhite,
          fontSize: (10 * ui).clamp(9, 11.5),
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// دکمه آیکونی کوچک (برای toggle ریل)
// ═══════════════════════════════════════════════════════════════
class _IconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double ui;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.ui,
  });

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final ui = widget.ui;
    final size = 32 * ui;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _hovering
                  ? AppColors.primaryWhite.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8 * ui),
            ),
            child: Icon(
              widget.icon,
              color: AppColors.primaryWhite.withValues(alpha: 0.75),
              size: 20 * ui,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// مدل داده‌ی آیتم منو
// ═══════════════════════════════════════════════════════════════
class _RailItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final _RailBadgeData? badge;
  final VoidCallback? onCustomTap;

  const _RailItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge,
    this.onCustomTap,
  });
}

class _RailBadgeData {
  final int? count;
  final bool dot;

  const _RailBadgeData({this.count, this.dot = false});
}
