import 'package:flutter/material.dart';
import '../../theme.dart';

/// Search Bar حرفه‌ای فروشگاه.
///
/// این ویجت دو حالت استفاده دارد تا هم با رفتار فعلی صفحه‌ی اصلی سازگار
/// باشد و هم مسیر توسعه‌ی آینده (صفحه‌ی Search مستقل با Suggestions،
/// Recent Searches، جستجوی برند/کد کالا، Barcode Scanner و ...) را باز
/// بگذارد:
///
/// 1) حالت Inline — وقتی [onChanged] داده شود: مثل یک TextField معمولی
///    عمل می‌کند و فیلتر می‌تواند همان‌جا (مثلاً در صفحه اصلی) انجام شود.
/// 2) حالت Navigate — وقتی [onChanged] داده نشود: فیلد فقط‌خواندنی
///    می‌شود و با لمس، صرفاً [onTap] صدا زده می‌شود (برای هدایت کاربر به
///    یک صفحه‌ی Search کامل).
class ShopSearchBar extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const ShopSearchBar({
    super.key,
    this.hintText = 'جستجوی محصول، برند یا کد کالا...',
    this.controller,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNavigateMode = onChanged == null;

    return Material(
      color: AppColors.primaryWhite,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: isNavigateMode ? onTap : null,
        child: SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            readOnly: isNavigateMode,
            onChanged: onChanged,
            onTap: onTap,
            textAlignVertical: TextAlignVertical.center,
            style: context.textStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: context.textStyles.bodyMedium?.withColor(
                AppColors.outlineGray,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.deepTeal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.primaryWhite,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
    );
  }
}
