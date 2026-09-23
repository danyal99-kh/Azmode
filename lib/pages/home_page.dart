import 'package:azmode/model.dart';
import 'package:azmode/pages/product_image.dart';
import 'package:azmode/pages/shop_app_bar.dart';
import 'package:azmode/pages/category_selector.dart';
import 'package:azmode/pages/home_banner_carousel.dart';
import 'package:azmode/pages/popular_categories_section.dart';
import 'package:azmode/pages/product_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../responsive.dart';
import '../store_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _selectedCategoryId = null;
    });
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  /// این متد مسیر دقیق اجرای Pull to Refresh است:
  /// RefreshIndicator.onRefresh → اینجا → store.refreshStore() → منتظر
  /// اتمام آن می‌مانیم. اگر خطا بدهد، برنامه Crash نمی‌کند؛ پیام مناسب
  /// با SnackBar نمایش داده می‌شود و RefreshIndicator خودش (چون await
  /// تمام شده) Spinner را جمع می‌کند.
  Future<void> _onRefresh(BuildContext context) async {
    final store = context.read<StoreProvider>();
    try {
      await store.refreshStore();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
    final store = context.watch<StoreProvider>();
    final categories = store.categories;
    final rs = context.rs;
    final ui = context.uiScale;

    // آیا کاربر در حال جستجو یا فیلتر دسته‌بندی است؟ در این حالت بخش‌های
    // Banner/دسته‌بندی‌های پرکاربرد/جدیدترین محصولات کنار می‌روند تا با
    // نتایج جستجو تداخل منطقی ایجاد نکنند — فقط همان رفتار فیلتر قبلی
    // ادامه پیدا می‌کند.
    final isFiltering = _searchQuery.isNotEmpty || _selectedCategoryId != null;

    final filteredProducts = store.products.where((p) {
      if (_selectedCategoryId != null && p.categoryId != _selectedCategoryId) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return p.name.contains(_searchQuery) ||
            p.description.contains(_searchQuery);
      }
      return true;
    }).toList();

    final displayedProducts = isFiltering
        ? filteredProducts
        : store.latestProducts;
    final isLoading = store.isRefreshing;

    final cartItemCount = store.cart.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    // ⬇️ این سه خط را اضافه کن (بیرون از CustomScrollView)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gridCrossAxisCount = context.gridColumnsFor(screenWidth);
    final gridAspectRatio = context.responsive<double>(
      mobile: 0.52,
      tablet: 0.62,
      desktop: 0.68,
    );
    final isInitialLoading = store.isRefreshing && store.products.isEmpty;
    final appBarConfig = ShopAppBarConfig(
      storeName: 'آزموده',
      searchController: _searchController,
      onSearchChanged: _onSearchChanged,
      onSearchTap: () {},
      cartItemCount: cartItemCount,
      onCartTap: () => context.push('/cart'),
      hasUnreadNotifications: store.unreadNotificationCount > 0,
      onNotificationTap: () => context.push('/notifications'),
      isLoggedIn: store.isAuthenticated,
      currentUserName: store.currentUser?.username,
      onProfileTap: () => context.push('/profile'),
    );

    final categorySelectorHeight = (48.0 * ui).clamp(44.0, 56.0);
    final bottomSpacer =
        context.responsive<double>(mobile: 95, tablet: 100, desktop: 40) *
        ui.clamp(0.95, 1.1);

    return Scaffold(
      body: context.centerMaxWidth(
        RefreshIndicator(
          color: AppColors.deepTeal,
          onRefresh: () => _onRefresh(context),
          child: CustomScrollView(
            // حتی وقتی محتوا کوتاه‌تر از صفحه است هم Pull to Refresh کار
            // کند.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              ShopAppBar(config: appBarConfig),

              // نوار فیلتر دسته‌بندی‌ها (رفتار قبلی — بدون تغییر)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: rs.sm),
                  child: SizedBox(
                    height: categorySelectorHeight,
                    child: CategorySelector(
                      categories: categories,
                      selectedCategoryId: _selectedCategoryId,
                      onCategorySelected: _onCategorySelected,
                    ),
                  ),
                ),
              ),

              if (!isFiltering) ...[
                SliverToBoxAdapter(
                  child: HomeBannerCarousel(
                    banners: store.activeBanners,
                    onBannerTap: (b) => _handleBannerTap(context, b),
                  ),
                ),
                SliverToBoxAdapter(
                  child: PopularCategoriesSection(
                    categories: store.popularCategories,
                    onCategoryTap: (id) =>
                        context.push('/categories?catId=$id'),
                    onViewAll: () => context.push('/categories/all'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(rs.md, rs.md, rs.md, rs.sm),
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
                ),
              ],

              // گرید محصولات (جدیدترین‌ها یا نتایج جستجو/فیلتر)
              SliverPadding(
                padding: EdgeInsets.all(rs.md),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final spacing = rs.md;
                      final totalWidth = constraints.maxWidth;
                      final itemWidth =
                          (totalWidth - spacing * (gridCrossAxisCount - 1)) /
                          gridCrossAxisCount;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          if (isLoading)
                            for (var i = 0; i < gridCrossAxisCount * 2; i++)
                              SizedBox(
                                width: itemWidth,
                                child: const ProductCardSkeleton(),
                              )
                          else
                            for (final p in displayedProducts)
                              SizedBox(
                                width: itemWidth,
                                child: ProductCard(product: p),
                              ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              if (!isLoading && displayedProducts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(rs.xl),
                    child: _EmptyProductsState(isFiltering: isFiltering),
                  ),
                ),

              SliverToBoxAdapter(child: SizedBox(height: bottomSpacer)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// حالت خالی بودن نتایج
// ═══════════════════════════════════════════════════════════════
class _EmptyProductsState extends StatelessWidget {
  final bool isFiltering;
  const _EmptyProductsState({required this.isFiltering});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltering ? Icons.search_off : Icons.inventory_2_outlined,
            size: 56,
            color: AppColors.outlineGray,
          ),
          SizedBox(height: context.rs.md),
          Text(
            isFiltering
                ? 'هیچ محصولی با این جستجو/فیلتر یافت نشد.'
                : 'هنوز محصول جدیدی ثبت نشده است.',
            style: context.textStyles.bodyLarge?.withColor(
              AppColors.outlineGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// کارت محصول
// ═══════════════════════════════════════════════════════════════
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final store = context.read<StoreProvider>();
    final rr = context.rr;

    final metaParts = <String>[
      if (product.brand != null && product.brand!.trim().isNotEmpty)
        product.brand!.trim(),
      if (product.sku != null && product.sku!.trim().isNotEmpty)
        'کد: ${product.sku!.trim()}',
    ];
    final metaLine = metaParts.join(' • ');
    final packaging = product.packagingType?.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rr.lg)),
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final scale = (cardWidth / 180.0).clamp(0.70, 1.40);

            final nameSize = (13.5 * scale).clamp(10.5, 16.0);
            final priceSize = (13.0 * scale).clamp(10.0, 15.0);
            final metaSize = (10.5 * scale).clamp(9.0, 12.0);
            final stockSize = (11.0 * scale).clamp(9.0, 12.5);
            final buttonFontSize = (12.0 * scale).clamp(10.0, 13.5);

            final pad = (8.0 * scale).clamp(5.0, 11.0);
            // فاصله‌های استاندارد بین بخش‌ها
            final gap = (15.0 * scale).clamp(9.0, 14.0); // ← از 6 به 9
            final smallGap = (gap * 0.9);
            final buttonHeight = (32.0 * scale).clamp(28.0, 40.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min, // ← ارتفاع = محتوا
              children: [
                // ── تصویر: مربعی ──
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(rr.lg),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ProductImage(
                          imageUrl: product.imageUrl,
                          imageSource: product.imageSource,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (packaging != null && packaging.isNotEmpty)
                      Positioned(
                        top: pad * 0.5,
                        right: pad * 0.5,
                        child: _PackagingTag(
                          text: packaging,
                          fontSize: metaSize,
                        ),
                      ),
                  ],
                ),

                // ── اطلاعات ──
                Padding(
                  padding: EdgeInsets.all(pad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // نام محصول
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: nameSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlack,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                      ),

                      // برند / SKU
                      if (metaLine.isNotEmpty) ...[
                        SizedBox(height: smallGap),
                        Text(
                          metaLine,
                          style: TextStyle(
                            fontSize: metaSize,
                            color: AppColors.outlineGray,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      SizedBox(height: gap),

                      // قیمت
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '${product.price.toStringAsFixed(0)} تومان',
                          style: TextStyle(
                            fontSize: priceSize,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepTeal,
                            height: 1.1,
                          ),
                        ),
                      ),

                      SizedBox(height: smallGap),

                      // موجودی
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          product.isAvailable
                              ? 'موجود: ${product.stock}'
                              : 'ناموجود',
                          style: TextStyle(
                            fontSize: stockSize,
                            color: product.isAvailable
                                ? AppColors.success
                                : AppColors.error,
                            height: 1.1,
                          ),
                        ),
                      ),

                      SizedBox(height: gap),

                      // دکمه
                      SizedBox(
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: product.isAvailable
                              ? () {
                                  store.addToCart(product, 1);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('به سبد خرید اضافه شد'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: pad * 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(rr.md),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'افزودن به سبد',
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryWhite,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PackagingTag extends StatelessWidget {
  final String text;
  final double fontSize;
  const _PackagingTag({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.primaryWhite,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
