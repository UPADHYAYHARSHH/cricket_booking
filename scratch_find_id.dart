import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: 'NOT_FOUND');
  final serviceRoleKey = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: 'NOT_FOUND');
  final supabase = SupabaseClient(supabaseUrl, serviceRoleKey);
  
  final id = 'r8WB3oHGjuVVMQR9ScmffKv7KZi2';
  try {
    final userCheck = await supabase.from('users').select().eq('id', id);
    print('In users: $userCheck');
    
    final ownerCheck = await supabase.from('owner_details').select().eq('id', id);
    print('In owner_details: $ownerCheck');
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
