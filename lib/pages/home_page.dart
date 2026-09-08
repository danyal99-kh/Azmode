import 'package:azmode/model.dart';
import 'package:azmode/pages/product_image.dart';
import 'package:azmode/pages/shop_app_bar.dart';
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
      // با شروع جستجو، انتخاب دسته‌بندی را لغو می‌کنیم
      _selectedCategoryId = null;
    });
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      // با انتخاب دسته‌بندی، جستجو پاک می‌شود
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final categories = store.categories;

    // فیلتر محصولات بر اساس دسته‌بندی و جستجو
    final products = store.products.where((p) {
      // فیلتر بر اساس دسته‌بندی
      if (_selectedCategoryId != null && p.categoryId != _selectedCategoryId) {
        return false;
      }
      // فیلتر بر اساس جستجو
      if (_searchQuery.isNotEmpty) {
        return p.name.contains(_searchQuery) ||
            p.description.contains(_searchQuery);
      }
      return true;
    }).toList();

    // مجموع تعداد کالاها در سبد خرید (نه فقط تعداد ردیف‌ها)، تا Badge
    // سبد خرید واقعاً «چند عدد کالا» را نشان دهد.
    final cartItemCount = store.cart.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    final appBarConfig = ShopAppBarConfig(
      storeName: 'آزموده',
      categories: categories,
      selectedCategoryId: _selectedCategoryId,
      onCategorySelected: _onCategorySelected,
      searchController: _searchController,
      onSearchChanged: _onSearchChanged,
      onSearchTap: () {}, // در حالت Inline نیازی به Navigate نیست
      cartItemCount: cartItemCount,
      onCartTap: () => context.push('/cart'),
      hasUnreadNotifications: store.unreadNotificationCount > 0,
      onNotificationTap: () {
        // صفحه‌ی اعلان‌ها هنوز پیاده‌سازی نشده؛ فعلاً یک پیام موقت.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('صفحه‌ی اعلان‌ها به‌زودی اضافه می‌شود.'),
          ),
        );
      },
      isLoggedIn: store.isAuthenticated,
      currentUserName: store.currentUser?.username,
      onProfileTap: () => context.push('/profile'),
    );

    return Scaffold(
      body: context.centerMaxWidth(
        CustomScrollView(
          slivers: [
            // AppBar فروشگاهی: لوگو/جستجو/سبدخرید/اعلان/پروفایل + نوار
            // دسته‌بندی‌ها. جزئیات رفتار جمع‌شدن هنگام اسکرول در خودِ
            // ShopAppBar پیاده‌سازی شده است.
            ShopAppBar(config: appBarConfig),

            // عنوان "جدیدترین محصولات" در صورتی که هیچ فیلتری اعمال نشده باشد
            if (_searchQuery.isEmpty && _selectedCategoryId == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rs.md,
                    vertical: context.rs.sm,
                  ),
                  child: Text(
                    'جدیدترین محصولات',
                    style: context.textStyles.titleLarge,
                  ),
                ),
              ),

            // شبکه محصولات — تعداد ستون و نسبت ابعاد بر اساس عرض واقعی صفحه
            SliverPadding(
              padding: EdgeInsets.all(context.rs.md),
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
                      crossAxisSpacing: context.rs.md,
                      mainAxisSpacing: context.rs.md,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductCard(product: products[index]),
                      childCount: products.length,
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: context.responsive<double>(
                  mobile: 95,
                  tablet: 100,
                  desktop: 40,
                ),
              ), // ارتفاع نوار ناوبری + فاصله
            ),
            // اگر محصولی وجود نداشت، پیام نمایش داده شود
            if (products.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(context.rs.xl),
                  child: Center(
                    child: Text(
                      'هیچ محصولی یافت نشد.',
                      style: context.textStyles.bodyLarge?.withColor(
                        AppColors.outlineGray,
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
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final store = context.read<StoreProvider>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بخش تصویر - دقیقاً همان قالبی که ادمین هنگام آپلود انتخاب کرده
            ProductImage(
              imageUrl: product.imageUrl,
              imageSource: product.imageSource,
              aspectRatio: product.imageAspectRatio,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            // بخش اطلاعات محصول
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(context.rs.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // نام و قیمت
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: context.textStyles.titleSmall?.bold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.price} تومان',
                          style: context.textStyles.bodyLarge
                              ?.withColor(AppColors.deepTeal)
                              .bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // وضعیت موجودی و دکمه
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.isAvailable
                              ? 'موجود: ${product.stock}'
                              : 'ناموجود',
                          style: context.textStyles.bodySmall?.withColor(
                            product.isAvailable
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: context.rs.xs),
                        // دکمه با اندازه‌ی مناسب
                        SizedBox(
                          width: double.infinity,
                          height: context.responsive<double>(
                            mobile: 36,
                            tablet: 38,
                            desktop: 40,
                          ),
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
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              textStyle: context.textStyles.bodySmall?.bold,
                            ),
                            child: const Text(
                              'افزودن به سبد',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }
}
