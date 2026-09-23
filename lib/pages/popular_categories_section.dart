import 'package:flutter/material.dart';
import '../model.dart';
import '../theme.dart';
import '../responsive.dart';
import 'product_image.dart';

/// بخش «دسته‌بندی‌های پرکاربرد» در صفحه اصلی.
///
/// فقط داده‌ی از پیش‌محاسبه‌شده (`categories`) و Callbackها را از بیرون
/// می‌گیرد — بدون دسترسی مستقیم به Provider — تا منطق انتخاب/ناوبری
/// دسته‌بندی در یک جا (`HomePage`) متمرکز بماند و با `CategorySelector`
/// موجود تداخل نکند.
class PopularCategoriesSection extends StatelessWidget {
  final List<ProductCategory> categories;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onViewAll;

  const PopularCategoriesSection({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final rs = context.rs;
    final ui = context.uiScale;

    // عرض کارت — مبنای محاسبه‌ی ارتفاع کل ردیف هم همین است، چون عکس
    // به‌صورت مربعی (aspectRatio: 1) روی همین عرض رندر می‌شود.
    final cardWidth = (100.0 * ui).clamp(88.0, 122.0);
    // فضای متن زیر عکس (نام دسته‌بندی، حداکثر ۲ خط)
    final labelBlockHeight = (40.0 * context.fontScale).clamp(34.0, 46.0);
    final rowHeight = cardWidth + labelBlockHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: rs.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'دسته‌بندی‌ها',
                  style: context.textStyles.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text('مشاهده همه ←'),
              ),
            ],
          ),
        ),
        SizedBox(height: rs.xs),
        SizedBox(
          height: rowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: rs.md),
            itemCount: categories.length,
            separatorBuilder: (_, __) => SizedBox(width: rs.sm),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _PopularCategoryCard(
                category: cat,
                width: cardWidth,
                onTap: () => onCategoryTap(cat.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PopularCategoryCard extends StatelessWidget {
  final ProductCategory category;
  final double width;
  final VoidCallback onTap;

  const _PopularCategoryCard({
    required this.category,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rr = context.rr;
    final rs = context.rs;
    final ui = context.uiScale;

    final hasImage =
        category.imageUrl != null && category.imageUrl!.trim().isNotEmpty;

    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rr.lg),
        ),
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── عکس: یک بخش مربعی از کارت را می‌گیرد ──
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
                            size: (28.0 * ui).clamp(22.0, 34.0),
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
      ),
    );
  }
}
