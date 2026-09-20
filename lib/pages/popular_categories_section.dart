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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: rs.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'دسته‌بندی‌های پرکاربرد',
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
          height:
              context.responsive<double>(
                mobile: 92,
                tablet: 104,
                desktop: 112,
              ) *
              context.uiScale.clamp(0.9, 1.1),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: rs.md),
            itemCount: categories.length,
            separatorBuilder: (_, __) => SizedBox(width: rs.sm),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _PopularCategoryCard(
                category: cat,
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
  final VoidCallback onTap;
  const _PopularCategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rr = context.rr;
    final rs = context.rs;
    final ui = context.uiScale;

    final width = (96.0 * ui).clamp(84.0, 116.0);
    final avatarSize = (40.0 * ui).clamp(34.0, 48.0);
    final hasImage =
        category.imageUrl != null && category.imageUrl!.trim().isNotEmpty;

    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rr.lg),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: rs.sm, horizontal: rs.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: AppColors.deepTeal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: hasImage
                      ? ClipOval(
                          child: SizedBox(
                            width: avatarSize,
                            height: avatarSize,
                            child: ProductImage(
                              imageUrl: category.imageUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.category_outlined,
                          color: AppColors.deepTeal,
                          size: (20.0 * ui).clamp(17.0, 24.0),
                        ),
                ),
                SizedBox(height: rs.xs),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.bold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
