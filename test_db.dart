import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabase = SupabaseClient(
      const String.fromEnvironment('SUPABASE_URL', defaultValue: 'NOT_FOUND'),
      const String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue: 'NOT_FOUND'));

  try {
    final response = await supabase.from('grounds').select('id, name, city');
    print("Grounds:");
    for (var g in response) {
      print(" - ${g['name']} in ${g['city']}");
    }
  } catch (e) {
    print("Error Grounds: $e");
  }
  exit(0);
}
