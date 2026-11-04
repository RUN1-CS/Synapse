import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  String? token;
  String? refreshToken;
  Future<void> Function(String accessToken, String refreshToken)?
      onTokensRefreshed;
  Future<void> Function()? onSessionExpired;
  Future<bool>? _refreshOperation;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path) => Uri.parse('${Config.baseUrl}/api$path');

  Future<dynamic> get(String path) async =>
      _request(() => http.get(_uri(path), headers: _headers), path);

  Future<dynamic> post(
          String path, Map<String, dynamic> body) async =>
      _request(
          () =>
              http.post(_uri(path), headers: _headers, body: jsonEncode(body)),
          path);

  Future<dynamic> patch(
          String path, Map<String, dynamic> body) async =>
      _request(
          () =>
              http.patch(_uri(path), headers: _headers, body: jsonEncode(body)),
          path);

  Future<dynamic> delete(String path) async =>
      _request(() => http.delete(_uri(path), headers: _headers), path);

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
    return _request(() async {
      final request = http.MultipartRequest('PATCH', _uri(path))
        ..headers.addAll(_headers..remove('Content-Type'))
        ..files.add(http.MultipartFile.fromBytes(
          field,
          bytes,
          filename: filename,
          contentType:
              mimeTypes[extension] ?? MediaType('application', 'octet-stream'),
        ));
      return http.Response.fromStream(await request.send());
    }, path);
  }

  Future<dynamic> _request(
      Future<http.Response> Function() send, String path) async {
    final response = await send();
    if (response.statusCode == 401 &&
        refreshToken != null &&
        path != '/auth/refresh' &&
        await _tryRefresh()) {
      return _handle(await send());
    }
    return _handle(response);
  }

  Future<bool> _tryRefresh() async {
    if (_refreshOperation != null) return _refreshOperation!;
    _refreshOperation = _performRefresh();
    try {
      return await _refreshOperation!;
    } finally {
      _refreshOperation = null;
    }
  }

  Future<bool> _performRefresh() async {
    final response = await http.post(
      _uri('/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await onSessionExpired?.call();
      return false;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    token = data['accessToken']?.toString() ?? data['token']?.toString();
    refreshToken = data['refreshToken']?.toString();
    if (token == null || refreshToken == null) {
      await onSessionExpired?.call();
      return false;
    }
    await onTokensRefreshed?.call(token!, refreshToken!);
    return true;
  }

  dynamic _handle(http.Response response) {
    final data = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    throw ApiException(
      data is Map && data['error'] != null
          ? data['error']
          : 'Request failed (${response.statusCode})',
      statusCode: response.statusCode,
    );
  }
}
