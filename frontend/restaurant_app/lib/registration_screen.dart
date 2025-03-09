import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_feed.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _accountType = 'user'; // Standard: 'user'; Alternative: 'company'
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    final url = Uri.parse('http://127.0.0.1:8000/api/auth/register/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
          'account_type': _accountType,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // Erfolgreich registriert, leite zur Home Feed-Seite weiter
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeFeed(
              username: _usernameController.text,
              profilePicture:
                  "", // Bei Registrierung wird noch kein Profilbild übermittelt
              favoriteCuisines:
                  "", // Add an empty string or appropriate value for favoriteCuisines
              dietaryPreferences:
                  "", // Add an empty string or appropriate value for dietaryPreferences
              accountType: "",
            ),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Registrierung fehlgeschlagen';
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
          'Registrierung',
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
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Account Typ: '),
                  DropdownButton<String>(
                    value: _accountType,
                    items: const [
                      DropdownMenuItem(child: Text('User'), value: 'user'),
                      DropdownMenuItem(
                          child: Text('Company'), value: 'company'),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _accountType = value!;
                      });
                    },
                  ),
                ],
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
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(
                            255, 225, 225, 225), // Hintergrundfarbe des Buttons
                        foregroundColor: const Color.fromARGB(
                            255, 248, 127, 52), // Schrift- und Icon-Farbe
                      ),
                      child: const Text('Registrieren'),
                    ),
              const SizedBox(height: 1), // Füge etwas Abstand hinzu
              Image.asset(
                'C:/Users/uhumb/Desktop/MM1/frontend/restaurant_app/web/Logo_MealMatch_Neu.png', // Pfad zu deinem Logo-Asset
                width: 600, // Passe die Breite nach Bedarf an
                height: 600, // Passe die Höhe nach Bedarf an
              ),
            ],
          ),
        ),
      ),
    );
  }
}
