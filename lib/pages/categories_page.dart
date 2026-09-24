import 'package:azmode/pages/product_feed_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../model.dart';
import '../responsive.dart';
import '../store_provider.dart';
import '../theme.dart';
import 'product_feed_sliver.dart';

/// دسته‌بندی‌ها: سایدبار دسته‌ها + Grid محصولات همان دسته.
///
/// فقط محصولات دسته‌ی انتخاب‌شده (صفحه‌به‌صفحه) از Repository گرفته
/// می‌شود؛ هیچ‌وقت «همه‌ی محصولات → فیلتر در Flutter» انجام نمی‌شود.
/// Cache باعث می‌شود برگشتن به دسته‌ی قبلی فوری باشد.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late final CategoryFeedController _feed;
  late final FeedScrollBinding _scroll;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _feed = context.read<CategoryFeedController>();
    _scroll = FeedScrollBinding(_feed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;

    final categories = context.read<StoreProvider>().categories;
    final queryCatId = GoRouterState.of(context).uri.queryParameters['catId'];

    // اولویت: catId در آدرس (بنر/دسته‌ی پرکاربرد) ← دسته‌ی قبلی ← اولین دسته
    String? target;
    if (queryCatId != null && categories.any((c) => c.id == queryCatId)) {
      target = queryCatId;
    } else {
      final current = _feed.query.categoryId;
      if (current != null && categories.any((c) => c.id == current)) {
        target = current;
      } else if (categories.isNotEmpty) {
        target = categories.first.id;
      }
    }
    if (target == null) return;

    final resolved = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _feed.setCategory(resolved); // اگر عوض شده باشد Reload می‌شود
      _feed.ensureLoaded(); // اگر عوض نشده، فقط در صورت نیاز بارگذاری
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

  @override
  Widget build(BuildContext context) {
    final aspect = context.responsive<double>(
      mobile: 0.52,
      tablet: 0.68,
      desktop: 0.78,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'دسته‌بندی‌ها',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
      ),
      body: context.centerMaxWidth(
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CategorySidebar(feed: _feed),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.outlineGray,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.deepTeal,
                onRefresh: _onRefresh,
                child: CustomScrollView(
                  controller: _scroll.controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  cacheExtent: 600,
                  slivers: [
                    ProductFeedSliver(
                      controller: _feed,
                      cardAspectRatio: aspect,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySidebar extends StatelessWidget {
  final CategoryFeedController feed;
  const _CategorySidebar({required this.feed});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final ui = context.uiScale;

    final width =
        context.responsive<double>(mobile: 90, tablet: 110, desktop: 130) *
        ui.clamp(0.95, 1.1);

    final selectedId = context.select<CategoryFeedController, String?>(
      (f) => f.query.categoryId,
    );

    return Container(
      width: width,
      color: AppColors.primaryWhite,
      child: Selector<StoreProvider, List<ProductCategory>>(
        selector: (_, s) => s.categories,
        builder: (context, categories, _) {
          // دسته‌ی انتخاب‌شده توسط ادمین حذف شده → برو به اولین دسته
          if (selectedId != null &&
              categories.isNotEmpty &&
              !categories.any((c) => c.id == selectedId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              feed.setCategory(categories.first.id);
            });
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.id == selectedId;
              return InkWell(
                onTap: () => feed.setCategory(category.id),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: rs.md,
                    horizontal: rs.sm,
                  ),
                  color: isSelected
                      ? AppColors.deepTeal.withValues(alpha: 0.1)
                      : Colors.transparent,
                  child: Text(
                    category.name,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: isSelected
                          ? AppColors.deepTeal
                          : AppColors.primaryBlack,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
