import 'package:supabase/supabase.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: 'NOT_FOUND');
  final serviceRoleKey = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: 'NOT_FOUND');

  final supabase = SupabaseClient(supabaseUrl, serviceRoleKey);

  try {
    // 1. Insert a dummy notification
    final res = await supabase.from('notifications').insert({
      'title': 'Test Push',
      'body': 'This is a test',
      'type': 'general',
      'target': 'all',
      'data': {}
    }).select().single();
    
    final notifId = res['id'];
    print('Created notification: $notifId');

    // 2. Call Edge Function manually
    final url = Uri.parse('$supabaseUrl/functions/v1/send-push-notification');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serviceRoleKey',
      },
      body: jsonEncode({'notification_id': notifId}),
    );
    
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
