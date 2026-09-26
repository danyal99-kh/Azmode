import 'package:azmode/models/%20proforma_item.dart';

enum ProformaStatus { pending, approved, rejected }

ProformaStatus proformaStatusFromKey(String? key) {
  switch (key) {
    case 'approved':
      return ProformaStatus.approved;
    case 'rejected':
      return ProformaStatus.rejected;
    case 'pending':
    default:
      return ProformaStatus.pending;
  }
}

String proformaStatusToKey(ProformaStatus status) {
  switch (status) {
    case ProformaStatus.pending:
      return 'pending';
    case ProformaStatus.approved:
      return 'approved';
    case ProformaStatus.rejected:
      return 'rejected';
  }
}

/// سفارش/پیش‌فاکتور — نگاشت مستقیم پاسخ `OrderSerializer` بک‌اند.
class ProformaOrder {
  final int id;
  final int? userId;
  final String customerName;
  final String customerPhone;
  ProformaStatus status;
  final DateTime createdAt;
  final List<ProformaOrderItem> items;

  ProformaOrder({
    required this.id,
    this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);

  factory ProformaOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return ProformaOrder(
      id: json['id'] as int? ?? 0,
      userId: json['user'] as int?,
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      status: proformaStatusFromKey(json['status']?.toString()),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (e) =>
                      ProformaOrderItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}
