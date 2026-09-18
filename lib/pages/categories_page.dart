import 'package:azmode/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../responsive.dart';
import '../store_provider.dart';
import 'home_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String? _selectedCategoryId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // اطمینان از انتخاب اولین دسته بعد از لود شدن داده‌ها
    final categories = context.read<StoreProvider>().categories;
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    } else if (_selectedCategoryId != null &&
        !categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = categories.isNotEmpty ? categories.first.id : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final categories = store.categories;

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
      body: context.centerMaxWidth(
        _CategoriesBody(
          categories: categories,
          products: products,
          selectedCategoryId: _selectedCategoryId,
          onSelectCategory: (id) => setState(() => _selectedCategoryId = id),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// بدنه اصلی: سایدبار + گرید محصولات
// ═══════════════════════════════════════════════════════════════
class _CategoriesBody extends StatelessWidget {
  final List<ProductCategory> categories;
  final List<Product> products;
  final String? selectedCategoryId;
  final ValueChanged<String> onSelectCategory;

  const _CategoriesBody({
    required this.categories,
    required this.products,
    required this.selectedCategoryId,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategorySidebar(
          categories: categories,
          selectedCategoryId: selectedCategoryId,
          onSelect: onSelectCategory,
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppColors.outlineGray,
        ),
        Expanded(child: _ProductGrid(products: products)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// نوار کناری دسته‌بندی
// ═══════════════════════════════════════════════════════════════
class _CategorySidebar extends StatelessWidget {
  final List<ProductCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onSelect;

  const _CategorySidebar({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final ui = context.uiScale;

    // عرض سایدبار: ریسپانسیو
    final width =
        context.responsive<double>(mobile: 90, tablet: 110, desktop: 130) *
        ui.clamp(0.95, 1.1);

    final vPad = rs.md;
    final hPad = rs.sm;

    return Container(
      width: width,
      color: AppColors.primaryWhite,
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedCategoryId;
          return InkWell(
            onTap: () => onSelect(category.id),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
              color: isSelected
                  ? AppColors.deepTeal.withValues(alpha: 0.1)
                  : Colors.transparent,
              child: Text(
                category.name,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: isSelected
                      ? AppColors.deepTeal
                      : AppColors.primaryBlack,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// گرید محصولات (ریسپانسیو بر اساس عرض واقعی موجود)
// ═══════════════════════════════════════════════════════════════
class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(rs.lg),
          child: Text(
            'هیچ محصولی در این دسته‌بندی وجود ندارد.',
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // تعداد ستون‌ها بر اساس عرض واقعی موجود
        final cols = context.gridColumnsFor(
          constraints.maxWidth,
          tileMinWidth: 165 * context.uiScale,
        );

        // نسبت ابعاد کارت
        final aspect = context.responsive<double>(
          mobile: 0.52,
          tablet: 0.68,
          desktop: 0.78,
        );

        return GridView.builder(
          padding: EdgeInsets.all(rs.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: aspect,
            crossAxisSpacing: rs.md,
            mainAxisSpacing: rs.md,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        );
      },
    );
  }
}
