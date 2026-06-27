import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/supplier.dart';

class ApiService {
  static const String baseUrl =
      'https://fabulous-vitality-production-26cf.up.railway.app';

  static Future<List<Supplier>> getRoute() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/route'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((j) => Supplier.fromJson(j)).toList();
    } else {
      throw Exception('Failed to load route: ${response.statusCode}');
    }
  }

  static Future<void> submitCollection(CollectionRecord record) async {
    final url = Uri.parse('$baseUrl/api/collection/${record.supplierId}');
    final body = json.encode(record.toJson());
    
    print('🌐 Sending POST to: $url');
    print('📦 Request body: $body');
    
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to submit: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  static Future<void> syncAll(List<CollectionRecord> records) async {
    final url = Uri.parse('$baseUrl/api/collection/sync');
    final body = json.encode(records.map((r) => r.toJson()).toList());
    
    print('🌐 Sending sync POST to: $url');
    print('📦 Sync body: $body');
    
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    print('📥 Sync response: ${response.statusCode}');
    print('📥 Sync body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Sync failed: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getTripSummary() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/trip/summary'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load summary: ${response.statusCode}');
    }
  }
}