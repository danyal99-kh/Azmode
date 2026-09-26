import 'package:azmode/pages/lib/pages/home_banner_carousel.dart';
import 'package:azmode/pages/product_feed_controller.dart';
import 'package:azmode/providers/auth_provider.dart';
import 'package:azmode/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../model.dart';
import '../responsive.dart';
import '../store_provider.dart';
import '../theme.dart';
import 'category_selector.dart';
import 'popular_categories_section.dart';
import 'product_feed_sliver.dart';
import 'shop_app_bar.dart';

/// صفحه‌ی اصلی.
///
/// اصل طراحی: خود `HomePage` هیچ Providerی را watch نمی‌کند. هر بخش
/// (AppBar، نوار دسته‌بندی، بنر، دسته‌های پرکاربرد، گرید محصولات) با
/// Selector/Listenable مخصوص خودش فقط وقتی داده‌ی همان بخش عوض شد Rebuild
/// می‌شود. مثلاً افزودن به سبد فقط Badge سبد را Rebuild می‌کند، نه Grid را.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeFeedController _feed;
  late final FeedScrollBinding _scroll;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // فید در سطح اپ ساخته شده؛ پس با تعویض تب، لیست/Query/Scroll از بین
    // نمی‌رود و درخواست تکراری هم ارسال نمی‌شود.
    _feed = context.read<HomeFeedController>();
    _scroll = FeedScrollBinding(_feed);
    _searchController = TextEditingController(text: _feed.query.search);

    // بعد از اولین فریم، تا notifyListeners وسط build اتفاق نیفتد.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _feed.ensureLoaded();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) =>
      _feed.setSearch(value, clearCategory: true);

  void _onCategorySelected(String? categoryId) {
    _searchController.clear();
    _feed.setCategory(categoryId, clearSearch: true);
  }

  /// Pull to Refresh: Pagination از ابتدا؛ لیست فعلی تا رسیدن پاسخ
  /// می‌ماند؛ درخواست‌های قبلی با نسل جدید باطل می‌شوند.
  Future<void> _onRefresh() async {
    final store = context.read<StoreProvider>();
    try {
      await Future.wait([_feed.refresh(), store.refreshStore()]);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
      return;
    }
    final err = _feed.refreshError;
    if (err != null) _showError(err.userMessage);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _handleBannerTap(BuildContext context, PromoBanner banner) {
    switch (banner.targetType) {
      case BannerTargetType.none:
        break;
      case BannerTargetType.product:
        if (banner.targetId != null) {
          context.push('/product/${banner.targetId}');
        }
        break;
      case BannerTargetType.category:
        if (banner.targetId != null) {
          context.push('/categories?catId=${banner.targetId}');
        }
        break;
      case BannerTargetType.page:
        if (banner.targetId != null && banner.targetId!.trim().isNotEmpty) {
          context.push(banner.targetId!.trim());
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.uiScale;
    final bottomSpacer =
        context.responsive<double>(mobile: 95, tablet: 100, desktop: 40) *
        ui.clamp(0.95, 1.1);

    return Scaffold(
      body: context.centerMaxWidth(
        RefreshIndicator(
          color: AppColors.deepTeal,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scroll.controller,
            physics: const AlwaysScrollableScrollPhysics(),
            // کمی جلوتر از Viewport بساز تا اسکرول سریع سفید نشود؛
            // ولی نه آن‌قدر که عکس‌های زیادی بی‌دلیل دانلود شود.
            cacheExtent: 600,
            slivers: [
              _HomeAppBar(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
              ),
              _HomeCategoryBar(onSelected: _onCategorySelected),
              SliverToBoxAdapter(
                child: _HomeHeader(
                  onBannerTap: (b) => _handleBannerTap(context, b),
                ),
              ),
              ProductFeedSliver(controller: _feed),
              SliverToBoxAdapter(child: SizedBox(height: bottomSpacer)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AppBar — فقط با تغییر تعداد سبد / اعلان نخوانده / وضعیت ورود Rebuild می‌شود
// ═══════════════════════════════════════════════════════════════
class _HomeAppBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _HomeAppBar({
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cartCount = context.select<CartProvider, int>(
      (c) => c.items.fold<int>(0, (sum, item) => sum + item.quantity),
    );
    final hasUnread = context.select<StoreProvider, bool>(
      (s) => s.unreadNotificationCountFor(auth.user?.id.toString()) > 0,
    );

    return ShopAppBar(
      config: ShopAppBarConfig(
        storeName: 'آزموده',
        searchController: searchController,
        onSearchChanged: onSearchChanged,
        onSearchTap: () {},
        cartItemCount: cartCount,
        onCartTap: () => context.push('/cart'),
        hasUnreadNotifications: hasUnread,
        onNotificationTap: () => context.push('/notifications'),
        isLoggedIn: auth.isAuthenticated,
        currentUserName: auth.user?.username,
        onProfileTap: () => context.push('/profile'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// نوار دسته‌بندی — فقط با تغییر لیست دسته‌بندی‌ها یا دسته‌ی انتخاب‌شده
// ═══════════════════════════════════════════════════════════════
class _HomeCategoryBar extends StatelessWidget {
  final ValueChanged<String?> onSelected;
  const _HomeCategoryBar({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final ui = context.uiScale;
    final height = (48.0 * ui).clamp(44.0, 56.0);
    final selectedId = context.select<HomeFeedController, String?>(
      (f) => f.query.categoryId,
    );

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: rs.sm),
        child: SizedBox(
          height: height,
          child: Selector<StoreProvider, List<ProductCategory>>(
            selector: (_, s) => s.categories,
            builder: (context, categories, _) => CategorySelector(
              categories: categories,
              selectedCategoryId: selectedId,
              onCategorySelected: onSelected,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// بنر + دسته‌های پرکاربرد + عنوان «جدیدترین محصولات»
// (هنگام جستجو/فیلتر مخفی می‌شود)
// ═══════════════════════════════════════════════════════════════
class _HomeHeader extends StatelessWidget {
  final ValueChanged<PromoBanner> onBannerTap;
  const _HomeHeader({required this.onBannerTap});

  @override
  Widget build(BuildContext context) {
    final isDefaultQuery = context.select<HomeFeedController, bool>(
      (f) => f.query.isDefault,
    );
    if (!isDefaultQuery) return const SizedBox.shrink();

    final rs = context.rs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Selector<StoreProvider, List<PromoBanner>>(
          selector: (_, s) => s.activeBanners,
          builder: (context, banners, _) =>
              HomeBannerCarousel(banners: banners, onBannerTap: onBannerTap),
        ),
        Selector<StoreProvider, List<ProductCategory>>(
          selector: (_, s) => s.popularCategories,
          builder: (context, popular, _) => PopularCategoriesSection(
            categories: popular,
            onCategoryTap: (id) => context.push('/categories?catId=$id'),
            onViewAll: () => context.push('/categories/all'),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(rs.md, rs.md, rs.md, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'جدیدترین محصولات',
                  style: context.textStyles.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/products'),
                child: const Text('مشاهده همه ←'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
