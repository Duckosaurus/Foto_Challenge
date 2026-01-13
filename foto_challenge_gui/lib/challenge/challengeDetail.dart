import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../shared/photo_platform.dart';
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
      if (!mounted) return;
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
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (xFile == null) return;

    // WICHTIG: Web -> data-url (base64), Mobile -> file path
    final ref = await refFromPickedXFile(xFile);

    await ChallengeStore.addPhoto(
      tripId: widget.tripId,
      challengeId: widget.challengeId,
      photoPath: ref,
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

                  Row(
                    children: [
                      Chip(label: Text(c.isDone ? "erledigt" : "offen")),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Als erledigt markieren"),
                          value: c.isDone,
                          onChanged: _toggleDone,
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
                        onPressed: _addPhoto,
                        icon: const Icon(Icons.photo),
                        label: const Text("Foto hinzufügen"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                              final photoRef = c.photoPaths[i];

                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: photoFromRef(
                                  photoRef,
                                  fit: BoxFit.cover,
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
