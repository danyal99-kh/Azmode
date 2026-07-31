import 'dart:convert';

import 'package:azmode/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
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
      body: CustomScrollView(
        slivers: [
          // فیلد جستجو
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                height: 60, // ارتفاع مناسب برای چیپ‌ها
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category.id == _selectedCategoryId;
                    return Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  'جدیدترین محصولات',
                  style: context.textStyles.titleLarge,
                ),
              ),
            ),

          // شبکه محصولات
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.6,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ProductCard(product: products[index]),
                childCount: products.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 95), // ارتفاع نوار ناوبری + فاصله
          ),
          // اگر محصولی وجود نداشت، پیام نمایش داده شود
          if (products.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
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
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  // تابع کمکی برای نمایش تصویر (Asset یا Base64)
  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else {
      try {
        final bytes = base64Decode(imageUrl);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      } catch (e) {
        return _buildPlaceholder();
      }
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.outlineGray.withOpacity(0.2),
      child: const Icon(
        Icons.image_not_supported,
        size: 48,
        color: AppColors.outlineGray,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<StoreProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    // تنظیم نسبت ابعاد بر اساس عرض صفحه
    final cardAspectRatio = screenWidth < 600 ? 0.65 : 0.75;

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
            // بخش تصویر با نسبت ابعاد ثابت
            AspectRatio(
              aspectRatio: 1, // تصویر مربعی
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
                child: _buildProductImage(product.imageUrl),
              ),
            ),
            // بخش اطلاعات محصول
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
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
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // دکمه با اندازه‌ی مناسب
                        SizedBox(
                          width: double.infinity,
                          height: 36,
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
                            child: const Text('افزودن به سبد'),
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
