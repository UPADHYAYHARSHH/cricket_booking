import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: 'NOT_FOUND');
  final serviceRoleKey = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: 'NOT_FOUND');
  final supabase = SupabaseClient(supabaseUrl, serviceRoleKey);
  
  try {
    // There is no easy way to query pg_proc via rest without RPC or raw SQL endpoint,
    // so let's just attempt to query auth.users and public.owners to check for that ID
    final idToCheck = 'r8WB3oHGjuVVMQR9ScmffKv7KZi2';
    
    var users = await supabase.from('users').select().eq('id', idToCheck);
    var owners = await supabase.from('owners').select().eq('id', idToCheck);
    
    print('Users check: $users');
    print('Owners check: $owners');
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
