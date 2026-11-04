import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  Future<dynamic> patch(String path, Map<String, dynamic> body) async =>
      _handle(await http.patch(_uri(path),
          headers: _headers, body: jsonEncode(body)));

  Future<dynamic> upload(
      String path, String field, List<int> bytes, String filename) async {
    final extension = filename.split('.').last.toLowerCase();
    final mimeTypes = {
      'jpg': MediaType('image', 'jpeg'),
      'jpeg': MediaType('image', 'jpeg'),
      'png': MediaType('image', 'png'),
      'gif': MediaType('image', 'gif'),
      'webp': MediaType('image', 'webp'),
    };
    final request = http.MultipartRequest('PATCH', _uri(path))
      ..headers.addAll(_headers..remove('Content-Type'))
      ..files.add(http.MultipartFile.fromBytes(field, bytes,
          filename: filename,
          contentType: mimeTypes[extension] ??
              MediaType('application', 'octet-stream')));
    return _handle(await http.Response.fromStream(await request.send()));
  }

  dynamic _handle(http.Response r) {
    final data = r.body.isEmpty ? null : jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) return data;
    throw ApiException(data is Map && data['error'] != null
        ? data['error']
        : 'Request failed (${r.statusCode})');
  }
}
