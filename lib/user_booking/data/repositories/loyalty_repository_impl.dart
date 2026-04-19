import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../models/loyalty_point_model.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<int> fetchTotalAvailablePoints() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('loyalty_points')
          .select('points')
          .eq('user_id', userId)
          .eq('is_used', false)
          .gt('expiry_date', now);

      int total = 0;
      for (var row in response) {
        total += (row['points'] as num).toInt();
      }
      return total;
    } catch (e) {
      debugPrint("Error fetching loyalty points: $e");
      return 0;
    }
  }

  @override
  Future<void> redeemPoints(int pointsToUse) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final now = DateTime.now().toIso8601String();
      // Fetch active points sorted by expiry (FIFO)
      final response = await _supabase
          .from('loyalty_points')
          .select()
          .eq('user_id', userId)
          .eq('is_used', false)
          .gt('expiry_date', now)
          .order('expiry_date', ascending: true);

      final activePoints = (response as List).map((e) => LoyaltyPointModel.fromJson(e)).toList();

      int remainingToRedeem = pointsToUse;
      for (var pointRecord in activePoints) {
        if (remainingToRedeem <= 0) break;

        if (pointRecord.points <= remainingToRedeem) {
          // Use this whole record
          await _supabase
              .from('loyalty_points')
              .update({'is_used': true})
              .eq('id', pointRecord.id);
          remainingToRedeem -= pointRecord.points;
        } else {
          // Partial use of this record (Update points left and mark as part-used or just reduce points)
          // Simplified logic: Reduce the points in this record and the rest remains
          await _supabase
              .from('loyalty_points')
              .update({'points': pointRecord.points - remainingToRedeem})
              .eq('id', pointRecord.id);
          remainingToRedeem = 0;
        }
      }
    } catch (e) {
      debugPrint("Error redeeming points: $e");
      throw Exception("Failed to redeem points: $e");
    }
  }

  @override
  Future<void> earnPoints(int pointsEarned) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final expiryDate = DateTime.now().add(const Duration(days: 180)); // 6 Months
      await _supabase.from('loyalty_points').insert({
        'user_id': userId,
        'points': pointsEarned,
        'expiry_date': expiryDate.toIso8601String(),
        'is_used': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Error earning points: $e");
    }
  }

  @override
  Future<List<LoyaltyPointModel>> fetchPointsHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('loyalty_points')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => LoyaltyPointModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error fetching points history: $e");
      return [];
    }
  }
}
