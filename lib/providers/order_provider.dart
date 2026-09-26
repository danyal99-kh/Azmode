import 'package:flutter/foundation.dart';

import '../pages/api_order_repository.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({required ApiOrderRepository repository})
    : _repository = repository;

  final ApiOrderRepository _repository;

  bool _isSubmitting = false;
  String? _error;
  Map<String, dynamic>? _lastOrder;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  Map<String, dynamic>? get lastOrder => _lastOrder;

  Future<Map<String, dynamic>?> submitOrder() async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _repository.submitOrder();

      _lastOrder = order;

      return order;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;

    _error = null;
    notifyListeners();
  }

  void clearLastOrder() {
    _lastOrder = null;
    notifyListeners();
  }
}
