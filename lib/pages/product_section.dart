import 'package:flutter/material.dart';
import '../model.dart';
import '../theme.dart';
import '../responsive.dart';
import 'home_page.dart' show ProductCard;

/// یک بخش افقی از محصولات با عنوان و آیکون — برای «پرفروش‌ترین‌ها»،
/// «تازه‌ترین‌ها»، «رو به اتمام» و «اخیراً دیده‌شده» در صفحه اصلی.
///
/// اگر [products] خالی باشد، کل بخش (حتی عنوان) رندر نمی‌شود، تا
/// فروشگاه تازه‌راه‌اندازی‌شده با بخش‌های خالی شلوغ نشود.
class ProductSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Product> products;

  const ProductSection({
    super.key,
    required this.title,
    required this.icon,
    required this.products,
    this.accentColor = AppColors.deepTeal,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final rs = context.rs;
    final ui = context.uiScale;

    final cardWidth =
        context.responsive<double>(mobile: 152, tablet: 168, desktop: 180) *
        ui.clamp(0.95, 1.1);
    final cardHeight = cardWidth * 1.55;

    return Padding(
      padding: EdgeInsets.only(bottom: rs.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: rs.md),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: accentColor,
                  size: (20.0 * ui).clamp(18.0, 24.0),
                ),
                SizedBox(width: rs.xs),
                Expanded(
                  child: Text(
                    title,
                    style: context.textStyles.titleMedium?.bold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: rs.sm),
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: rs.md),
              itemCount: products.length,
              separatorBuilder: (_, __) => SizedBox(width: rs.sm),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: cardWidth,
                  child: ProductCard(product: products[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
