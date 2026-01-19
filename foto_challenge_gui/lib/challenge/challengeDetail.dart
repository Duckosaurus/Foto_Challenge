import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../shared/photo_platform.dart';
import 'challengeStore.dart';
import 'challengeTemplateStore.dart';
import 'collageScreen.dart';

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

  Future<void> _addPhoto() async {
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
      challengeId: widget.challengeId,
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
    await _load();
  }

  Future<void> _removePhotoAt(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Foto entfernen?"),
        content: const Text(
          "Hiermit wird das Foto aus der Challenge gelöscht.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Entfernen"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ChallengeStore.removePhotoAt(
      tripId: widget.tripId,
      challengeId: widget.challengeId,
      index: index,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Foto entfernt.")),
    );
    await _load();
  }

  Future<void> _editTitle() async {
    final c = challenge;
    if (c == null) return;

    final controller = TextEditingController(text: c.title);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Challenge-Titel bearbeiten"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: "Titel"),
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

              try {
                await ChallengeStore.updateTitle(
                  tripId: widget.tripId,
                  challengeId: widget.challengeId,
                  newTitle: controller.text,
                );
                if (!mounted) return;
                Navigator.pop(ctx, true);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Fehler: $e")),
                );
              }
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );

    if (saved == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Titel aktualisiert.")),
      );
    }
  }

  Future<void> _saveAsTemplate() async {
    final c = challenge;
    if (c == null) return;

    final controller = TextEditingController(text: c.title);
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Als Vorlage speichern"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: "Vorlagen-Titel"),
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
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(ctx, true);
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final added = await ChallengeTemplateStore.add(controller.text);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added ? "Vorlage gespeichert." : "Vorlage existiert bereits.",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = challenge;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Challenge Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Titel bearbeiten",
            onPressed: _editTitle,
          ),
          IconButton(
            tooltip: "Als Vorlage speichern",
            icon: const Icon(Icons.bookmark_add),
            onPressed: _saveAsTemplate,
          ),
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
                      OutlinedButton.icon(
                        onPressed: (c.photoPaths.length < 2)
                            ? null
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CollageScreen(photoRefs: c.photoPaths),
                            ),
                          );
                        },
                        icon: const Icon(Icons.grid_on),
                        label: const Text("Kollage"),
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
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    photoFromRef(photoRef, fit: BoxFit.cover),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Material(
                                        color: Colors.black54,
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          customBorder:
                                          const CircleBorder(),
                                          onTap: () => _removePhotoAt(i),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.close,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
