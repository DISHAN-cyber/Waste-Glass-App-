import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/supplier.dart';

class ApiService {
  // TODO: Replace with your hosted backend URL before building APK
  static const String baseUrl = 'https://YOUR_BACKEND_URL';

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
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/collection/${record.supplierId}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(record.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit collection: ${response.statusCode}');
    }
  }

  static Future<void> syncAll(List<CollectionRecord> records) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/collection/sync'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(records.map((r) => r.toJson()).toList()),
        )
        .timeout(const Duration(seconds: 30));

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
