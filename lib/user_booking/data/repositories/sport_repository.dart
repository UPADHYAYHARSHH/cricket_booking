import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro/user_booking/data/models/sport_model.dart';

class SportRepository {
  final SupabaseClient _supabase;
  static const String _boxName = 'sports_cache';
  static const String _key = 'sports_list';

  SportRepository(this._supabase);

  Future<List<SportModel>> fetchSports() async {
    try {
      final response = await _supabase
          .from('sports')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final sports = (response as List)
          .map((e) => SportModel.fromJson(e as Map<String, dynamic>))
          .toList();

      await _cacheSports(sports);

      return sports;
    } catch (e) {
      debugPrint('[SportRepository] Error fetching sports: $e');
      return await _getCachedSports();
    }
  }

  Future<void> _cacheSports(List<SportModel> sports) async {
    try {
      final box = await Hive.openBox(_boxName);
      final jsonList = sports.map((s) => s.toJson()).toList();
      await box.put(_key, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[SportRepository] Error caching sports: $e');
    }
  }

  Future<List<SportModel>> _getCachedSports() async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get(_key);
      if (data == null) return [];
      final jsonList = jsonDecode(data as String) as List;
      return jsonList
          .map((e) => SportModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SportRepository] Error reading cached sports: $e');
      return [];
    }
  }
}
