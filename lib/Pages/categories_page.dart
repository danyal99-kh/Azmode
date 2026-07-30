import 'package:azmode/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../store_provider.dart';
import 'home_page.dart'; // for ProductCard

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final categories = store.categories;

    // Default to first category if none selected
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    final products = _selectedCategoryId != null
        ? store.getProductsByCategory(_selectedCategoryId!)
        : <Product>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'دسته‌بندی‌ها',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
      ),
      body: Row(
        children: [
          // Sidebar for categories
          Container(
            width: 120,
            color: AppColors.primaryWhite,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.id == _selectedCategoryId;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    color: isSelected
                        ? AppColors.deepTeal.withValues(alpha: 0.1)
                        : Colors.transparent,
                    child: Text(
                      category.name,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: isSelected
                            ? AppColors.deepTeal
                            : AppColors.primaryBlack,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.outlineGray,
          ),
          // Products grid
          Expanded(
            child: products.isEmpty
                ? const Center(
                    child: Text('هیچ محصولی در این دسته‌بندی وجود ندارد.'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return ProductCard(product: products[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
