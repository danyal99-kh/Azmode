import 'dart:async';

/// درخواست یک صفحه از داده. هم Page-based (`page`) و هم Cursor-based
/// (`cursor`) را پشتیبانی می‌کند؛ Backend هر کدام را بدهد همان استفاده می‌شود.
class PageRequest {
  /// شماره‌ی صفحه (از ۱ شروع می‌شود).
  final int page;

  /// Cursor صفحه‌ی بعد (اگر Backend از Cursor Pagination استفاده کند).
  final String? cursor;

  final int pageSize;

  const PageRequest({required this.page, this.cursor, required this.pageSize});
}

/// نتیجه‌ی یک صفحه.
class PagedResult<T> {
  final List<T> items;
  final bool hasMore;
  final String? nextCursor;

  /// تعداد کل نتایج (اگر Backend بدهد).
  final int? total;

  const PagedResult({
    required this.items,
    required this.hasMore,
    this.nextCursor,
    this.total,
  });
}

enum DataErrorKind { network, timeout, server, unknown }

/// خطای لایه‌ی داده. لایه‌ی API واقعی باید SocketException → network،
/// پاسخ 5xx → server و ... را به این نوع تبدیل کند تا UI هیچ‌وقت با
/// Exceptionهای خام سروکار نداشته باشد.
class DataException implements Exception {
  final DataErrorKind kind;
  final String? detail;

  const DataException(this.kind, [this.detail]);

  factory DataException.from(Object error) {
    if (error is DataException) return error;
    if (error is TimeoutException) {
      return const DataException(DataErrorKind.timeout);
    }
    return DataException(DataErrorKind.unknown, error.toString());
  }

  String get userMessage {
    switch (kind) {
      case DataErrorKind.network:
        return 'ارتباط با اینترنت برقرار نیست. اتصال خود را بررسی کنید.';
      case DataErrorKind.timeout:
        return 'پاسخ سرور طولانی شد. دوباره تلاش کنید.';
      case DataErrorKind.server:
        return 'مشکلی در سرور رخ داد. کمی بعد دوباره تلاش کنید.';
      case DataErrorKind.unknown:
        return 'خطای ناشناخته‌ای رخ داد. دوباره تلاش کنید.';
    }
  }

  @override
  String toString() =>
      'DataException($kind${detail != null ? ': $detail' : ''})';
}
