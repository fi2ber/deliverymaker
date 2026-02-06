import 'package:isar/isar.dart';

part 'stock.g.dart';

@collection
class Stock {
  Id id = Isar.autoIncrement;

  @Index()
  late String productId;
  
  late String productName;

  double quantity = 0.0;
  
  // Price for van sale
  double price = 0.0;
  
  String? batchCode;
  
  DateTime? expirationDate;
}
