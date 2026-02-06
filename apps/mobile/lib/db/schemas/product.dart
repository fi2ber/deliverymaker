import 'package:isar/isar.dart';

part 'product.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String remoteId; // ID from PostgreSQL

  late String name;
  late String sku;
  
  double? price;
  
  String? unit;
  
  late DateTime updatedAt;
}
