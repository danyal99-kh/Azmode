import 'package:flutter/material.dart';
import '../../model.dart';
import '../../theme.dart';
import '../../responsive.dart';

/// نوار افقی دسته‌بندی‌ها.
///
/// گزینه‌ی «همه» همیشه خودکار در ابتدای لیست اضافه می‌شود و با
/// `selectedCategoryId == null` مشخص می‌شود.
///
/// ابعاد داخلی (پدینگ، رادیوس، ضخامت border) با `uiScale` هماهنگ
/// می‌شوند تا روی گوشی کوچک، تبلت و ویندوز یکدست دیده شود.
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
    final rs = context.rs;
    final rr = context.rr;
    final ui = context.uiScale;

    // ضخامت border انتخاب‌شده — ریسپانسیو
    final borderWidth = (1.5 * ui).clamp(1.2, 2.0);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: rs.md),
      itemCount: categories.length + 1,
      itemBuilder: (context, index) {
        final bool isAll = index == 0;
        final String? id = isAll ? null : categories[index - 1].id;
        final String label = isAll ? 'همه' : categories[index - 1].name;
        final bool isSelected = selectedCategoryId == id;

        return Padding(
          padding: EdgeInsets.only(left: rs.sm),
          child: ChoiceChip(
            label: Text(
              label,
              style: context.textStyles.bodyMedium?.copyWith(
                color: isSelected
                    ? AppColors.primaryWhite
                    : AppColors.primaryBlack,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(id),
            backgroundColor: AppColors.primaryWhite,
            selectedColor: AppColors.deepTeal,
            padding: EdgeInsets.symmetric(horizontal: rs.md, vertical: rs.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(rr.lg),
              side: BorderSide(
                color: isSelected ? AppColors.deepTeal : AppColors.outlineGray,
                width: isSelected ? borderWidth : 1.0,
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
