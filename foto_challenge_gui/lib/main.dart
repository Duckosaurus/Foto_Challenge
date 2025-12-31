import 'package:flutter/material.dart';
import 'auth/userIDstore.dart';
import 'auth/login.dart';
import 'trip/tripListScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isLoggedIn() async {
    final id = await UserIdStore.getUserId();
    print("Id bei Login: $id");
    return id != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snap.data == true
              ? const TripListScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
