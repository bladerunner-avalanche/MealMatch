import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'registration_screen.dart';
import 'home_feed.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    final url = Uri.parse('http://127.0.0.1:8000/api/auth/login/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // Erfolgreich eingeloggt, leite zur Home Feed-Seite weiter
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeFeed(
              username: _usernameController.text,
              profilePicture: data['profile_picture'] ?? "",
              favoriteCuisines: data['favorite_cuisines'] ?? "",
              dietaryPreferences:
                  data['dietary_preferences'] ?? "", // Hier hinzugefügt
              accountType: data['account_type'] ?? "user",
            ),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Login fehlgeschlagen';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler: $e';
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login',
          style: TextStyle(
            color: const Color.fromARGB(255, 248, 127, 52),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(
            255, 252, 197, 42), // Gelb als Hintergrundfarbe
      ),
      body: SingleChildScrollView(
        // Hier SingleChildScrollView hinzufügen
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(
                            255, 225, 225, 225), // Hintergrundfarbe des Buttons
                        foregroundColor: const Color.fromARGB(
                            255, 248, 127, 52), // Schrift- und Icon-Farbe
                      ),
                      child: const Text('Login'),
                    ),
              TextButton(
                onPressed: () {
                  // Zur Registrierungsseite wechseln
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegistrationScreen()),
                  );
                },
                child: const Text('Noch keinen Account? Hier registrieren'),
              ),
              const SizedBox(height: 1), // Füge etwas Abstand hinzu
              Image.asset(
                'C:/Users/uhumb/Desktop/MM1/frontend/restaurant_app/web/Logo_MealMatch_Neu.png', // Pfad zu deinem Logo-Asset
                width: 500, // Passe die Breite nach Bedarf an
                height: 500, // Passe die Höhe nach Bedarf an
              ),
            ],
          ),
        ),
      ),
    );
  }
}
