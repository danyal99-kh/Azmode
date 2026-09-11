import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../responsive.dart';
import 'shop_search_bar.dart';
import 'cart_badge.dart';
import 'notification_button.dart';
import 'profile_avatar_button.dart';

/// همه‌ی داده‌ها و Callbackهایی که [ShopAppBar] برای نمایش نیاز دارد، در
/// یک کلاس جمع شده‌اند تا:
/// 1) امضای ShopAppBar شلوغ و پر از پارامتر نشود.
/// 2) وصل کردن این AppBar به هر State Management (Provider، Riverpod،
///    Bloc و ...) در آینده فقط به معنی ساختن یک [ShopAppBarConfig] جدید
///    از روی همان State باشد؛ خود ShopAppBar هیچ وابستگی مستقیمی به
///    StoreProvider ندارد.
///
/// نکته: فیلتر دسته‌بندی‌ها دیگر بخشی از این AppBar نیست — مسئولیت آن
/// به خودِ صفحه (مثلاً HomePage) منتقل شده تا این کامپوننت فقط مسئول
/// «هویت فروشگاه + جستجو + اکشن‌های همیشگی (سبد خرید/اعلان/پروفایل)»
/// باشد و ساختارش ساده‌تر و تک‌مسئولیتی‌تر بماند.
@immutable
class ShopAppBarConfig {
  /// نام فروشگاه؛ وقتی [logo] داده نشده باشد به‌جای آن نمایش داده می‌شود.
  final String storeName;

  /// در صورت وجود لوگوی گرافیکی (Image.asset و ...)، به‌جای [storeName]
  /// نمایش داده می‌شود. جایگزین کردن لوگو فقط یعنی همین یک پارامتر عوض
  /// شود.
  final Widget? logo;

  /// برای حالت Inline (فیلتر همان‌جا در صفحه اصلی). اگر null باشد،
  /// SearchBar به‌صورت خودکار در حالت Navigate قرار می‌گیرد.
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  /// همیشه لازم است: هم برای حالت Navigate (لمس کل نوار جستجو) و هم برای
  /// آیکون جستجوی جمع‌شده‌ای که هنگام اسکرول جای لوگو را می‌گیرد.
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

/// AppBar فروشگاهی، به‌صورت یک Sliver، برای استفاده‌ی مستقیم داخل
/// `CustomScrollView(slivers: [ShopAppBar(config: ...), ...])` — دقیقاً
/// مثل SliverAppBar استاندارد فلاتر.
///
/// ساختار (از بالا به پایین):
/// - ردیف بالا («ثابت» و همیشه در دسترس): لوگو/نام فروشگاه (که هنگام
///   اسکرول محو می‌شود و جایش را به یک آیکون جستجوی جمع‌شده می‌دهد) +
///   سبد خرید + اعلان‌ها + پروفایل.
/// - نوار جستجوی کامل: هنگام اسکرول به سمت بالا جمع و محو می‌شود.
///
/// چون از `SliverPersistentHeader(pinned: true, ...)` استفاده شده، خود
/// فلاتر رفتار «هنگام اسکرول رو به بالا کوچک شو تا به minExtent برسی و
/// همان‌جا بمان» را مدیریت می‌کند؛ لازم نیست خودمان اسکرول را گوش بدهیم.
class ShopAppBar extends StatelessWidget {
  final ShopAppBarConfig config;

  const ShopAppBar({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ShopAppBarDelegate(
        config: config,
        topPadding: MediaQuery.paddingOf(context).top,
      ),
    );
  }
}

class _ShopAppBarDelegate extends SliverPersistentHeaderDelegate {
  final ShopAppBarConfig config;
  final double topPadding; // ارتفاع Status Bar، تا زیر آن قایم نشود

  static const double _topRowHeight = 58;
  static const double _searchRowHeight = 62;

  _ShopAppBarDelegate({required this.config, required this.topPadding});

  // maxExtent: حالت کاملاً باز (لوگو + جستجوی کامل)
  @override
  double get maxExtent => topPadding + _topRowHeight + _searchRowHeight;

  // minExtent: حالت کاملاً جمع (فقط ردیف بالا) — این مقدار همانی است که
  // چون pinned=true است، همیشه روی صفحه باقی می‌ماند.
  @override
  double get minExtent => topPadding + _topRowHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double collapseRange = maxExtent - minExtent;
    // t: پیشرفت جمع‌شدن؛ 0 یعنی کاملاً باز، 1 یعنی کاملاً جمع.
    final double t = collapseRange <= 0
        ? 0.0
        : (shrinkOffset / collapseRange).clamp(0.0, 1.0);

    final double searchRowHeight = _searchRowHeight * (1 - t);
    // محو شدن متن جستجو کمی سریع‌تر از خودِ جمع‌شدن ارتفاع انجام می‌شود
    // تا محتوای فیلد قبل از این‌که کاملاً برش بخورد ناپدید شده باشد.
    final double searchOpacity = (1 - (t * 1.6)).clamp(0.0, 1.0);

    return Material(
      // از رنگ Theme استفاده می‌شود (نه Hard-code)، تا با تغییر تم روشن/
      // تاریک در آینده هماهنگ بماند.
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
              height: _topRowHeight,
              child: _TopActionsRow(config: config, collapseProgress: t),
            ),
            // نوار جستجو: با ClipRect+OverflowBox جمع می‌شود، طوری که
            // محتوا از بالا «باز» و از پایین «برش» می‌خورد؛ همان جلوه‌ی
            // معمول AppBarهای فروشگاهی حرفه‌ای.
            ClipRect(
              child: SizedBox(
                height: searchRowHeight,
                child: OverflowBox(
                  minHeight: _searchRowHeight,
                  maxHeight: _searchRowHeight,
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

  // چون [config] هر بار که StoreProvider تغییر می‌کند (سبد خرید، ورود/
  // خروج و ...) از نو ساخته می‌شود، همیشه rebuild می‌کنیم تا Badgeها و
  // وضعیت پروفایل بلافاصله به‌روز شوند؛ هزینه‌ی این کار برای یک Header
  // ناچیز است.
  @override
  bool shouldRebuild(covariant _ShopAppBarDelegate oldDelegate) => true;
}

/// ردیف بالای AppBar: لوگو/نام فروشگاه (که با اسکرول محو و جایگزین
/// آیکون جستجوی جمع‌شده می‌شود) + دکمه‌های سبد خرید، اعلان‌ها و پروفایل
/// که در هر دو حالت (باز/بسته) همیشه در دسترس‌اند.
class _TopActionsRow extends StatelessWidget {
  final ShopAppBarConfig config;
  final double collapseProgress; // 0 = کاملاً باز, 1 = کاملاً جمع

  const _TopActionsRow({required this.config, required this.collapseProgress});

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
              // به‌جای centerLeft/centerRight از نسخه‌ی Directional
              // استفاده شده تا در RTL (فارسی) و LTR به‌درستی و خودکار
              // جای مناسب خودش را پیدا کند.
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
                      borderRadius: BorderRadius.circular(22),
                      onTap: config.onSearchTap,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.search,
                          color: AppColors.primaryWhite,
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
