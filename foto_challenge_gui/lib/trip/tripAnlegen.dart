import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripAnlegen extends StatefulWidget {
  const TripAnlegen({super.key});

  @override
  State<TripAnlegen> createState() => _TripAnlegenState();
}

class _TripAnlegenState extends State<TripAnlegen> {
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();

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
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Tripname eingeben",
              ),
            ),
            SizedBox(height: 16),

            Text("Beschreibung"),
            TextField(
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
