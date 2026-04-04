import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://qcybnzopffyzmpiaxwbc.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg',
  );

  try {
    // Attempt to select from information_schema to see columns
    final response = await supabase.rpc('get_column_names', params: {'table_name': 'slots'});
    print("SLOTS COLUMNS (RPC): $response");
  } catch (e) {
    print("RPC FAILED, trying direct select on information_schema");
    try {
      // Direct select on information_schema.columns might not be allowed for anon key
      // but let's try a simple select without filters
      final response = await supabase.from('slots').select().limit(1);
      print("SLOTS DATA: $response");
    } catch (e2) {
      print("DIRECT SELECT FAILED: $e2");
    }
  }
}
