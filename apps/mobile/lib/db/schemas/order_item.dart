import 'package:isar/isar.dart';

part 'order_item.g.dart';

@embedded
class OrderItem {
  late String productId;
  late String productName;
  
  double quantity = 0;
  double price = 0;
  
  // For partial delivery/returns
  double? deliveredQuantity;
  double? rejectedQuantity;
}
