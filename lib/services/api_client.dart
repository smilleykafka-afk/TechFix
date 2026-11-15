import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();
  String? token;
  void Function()? onUnauthorized;
  http.Client client = http.Client();
  Future<dynamic> request(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      final request = http.Request(
        method,
        Uri.parse('${ApiConfig.baseUrl}/$path'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (data != null) request.body = jsonEncode(data);
      final response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 20)),
      );
      dynamic body;
      try {
        body = response.body.isEmpty ? null : jsonDecode(response.body);
      } catch (_) {
        throw ApiException(
          'Resposta inválida do servidor.',
          response.statusCode,
        );
      }
      if (response.statusCode >= 400) {
        if (response.statusCode == 401 && token != null) onUnauthorized?.call();
        final errors = body is Map ? body['errors'] : null;
        throw ApiException(
          errors is Map
              ? errors.values.expand((e) => e as List).join('\n')
              : body is Map
              ? '${body['message'] ?? 'Falha na solicitação.'}'
              : 'Falha na solicitação.',
          response.statusCode,
        );
      }
      return body;
    } on TimeoutException {
      throw ApiException('Tempo esgotado. Tente novamente.');
    } on http.ClientException {
      throw ApiException(
        'Não foi possível conectar à API. Verifique sua conexão.',
      );
    }
  }
}
