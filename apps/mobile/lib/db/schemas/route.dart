import 'package:isar/isar.dart';

part 'route.g.dart';

@collection
class Route {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? remoteId;

  late DateTime date;
  late String status; // 'planned', 'active', 'finished'
  
  // Embedded list of stops
  List<RouteStop> stops = [];
}

@embedded
class RouteStop {
  String? orderRemoteId; // Link to order by remote ID
  late int sequence;
  
  late String address;
  double? lat;
  double? lng;
  
  String status = 'pending'; // 'pending', 'arrived', 'completed', 'skipped'
  DateTime? completedAt;
}
