import 'dart:async';
import 'package:flutter/material.dart';
import '../model.dart';
import '../theme.dart';
import '../responsive.dart';

/// اسلایدر بنرهای تبلیغاتی بالای صفحه اصلی.
///
/// به‌صورت خودکار (هر ۵ ثانیه) بین بنرها می‌چرخد؛ کاربر هم می‌تواند
/// دستی سوایپ کند. با لمس هر بنر، اگر [PromoBanner.productId] ست شده
/// باشد، [onBannerTap] صدا زده می‌شود.
class PromoBannerCarousel extends StatefulWidget {
  final List<PromoBanner> banners;
  final ValueChanged<PromoBanner> onBannerTap;

  const PromoBannerCarousel({
    super.key,
    required this.banners,
    required this.onBannerTap,
  });

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.banners.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextPage = (_currentPage + 1) % widget.banners.length;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final rs = context.rs;
    final ui = context.uiScale;
    final rr = context.rr;

    final height =
        context.responsive<double>(mobile: 120, tablet: 140, desktop: 160) *
        ui.clamp(0.95, 1.15);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: rs.md),
                child: _BannerCard(
                  banner: banner,
                  radius: rr.lg,
                  onTap: () => widget.onBannerTap(banner),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          SizedBox(height: rs.sm),
          _PageIndicator(
            count: widget.banners.length,
            currentIndex: _currentPage,
          ),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final PromoBanner banner;
  final double radius;
  final VoidCallback onTap;

  const _BannerCard({
    required this.banner,
    required this.radius,
    required this.onTap,
  });

  _BannerVisuals get _visuals {
    switch (banner.style) {
      case PromoBannerStyle.teal:
        return _BannerVisuals(
          gradient: [AppColors.deepTeal, const Color(0xFF00363A)],
          icon: Icons.local_offer_rounded,
        );
      case PromoBannerStyle.warm:
        return _BannerVisuals(
          gradient: [AppColors.warning, const Color(0xFFB33F00)],
          icon: Icons.new_releases_rounded,
        );
      case PromoBannerStyle.dark:
        return _BannerVisuals(
          gradient: [AppColors.primaryBlack, AppColors.darkGray],
          icon: Icons.local_shipping_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final ui = context.uiScale;
    final visuals = _visuals;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: visuals.gradient,
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
          ),
          padding: EdgeInsets.all(rs.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      banner.title,
                      style: context.textStyles.titleMedium
                          ?.withColor(AppColors.primaryWhite)
                          .bold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: rs.xs),
                    Text(
                      banner.subtitle,
                      style: context.textStyles.bodySmall?.withColor(
                        AppColors.primaryWhite.withValues(alpha: 0.85),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: rs.sm),
              Icon(
                visuals.icon,
                color: AppColors.primaryWhite.withValues(alpha: 0.85),
                size: (36.0 * ui).clamp(30.0, 44.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerVisuals {
  final List<Color> gradient;
  final IconData icon;
  const _BannerVisuals({required this.gradient, required this.icon});
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _PageIndicator({required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final ui = context.uiScale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 3 * ui),
          width: (isActive ? 18.0 : 6.0) * ui,
          height: 6.0 * ui,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.deepTeal
                : AppColors.outlineGray.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(3 * ui),
          ),
        );
      }),
    );
  }
}
