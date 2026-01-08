import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html; // Nur für Web
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:http/http.dart' as http;
import '../config/apiConfig.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final String challengeId;
  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  late Future<List<Map<String, dynamic>>> _imagesFuture;

  @override
  void initState() {
    super.initState();
    _imagesFuture = fetchImages();
  }

  // Hole alle Bilder für diese Challenge
  Future<List<Map<String, dynamic>>> fetchImages() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/challenge/${widget.challengeId}/images",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['images']);
    } else if (response.statusCode != 404) {
      throw Exception('Fehler beim Laden der Bilder');
    } else {
      return [];
    }
  }

  // Bild aus der Galerie hinzufügen
  Future<void> _addImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Bild hochladen
      await _uploadImage(pickedFile.path);
      setState(() {
        _imagesFuture = fetchImages(); // Lade nach dem Hochladen die Bilder neu
      });
    }
  }

  //Wenn nur Emulator??
  /* Future<void> _uploadImage(String imagePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          "${ApiConfig.baseUrl}/challenge/${widget.challengeId}/images",
        ),
      );

      // Lade das Bild als multipart-form Daten
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      // Optional: Zusätzliche Daten wie Notizen
      request.fields['notiz'] = 'Ein Bild zur Challenge';

      // Sende die Anfrage
      var response = await request.send();

      if (response.statusCode == 200) {
        print("Bild erfolgreich hochgeladen");
      } else {
        print("Fehler beim Hochladen: ${response.statusCode}");
      }
    } catch (e) {
      print("Fehler beim Hochladen des Bildes: $e");
    }
  } */

  Future<void> _uploadImage(String imagePath) async {
    try {
      if (kIsWeb) {
        // Web-Upload - Sende die Datei als FormData
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          final html.FileUploadInputElement uploadInput =
              html.FileUploadInputElement();
          uploadInput.accept = 'image/*';
          uploadInput.click();

          uploadInput.onChange.listen((e) async {
            final files = uploadInput.files;
            if (files?.isEmpty ?? true) return;

            final reader = html.FileReader();
            reader.readAsDataUrl(files!.first);

            reader.onLoadEnd.listen((e) async {
              final formData = html.FormData();
              formData.appendBlob(
                'image',
                files.first,
              ); // Stelle sicher, dass der Name 'image' hier übereinstimmt
              formData.append('notiz', 'Ein Bild zur Challenge');

              // Web-spezifischer Upload: Sende FormData an den Server
              final response = await http.post(
                Uri.parse(
                  "${ApiConfig.baseUrl}/challenge/${widget.challengeId}/images",
                ),
                body: formData,
              );

              if (response.statusCode == 200) {
                print("Bild erfolgreich hochgeladen");
              } else {
                print("Fehler beim Hochladen: ${response.statusCode}");
              }
            });
          });
        }
      } else {
        // Mobiler Upload (für Emulator und echte Geräte)
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(
            "${ApiConfig.baseUrl}/challenge/${widget.challengeId}/images",
          ),
        );

        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        ); // Hier auch sicherstellen, dass der Name korrekt ist
        request.fields['notiz'] = 'Ein Bild zur Challenge';

        var response = await request.send();

        if (response.statusCode == 200) {
          print("Bild erfolgreich hochgeladen");
        } else {
          print("Fehler beim Hochladen: ${response.statusCode}");
        }
      }
    } catch (e) {
      print("Fehler beim Hochladen des Bildes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Challenge Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // "+" Symbol zum Hinzufügen eines Bildes
            GestureDetector(
              onTap: _addImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                  color: Colors.blue[50],
                ),
                child: const Icon(Icons.add, size: 50, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16),

            // GridView für die angezeigten Bilder
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _imagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Fehler: ${snapshot.error}'));
                }

                final images = snapshot.data ?? [];

                if (images.isEmpty) {
                  return const Center(
                    child: Text("Noch keine Bilder hinzugefügt"),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final image = images[index];
                    final imageData = image['data'] ?? '';
                    final imageBytes = base64Decode(
                      imageData,
                    ); // Decode the base64

                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Image.memory(imageBytes, fit: BoxFit.cover),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
