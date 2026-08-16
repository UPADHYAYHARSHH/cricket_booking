import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://qcybnzopffyzmpiaxwbc.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  print('Testing SELECT...');
  try {
    final response = await client.from('fcm_tokens').select('id').eq('token', 'fake_test_token').limit(1);
    print('SELECT response: $response');

    if (response.isNotEmpty) {
      print('Updating...');
      await client.from('fcm_tokens').update({
        'user_id': 'fake_user_id',
        'platform': 'android',
        'last_used_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('token', 'fake_test_token');
      print('Updated successfully');
    } else {
      print('Inserting...');
      await client.from('fcm_tokens').insert({
        'user_id': 'fake_user_id',
        'token': 'fake_test_token',
        'platform': 'android',
        'last_used_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('Inserted successfully');
    }
  } catch (e) {
    print('Error caught: $e');
  }
}
