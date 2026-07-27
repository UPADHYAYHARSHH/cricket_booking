import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: 'NOT_FOUND');
  final serviceRoleKey = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: 'NOT_FOUND');
  final supabase = SupabaseClient(supabaseUrl, serviceRoleKey);
  try {
    final res = await supabase.from('notifications').insert({
      'title': 'Test Trigger Push',
      'message': 'Testing pg_net trigger',
      'type': 'general',
      'user_id': null
    }).select().single();
    
    print('Inserted notification successfully: ${res['id']}');
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
