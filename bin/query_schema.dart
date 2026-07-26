import 'package:supabase/supabase.dart';
void main() async {
  final supabase = SupabaseClient('https://qcybnzopffyzmpiaxwbc.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg');
  final slots = await supabase.from('slots').select().limit(1);
  final bookings = await supabase.from('bookings').select().limit(1);
  print('Slots: $slots');
  print('Bookings: $bookings');
}
