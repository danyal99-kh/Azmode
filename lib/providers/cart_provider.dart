import 'package:azmode/services/cart_service.dart';
import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';

enum CartStatus { initial, loading, loaded, error }

class CartProvider extends ChangeNotifier {
  CartProvider({required CartService cartService}) : _cartService = cartService;

  final CartService _cartService;

  CartStatus _status = CartStatus.initial;
  List<CartItem> _items = [];
  String? _errorMessage;

  CartStatus get status => _status;
  List<CartItem> get items => List.unmodifiable(_items);
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == CartStatus.loading;

  bool get isEmpty => _items.isEmpty;

  double get totalPrice {
    return _items.fold(0, (total, item) => total + item.totalPrice);
  }

  Future<void> loadCart() async {
    _status = CartStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _cartService.getCart();
      _status = CartStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = CartStatus.error;
    }

    notifyListeners();
  }

  Future<bool> addToCart({
    required int productId,
    required int quantity,
    String? selectedColor,
  }) async {
    try {
      await _cartService.addToCart(
        productId: productId,
        quantity: quantity,
        selectedColor: selectedColor,
      );

      await loadCart();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    try {
      await _cartService.updateCartItem(
        cartItemId: cartItemId,
        quantity: quantity,
      );

      await loadCart();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeItem(int cartItemId) async {
    try {
      await _cartService.removeFromCart(cartItemId);

      _items.removeWhere((item) => item.id == cartItemId);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;

    if (_status == CartStatus.error) {
      _status = _items.isEmpty ? CartStatus.initial : CartStatus.loaded;
    }

    notifyListeners();
  }
}
