import 'package:supabase/supabase.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: 'NOT_FOUND');
  final serviceRoleKey = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: 'NOT_FOUND');

  if (supabaseUrl == 'NOT_FOUND' || serviceRoleKey == 'NOT_FOUND') {
    print("Environment variables not set properly.");
    exit(1);
  }

  final url = Uri.parse('$supabaseUrl/functions/v1/send-push-notification');
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serviceRoleKey',
      },
      body: jsonEncode({'notification_id': '00000000-0000-0000-0000-000000000000'}),
    );
    
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
