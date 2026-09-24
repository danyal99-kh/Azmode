import 'dart:async';
import 'package:azmode/model.dart';
import 'package:azmode/pages/product_image.dart';
import 'package:azmode/responsive.dart';
import 'package:azmode/theme.dart';
import 'package:flutter/material.dart';

/// کاروسل بنرهای تبلیغاتی صفحه اصلی.
///
/// این ویجت هیچ وابستگی مستقیمی به `StoreProvider` ندارد؛ لیست بنرها و
/// رفتار کلیک از بیرون (توسط `HomePage`) داده می‌شود — هماهنگ با الگوی
/// «Config Object» فعلی پروژه (مثل `ShopAppBarConfig`).
class HomeBannerCarousel extends StatefulWidget {
  final List<PromoBanner> banners;
  final ValueChanged<PromoBanner> onBannerTap;

  const HomeBannerCarousel({
    super.key,
    required this.banners,
    required this.onBannerTap,
  });

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  static const _autoPlayInterval = Duration(seconds: 5);

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _restartAutoPlay(int itemCount) {
    _autoPlayTimer?.cancel();
    if (itemCount <= 1) return;
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) {
      if (!_pageController.hasClients) return;
      final next = (_currentPage + 1) % itemCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    if (_currentPage >= banners.length) {
      _currentPage = 0;
    }

    // هر بار که تعداد بنرها یا این ویجت تغییر کند، تایمر با اطلاعات
    // جدید ری‌استارت می‌شود (بدون Memory Leak، چون قبلی همیشه Cancel
    // می‌شود).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restartAutoPlay(banners.length);
    });

    final rs = context.rs;
    final rr = context.rr;
    final ui = context.uiScale;

    final height =
        context.responsive<double>(mobile: 150, tablet: 190, desktop: 230) *
        ui.clamp(0.9, 1.15);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: rs.md, vertical: rs.sm),
      child: Column(
        children: [
          SizedBox(
            height: height,
            child: Listener(
              onPointerDown: (_) => _restartAutoPlay(banners.length),
              child: PageView.builder(
                controller: _pageController,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: rs.xs),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(rr.lg),
                      child: GestureDetector(
                        onTap: () => widget.onBannerTap(banner),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ProductImage(
                              imageUrl: banner.imageUrl,
                              imageSource: banner.imageSource,
                              fit: BoxFit.cover,
                            ),
                            const Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Color(0x8C000000),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: rs.md,
                              left: rs.md,
                              bottom: rs.md,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    banner.title,
                                    style: context.textStyles.titleMedium
                                        ?.withColor(AppColors.primaryWhite)
                                        .bold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (banner.subtitle.trim().isNotEmpty) ...[
                                    SizedBox(height: rs.xs * 0.5),
                                    Text(
                                      banner.subtitle,
                                      style: context.textStyles.bodySmall
                                          ?.withColor(AppColors.primaryWhite),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (banners.length > 1) ...[
            SizedBox(height: rs.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 3 * ui),
                  width: isActive ? 18 * ui : 7 * ui,
                  height: 7 * ui,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.deepTeal
                        : AppColors.outlineGray,
                    borderRadius: BorderRadius.circular(4 * ui),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
