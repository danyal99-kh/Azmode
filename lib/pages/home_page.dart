import 'package:azmode/model.dart';
import 'package:azmode/pages/product_image.dart';
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
  String _searchQuery = '';
  String? _selectedCategoryId;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سیستم سفارش‌گیری آزموده',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
      ),
      body: context.centerMaxWidth(
        CustomScrollView(
          slivers: [
            // فیلد جستجو
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(context.rs.md),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'جستجوی محصولات...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.deepTeal,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.primaryWhite,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      // با شروع جستجو، انتخاب دسته‌بندی را لغو می‌کنیم
                      _selectedCategoryId = null;
                    });
                  },
                ),
              ),
            ),

            // نوار افقی دسته‌بندی‌ها
            if (categories.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: context.responsive<double>(
                    mobile: 56,
                    tablet: 60,
                    desktop: 64,
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.rs.md,
                      vertical: context.rs.xs,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category.id == _selectedCategoryId;
                      return Padding(
                        padding: EdgeInsets.only(left: context.rs.sm),
                        child: ChoiceChip(
                          label: Text(
                            category.name,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: isSelected
                                  ? AppColors.primaryWhite
                                  : AppColors.primaryBlack,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategoryId = category.id;
                                _searchQuery =
                                    ''; // پاک کردن جستجو هنگام انتخاب دسته
                              } else {
                                _selectedCategoryId = null;
                              }
                            });
                          },
                          backgroundColor: AppColors.primaryWhite,
                          selectedColor: AppColors.deepTeal,
                          padding: EdgeInsets.symmetric(
                            horizontal: context.rs.md,
                            vertical: context.rs.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.deepTeal
                                  : AppColors.outlineGray,
                              width: 1.5,
                            ),
                          ),
                          labelPadding: EdgeInsets.zero,
                          elevation: 0,
                        ),
                      );
                    },
                  ),
                ),
              ),

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
