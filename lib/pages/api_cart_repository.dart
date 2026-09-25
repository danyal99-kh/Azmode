import 'package:azmode/Core/api/api_client.dart';
import 'package:azmode/Core/api/api_endpoints.dart';

import '../model.dart';
import 'product_repository.dart';

class ApiCartRepository {
  ApiCartRepository({
    required ApiClient apiClient,
    required ProductRepository productRepository,
  }) : _apiClient = apiClient,
       _productRepository = productRepository;

  final ApiClient _apiClient;
  final ProductRepository _productRepository;

  Future<List<CartItem>> fetchCart() async {
    final response = await _apiClient.get(
      ApiEndpoints.cart,
      requiresAuth: true,
    );

    if (response is! List) {
      throw ApiException('پاسخ سبد خرید از سرور نامعتبر است.');
    }

    final items = <CartItem>[];

    for (final rawItem in response) {
      if (rawItem is! Map<String, dynamic>) {
        continue;
      }

      final item = await _mapCartItem(rawItem);

      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  Future<CartItem> addToCart({
    required String productId,
    required int quantity,
    String? selectedColor,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.cartAdd,
      requiresAuth: true,
      body: {
        'product': _parseId(productId),
        'quantity': quantity,
        'selected_color': selectedColor,
      },
    );

    return _mapSingleCartItem(response);
  }

  Future<CartItem> updateCartItem({
    required String cartItemId,
    required int quantity,
    String? selectedColor,
  }) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.cartUpdate}$cartItemId/',
      requiresAuth: true,
      body: {'quantity': quantity, 'selected_color': selectedColor},
    );

    return _mapSingleCartItem(response);
  }

  Future<void> removeCartItem(String cartItemId) async {
    await _apiClient.delete(
      '${ApiEndpoints.cartRemove}$cartItemId/remove/',
      requiresAuth: true,
    );
  }

  Future<CartItem?> _mapCartItem(Map<String, dynamic> json) async {
    final productId = json['product']?.toString();

    if (productId == null || productId.isEmpty) {
      return null;
    }

    final product = await _productRepository.fetchProduct(productId);

    if (product == null) {
      return null;
    }

    return CartItem(
      id: json['id']?.toString(),
      product: product,
      quantity: _toInt(json['quantity']),
      selectedColor: json['selected_color']?.toString(),
    );
  }

  Future<CartItem> _mapSingleCartItem(dynamic response) async {
    if (response is! Map<String, dynamic>) {
      throw ApiException('پاسخ سبد خرید از سرور نامعتبر است.');
    }

    final item = await _mapCartItem(response);

    if (item == null) {
      throw ApiException('محصول سبد خرید پیدا نشد.');
    }

    return item;
  }

  int _parseId(String value) {
    final parsed = int.tryParse(value);

    if (parsed == null) {
      throw ApiException('شناسه محصول نامعتبر است.');
    }

    return parsed;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
