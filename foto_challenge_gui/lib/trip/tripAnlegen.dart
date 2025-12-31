import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tripDetail.dart';
import '../auth/userIDstore.dart';

class TripAnlegen extends StatefulWidget {
  const TripAnlegen({super.key});

  @override
  State<TripAnlegen> createState() => _TripAnlegenState();
}

class _TripAnlegenState extends State<TripAnlegen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd.MM.yyyy');

  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void dispose() {
    dateFromController.dispose();
    dateToController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    try {
      return _dateFormat.parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  Future<String?> sendTripToBackend() async {
    final url = Uri.parse("http://10.0.2.2:3000/trips");
    final userId = await UserIdStore.getUserId();
    final body = {
      "name": nameController.text.trim(),
      "beschreibung": descriptionController.text.trim(),
      "startdatum": dateFromController.text.trim(),
      "enddatum": dateToController.text.trim(),
      "userid": userId,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["id"].toString();
      } else {
        if (!mounted) null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler: ${response.statusCode}")),
        );
        // Debug:
        print("Hier wird geprintet");
        print(response.body);
      }
    } catch (e) {
      if (!mounted) null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Netzwerkfehler: $e")));
    }
    return null;
  }

  Future<void> pickDate(TextEditingController controller) async {
    final DateTime now = DateTime.now();

    DateTime firstDate = DateTime(1950);
    DateTime initialDate = now;

    final fromDate = _parseDate(dateFromController.text);

    if (controller == dateToController && fromDate != null) {
      firstDate = fromDate;
      initialDate = fromDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        controller.text = _dateFormat.format(picked);

        if (controller == dateFromController) {
          final toDate = _parseDate(dateToController.text);
          if (toDate != null && toDate.isBefore(picked)) {
            dateToController.clear();
          }
        }
      });
    }
  }

  Future<void> _onSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final tripId = await sendTripToBackend();
    if (tripId == null) return;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: tripId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trip anlegen")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Name des Trips"),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Tripname eingeben",
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Bitte einen Tripnamen eingeben.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text("Beschreibung"),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Beschreibung eingeben",
                ),
              ),
              const SizedBox(height: 24),

              const Text("Von"),
              TextFormField(
                controller: dateFromController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Startdatum auswählen",
                ),
                onTap: () => pickDate(dateFromController),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (_parseDate(value) == null) {
                      return "Ungültiges Datum (dd.MM.yyyy).";
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text("Bis"),
              TextFormField(
                controller: dateToController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enddatum auswählen",
                ),
                onTap: () => pickDate(dateToController),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final to = _parseDate(value);
                    if (to == null) {
                      return "Ungültiges Datum (dd.MM.yyyy).";
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _onSubmit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Trip anlegen"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
