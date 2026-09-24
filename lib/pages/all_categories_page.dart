import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../model.dart';
import '../theme.dart';
import '../responsive.dart';
import '../store_provider.dart';
import 'product_image.dart';

/// صفحه‌ی Grid برای نمایش تمام دسته‌بندی‌ها. با کلیک روی هر دسته‌بندی،
/// کاربر به `/categories` هدایت می‌شود و همان دسته‌بندی انتخاب‌شده است
/// (از طریق Query Param `catId` که `CategoriesPage` آن را می‌خواند).
class AllCategoriesPage extends StatelessWidget {
  const AllCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final categories = store.categories;
    final rs = context.rs;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'همه دسته‌بندی‌ها',
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
      body: categories.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(rs.xl),
                child: Text(
                  'هیچ دسته‌بندی‌ای وجود ندارد.',
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
                    tileMinWidth: 150 * context.uiScale,
                  );
                  return GridView.builder(
                    padding: EdgeInsets.all(rs.md),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: rs.md,
                      mainAxisSpacing: rs.md,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return _CategoryGridCard(
                        category: cat,
                        onTap: () =>
                            context.push('/categories?catId=${cat.id}'),
                      );
                    },
                  );
                },
              ),
              maxWidth: 1000 * context.uiScale.clamp(0.95, 1.15),
            ),
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  final ProductCategory category;
  final VoidCallback onTap;
  const _CategoryGridCard({required this.category, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final rr = context.rr;
    final rs = context.rs;
    final ui = context.uiScale;
    final hasImage =
        category.imageUrl != null && category.imageUrl!.trim().isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rr.lg)),
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── عکس: مربعی و گرد، دقیقاً مثل کارت صفحه اصلی ──
            ClipRRect(
              borderRadius: BorderRadius.circular(rr.md),
              child: AspectRatio(
                aspectRatio: 1,
                child: hasImage
                    ? ProductImage(
                        imageUrl: category.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.deepTeal.withValues(alpha: 0.10),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.category_outlined,
                          color: AppColors.deepTeal,
                          size: (32.0 * ui).clamp(24.0, 38.0),
                        ),
                      ),
              ),
            ),

            // ── نام دسته‌بندی ──
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: rs.xs,
                  vertical: rs.xs * 0.75,
                ),
                child: Center(
                  child: Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall?.bold,
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
