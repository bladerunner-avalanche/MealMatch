import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'restaurant.dart'; // enthält RestaurantDetailsScreen und Restaurant-Modell

class GroupDetailScreen extends StatefulWidget {
  final Map group;
  final String currentUser;
  const GroupDetailScreen(
      {Key? key, required this.group, required this.currentUser})
      : super(key: key);

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _isProcessing = false;
  String _message = "";
  String _recommendation = "";
  bool _isLoadingRecommendation = false;

  // Variablen für den Restaurant-Bereich
  String _locationFilter = "";
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoadingRestaurants = false;
  Timer? _locationDebounce;

  // Neue Variable für aggregierte diätetische Präferenzen der Gruppenmitglieder
  List<String> _groupDietaryPreferences = [];

  Future<void> _getRecommendation() async {
    setState(() {
      _isLoadingRecommendation = true;
      _recommendation = "";
    });
    final url = Uri.parse('http://127.0.0.1:8000/api/recommender/recommend/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"group_id": widget.group["group_id"]}),
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        String rec = data["recommended_cuisine"] ?? "";
        if (rec.trim().isEmpty) {
          rec = "Keine Empfehlung gefunden";
        }
        setState(() {
          _recommendation = rec;
        });
        // Sobald die Empfehlung vorliegt, rufe auch die gruppenweiten diätetischen Präferenzen ab
        await _fetchGroupDietaryPreferences();
        // Anschließend rufe die Restaurantliste ab
        _fetchFilteredRestaurants();
      } else {
        setState(() {
          _recommendation = "Fehler in der Antwort";
        });
      }
    } catch (e) {
      setState(() {
        _recommendation = "Fehler: $e";
      });
    }
    setState(() {
      _isLoadingRecommendation = false;
    });
  }

  /// Ruft die aggregierten diätetischen Präferenzen für die Gruppenmitglieder ab.
  Future<void> _fetchGroupDietaryPreferences() async {
    final url = Uri.parse(
        'http://127.0.0.1:8000/api/auth/get_group_dietary_preferences/');
    // Extrahiere Mitglieder aus dem Gruppenfeld ("members" als kommagetrennte Zeichenkette)
    List<String> members = widget.group["members"]
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"members": members}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            _groupDietaryPreferences =
                List<String>.from(data["dietary_preferences"]);
          });
        } else {
          setState(() {
            _groupDietaryPreferences = [];
          });
        }
      } else {
        setState(() {
          _groupDietaryPreferences = [];
        });
      }
    } catch (e) {
      setState(() {
        _groupDietaryPreferences = [];
      });
    }
  }

  Future<void> _fetchFilteredRestaurants() async {
    if (_recommendation.trim().isEmpty ||
        _recommendation == "Keine Empfehlung gefunden") return;
    setState(() {
      _isLoadingRestaurants = true;
    });
    try {
      // Falls _groupDietaryPreferences leer ist, setze einen Default-Wert oder lasse ihn weg
      String dietaryQuery = _groupDietaryPreferences.isNotEmpty
          ? _groupDietaryPreferences.join(" ")
          : ""; // oder: "alle"
      String query =
          "${_recommendation.trim()} ${dietaryQuery} ${_locationFilter.trim()}";
      List<Restaurant> results =
          await searchRestaurants(query: query, page: 1, pageSize: 5);
      setState(() {
        _filteredRestaurants = results;
      });
    } catch (e) {
      setState(() {
        _filteredRestaurants = [];
      });
    }
    setState(() {
      _isLoadingRestaurants = false;
    });
  }

  Future<void> _deleteGroup() async {
    setState(() {
      _isProcessing = true;
      _message = "";
    });
    final url =
        Uri.parse("http://127.0.0.1:8000/api/recommender/delete_group/");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "group_id": widget.group["group_id"],
          "username": widget.currentUser,
        }),
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _message = data["message"] ?? "Fehler beim Löschen der Gruppe.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Fehler: $e";
      });
    }
    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _leaveGroup() async {
    setState(() {
      _isProcessing = true;
      _message = "";
    });
    final url = Uri.parse("http://127.0.0.1:8000/api/recommender/leave_group/");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "group_id": widget.group["group_id"],
          "username": widget.currentUser,
        }),
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _message = data["message"] ?? "Fehler beim Verlassen der Gruppe.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Fehler: $e";
      });
    }
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isCreator = widget.currentUser == widget.group["created_by"];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gruppendetails',
          style: TextStyle(
            color: const Color.fromARGB(255, 248, 127, 52),
            fontWeight: FontWeight.bold,
          ), // Titeltext wird orange
        ),
        backgroundColor: const Color.fromARGB(
            255, 252, 197, 42), // Gelb als Hintergrundfarbe
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Gruppenname: ${widget.group["group_name"]}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Erstellt von: ${widget.group["created_by"]}"),
            const SizedBox(height: 8),
            Text("Mitglieder: ${widget.group["members"]}"),
            const SizedBox(height: 20),
            _isLoadingRecommendation
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _getRecommendation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(
                          255, 225, 225, 225), // Hintergrundfarbe des Buttons
                      foregroundColor: const Color.fromARGB(
                          255, 248, 127, 52), // Schrift- und Icon-Farbe
                    ),
                    child: const Text("Empfehlung berechnen"),
                  ),
            const SizedBox(height: 20),
            if (_recommendation.isNotEmpty)
              Text("Empfehlung: $_recommendation",
                  style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            // Restaurantliste-Abschnitt
            if (_recommendation.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 10),
              const Text("Restaurants für diese Empfehlung:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Standort filtern",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _locationFilter = value;
                  if (_locationDebounce?.isActive ?? false)
                    _locationDebounce!.cancel();
                  _locationDebounce =
                      Timer(const Duration(milliseconds: 500), () {
                    _fetchFilteredRestaurants();
                  });
                },
              ),
              const SizedBox(height: 10),
              _isLoadingRestaurants
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRestaurants.isEmpty
                      ? const Text("Keine Restaurants gefunden.")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredRestaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = _filteredRestaurants[index];
                            return ListTile(
                              title: Text(restaurant.name),
                              subtitle: Text(restaurant.city),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RestaurantDetailsScreen(
                                            restaurant: restaurant),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ],
            const SizedBox(height: 20),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else if (isCreator)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _deleteGroup,
                    child: const Text("Gruppe löschen"),
                  ),
                  ElevatedButton(
                    onPressed: _leaveGroup,
                    child: const Text("Gruppe verlassen"),
                  ),
                ],
              )
            else
              Center(
                child: ElevatedButton(
                  onPressed: _leaveGroup,
                  child: const Text("Gruppe verlassen"),
                ),
              ),
            const SizedBox(height: 20),
            if (_message.isNotEmpty)
              Text(_message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
