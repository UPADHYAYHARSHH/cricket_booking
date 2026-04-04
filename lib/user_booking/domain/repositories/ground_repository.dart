import 'package:bloc_structure/user_booking/data/models/ground_model.dart';

abstract class GroundRepository {
  Future<List<GroundModel>> fetchGrounds();
}
