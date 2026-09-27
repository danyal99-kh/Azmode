import '../model.dart';

abstract class CategoryRepository {
  Future<List<ProductCategory>> fetchCategories();

  /// ساخت دسته‌بندی جدید در Backend.
  ///
  /// [imageBase64] تصویر دسته‌بندی به‌صورت base64 (اختیاری).
  /// اگر Backend از multipart استفاده کند، repository باید تصویر را
  /// به‌صورت multipart file ارسال کند.
  Future<ProductCategory> createCategory(String name, {String? imageBase64});

  /// ویرایش دسته‌بندی در Backend.
  ///
  /// [imageBase64] تصویر جدید (اختیاری). [clearImage] برای حذف تصویر.
  Future<ProductCategory> updateCategory(
    String id,
    String newName, {
    String? imageBase64,
    bool clearImage = false,
  });

  /// حذف دسته‌بندی در Backend.
  Future<void> deleteCategory(String id);
}
