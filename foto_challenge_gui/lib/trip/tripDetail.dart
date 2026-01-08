import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/apiConfig.dart';
import 'package:foto_challenge_gui/challenge/challengeAnlegen.dart';
import 'package:intl/intl.dart';
import 'package:foto_challenge_gui/challenge/challengeDetailScreen.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  Map<String, dynamic>? trip;
  bool loading = true;
  String? error;
  late Future<List<dynamic>> _challengesFuture;

  @override
  void initState() {
    super.initState();
    _loadTrip();
    _challengesFuture = fetchChallenges();
  }

  Future<void> _loadTrip() async {
    setState(() {
      loading = true;
      error = null;
    });

    final url = Uri.parse("${ApiConfig.baseUrl}/trips/${widget.tripId}");

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          trip = jsonDecode(res.body) as Map<String, dynamic>;
          loading = false;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          error = "Trip nicht gefunden (404).";
          loading = false;
        });
      } else {
        setState(() {
          error = "Fehler: ${res.statusCode}";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Netzwerkfehler: $e";
        loading = false;
      });
    }
  }

  // Challenges für den Trip laden
  Future<List<dynamic>> fetchChallenges() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/challenge/byTrip/${widget.tripId}",
    );
    final res = await http.get(url);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      throw Exception('Fehler beim Laden der Challenges');
    }
  }

  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd.MM.yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = trip?["name"]?.toString() ?? "—";
    final beschreibung = trip?["beschreibung"]?.toString() ?? "";
    final startdatum = trip?["startdatum"]?.toString() ?? "—";
    final enddatum = trip?["enddatum"]?.toString() ?? "—";

    final formattedStartdatum = formatDate(startdatum);
    final formattedEnddatum = formatDate(enddatum);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Details"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTrip),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : (error != null)
            ? Center(child: Text(error!))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (beschreibung.isNotEmpty) ...[
                      Text(beschreibung),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      children: [
                        Expanded(child: Text("Von: $formattedStartdatum")),
                        const SizedBox(width: 12),
                        Expanded(child: Text("Bis: $formattedEnddatum")),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Challenge-Liste
                    Text(
                      "Foto-Challenges",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    // Challenge-Liste aus FutureBuilder laden
                    FutureBuilder<List<dynamic>>(
                      future: _challengesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Fehler: ${snapshot.error}'),
                          );
                        }

                        final challenges = snapshot.data ?? [];

                        if (challenges.isEmpty) {
                          return const Center(
                            child: Text("Noch keine Challenges"),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: challenges.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final challenge = challenges[index];
                            final challengeName =
                                challenge['titel'] ?? 'Unbenannt';
                            final status = challenge['status'] ?? 'Unbekannt';

                            return ListTile(
                              title: Text(challengeName),
                              subtitle: Text('Status: $status'),
                              onTap: () {
                                // Navigiere zur Challenge Detailseite und übergebe die challengeId
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChallengeDetailScreen(
                                      challengeId: challenge['id']
                                          .toString(), // Übergebe die challengeId
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),

      // Challenge hinzufügen
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => ChallengeAnlegen(tripId: widget.tripId),
            ),
          );
          if (saved == true) {
            // Lade die Challenges nach dem Hinzufügen einer neuen Challenge neu
            setState(() {
              _challengesFuture = fetchChallenges();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
