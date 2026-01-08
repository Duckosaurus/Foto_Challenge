import 'package:flutter/material.dart';
import 'package:foto_challenge_gui/config/apiConfig.dart';
import '../auth/userIDstore.dart';

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
        const SnackBar(content: Text('Bitte alle Felder ausfüllen')),
      );
      return;
    }

    final url = Uri.parse("${ApiConfig.baseUrl}/challenge");
    final userId = await UserIdStore.getUserId();
    final body = {
      "name": name,
      "beschreibung": "",
      "status": "offen",
      "tripid": ,
    };
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
