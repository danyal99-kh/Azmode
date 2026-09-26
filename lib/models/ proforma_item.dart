/// یک ردیف از سفارش، دقیقاً همان اسنپ‌شاتی که بک‌اند لحظه‌ی ثبت سفارش
/// ذخیره کرده (نام و قیمت لحظه‌ی خرید، نه وضعیت فعلی محصول در فروشگاه).
class ProformaOrderItem {
  final int id;
  final int? productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? selectedColor;

  ProformaOrderItem({
    required this.id,
    this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.selectedColor,
  });

  double get totalPrice => unitPrice * quantity;

  factory ProformaOrderItem.fromJson(Map<String, dynamic> json) {
    return ProformaOrderItem(
      id: json['id'] as int? ?? 0,
      productId: json['product'] as int?,
      productName: json['product_name_snapshot']?.toString() ?? '',
      unitPrice:
          double.tryParse(json['unit_price_snapshot']?.toString() ?? '') ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      selectedColor: json['selected_color']?.toString(),
    );
  }
}
