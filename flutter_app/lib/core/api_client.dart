import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Thin HTTP wrapper. Holds the auth token so repositories stay tiny.
class ApiClient {
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path) => Uri.parse('${Config.baseUrl}/api$path');

  Future<dynamic> get(String path) async =>
      _handle(await http.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, Map<String, dynamic> body) async => _handle(
      await http.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  dynamic _handle(http.Response r) {
    final data = r.body.isEmpty ? null : jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) return data;
    throw ApiException(data is Map && data['error'] != null
        ? data['error']
        : 'Request failed (${r.statusCode})');
  }
}
