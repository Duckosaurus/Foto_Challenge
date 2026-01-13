// lib/trip/tripDetail.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/apiConfig.dart';
import '../challenge/challengeStore.dart';
import '../challenge/challengeDetail.dart';

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

  List<Challenge> challenges = [];
  bool challengesLoading = true;
  String? challengesError;

  @override
  void initState() {
    super.initState();
    _loadTrip();
    _loadChallenges();
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

  Future<void> _loadChallenges() async {
    setState(() {
      challengesLoading = true;
      challengesError = null;
    });

    try {
      final list = await ChallengeStore.listForTrip(widget.tripId);
      if (!mounted) return;
      setState(() {
        challenges = list;
        challengesLoading = false;
      });
    } catch (e) {
      setState(() {
        challengesError = "Fehler: $e";
        challengesLoading = false;
      });
    }
  }

  Future<void> _createChallengeDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Neue Challenge"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Titel",
              hintText: "z. B. Fotografiere rote Objekte",
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Titel ist Pflicht.";
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              // M4: Challenge hinzufügen (Titel Pflicht) :contentReference[oaicite:10]{index=10}
              await ChallengeStore.addChallenge(
                tripId: widget.tripId,
                title: controller.text,
              );

              if (!mounted) return;
              Navigator.pop(ctx, true);
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );

    if (created == true) {
      // M5: danach in Liste sichtbar :contentReference[oaicite:11]{index=11}
      await _loadChallenges();
    }
  }

  Future<void> _toggleDone(Challenge c) async {
    await ChallengeStore.setStatus(
      tripId: widget.tripId,
      challengeId: c.id,
      done: !c.isDone,
    );
    await _loadChallenges(); // M10 :contentReference[oaicite:12]{index=12}
  }

  Future<void> _pickAndAddPhoto(Challenge c) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return;

    // M7: Foto aus Galerie wählen und Challenge zuordnen :contentReference[oaicite:13]{index=13}
    await ChallengeStore.addPhoto(
      tripId: widget.tripId,
      challengeId: c.id,
      photoPath: xFile.path,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Foto hinzugefügt.")));
  }

  @override
  Widget build(BuildContext context) {
    final name = trip?["name"]?.toString() ?? "—";
    final beschreibung = trip?["beschreibung"]?.toString() ?? "";
    final startdatum = trip?["startdatum"]?.toString() ?? "—";
    final enddatum = trip?["enddatum"]?.toString() ?? "—";

    final doneCount = challenges.where((c) => c.isDone).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadTrip();
              await _loadChallenges();
            },
          ),
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
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(child: Text("Von: $startdatum")),
                        const SizedBox(width: 12),
                        Expanded(child: Text("Bis: $enddatum")),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    // M6: Challenge-Liste pro Trip anzeigen :contentReference[oaicite:14]{index=14}
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Foto-Challenges",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text("Erledigt: $doneCount / ${challenges.length}"),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (challengesLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (challengesError != null)
                      Text(challengesError!)
                    else if (challenges.isEmpty)
                      const Text(
                        "Noch keine Challenges. Tippe auf + zum Anlegen.",
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: challenges.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final c = challenges[i];

                          // M9: Titel + Status in Liste :contentReference[oaicite:15]{index=15}
                          return ListTile(
                            leading: Icon(
                              c.isDone
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                            ),
                            title: Text(c.title),
                            subtitle: Text(
                              "Status: ${c.isDone ? "erledigt" : "offen"}",
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChallengeDetailScreen(
                                    tripId: widget.tripId,
                                    challengeId: c.id,
                                  ),
                                ),
                              );
                              await _loadChallenges();
                            },
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: "Foto hinzufügen",
                                  icon: const Icon(Icons.photo),
                                  onPressed: () => _pickAndAddPhoto(c),
                                ),
                                IconButton(
                                  tooltip: "Erledigt umschalten",
                                  icon: Icon(
                                    c.isDone ? Icons.undo : Icons.done,
                                  ),
                                  onPressed: () => _toggleDone(c),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),

      // M4/M5: Challenge hinzufügen :contentReference[oaicite:16]{index=16}
      floatingActionButton: FloatingActionButton(
        onPressed: _createChallengeDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
