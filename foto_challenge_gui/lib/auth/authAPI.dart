import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  // Android Emulator: 10.0.2.2
  static const String baseUrl = "http://localhost:3000/auth";

  static Future<int> login({
    required String username,
    required String passwort,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username.trim(), "passwort": passwort}),
    );

    if (res.statusCode != 200) {
      throw Exception("Login fehlgeschlagen (${res.statusCode})");
    }

    final data = jsonDecode(res.body);
    final userId = data["userid"];
    if (userId == null) throw Exception("Backend hat keine userid geliefert.");

    return int.parse(userId.toString());
  }

  static Future<int> register({
    required String username,
    required String passwort,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username.trim(), "passwort": passwort}),
    );

    if (res.statusCode != 201) {
      throw Exception("Registrierung fehlgeschlagen (${res.statusCode})");
    }

    final data = jsonDecode(res.body);
    final userId = data["userid"];
    if (userId == null) throw Exception("Backend hat keine userid geliefert.");

    return int.parse(userId.toString());
  }
}
