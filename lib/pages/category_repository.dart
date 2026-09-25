import '../model.dart';

abstract class CategoryRepository {
  Future<List<ProductCategory>> fetchCategories();
}
