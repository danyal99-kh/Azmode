import 'package:flutter/material.dart';
import '../../theme.dart';

/// Search Bar حرفه‌ای فروشگاه.
///
/// نسبت به نسخه‌ی قبلی، این ویجت:
/// - به‌جای یک باکس سفید بدون قاب، یک بردر ظریف با رنگ اصلی برنامه
///   (deepTeal / سبز کله‌قازی) دارد تا هم‌رنگ با بقیه‌ی اپ باشد و هم
///   لبه‌ی آن مشخص و منظم دیده شود.
/// - یک دکمه‌ی پاک‌کردن (×) دارد که فقط وقتی متنی تایپ شده نمایش داده
///   می‌شود، تا کاربر مجبور نباشد با دست همه‌ی متن را پاک کند.
///
/// دو حالت استفاده دارد:
/// 1) حالت Inline — وقتی [onChanged] داده شود: مثل یک TextField معمولی
///    عمل می‌کند و فیلتر می‌تواند همان‌جا (مثلاً در صفحه اصلی) انجام شود.
/// 2) حالت Navigate — وقتی [onChanged] داده نشود: فیلد فقط‌خواندنی
///    می‌شود و با لمس، صرفاً [onTap] صدا زده می‌شود (برای هدایت کاربر به
///    یک صفحه‌ی Search کامل در آینده).
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

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.deepTeal.withOpacity(0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlack.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isNavigateMode ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                const SizedBox(width: 8),
                const Icon(Icons.search, color: AppColors.deepTeal, size: 20),
                const SizedBox(width: 8),
                Expanded(child: _buildField(context, isNavigateMode)),
                _buildClearButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context, bool isNavigateMode) {
    final decoration = InputDecoration(
      hintText: hintText,
      hintStyle: context.textStyles.bodySmall?.withColor(AppColors.outlineGray),
      border: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );

    if (controller == null) {
      return TextField(
        readOnly: true,
        onTap: onTap,
        textAlignVertical: TextAlignVertical.center,
        style: context.textStyles.bodyMedium,
        decoration: decoration,
      );
    }

    // با AnimatedBuilder به controller گوش می‌دهیم تا دکمه‌ی پاک‌کردن
    // بلافاصله با تایپ/پاک‌شدن متن ظاهر یا مخفی شود.
    return AnimatedBuilder(
      animation: controller!,
      builder: (context, _) {
        return TextField(
          controller: controller,
          readOnly: isNavigateMode,
          onChanged: onChanged,
          onTap: onTap,
          textAlignVertical: TextAlignVertical.center,
          style: context.textStyles.bodyMedium,
          decoration: decoration,
        );
      },
    );
  }

  Widget _buildClearButton() {
    if (controller == null) return const SizedBox(width: 8);
    return AnimatedBuilder(
      animation: controller!,
      builder: (context, _) {
        if (controller!.text.isEmpty) return const SizedBox(width: 8);
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            controller!.clear();
            onChanged?.call('');
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.close, color: AppColors.outlineGray, size: 18),
          ),
        );
      },
    );
  }
}
