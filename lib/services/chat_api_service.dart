import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ChatApiService {
  Future<String> sendMessage({
    required String message,
    required String conversationId,
  }) async {
    final uri = Uri.parse('$baseUrl/chat');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        'conversationId': conversationId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        if (data['reply'] != null) {
          return data['reply'].toString();
        }

        if (data['answer'] != null) {
          return data['answer'].toString();
        }

        if (data['message'] != null) {
          return data['message'].toString();
        }
      }

      return 'He recibido una respuesta, pero no tiene el formato esperado.';
    }

    throw Exception(
      'Error al conectar con el chatbot. Código: ${response.statusCode}',
    );
  }
}