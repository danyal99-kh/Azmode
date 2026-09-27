import '../model.dart';

abstract class NotificationRepository {
  /// دریافت لیست اعلان‌ها از Backend.
  Future<List<AppNotification>> fetchNotifications();

  /// علامت‌گذاری همه اعلان‌ها به‌عنوان خوانده‌شده.
  Future<void> markAllAsRead();

  /// علامت‌گذاری یک اعلان به‌عنوان خوانده‌شده.
  Future<void> markAsRead(String id);

  /// حذف یک اعلان.
  Future<void> deleteNotification(String id);
}
