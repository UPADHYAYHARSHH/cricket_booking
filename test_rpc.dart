import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://qcybnzopffyzmpiaxwbc.supabase.co';
  final supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    // get a user and ground
    final userRes = await client.from('users').select('id').limit(1);
    final groundRes = await client.from('grounds').select('id').limit(1);
    
    if (userRes.isNotEmpty && groundRes.isNotEmpty) {
      final res = await client.rpc('save_booking', params: {
        'p_user_id': userRes[0]['id'],
        'p_ground_id': groundRes[0]['id'],
        'p_slot_time': DateTime.now().toUtc().toIso8601String(),
        'p_amount': 100,
        'p_status': 'confirmed',
      });
      print('RPC Output Type: ' + res.runtimeType.toString());
      print('RPC Output: ' + res.toString());
    }
  } catch (e) {
    print('Error: ' + e.toString());
  }

  exit(0);
}
