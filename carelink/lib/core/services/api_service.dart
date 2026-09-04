import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Perform GET request
  static Future<dynamic> get(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(uri, headers: _headers).timeout(
            const Duration(seconds: 5),
          );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      debugPrint('[ApiService GET Error] Status ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('[ApiService GET Exception] $endpoint: $e');
      return null;
    }
  }

  /// Perform POST request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      debugPrint('[ApiService POST Error] Status ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('[ApiService POST Exception] $endpoint: $e');
      return null;
    }
  }

  /// Perform PUT request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .put(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      debugPrint('[ApiService PUT Error] Status ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('[ApiService PUT Exception] $endpoint: $e');
      return null;
    }
  }
}
