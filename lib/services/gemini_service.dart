import 'dart:convert';
import 'package:http/http.dart' as http;
import './../config.dart';

class GeminiService {
  // API Key desde config.dart
  final String _apiKey = GEMINI_API_KEY;

  // URL usando API Key
  String get _url =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';

  Future<String> obtenerRespuesta(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "Sin respuesta.";
      } else {
        print("Error Gemini API: ${response.statusCode} - ${response.body}");
        return "Error de IA: ${response.statusCode}";
      }
    } catch (e) {
      print("Excepción al llamar a Gemini: $e");
      return "Error de conexión con IA.";
    }
  }
}
