import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://qcybnzopffyzmpiaxwbc.supabase.co';
  final supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    // We can't query users table easily due to RLS, but we can try just selecting latitude, longitude
    // to see if we get a "column doesn't exist" error or an empty array (which means they exist).
    await client.from('users').select('latitude, longitude').limit(1);
    print('Columns latitude and longitude exist!');
  } catch (e) {
    print('Error: $e');
  }

  client.dispose();
  exit(0);
}
