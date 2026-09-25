import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/order_service.dart';

enum OrderStatusState { initial, loading, loaded, error }

class OrderProvider extends ChangeNotifier {
  OrderProvider({required OrderService orderService})
    : _orderService = orderService;

  final OrderService _orderService;

  OrderStatusState _status = OrderStatusState.initial;
  String? _errorMessage;
  Order? _submittedOrder;
  List<Order> _orders = [];

  OrderStatusState get status => _status;
  String? get errorMessage => _errorMessage;
  Order? get submittedOrder => _submittedOrder;
  List<Order> get orders => List.unmodifiable(_orders);

  bool get isLoading => _status == OrderStatusState.loading;

  Future<bool> submitOrder() async {
    _status = OrderStatusState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _submittedOrder = await _orderService.submitOrder();
      _status = OrderStatusState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = OrderStatusState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadMyOrders() async {
    _status = OrderStatusState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderService.getMyOrders();
      _status = OrderStatusState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = OrderStatusState.error;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;

    if (_status == OrderStatusState.error) {
      _status = OrderStatusState.initial;
    }

    notifyListeners();
  }
}
