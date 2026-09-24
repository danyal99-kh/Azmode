import 'package:azmode/pages/product_feed_controller.dart';
import 'package:azmode/pages/product_query.dart';
import 'package:azmode/pages/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../responsive.dart';
import '../store_provider.dart';
import '../theme.dart';
import 'product_feed_sliver.dart';

/// «مشاهده همه محصولات» — Pagination + Infinite Scroll + مرتب‌سازی/فیلتر.
///
/// فید مخصوص همین صفحه ساخته می‌شود (و با بسته‌شدن صفحه dispose می‌شود)؛
/// Cache مشترک Repository باعث می‌شود باز شدن دوباره‌ی صفحه سریع باشد.
class AllProductsPage extends StatelessWidget {
  const AllProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductFeedController>(
      create: (ctx) => ProductFeedController(
        repository: ctx.read<ProductRepository>(),
        invalidation: ctx.read<StoreProvider>().catalogRevision,
      ),
      child: const _AllProductsView(),
    );
  }
}

class _AllProductsView extends StatefulWidget {
  const _AllProductsView();

  @override
  State<_AllProductsView> createState() => _AllProductsViewState();
}

class _AllProductsViewState extends State<_AllProductsView> {
  late final ProductFeedController _feed;
  late final FeedScrollBinding _scroll;

  @override
  void initState() {
    super.initState();
    _feed = context.read<ProductFeedController>();
    _scroll = FeedScrollBinding(_feed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _feed.ensureLoaded();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _feed.refresh();
    final err = _feed.refreshError;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.userMessage),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  static String _sortLabel(ProductSort s) {
    switch (s) {
      case ProductSort.newest:
        return 'جدیدترین';
      case ProductSort.priceAsc:
        return 'ارزان‌ترین';
      case ProductSort.priceDesc:
        return 'گران‌ترین';
      case ProductSort.nameAsc:
        return 'نام (الف تا ی)';
      case ProductSort.popular:
        return 'محبوب‌ترین';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'همه محصولات',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryWhite),
          tooltip: 'بازگشت',
        ),
        actions: [
          // فقط موجودها
          Builder(
            builder: (context) {
              final inStockOnly = context.select<ProductFeedController, bool>(
                (f) => f.query.stock == StockFilter.inStock,
              );
              return IconButton(
                tooltip: 'فقط کالاهای موجود',
                icon: Icon(
                  inStockOnly ? Icons.inventory_2 : Icons.inventory_2_outlined,
                  color: inStockOnly
                      ? AppColors.warning
                      : AppColors.primaryWhite,
                ),
                onPressed: () => _feed.setStockFilter(
                  inStockOnly ? StockFilter.all : StockFilter.inStock,
                ),
              );
            },
          ),
          // مرتب‌سازی (فعلاً «محبوب‌ترین» چون داده ندارد در منو نیست)
          PopupMenuButton<ProductSort>(
            tooltip: 'مرتب‌سازی',
            icon: const Icon(Icons.sort, color: AppColors.primaryWhite),
            onSelected: _feed.setSort,
            itemBuilder: (_) => [
              for (final s in const [
                ProductSort.newest,
                ProductSort.priceAsc,
                ProductSort.priceDesc,
                ProductSort.nameAsc,
              ])
                PopupMenuItem(value: s, child: Text(_sortLabel(s))),
            ],
          ),
        ],
      ),
      body: context.centerMaxWidth(
        RefreshIndicator(
          color: AppColors.deepTeal,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scroll.controller,
            physics: const AlwaysScrollableScrollPhysics(),
            cacheExtent: 600,
            slivers: [ProductFeedSliver(controller: _feed)],
          ),
        ),
      ),
    );
  }
}
