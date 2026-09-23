import 'package:azmode/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
  bool _initializedFromQuery = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final categories = context.read<StoreProvider>().categories;

    // اگر از طریق «مشاهده همه دسته‌بندی‌ها» یا یک بنر/دسته‌ی پرکاربرد
    // با catId خاصی به این صفحه آمده‌ایم، فقط یک‌بار همان دسته‌بندی
    // انتخاب می‌شود؛ بعد از آن دیگر انتخاب دستی کاربر نادیده گرفته
    // نمی‌شود.
    if (!_initializedFromQuery) {
      final queryCatId = GoRouterState.of(context).uri.queryParameters['catId'];
      if (queryCatId != null) {
        _initializedFromQuery = true;
        if (categories.any((c) => c.id == queryCatId)) {
          _selectedCategoryId = queryCatId;
        }
      }
    }

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
        final cols = context.gridColumnsFor(
          constraints.maxWidth,
          tileMinWidth: 165 * context.uiScale,
        );

        final spacing = rs.md;
        final itemWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;

        return SingleChildScrollView(
          padding: EdgeInsets.all(rs.md),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final p in products)
                SizedBox(
                  width: itemWidth,
                  child: ProductCard(product: p),
                ),
            ],
          ),
        );
      },
    );
  }
}
