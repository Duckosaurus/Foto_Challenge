import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'tripDetail.dart';
import 'tripAnlegen.dart';
import '../auth/userIDstore.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  late Future<List<dynamic>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = fetchTrips();
  }

  Future<List<dynamic>> fetchTrips() async {
    final userId = await UserIdStore.getUserId();
    if (userId == null) throw Exception("Kein UserId gespeichert.");

    final url = Uri.parse("http://10.0.2.2:3000/trips?userid=$userId");
    final res = await http.get(url);
    print(res.statusCode);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception("Fehler beim Laden: ${res.statusCode}");
  }

  Future<void> _refresh() async {
    setState(() {
      _tripsFuture = fetchTrips();
    });
    await _tripsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meine Trips"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Fehler: ${snapshot.error}"));
          }

          final trips = snapshot.data ?? [];
          if (trips.isEmpty) {
            return const Center(child: Text("Noch keine Trips gespeichert."));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: trips.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = trips[i] as Map<String, dynamic>;

                final id = t["id"].toString();
                final name = (t["name"] ?? "—").toString();
                final tripDate = (t["startdatum"] ?? "—")
                    .toString(); // ✅ Trip-Datum für M–3

                return ListTile(
                  title: Text(name),
                  subtitle: Text("Datum: $tripDate"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripDetailScreen(tripId: id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),

      // optional: neuer Trip (verknüpft M1/M2)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TripAnlegen()),
          );
          // nach Rückkehr Liste neu laden
          _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
