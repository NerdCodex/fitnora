import 'dart:convert';
import 'package:fitnora/services/constants.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class ApiResponse {
  final int statusCode;
  final Map<String, dynamic>? data;

  ApiResponse({required this.statusCode, this.data});

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ApiService {
  static String? _getToken() {
    final box = Hive.box("auth");
    return box.get("access_token");
  }

  static Map<String, String> _headers({bool withAuth = false}) {
    final headers = {"Content-Type": "application/json"};

    if (withAuth) {
      final token = _getToken();
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    return headers;
  }

  static Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool withAuth = false,
  }) async {
    final url = Uri.parse("$base_url$endpoint");

    try {
      final response = await http.post(
        url,
        headers: _headers(withAuth: withAuth),
        body: jsonEncode(data),
      );

      Map<String, dynamic>? jsonData;

      if (response.body.isNotEmpty) {
        try {
          jsonData = jsonDecode(response.body);
        } catch (_) {
          jsonData = {"raw": response.body};
        }
      }

      return ApiResponse(statusCode: response.statusCode, data: jsonData);
    } catch (e) {
      return ApiResponse(statusCode: 0, data: {"error": e.toString()});
    }
  }

  static Future<ApiResponse> get(
    String endpoint, {
    bool withAuth = false,
  }) async {
    final url = Uri.parse("$base_url$endpoint");

    try {
      final response = await http.get(
        url,
        headers: _headers(withAuth: withAuth),
      );

      Map<String, dynamic>? jsonData;

      if (response.body.isNotEmpty) {
        try {
          jsonData = jsonDecode(response.body);
        } catch (_) {
          jsonData = {"raw": response.body};
        }
      }

      return ApiResponse(statusCode: response.statusCode, data: jsonData);
    } catch (e) {
      return ApiResponse(statusCode: 0, data: {"error": e.toString()});
    }
  }
}
