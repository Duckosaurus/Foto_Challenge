import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TripAnlegen extends StatefulWidget {
  const TripAnlegen({super.key});

  @override
  State<TripAnlegen> createState() => _TripAnlegenState();
  //TODO: Eingabefelder validieren (bis kann nicht vor von liegen)
}

class _TripAnlegenState extends State<TripAnlegen> {
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  Future<void> sendTripToBackend() async {
    final url = Uri.parse("http://localhost:3000/trips");

    final body = {
      "name": nameController.text,
      "description": descriptionController.text,
      "dateFrom": dateFromController.text,
      "dateTo": dateToController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Trip erfolgreich gespeichert");
      } else {
        print("Fehler: ${response.statusCode}");
        print(response.body);
      }
    } catch (e) {
      print("Netzwerkfehler: $e");
    }
  }

  Future<void> pickDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Trip anlegen")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name des Trips"),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Tripname eingeben",
              ),
            ),
            SizedBox(height: 16),

            Text("Beschreibung"),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Beschreibung eingeben",
              ),
            ),
            SizedBox(height: 24),

            Text("Von"),
            TextField(
              controller: dateFromController,
              readOnly: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Startdatum auswählen",
              ),
              onTap: () => pickDate(dateFromController),
            ),
            SizedBox(height: 16),

            Text("Bis"),
            TextField(
              controller: dateToController,
              readOnly: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enddatum auswählen",
              ),
              onTap: () => pickDate(dateToController),
            ),

            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                sendTripToBackend();
                print("Trip gespeichert!");
              },
              child: Text("Trip anlegen"),
              style: ElevatedButton.styleFrom(
                // backgroundColor: const Color.fromARGB(255, 132, 199, 255),
                // foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
