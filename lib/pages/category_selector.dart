import 'package:flutter/material.dart';
import '../../model.dart';
import '../../theme.dart';
import '../../responsive.dart';

/// نوار افقی دسته‌بندی‌ها.
///
/// این ویجت هیچ ایده‌ای درباره‌ی این‌که [categories] از کجا می‌آید ندارد
/// (از بیرون، مثلاً از `StoreProvider.categories`، دریافت می‌شود)، پس
/// وقتی بعداً دسته‌بندی‌ها از یک Backend واقعی بیایند، فقط کافی است
/// لیستی که به این ویجت پاس داده می‌شود عوض شود — بدون هیچ تغییری در
/// خود این فایل. گزینه‌ی «همه» همیشه خودکار در ابتدای لیست اضافه
/// می‌شود و با `selectedCategoryId == null` مشخص می‌شود.
class CategorySelector extends StatelessWidget {
  final List<ProductCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: context.rs.md),
      itemCount: categories.length + 1,
      itemBuilder: (context, index) {
        final bool isAll = index == 0;
        final String? id = isAll ? null : categories[index - 1].id;
        final String label = isAll ? 'همه' : categories[index - 1].name;
        final bool isSelected = selectedCategoryId == id;

        return Padding(
          padding: EdgeInsets.only(left: context.rs.sm),
          child: ChoiceChip(
            label: Text(
              label,
              style: context.textStyles.bodyMedium?.copyWith(
                color: isSelected
                    ? AppColors.primaryWhite
                    : AppColors.primaryBlack,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(id),
            backgroundColor: AppColors.primaryWhite,
            selectedColor: AppColors.deepTeal,
            padding: EdgeInsets.symmetric(
              horizontal: context.rs.md,
              vertical: context.rs.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(
                color: isSelected ? AppColors.deepTeal : AppColors.outlineGray,
                width: 1.5,
              ),
            ),
            labelPadding: EdgeInsets.zero,
            elevation: 0,
          ),
        );
      },
    );
  }
}
