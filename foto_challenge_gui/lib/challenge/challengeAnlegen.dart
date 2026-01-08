import 'package:flutter/material.dart';
import 'package:foto_challenge_gui/config/apiConfig.dart';
import '../auth/userIDstore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChallengeAnlegen extends StatefulWidget {
  final String tripId;
  const ChallengeAnlegen({super.key, required this.tripId});

  @override
  State<ChallengeAnlegen> createState() => _ChallengeAnlegenState();
}

class _ChallengeAnlegenState extends State<ChallengeAnlegen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChallenge() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Challenge Name eingeben')),
      );
      return;
    }

    final url = Uri.parse("${ApiConfig.baseUrl}/challenge");
    //final userId = await UserIdStore.getUserId();
    final body = {
      "name": name,
      "beschreibung": "",
      "status": "offen",
      "tripid": int.parse(widget.tripId),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        // optional: Response enthält die neue Challenge inkl. id
        // final created = jsonDecode(response.body);

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Challenge gespeichert")));

        Navigator.pop(context, true); // ✅ signalisiert „neu angelegt“
      } else {
        debugPrint("Fehler: ${response.statusCode}");
        debugPrint(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler: ${response.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("Netzwerkfehler: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Netzwerkfehler: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Challenge hinzufügen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Challenge-Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChallenge,
                child: const Text('Speichern'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
