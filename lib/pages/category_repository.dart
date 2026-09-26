import '../model.dart';

abstract class CategoryRepository {
  Future<List<ProductCategory>> fetchCategories();

  /// ساخت دسته‌بندی جدید در Backend.
  Future<ProductCategory> createCategory(String name);

  /// ویرایش دسته‌بندی در Backend.
  Future<ProductCategory> updateCategory(String id, String newName);

  /// حذف دسته‌بندی در Backend.
  Future<void> deleteCategory(String id);
}
