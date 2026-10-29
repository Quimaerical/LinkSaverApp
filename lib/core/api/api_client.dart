import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ValidationException extends ApiException {
  final Map<String, dynamic> errors;
  ValidationException(super.message, this.errors, [super.statusCode]);
}

class RateLimitException extends ApiException {
  RateLimitException(super.message, [super.statusCode]);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message, [super.statusCode]);
}

class ApiClient {
  String _baseUrl;
  final http.Client _httpClient;

  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = _cleanBaseUrl(baseUrl),
        _httpClient = httpClient ?? http.Client();

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String newUrl) {
    _baseUrl = _cleanBaseUrl(newUrl);
  }

  static String _cleanBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? headers, Duration timeout = const Duration(seconds: 10)}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    try {
      final response = await _httpClient.get(uri, headers: _mergeHeaders(headers)).timeout(timeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No se pudo conectar al servidor en $_baseUrl');
    } on TimeoutException {
      throw ApiException('Tiempo de espera agotado al conectar al servidor');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers, Duration timeout = const Duration(seconds: 15)}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    try {
      final response = await _httpClient
          .post(
            uri,
            headers: _mergeHeaders(headers, {'Content-Type': 'application/json'}),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No se pudo conectar al servidor en $_baseUrl');
    } on TimeoutException {
      throw ApiException('Tiempo de espera agotado al conectar al servidor');
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers, Duration timeout = const Duration(seconds: 15)}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    try {
      final response = await _httpClient
          .put(
            uri,
            headers: _mergeHeaders(headers, {'Content-Type': 'application/json'}),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No se pudo conectar al servidor en $_baseUrl');
    } on TimeoutException {
      throw ApiException('Tiempo de espera agotado al conectar al servidor');
    }
  }

  Future<dynamic> postMultipart({
    required String endpoint,
    required String fileParamName,
    required List<int> fileBytes,
    required String filename,
    Map<String, String>? fields,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    try {
      final request = http.MultipartRequest('POST', uri);
      if (headers != null) {
        request.headers.addAll(headers);
      }
      if (fields != null) {
        request.fields.addAll(fields);
      }
      request.files.add(http.MultipartFile.fromBytes(
        fileParamName,
        fileBytes,
        filename: filename,
      ));

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No se pudo conectar al servidor en $_baseUrl');
    } on TimeoutException {
      throw ApiException('Tiempo de espera agotado al subir el archivo');
    }
  }

  Future<List<int>> getRawBytes(String endpoint, {Map<String, String>? headers, Duration timeout = const Duration(seconds: 30)}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    debugPrint('[ApiClient] getRawBytes conectando a: $uri');
    try {
      final response = await _httpClient.get(uri, headers: _mergeHeaders(headers)).timeout(timeout);
      debugPrint('[ApiClient] getRawBytes respuesta: ${response.statusCode} (${response.bodyBytes.length} bytes)');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      debugPrint('[ApiClient] getRawBytes error payload: ${response.body}');
      throw ApiException('Error al descargar archivo (${response.statusCode}): ${response.body}', response.statusCode);
    } on SocketException catch (e) {
      debugPrint('[ApiClient] getRawBytes SocketException: $e');
      throw ApiException('No se pudo conectar al servidor en $_baseUrl');
    } on TimeoutException catch (e) {
      debugPrint('[ApiClient] getRawBytes TimeoutException: $e');
      throw ApiException('Tiempo de espera agotado al descargar archivo');
    }
  }

  Map<String, String> _mergeHeaders(Map<String, String>? custom, [Map<String, String>? defaults]) {
    final merged = <String, String>{
      'Accept': 'application/json',
      'X-Client-Type': 'Android',
    };
    if (defaults != null) {
      merged.addAll(defaults);
    }
    if (custom != null) {
      merged.addAll(custom);
    }
    return merged;
  }

  dynamic _processResponse(http.Response response) {
    final status = response.statusCode;
    final body = response.body;

    dynamic jsonBody;
    try {
      if (body.isNotEmpty) {
        jsonBody = jsonDecode(body);
      }
    } catch (_) {
      jsonBody = null;
    }

    if (status >= 200 && status < 300) {
      return jsonBody ?? body;
    }

    final message = (jsonBody is Map && jsonBody['error'] != null)
        ? jsonBody['error'].toString()
        : 'Error HTTP $status';

    if (status == 422 && jsonBody is Map && jsonBody['errors'] is Map) {
      throw ValidationException(message, Map<String, dynamic>.from(jsonBody['errors']), status);
    } else if (status == 429) {
      throw RateLimitException(message, status);
    } else if (status == 401 || status == 403) {
      throw UnauthorizedException(message, status);
    }

    throw ApiException(message, status);
  }
}
