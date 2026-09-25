import 'package:flutter/foundation.dart';

import '../model.dart';
import '../pages/api_cart_repository.dart';

class CartProvider extends ChangeNotifier {
  CartProvider({required ApiCartRepository repository})
    : _repository = repository;

  final ApiCartRepository _repository;

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isEmpty => _items.isEmpty;

  int get itemCount => _items.fold(0, (total, item) => total + item.quantity);

  double get totalPrice =>
      _items.fold(0, (total, item) => total + item.totalPrice);

  Future<void> loadCart() async {
    _setLoading(true);
    _error = null;

    try {
      _items = await _repository.fetchCart();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addToCart({
    required Product product,
    required int quantity,
    String? selectedColor,
  }) async {
    _error = null;

    try {
      final item = await _repository.addToCart(
        productId: product.id,
        quantity: quantity,
        selectedColor: selectedColor,
      );

      _upsertItem(item);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateQuantity({
    required CartItem item,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeItem(item);
      return;
    }

    final cartItemId = item.id;

    if (cartItemId == null) {
      throw StateError('شناسه آیتم سبد خرید موجود نیست.');
    }

    _error = null;

    try {
      final updatedItem = await _repository.updateCartItem(
        cartItemId: cartItemId,
        quantity: quantity,
        selectedColor: item.selectedColor,
      );

      _replaceItem(updatedItem);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeItem(CartItem item) async {
    final cartItemId = item.id;

    if (cartItemId == null) {
      throw StateError('شناسه آیتم سبد خرید موجود نیست.');
    }

    _error = null;

    try {
      await _repository.removeCartItem(cartItemId);

      _items.removeWhere((current) => current.id == cartItemId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem({
    required CartItem item,
    required int quantity,
    String? selectedColor,
  }) async {
    final cartItemId = item.id;

    if (cartItemId == null) {
      throw StateError('شناسه آیتم سبد خرید موجود نیست.');
    }

    if (quantity <= 0) {
      await removeItem(item);
      return;
    }

    _error = null;

    try {
      final updatedItem = await _repository.updateCartItem(
        cartItemId: cartItemId,
        quantity: quantity,
        selectedColor: selectedColor,
      );

      _replaceItem(updatedItem);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }

  void _upsertItem(CartItem item) {
    final id = item.id;

    if (id == null) {
      _items.add(item);
      return;
    }

    final index = _items.indexWhere((current) => current.id == id);

    if (index == -1) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
  }

  void _replaceItem(CartItem item) {
    final id = item.id;

    if (id == null) {
      return;
    }

    final index = _items.indexWhere((current) => current.id == id);

    if (index != -1) {
      _items[index] = item;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
