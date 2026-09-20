import 'package:flutter/material.dart';
import '../theme.dart';
import '../responsive.dart';

/// Placeholder با انیمیشن Shimmer ساده برای `ProductCard`، برای زمانی
/// که اطلاعات محصولات در حال دریافت/Refresh است. کاملاً Backend-ready:
/// هر جا در آینده یک وضعیت Loading واقعی از API داشتیم، کافی است همین
/// ویجت به‌جای `ProductCard` رندر شود.
class ProductCardSkeleton extends StatefulWidget {
  const ProductCardSkeleton({super.key});

  @override
  State<ProductCardSkeleton> createState() => _ProductCardSkeletonState();
}

class _ProductCardSkeletonState extends State<ProductCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rr = context.rr;
    final rs = context.rs;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + (_controller.value * 0.25);
        final baseColor = AppColors.outlineGray.withValues(alpha: opacity);

        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rr.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 4, child: Container(color: baseColor)),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: EdgeInsets.all(rs.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(height: 12, color: baseColor),
                      Container(height: 10, width: 70, color: baseColor),
                      Container(height: 12, width: 60, color: baseColor),
                      Container(height: 28, color: baseColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
