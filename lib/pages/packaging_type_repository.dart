import '../model.dart';

abstract class PackagingTypeRepository {
  Future<List<PackagingType>> fetchPackagingTypes();

  /// ساخت نوع بسته‌بندی جدید در Backend.
  Future<PackagingType> createPackagingType(String name);

  /// ویرایش نوع بسته‌بندی در Backend.
  Future<PackagingType> updatePackagingType(String id, String newName);

  /// حذف نوع بسته‌بندی در Backend.
  Future<void> deletePackagingType(String id);
}
