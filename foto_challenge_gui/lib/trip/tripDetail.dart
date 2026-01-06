import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/apiConfig.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    setState(() {
      loading = true;
      error = null;
    });

    final url = Uri.parse("${ApiConfig.baseUrl}/trips/${widget.tripId}");

    // final url = Uri.parse("http://localhost:3000/trips/${widget.tripId}");

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

  @override
  Widget build(BuildContext context) {
    final name = trip?["name"]?.toString() ?? "—";
    final beschreibung = trip?["beschreibung"]?.toString() ?? "";
    final startdatum = trip?["startdatum"]?.toString() ?? "—";
    final enddatum = trip?["enddatum"]?.toString() ?? "—";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Details"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTrip),
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
                      const SizedBox(height: 16),
                    ],

                    Row(
                      children: [
                        Expanded(child: Text("Von: $startdatum")),
                        const SizedBox(width: 12),
                        Expanded(child: Text("Bis: $enddatum")),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Platz für M6: Challenge-Liste
                    Text(
                      "Foto-Challenges",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Hier kommt später die Challenge-Liste rein (M6).",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
      ),

      // Platz für M4/M5: Challenge hinzufügen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // später: Challenge hinzufügen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("TODO: Challenge hinzufügen")),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
