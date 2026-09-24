import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../responsive.dart';

/// Search Bar حرفه‌ای فروشگاه.
///
/// دو حالت استفاده دارد:
/// 1) حالت Inline — وقتی [onChanged] داده شود: مثل یک TextField معمولی
///    عمل می‌کند و فیلتر همان‌جا انجام می‌شود.
/// 2) حالت Navigate — وقتی [onChanged] داده نشود: فیلد فقط‌خواندنی
///    می‌شود و با لمس، [onTap] صدا زده می‌شود.
///
/// تمام ابعاد (ارتفاع، آیکون‌ها، پدینگ‌ها، رادیوس، سایه) با
/// `uiScale`/`fontScale` هماهنگ می‌شوند تا روی گوشی کوچک، تبلت و ویندوز
/// یکدست دیده شود.
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
    final rr = context.rr;
    final ui = context.uiScale;

    // ارتفاع نوار جستجو — ریسپانسیو
    final barHeight = (46.0 * ui).clamp(42.0, 54.0);

    // آیکون‌ها
    final searchIconSize = (20.0 * ui).clamp(18.0, 24.0);
    final clearIconSize = (18.0 * ui).clamp(16.0, 22.0);

    // پدینگ‌ها
    final horizontalOuterPad = (6.0 * ui).clamp(5.0, 8.0);
    final innerGap = (8.0 * ui).clamp(6.0, 10.0);
    final verticalContentPad = (12.0 * ui).clamp(10.0, 16.0);

    // رادیوس pill
    final pillRadius = BorderRadius.circular(rr.xl + 100); // بزرگ → pill

    return SizedBox(
      height: barHeight,

      child: Material(
        color: Colors.transparent,
        borderRadius: pillRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isNavigateMode ? onTap : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalOuterPad),
            child: Row(
              children: [
                SizedBox(width: innerGap),
                Icon(
                  Icons.search,
                  color: AppColors.deepTeal,
                  size: searchIconSize,
                ),
                SizedBox(width: innerGap),
                Expanded(
                  child: _SearchField(
                    hintText: hintText,
                    controller: controller,
                    onChanged: onChanged,
                    onTap: onTap,
                    isNavigateMode: isNavigateMode,
                    verticalContentPad: verticalContentPad,
                  ),
                ),
                _ClearButton(
                  controller: controller,
                  onChanged: onChanged,
                  iconSize: clearIconSize,
                  trailingGap: innerGap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// فیلد متنی (یا فقط‌خواندنی)
// ═══════════════════════════════════════════════════════════════
class _SearchField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool isNavigateMode;
  final double verticalContentPad;

  const _SearchField({
    required this.hintText,
    required this.controller,
    required this.onChanged,
    required this.onTap,
    required this.isNavigateMode,
    required this.verticalContentPad,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      hintText: hintText,
      hintStyle: context.textStyles.bodySmall?.withColor(AppColors.outlineGray),
      border: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: verticalContentPad),
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
}

// ═══════════════════════════════════════════════════════════════
// دکمه پاک‌کردن (×) — فقط وقتی متن هست نمایش می‌یابد
// ═══════════════════════════════════════════════════════════════
class _ClearButton extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final double iconSize;
  final double trailingGap;

  const _ClearButton({
    required this.controller,
    required this.onChanged,
    required this.iconSize,
    required this.trailingGap,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null) return SizedBox(width: trailingGap);

    final ui = context.uiScale;
    final touchRadius = (20.0 * ui).clamp(18.0, 24.0);

    return AnimatedBuilder(
      animation: controller!,
      builder: (context, _) {
        if (controller!.text.isEmpty) return SizedBox(width: trailingGap);
        return InkWell(
          borderRadius: BorderRadius.circular(touchRadius),
          onTap: () {
            controller!.clear();
            onChanged?.call('');
          },
          child: Padding(
            padding: EdgeInsets.all((8.0 * ui).clamp(6.0, 10.0)),
            child: Icon(
              Icons.close,
              color: AppColors.outlineGray,
              size: iconSize,
            ),
          ),
        );
      },
    );
  }
}
