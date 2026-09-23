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
                  final padding = rs.md;
                  // عرض واقعیِ داخل پدینگ
                  final availableWidth = constraints.maxWidth - padding * 2;

                  final cols = context
                      .gridColumnsFor(
                        availableWidth,
                        tileMinWidth: 120 * context.uiScale,
                      )
                      .clamp(2, 6);

                  final spacing = rs.md;
                  final itemWidth =
                      (availableWidth - spacing * (cols - 1)) / cols;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
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
              ),
            ),
    );
  }
}
