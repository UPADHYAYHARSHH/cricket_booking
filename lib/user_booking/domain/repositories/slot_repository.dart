import '../models/slot_models.dart';

abstract class SlotRepository {
  Future<List<TimeSlot>> fetchSlotsForGround(String groundId, DateTime date);
  Stream<List<TimeSlot>> getSlotsStream(String groundId, DateTime date);
}
