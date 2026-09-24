import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'paged_result.dart';

/// کنترلر عمومی لیست صفحه‌بندی‌شده — مستقل از UI و مستقل از نوع داده.
///
/// این کلاس برای محصولات استفاده می‌شود، ولی عمداً Generic نوشته شده تا
/// بعداً برای سفارش‌ها، اعلان‌ها، کاربران (پنل ادمین) و ... هم بدون کپی
/// کردن منطق استفاده شود.
///
/// تضمین‌ها:
/// - همزمان فقط یک درخواست Load More در حال اجراست.
/// - هر `reload` یک «نسل» (generation) جدید می‌سازد؛ پاسخ درخواست‌های
///   قدیمی (Search قبلی، Pagination قبلی، Refresh قبلی) دور ریخته می‌شود
///   → Race Condition ندارد.
/// - آیتم‌های تکراری (بر اساس id) هرگز وارد لیست نمی‌شوند.
/// - Initial Loading / Refreshing / Load More سه وضعیت جدا هستند.
/// - بعد از dispose هیچ notifyListeners ای اجرا نمی‌شود.
abstract class PagedListController<T> extends ChangeNotifier {
  PagedListController({this.requestTimeout = const Duration(seconds: 15)});

  final Duration requestTimeout;

  // ── Hookهایی که زیرکلاس پیاده‌سازی می‌کند ──────────────────────
  int get pageSize;
  String idOf(T item);
  Future<PagedResult<T>> fetchPage(PageRequest request);

  /// سقف اختیاری برای تعداد آیتم‌ها (مثلاً «جدیدترین‌ها» در Home).
  int? get maxItems => null;

  // ── State ─────────────────────────────────────────────────────
  final LinkedHashMap<String, T> _byId = LinkedHashMap<String, T>();
  List<T> _items = const [];

  bool _started = false;
  bool _stale = false;
  bool _initialLoading = false;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _disposed = false;

  DataException? _error;
  DataException? _loadMoreError;
  DataException? _refreshError;

  int? _total;
  int _generation = 0;
  int _nextPage = 1;
  String? _nextCursor;

  /// موقعیت اسکرول — برای برگشت از صفحه‌ی جزئیات یا تعویض تب.
  double savedScrollOffset = 0;

  // ── Getters ───────────────────────────────────────────────────
  /// Snapshot تغییرناپذیر. فقط هنگام تغییر داده (نه در هر build) ساخته
  /// می‌شود، پس مقایسه‌ی identity برای Selector/Rebuild ارزان است.
  List<T> get items => _items;
  bool get started => _started;
  bool get initialLoading => _initialLoading;
  bool get refreshing => _refreshing;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  DataException? get error => _error;
  DataException? get loadMoreError => _loadMoreError;
  DataException? get refreshError => _refreshError;
  int? get total => _total;

  /// «خالی» یعنی واقعاً بارگذاری تمام شده و چیزی نیست
  /// (با Loading و Error اشتباه گرفته نمی‌شود).
  bool get isEmpty =>
      _started && !_initialLoading && _error == null && _items.isEmpty;

  // ── API عمومی ─────────────────────────────────────────────────

  /// Idempotent: بارها صدا زدن (مثلاً از initState صفحه‌ها) درخواست
  /// تکراری نمی‌سازد.
  Future<void> ensureLoaded() {
    if (!_started) return reload(clearItems: true);
    if (_stale) return refresh();
    return Future<void>.value();
  }

  /// علامت‌گذاری «داده قدیمی شده»؛ دفعه‌ی بعد که صفحه نمایش داده شد
  /// (ensureLoaded) بازخوانی می‌شود.
  void markStale() => _stale = true;

  /// Pull-to-Refresh / Invalidation: لیست فعلی تا رسیدن پاسخ نمایش داده
  /// می‌ماند (Skeleton نمی‌پرد)، سپس با صفحه‌ی ۱ جایگزین می‌شود.
  Future<void> refresh() => reload(clearItems: false);

  /// شروع از صفحه‌ی ۱. اگر [clearItems] درست باشد (تغییر Query) لیست
  /// قبلی فوراً پاک و Skeleton نمایش داده می‌شود.
  Future<void> reload({bool clearItems = false}) async {
    if (_disposed) return;
    _started = true;
    _stale = false;
    final generation = ++_generation; // درخواست‌های قبلی را باطل می‌کند
    _loadingMore = false;
    _loadMoreError = null;
    _refreshError = null;

    if (clearItems || _byId.isEmpty) {
      _byId.clear();
      _items = const [];
      _hasMore = false;
      _initialLoading = true;
      _refreshing = false;
      _error = null;
    } else {
      _initialLoading = false;
      _refreshing = true;
    }
    notifyListeners();

    try {
      final result = await _fetch(PageRequest(page: 1, pageSize: pageSize));
      if (_isStale(generation)) return;
      _byId.clear();
      _addAll(result.items);
      _publish();
      _nextPage = 2;
      _nextCursor = result.nextCursor;
      _total = result.total;
      _hasMore = result.hasMore && result.items.isNotEmpty && !_reachedMax;
      _error = null;
    } catch (e) {
      if (_isStale(generation)) return;
      final ex = DataException.from(e);
      if (_byId.isEmpty) {
        _error = ex; // خطای بارگذاری اولیه → صفحه‌ی خطا
      } else {
        _refreshError = ex; // Refresh شکست خورد → لیست قبلی سالم می‌ماند
      }
    }
    _initialLoading = false;
    _refreshing = false;
    notifyListeners();
  }

  /// دریافت صفحه‌ی بعد. امن برای فراخوانی مکرر (از اسکرول).
  Future<void> loadMore() async {
    if (_disposed ||
        !_hasMore ||
        _loadingMore ||
        _initialLoading ||
        _refreshing ||
        _loadMoreError != null) {
      return;
    }
    final generation = _generation;
    _loadingMore = true;
    notifyListeners();

    try {
      final result = await _fetch(
        PageRequest(page: _nextPage, cursor: _nextCursor, pageSize: pageSize),
      );
      if (_isStale(generation)) return;
      _addAll(result.items);
      _publish();
      _nextPage += 1;
      _nextCursor = result.nextCursor;
      _total = result.total ?? _total;
      // صفحه‌ی خالی = پایان (جلوگیری از حلقه‌ی بی‌نهایت در Backend اشتباه)
      _hasMore = result.hasMore && result.items.isNotEmpty && !_reachedMax;
    } catch (e) {
      if (_isStale(generation)) return;
      _loadMoreError = DataException.from(e);
    }
    _loadingMore = false;
    notifyListeners();
  }

  /// Retry فقط برای همان بخش پایین لیست، بدون Load مجدد کل صفحه.
  Future<void> retryLoadMore() {
    _loadMoreError = null;
    notifyListeners();
    return loadMore();
  }

  // ── داخلی ─────────────────────────────────────────────────────
  Future<PagedResult<T>> _fetch(PageRequest request) =>
      fetchPage(request).timeout(requestTimeout);

  bool _isStale(int generation) => _disposed || generation != _generation;

  bool get _reachedMax {
    final max = maxItems;
    return max != null && _byId.length >= max;
  }

  void _addAll(List<T> incoming) {
    for (final item in incoming) {
      final max = maxItems;
      if (max != null && _byId.length >= max) break;
      String id;
      try {
        id = idOf(item);
      } catch (_) {
        continue; // آیتم خراب
      }
      if (id.isEmpty) continue;
      _byId.putIfAbsent(id, () => item); // Duplicate نادیده گرفته می‌شود
    }
  }

  void _publish() => _items = List<T>.unmodifiable(_byId.values);

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
