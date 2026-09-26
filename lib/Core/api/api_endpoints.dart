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

  // ── جدید: سفارش‌ها / پیش‌فاکتور ──
  static const String orders = '/api/orders/';
  static const String orderSubmit = '/api/orders/submit/';
  static const String myOrders = '/api/orders/mine/';
}
