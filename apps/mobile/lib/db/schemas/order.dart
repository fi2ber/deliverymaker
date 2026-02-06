import 'package:isar/isar.dart';
import 'order_item.dart';

part 'order.g.dart';

@collection
class Order {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? remoteId;

  late String clientName;
  late String address;
  
  double totalAmount = 0.0;
  double paidAmount = 0.0;
  
  late DateTime createdAt;
  late DateTime? deliveryDate;

  String status = 'confirmed'; // 'confirmed', 'delivered', 'cancelled', 'partial'
  
  String paymentInfo = 'CASH'; // 'CASH', 'CREDIT'
  
  // List of items
  List<OrderItem> items = [];

  bool isSynced = false;
}
