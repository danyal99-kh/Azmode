import 'package:azmode/pages/product_feed_controller.dart';
import 'package:azmode/pages/product_query.dart';
import 'package:flutter/material.dart';
import '../responsive.dart';
import '../theme.dart';
import 'product_card.dart';
import 'product_card_skeleton.dart';

/// نمایش کامل یک [ProductFeedController] به‌صورت Sliver:
/// Skeleton (Initial Load) / خطا / خالی / Grid مجازی‌شده / فوتر Load More.
///
/// فقط همین Sliver به کنترلر گوش می‌دهد؛ AppBar، نوار دسته‌بندی، بنر و ...
/// با تغییر وضعیت لیست Rebuild نمی‌شوند.
///
/// Grid با SliverGrid (Lazy) ساخته می‌شود: فقط کارت‌های داخل Viewport
/// (+ cacheExtent صفحه) ساخته می‌شوند، نه همه‌ی محصولات.
class ProductFeedSliver extends StatelessWidget {
  final ProductFeedController controller;
  final EdgeInsetsGeometry? padding;
  final double? cardAspectRatio;

  const ProductFeedSliver({
    super.key,
    required this.controller,
    this.padding,
    this.cardAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final rs = context.rs;
        final pad = padding ?? EdgeInsets.all(rs.md);
        final aspect =
            cardAspectRatio ??
            context.responsive<double>(
              mobile: 0.52,
              tablet: 0.62,
              desktop: 0.68,
            );

        // ۱) بارگذاری اولیه → Skeleton
        if (!controller.started || controller.initialLoading) {
          return _grid(
            context,
            pad: pad,
            aspect: aspect,
            skeletonRows: 3,
            itemCount: 0,
            itemBuilder: (_, __) => const SizedBox.shrink(),
          );
        }

        // ۲) خطای بارگذاری اولیه
        if (controller.error != null && controller.items.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _StateMessage(
              icon: Icons.wifi_off_rounded,
              message: controller.error!.userMessage,
              actionLabel: 'تلاش مجدد',
              onAction: () => controller.reload(clearItems: true),
            ),
          );
        }

        // ۳) خالی (با Loading/Error اشتباه گرفته نمی‌شود)
        if (controller.items.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(query: controller.query),
          );
        }

        // ۴) لیست + فوتر
        final items = controller.items;
        return SliverMainAxisGroup(
          slivers: [
            _grid(
              context,
              pad: pad,
              aspect: aspect,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final p = items[index];
                return ProductCard(key: ValueKey(p.id), product: p);
              },
            ),
            if (controller.hasMore ||
                controller.loadingMore ||
                controller.loadMoreError != null)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  // Lazy: فقط وقتی نزدیک Viewport برسد ساخته می‌شود و
                  // همان لحظه صفحه‌ی بعد را درخواست می‌کند.
                  (context, _) => _LoadMoreFooter(controller: controller),
                  childCount: 1,
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: rs.sm)),
          ],
        );
      },
    );
  }

  Widget _grid(
    BuildContext context, {
    required EdgeInsetsGeometry pad,
    required double aspect,
    required int itemCount,
    required NullableIndexedWidgetBuilder itemBuilder,
    int skeletonRows = 0,
  }) {
    final rs = context.rs;
    return SliverPadding(
      padding: pad,
      // SliverLayoutBuilder: تعداد ستون بر اساس عرض «واقعی» Viewport
      // (نه عرض کل صفحه) → با Resize/Rail دسکتاپ هم درست می‌ماند.
      sliver: SliverLayoutBuilder(
        builder: (context, sc) {
          final cols = context.gridColumnsFor(
            sc.crossAxisExtent,
            tileMinWidth: 165 * context.uiScale,
          );
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              childAspectRatio: aspect,
              crossAxisSpacing: rs.md,
              mainAxisSpacing: rs.md,
            ),
            delegate: SliverChildBuilderDelegate(
              skeletonRows > 0
                  ? (_, __) => const ProductCardSkeleton()
                  : itemBuilder,
              childCount: skeletonRows > 0 ? cols * skeletonRows : itemCount,
              addAutomaticKeepAlives: false,
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// فوتر: Loading / Retry / تریگر خودکار Load More
// ═══════════════════════════════════════════════════════════════
class _LoadMoreFooter extends StatelessWidget {
  final ProductFeedController controller;
  const _LoadMoreFooter({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    if (controller.loadMoreError != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: rs.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.loadMoreError!.userMessage,
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall,
            ),
            SizedBox(height: rs.sm),
            OutlinedButton.icon(
              onPressed: controller.retryLoadMore,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }

    if (!controller.loadingMore) {
      // این Widget فقط وقتی ساخته می‌شود که کاربر نزدیک انتهای لیست
      // است. loadMore خودش در برابر فراخوانی تکراری ایمن است.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadMore();
      });
    }

    return SizedBox(
      height: 56,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.deepTeal,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// حالت‌های پیام (خطا / خالی)
// ═══════════════════════════════════════════════════════════════
class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(rs.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.outlineGray),
            SizedBox(height: rs.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textStyles.bodyLarge?.withColor(
                AppColors.primaryBlack.withValues(alpha: 0.6),
              ),
            ),
            if (actionLabel != null) ...[
              SizedBox(height: rs.md),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ProductQuery query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final search = query.search.trim();
    if (search.isNotEmpty) {
      return _StateMessage(
        icon: Icons.search_off,
        message: 'نتیجه‌ای برای «$search» پیدا نشد.',
      );
    }
    if (query.categoryId != null) {
      return const _StateMessage(
        icon: Icons.category_outlined,
        message: 'در این دسته‌بندی هنوز محصولی وجود ندارد.',
      );
    }
    if (!query.isDefault) {
      return const _StateMessage(
        icon: Icons.filter_alt_off_outlined,
        message: 'با این فیلترها محصولی پیدا نشد.',
      );
    }
    return const _StateMessage(
      icon: Icons.inventory_2_outlined,
      message: 'هنوز محصولی ثبت نشده است.',
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// نگه‌دارنده‌ی ScrollController: موقعیت اسکرول را در فید ذخیره/بازیابی
// می‌کند و با تغییر Query (جستجو/دسته/فیلتر) به ابتدای لیست می‌برد.
// ═══════════════════════════════════════════════════════════════
class FeedScrollBinding {
  FeedScrollBinding(this.feed)
    : controller = ScrollController(
        initialScrollOffset: feed.savedScrollOffset,
      ) {
    _lastQuery = feed.query;
    controller.addListener(_remember);
    feed.addListener(_onFeedChanged);
  }

  final ProductFeedController feed;
  final ScrollController controller;
  late ProductQuery _lastQuery;

  void _remember() {
    if (controller.hasClients) feed.savedScrollOffset = controller.offset;
  }

  void _onFeedChanged() {
    if (feed.query == _lastQuery) return;
    _lastQuery = feed.query;
    if (controller.hasClients && controller.offset > 0) {
      controller.jumpTo(0);
    }
  }

  void dispose() {
    controller.removeListener(_remember);
    feed.removeListener(_onFeedChanged);
    controller.dispose();
  }
}
