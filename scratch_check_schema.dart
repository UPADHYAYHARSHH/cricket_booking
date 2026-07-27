import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: 'NOT_FOUND');
  final serviceRoleKey = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: 'NOT_FOUND');
  final supabase = SupabaseClient(supabaseUrl, serviceRoleKey);
  try {
    final res = await supabase.from('notifications').select().limit(1);
    if (res.isNotEmpty) {
      print('Keys: ${res[0].keys.join(', ')}');
    } else {
      print('No notifications found');
    }
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
