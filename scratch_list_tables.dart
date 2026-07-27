import 'package:supabase/supabase.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: 'NOT_FOUND');
  final serviceRoleKey = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: 'NOT_FOUND');
  
  final url = Uri.parse('$supabaseUrl/rest/v1/');
  try {
    final response = await http.get(url, headers: {
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
    });
    print(response.body);
  } catch(e) {
    print(e);
  }
  exit(0);
}
