import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/slot_models.dart';
import '../../domain/repositories/slot_repository.dart';

class SlotRepositoryImpl implements SlotRepository {
  final SupabaseClient supabase;

  SlotRepositoryImpl(this.supabase);

  @override
  Future<List<TimeSlot>> fetchSlotsForGround(
      String groundId, DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await supabase
        .from('slots')
        .select('*')
        .eq('ground_id', groundId)
        .eq('date', formattedDate);

    return (response as List).map((json) {
      return TimeSlot(
        startTime: _formatTime(json['start_time']),
        endTime: _formatTime(json['end_time']),
        price: (json['price'] ?? 0).toDouble(),
        status: _parseStatus(json['status']),
      );
    }).toList();
  }

  String _formatTime(String timeString) {
    try {
      if (timeString.contains('T')) {
        final date = DateTime.parse(timeString);
        final hour =
            date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
        final amPm = date.hour >= 12 ? 'PM' : 'AM';
        final minute = date.minute.toString().padLeft(2, '0');
        return '$hour:$minute $amPm';
      } else {
        // Handle HH:mm:ss
        final parts = timeString.split(':');
        int hour = int.parse(parts[0]);
        final minute = parts[1];
        final amPm = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        return '${hour.toString().padLeft(2, '0')}:$minute $amPm';
      }
    } catch (e) {
      return timeString;
    }
  }

  SlotStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return SlotStatus.available;
      case 'booked':
        return SlotStatus.booked;
      case 'selected':
        return SlotStatus.selected;
      case 'blocked':
        return SlotStatus.blocked;
      default:
        return SlotStatus.available;
    }
  }
}
