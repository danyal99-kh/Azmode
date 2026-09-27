class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/api/auth/login/';
  static const String refresh = '/api/auth/refresh/';

  static const String me = '/api/account/me/';
  static const String updateProfile = '/api/account/me/update/';
  static const String adminCreateUser = '/api/account/create-user/';

  static const String cart = '/api/cart/';
  static const String cartAdd = '/api/cart/add/';
  static const String cartUpdate = '/api/cart/';
  static const String cartRemove = '/api/cart/';

  static const String orders = '/api/orders/';
  static const String orderSubmit = '/api/orders/submit/';
  static const String myOrders = '/api/orders/mine/';

  // ── Products (DRF ModelViewSet) ──────────────────────────────
  /// لیست و ساخت محصول: GET / POST
  static const String products = '/api/products/';

  /// ویرایش و حذف محصول: PATCH / PUT / DELETE
  static String product(String id) => '/api/products/$id/';

  // ── Categories (DRF ModelViewSet) ─────────────────────────────
  /// لیست و ساخت دسته‌بندی: GET / POST
  static const String categories = '/api/categories/';

  /// ویرایش و حذف دسته‌بندی: PATCH / PUT / DELETE
  static String category(String id) => '/api/categories/$id/';

  // ── Packaging Types (DRF ModelViewSet) ────────────────────────
  /// لیست و ساخت نوع بسته‌بندی: GET / POST
  static const String packagingTypes = '/api/packaging-types/';

  /// ویرایش و حذف نوع بسته‌بندی: PATCH / PUT / DELETE
  static String packagingType(String id) => '/api/packaging-types/$id/';

  // ── Banners (DRF ModelViewSet) ─────────────────────────────────
  /// لیست و ساخت بنر: GET / POST
  static const String banners = '/api/banners/';

  /// ویرایش و حذف بنر: PATCH / PUT / DELETE
  static String banner(String id) => '/api/banners/$id/';

  // ── Warehouse / Stock ─────────────────────────────────────────
  /// ثبت تغییر موجودی: POST
  static const String stockAdjust = '/api/warehouse/stock/adjust/';

  /// تاریخچه تغییرات موجودی: GET
  static const String stockHistory = '/api/warehouse/stock/history/';

  // ── Notifications ──────────────────────────────────────────────
  /// لیست اعلان‌ها: GET
  static const String notifications = '/api/notifications/';
}
