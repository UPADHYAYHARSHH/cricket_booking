import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: 'NOT_FOUND');
  final serviceRoleKey = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: 'NOT_FOUND');
  final supabase = SupabaseClient(supabaseUrl, serviceRoleKey);
  
  try {
    final response = await supabase.rpc('get_foreign_keys');
    print(response);
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
