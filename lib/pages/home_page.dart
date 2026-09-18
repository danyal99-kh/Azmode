import 'package:azmode/model.dart';
import 'package:azmode/pages/product_image.dart';
import 'package:azmode/pages/shop_app_bar.dart';
import 'package:azmode/pages/category_selector.dart';
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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final categories = store.categories;
    final rs = context.rs;
    final ui = context.uiScale;

    // فیلتر محصولات
    final products = store.products.where((p) {
      if (_selectedCategoryId != null && p.categoryId != _selectedCategoryId) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return p.name.contains(_searchQuery) ||
            p.description.contains(_searchQuery);
      }
      return true;
    }).toList();

    final cartItemCount = store.cart.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

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

    // ارتفاع نوار انتخاب دسته — ریسپانسیو
    final categorySelectorHeight = (48.0 * ui).clamp(44.0, 56.0);

    // اسپیسر پایین صفحه — بر اساس نوع دستگاه + uiScale
    final bottomSpacer =
        context.responsive<double>(mobile: 95, tablet: 100, desktop: 40) *
        ui.clamp(0.95, 1.1);

    return Scaffold(
      body: context.centerMaxWidth(
        CustomScrollView(
          slivers: [
            ShopAppBar(config: appBarConfig),

            // نوار فیلتر دسته‌بندی‌ها
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

            // عنوان "جدیدترین محصولات"
            if (_searchQuery.isEmpty && _selectedCategoryId == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: rs.md,
                    vertical: rs.sm,
                  ),
                  child: Text(
                    'جدیدترین محصولات',
                    style: context.textStyles.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            // گرید محصولات
            SliverPadding(
              padding: EdgeInsets.all(rs.md),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = context.gridColumnsFor(
                    constraints.crossAxisExtent,
                  );
                  final aspectRatio = context.responsive<double>(
                    mobile: 0.6,
                    tablet: 0.68,
                    desktop: 0.72,
                  );
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: aspectRatio,
                      crossAxisSpacing: rs.md,
                      mainAxisSpacing: rs.md,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductCard(product: products[index]),
                      childCount: products.length,
                    ),
                  );
                },
              ),
            ),

            // پیام خالی بودن — قبل از اسپیسر، تا زیر گرید بیاید
            if (products.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(rs.xl),
                  child: Center(
                    child: Text(
                      'هیچ محصولی یافت نشد.',
                      style: context.textStyles.bodyLarge?.withColor(
                        AppColors.outlineGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

            // اسپیسر پایین (برای اینکه BottomNav روی محتوا نیفتد)
            SliverToBoxAdapter(child: SizedBox(height: bottomSpacer)),
          ],
        ),
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
            // ═══════════════════════════════════════════════════════
            // مقیاس‌بندی بر اساس عرض خودِ کارت (نه عرض صفحه!)
            // مبنا: ۱۸۰px = کارت معمولی روی گوشی
            // ═══════════════════════════════════════════════════════
            final cardWidth = constraints.maxWidth;
            final scale = (cardWidth / 180.0).clamp(0.70, 1.40);

            // ── فونت‌ها ──
            final nameSize = (13.5 * scale).clamp(10.5, 16.0);
            final priceSize = (13.0 * scale).clamp(10.0, 15.0);
            final stockSize = (11.0 * scale).clamp(9.0, 12.5);
            final buttonFontSize = (12.0 * scale).clamp(10.0, 13.5);

            // ── فاصله‌ها ──
            final pad = (8.0 * scale).clamp(5.0, 11.0);
            final gap = (3.0 * scale).clamp(2.0, 5.0);
            final buttonHeight = (32.0 * scale).clamp(26.0, 40.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── تصویر: ۵ از ۹ ──
                Expanded(
                  flex: 5,
                  child: ProductImage(
                    imageUrl: product.imageUrl,
                    imageSource: product.imageSource,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(rr.lg),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),

                // ── اطلاعات: ۴ از ۹ ──
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.all(pad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      // سه بخش: اسم / قیمت / (موجودی + دکمه)
                      // با spaceBetween فاصله‌ها متوازن پخش می‌شن
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ── نام محصول ──
                        // بدون Flexible و بدون Expanded که باعث
                        // فشرده‌شدن یا رفتن زیر قیمت بشه
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

                        // ── قیمت ──
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

                        // ── موجودی + دکمه ──
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                            SizedBox(
                              height: buttonHeight,
                              child: ElevatedButton(
                                onPressed: product.isAvailable
                                    ? () {
                                        store.addToCart(product, 1);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'به سبد خرید اضافه شد',
                                            ),
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
                      ],
                    ),
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
