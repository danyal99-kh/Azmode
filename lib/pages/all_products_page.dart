import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../responsive.dart';
import '../store_provider.dart';
import 'home_page.dart' show ProductCard;

/// صفحه‌ی «مشاهده همه محصولات» — با کلیک روی «مشاهده همه ←» در بخش
/// جدیدترین محصولات Home باز می‌شود. از همان `ProductCard` استفاده
/// می‌کند تا هیچ منطق تکراری ساخته نشود.
class AllProductsPage extends StatelessWidget {
  const AllProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final products = store.products;
    final rs = context.rs;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'همه محصولات',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryWhite),
          tooltip: 'بازگشت',
        ),
      ),
      body: products.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(rs.xl),
                child: Text(
                  'هیچ محصولی یافت نشد.',
                  style: context.textStyles.bodyLarge?.withColor(
                    AppColors.outlineGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : context.centerMaxWidth(
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = context.gridColumnsFor(
                    constraints.maxWidth,
                    tileMinWidth: 165 * context.uiScale,
                  );
                  final aspect = context.responsive<double>(
                    mobile: 0.52,
                    tablet: 0.62,
                    desktop: 0.68,
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
                    itemBuilder: (context, index) =>
                        ProductCard(product: products[index]),
                  );
                },
              ),
            ),
    );
  }
}
