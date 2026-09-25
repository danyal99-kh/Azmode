class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/api/auth/login/';
  static const String refresh = '/api/auth/refresh/';

  static const String me = '/api/account/me/';

  static const String cart = '/api/cart/';
  static const String cartAdd = '/api/cart/add/';
  static const String cartUpdate = '/api/cart/';
  static const String cartRemove = '/api/cart/';

  static const String orders = '/api/orders/';
  static const String submitOrder = '/api/orders/submit/';
  static const String myOrders = '/api/orders/mine/';
}
