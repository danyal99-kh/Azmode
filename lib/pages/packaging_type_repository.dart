import '../model.dart';

abstract class PackagingTypeRepository {
  Future<List<PackagingType>> fetchPackagingTypes();
}
