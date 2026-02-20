import 'dart:convert';
import 'package:fitnora/services/constants.dart';
import 'package:http/http.dart' as http;

class ApiResponse {
  final int statusCode;
  final Map<String, dynamic>? data;

  ApiResponse({
    required this.statusCode,
    this.data,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ApiService {

  static Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse("$base_url$endpoint");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
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

      return ApiResponse(
        statusCode: response.statusCode,
        data: jsonData,
      );
    } catch (e) {
      // Network error / timeout
      return ApiResponse(
        statusCode: 0,
        data: {"error": e.toString()},
      );
    }
  }
}