import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChallengeTemplateStore {
  static const _key = "challenge_templates_custom_v1";

  static String _norm(String s) => s.trim().toLowerCase();

  static Future<List<String>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <String>[];

    final items = decoded.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return items;
  }

  static Future<bool> add(String title) async {
    final t = title.trim();
    if (t.isEmpty) throw Exception("Vorlagen-Titel darf nicht leer sein.");

    final prefs = await SharedPreferences.getInstance();
    final items = await list();

    final exists = items.any((x) => _norm(x) == _norm(t));
    if (exists) return false;

    items.add(t);
    items.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    await prefs.setString(_key, jsonEncode(items));
    return true;
  }

  static Future<void> remove(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await list();
    items.removeWhere((x) => _norm(x) == _norm(title));

    await prefs.setString(_key, jsonEncode(items));
  }
}
