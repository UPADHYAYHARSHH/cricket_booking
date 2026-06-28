import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/data/models/location_model.dart';
abstract class GroundRepository {
  Future<List<GroundModel>> fetchGrounds();
  Future<GroundModel?> fetchGroundById(String id);
  Future<List<LocationModel>> fetchLocations();
}
