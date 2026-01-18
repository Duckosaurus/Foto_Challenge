// lib/challenge/challengeStore.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Challenge {
  final String id;
  final String tripId;
  final String title;
  final String status; // "offen" | "erledigt"
  final List<String> photoPaths;

  const Challenge({
    required this.id,
    required this.tripId,
    required this.title,
    required this.status,
    required this.photoPaths,
  });

  bool get isDone => status == "erledigt";

  Challenge copyWith({
    String? title,
    String? status,
    List<String>? photoPaths,
  }) {
    return Challenge(
      id: id,
      tripId: tripId,
      title: title ?? this.title,
      status: status ?? this.status,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "tripId": tripId,
    "title": title,
    "status": status,
    "photoPaths": photoPaths,
  };

  static Challenge fromJson(Map<String, dynamic> json) => Challenge(
    id: json["id"].toString(),
    tripId: json["tripId"].toString(),
    title: (json["title"] ?? "").toString(),
    status: (json["status"] ?? "offen").toString(),
    photoPaths: (json["photoPaths"] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
  );
}

class ChallengeStore {
  static String _key(String tripId) => "challenges_$tripId";

  static Future<List<Challenge>> listForTrip(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(tripId));
    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Challenge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _saveForTrip(String tripId, List<Challenge> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((c) => c.toJson()).toList());
    await prefs.setString(_key(tripId), raw);
  }

  static Future<String> addChallenge({
    required String tripId,
    required String title,
  }) async {
    final clean = title.trim();
    if (clean.isEmpty) {
      throw Exception("Challenge-Titel darf nicht leer sein.");
    }

    final list = await listForTrip(tripId);
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final newChallenge = Challenge(
      id: id,
      tripId: tripId,
      title: clean,
      status: "offen",
      photoPaths: const [],
    );

    list.add(newChallenge);
    await _saveForTrip(tripId, list);
    return id;
  }

  static Future<Challenge?> getById(String tripId, String challengeId) async {
    final list = await listForTrip(tripId);
    try {
      return list.firstWhere((c) => c.id == challengeId);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setStatus({
    required String tripId,
    required String challengeId,
    required bool done,
  }) async {
    final list = await listForTrip(tripId);
    final idx = list.indexWhere((c) => c.id == challengeId);
    if (idx < 0) return;

    list[idx] = list[idx].copyWith(status: done ? "erledigt" : "offen");
    await _saveForTrip(tripId, list);
  }

  static Future<void> addPhoto({
    required String tripId,
    required String challengeId,
    required String photoPath,
  }) async {
    final path = photoPath.trim();
    if (path.isEmpty) return;

    final list = await listForTrip(tripId);
    final idx = list.indexWhere((c) => c.id == challengeId);
    if (idx < 0) return;

    final updatedPhotos = [...list[idx].photoPaths, path];
    list[idx] = list[idx].copyWith(photoPaths: updatedPhotos);
    await _saveForTrip(tripId, list);
  }

  static Future<void> deleteChallenge({
    required String tripId,
    required String challengeId,
  }) async {
    final list = await listForTrip(tripId);
    final newList = list.where((c) => c.id != challengeId).toList();

    if (newList.length == list.length) return;

    await _saveForTrip(tripId, newList);
  }

  static Future<void> updateTitle({
    required String tripId,
    required String challengeId,
    required String newTitle,
  }) async {
    final clean = newTitle.trim();
    if (clean.isEmpty) {
      throw Exception("Challenge-Titel darf nicht leer sein.");
    }

    final list = await listForTrip(tripId);
    final idx = list.indexWhere((c) => c.id == challengeId);
    if (idx < 0) return;

    list[idx] = list[idx].copyWith(title: clean);
    await _saveForTrip(tripId, list);
  }
}
