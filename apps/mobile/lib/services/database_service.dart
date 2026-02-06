import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../db/schemas/product.dart';
import '../db/schemas/order.dart' as db;
import '../db/schemas/sync_queue.dart';
import '../db/schemas/stock.dart';
import '../db/schemas/route.dart'; // Ensure route is also there if not already

class DatabaseService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ProductSchema, db.OrderSchema, SyncQueueSchema, StockSchema, RouteSchema],
      directory: dir.path,
    );
  }

  Future<void> close() async {
    await isar.close();
  }
}
