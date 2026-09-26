import 'package:flutter/foundation.dart';

import '../models/proforma.dart';
import '../services/proforma_service.dart';

typedef OrderStatusChangedCallback =
    void Function(ProformaOrder order, ProformaStatus previousStatus);

class ProformaProvider extends ChangeNotifier {
  ProformaProvider({required ProformaService service, this.onStatusChanged})
    : _service = service;

  final ProformaService _service;

  /// بعد از تایید/رد موفق یک سفارش صدا زده می‌شود — برای ساختن اعلان
  /// محلی در `StoreProvider`، بدون این‌که این پروایدر مستقیماً به آن
  /// وابسته باشد.
  final OrderStatusChangedCallback? onStatusChanged;

  // ── سفارش‌های من (مشتری) ────────────────────────────────────
  List<ProformaOrder> _myOrders = [];
  bool _myOrdersLoading = false;
  String? _myOrdersError;

  List<ProformaOrder> get myOrders => List.unmodifiable(_myOrders);
  bool get myOrdersLoading => _myOrdersLoading;
  String? get myOrdersError => _myOrdersError;

  // ── همه‌ی سفارش‌ها (ادمین) ───────────────────────────────────
  List<ProformaOrder> _allOrders = [];
  bool _allOrdersLoading = false;
  String? _allOrdersError;

  List<ProformaOrder> get allOrders => List.unmodifiable(_allOrders);
  bool get allOrdersLoading => _allOrdersLoading;
  String? get allOrdersError => _allOrdersError;

  bool _submitting = false;
  bool get submitting => _submitting;

  Future<void> loadMyOrders() async {
    _myOrdersLoading = true;
    _myOrdersError = null;
    notifyListeners();
    try {
      final orders = await _service.fetchMine();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _myOrders = orders;
    } catch (e) {
      _myOrdersError = e.toString();
    } finally {
      _myOrdersLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllOrders() async {
    _allOrdersLoading = true;
    _allOrdersError = null;
    notifyListeners();
    try {
      final orders = await _service.fetchAll();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _allOrders = orders;
    } catch (e) {
      _allOrdersError = e.toString();
    } finally {
      _allOrdersLoading = false;
      notifyListeners();
    }
  }

  /// ثبت سفارش از سبد خرید فعلی. در موفقیت، سفارش تازه به ابتدای
  /// «سفارش‌های من» اضافه می‌شود. خطا را به‌صورت متن برمی‌گرداند
  /// (null یعنی موفق) — همان الگوی قبلی `submitOrder` در StoreProvider.
  Future<String?> submitOrder() async {
    _submitting = true;
    notifyListeners();
    try {
      final order = await _service.submit();
      _myOrders = [order, ..._myOrders];
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// فقط ادمین. در موفقیت، هم در لیست ادمین وضعیت را به‌روزرسانی
  /// می‌کند و هم `onStatusChanged` را صدا می‌زند.
  Future<String?> updateOrderStatus(
    ProformaOrder order,
    ProformaStatus newStatus,
  ) async {
    final previousStatus = order.status;
    try {
      await _service.updateStatus(order.id, newStatus);
      order.status = newStatus;
      onStatusChanged?.call(order, previousStatus);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
