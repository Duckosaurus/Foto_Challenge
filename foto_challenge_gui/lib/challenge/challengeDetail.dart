// lib/challenge/challengeDetail.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'challengeStore.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final String tripId;
  final String challengeId;

  const ChallengeDetailScreen({
    super.key,
    required this.tripId,
    required this.challengeId,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  Challenge? challenge;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final c = await ChallengeStore.getById(widget.tripId, widget.challengeId);
      if (!mounted) return;

      setState(() {
        challenge = c;
        loading = false;
        if (c == null) error = "Challenge nicht gefunden.";
      });
    } catch (e) {
      setState(() {
        error = "Fehler: $e";
        loading = false;
      });
    }
  }

  Future<void> _toggleDone(bool value) async {
    await ChallengeStore.setStatus(
      tripId: widget.tripId,
      challengeId: widget.challengeId,
      done: value,
    );
    await _load();
  }

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return;

    // Web: keine File-Pfade wie auf Android -> für Android Must passt das.
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Foto-Upload am Web ist hier nicht implementiert."),
        ),
      );
      return;
    }

    await ChallengeStore.addPhoto(
      tripId: widget.tripId,
      challengeId: widget.challengeId,
      photoPath: xFile.path,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Foto hinzugefügt.")));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = challenge;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Challenge Details"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : (error != null)
            ? Center(child: Text(error!))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c!.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),

                  // M9: Titel + Status anzeigen :contentReference[oaicite:6]{index=6}
                  Row(
                    children: [
                      Chip(label: Text(c.isDone ? "erledigt" : "offen")),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Als erledigt markieren"),
                          value: c.isDone,
                          onChanged:
                              _toggleDone, // M10 :contentReference[oaicite:7]{index=7}
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Fotos",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            _addPhoto, // M7 :contentReference[oaicite:8]{index=8}
                        icon: const Icon(Icons.photo),
                        label: const Text("Foto hinzufügen"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // M8: Fotos anzeigen :contentReference[oaicite:9]{index=9}
                  Expanded(
                    child: c.photoPaths.isEmpty
                        ? const Center(
                            child: Text("Noch keine Fotos gespeichert."),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: c.photoPaths.length,
                            itemBuilder: (context, i) {
                              final path = c.photoPaths[i];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
