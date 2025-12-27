import 'package:flutter/material.dart';
import 'authAPI.dart';
import 'userIDStore.dart';
import '../trip/tripListScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _pwController = TextEditingController();

  bool _loading = false;
  bool _registerMode = false; // false = Login, true = Register

  @override
  void dispose() {
    _usernameController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);

    try {
      final username = _usernameController.text.trim();
      final passwort = _pwController.text;
      print(username);
      print(passwort);
      final userId = _registerMode
          ? await AuthApi.register(username: username, passwort: passwort)
          : await AuthApi.login(username: username, passwort: passwort);

      await UserIdStore.saveUserId(userId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TripListScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _registerMode
                ? "Registrierung fehlgeschlagen: $e"
                : "Login fehlgeschlagen: $e",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _registerMode ? "Registrieren" : "Anmelden";
    final buttonText = _registerMode ? "Account erstellen" : "Anmelden";
    final toggleText = _registerMode
        ? "Schon einen Account? → Anmelden"
        : "Noch keinen Account? → Registrieren";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final s = (v ?? "").trim();
                  if (s.isEmpty) return "Bitte Username eingeben.";
                  if (s.length < 3) return "Username zu kurz (min. 3).";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pwController,
                decoration: const InputDecoration(
                  labelText: "Passwort",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) {
                  final s = (v ?? "");
                  if (s.isEmpty) return "Bitte Passwort eingeben.";
                  if (_registerMode && s.length < 4) {
                    return "Passwort zu kurz (min. 4).";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(buttonText),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() => _registerMode = !_registerMode);
                      },
                child: Text(toggleText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
