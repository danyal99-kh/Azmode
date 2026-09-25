import 'package:azmode/Core/api/api_client.dart';
import 'package:azmode/Core/api/api_endpoints.dart';

import '../models/cart_item.dart';

class CartService {
  CartService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<CartItem>> getCart() async {
    final response = await apiClient.get(ApiEndpoints.cart, requiresAuth: true);

    if (response is! List) {
      throw ApiException('پاسخ سبد خرید نامعتبر است.');
    }

    return response
        .map(
          (item) => CartItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<CartItem> addToCart({
    required int productId,
    required int quantity,
    String? selectedColor,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.cartAdd,
      requiresAuth: true,
      body: {
        'product': productId,
        'quantity': quantity,
        if (selectedColor != null) 'selected_color': selectedColor,
      },
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('پاسخ افزودن به سبد نامعتبر است.');
    }

    return CartItem.fromJson(response);
  }

  Future<CartItem> updateCartItem({
    required int cartItemId,
    required int quantity,
  }) async {
    final response = await apiClient.patch(
      '${ApiEndpoints.cartUpdate}$cartItemId/',
      requiresAuth: true,
      body: {'quantity': quantity},
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('پاسخ بروزرسانی سبد نامعتبر است.');
    }

    return CartItem.fromJson(response);
  }

  Future<void> removeFromCart(int cartItemId) async {
    await apiClient.delete(
      '${ApiEndpoints.cartRemove}$cartItemId/remove/',
      requiresAuth: true,
    );
  }
}
