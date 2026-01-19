import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/apiConfig.dart';
import '../shared/photo_platform.dart';
import '../challenge/challengeStore.dart';
import '../challenge/challengeDetail.dart';
import '../challenge/challengeTemplates.dart';
import '../challenge/challengeTemplateStore.dart';

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
      if (!mounted) return;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.view_list),
                  label: const Text("Aus Vorlagen"),
                  onPressed: () async {
                    final selected = await showModalBottomSheet<String>(
                      context: ctx,
                      builder: (sheetCtx) => SafeArea(
                        child: FutureBuilder<List<String>>(
                          future: ChallengeTemplateStore.list(),
                          builder: (context, snap) {
                            final saved = snap.data ?? const <String>[];
                            final builtIn = ChallengeTemplates.items;

                            return ListView(
                              children: [
                                const ListTile(
                                  title: Text("Standard App Vorlagen"),
                                  dense: true,
                                ),
                                ...builtIn.map((t) => ListTile(
                                  title: Text(t),
                                  onTap: () => Navigator.pop(sheetCtx, t),
                                )),
                                if (saved.isNotEmpty) const Divider(height: 16),
                                if (saved.isNotEmpty)
                                  const ListTile(
                                    title: Text("Eigene Vorlagen"),
                                    dense: true,
                                  ),
                                ...saved.map((t) => ListTile(
                                  title: Text(t),
                                  trailing: IconButton(
                                    tooltip: "Vorlage entfernen",
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      await ChallengeTemplateStore.remove(t);
                                      // Sheet neu bauen:
                                      if (Navigator.canPop(sheetCtx)) {
                                        Navigator.pop(sheetCtx); // schließt Sheet
                                      }
                                      // optional: direkt wieder öffnen wäre möglich, aber nicht nötig
                                    },
                                  ),
                                  onTap: () => Navigator.pop(sheetCtx, t),
                                )),
                                if (snap.connectionState == ConnectionState.waiting)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    );

                    if (selected != null) {
                      controller.text = selected; // User kann noch ändern
                    }


                    if (selected != null) {
                      controller.text = selected; // User kann noch editieren
                    }
                  },
                ),
              ),
            ],
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
      await _loadChallenges();
    }
  }

  Future<void> _toggleDone(Challenge c) async {
    await ChallengeStore.setStatus(
      tripId: widget.tripId,
      challengeId: c.id,
      done: !c.isDone,
    );
    await _loadChallenges();
  }

  Future<ImageSource?> _chooseImageSource() async {
    if (kIsWeb) return ImageSource.gallery;

    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Galerie"),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text("Kamera"),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndAddPhoto(Challenge c) async {
    final source = await _chooseImageSource();
    if (source == null) return;

    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (xFile == null) return;

    final ref = await refFromPickedXFile(xFile);

    await ChallengeStore.addPhoto(
      tripId: widget.tripId,
      challengeId: c.id,
      photoPath: ref,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          source == ImageSource.camera
              ? "Foto aufgenommen und hinzugefügt."
              : "Foto hinzugefügt.",
        ),
      ),
    );

    await _loadChallenges();
  }

  Future<void> _deleteChallenge(Challenge c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Challenge löschen?"),
        content: Text("„${c.title}“ wird aus diesem Trip entfernt."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Löschen"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ChallengeStore.deleteChallenge(
      tripId: widget.tripId,
      challengeId: c.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Challenge gelöscht.")),
    );

    await _loadChallenges();
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

    final doneCount = challenges.where((c) => c.isDone).length;

    final formattedStartdatum = formatDate(startdatum);
    final formattedEnddatum = formatDate(enddatum);
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
                        Expanded(child: Text("Von: $formattedStartdatum")),
                        const SizedBox(width: 12),
                        Expanded(child: Text("Bis: $formattedEnddatum")),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

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

                          return ListTile(
                            leading: Icon(
                              c.isDone
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                            ),
                            title: Text(c.title),
                            subtitle: Text(
                              "Status: ${c.isDone ? "erledigt" : "offen"}"
                              " • Fotos: ${c.photoPaths.length}",
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
                                IconButton(
                                  tooltip: "Challenge löschen",
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteChallenge(c),
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

      floatingActionButton: FloatingActionButton(
        onPressed: _createChallengeDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
