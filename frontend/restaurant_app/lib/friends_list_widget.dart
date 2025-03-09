import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FriendListScreen extends StatefulWidget {
  final String currentUser;
  final List<String> allUsers;

  const FriendListScreen(
      {Key? key, required this.currentUser, required this.allUsers})
      : super(key: key);

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  List<String> _friends = [];
  final TextEditingController _friendController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  List<String> _potentialFriends = []; // Liste für potenzielle Freunde

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final url = Uri.parse('http://127.0.0.1:8000/api/friends/get_friends/');
    try {
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"username": widget.currentUser}));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            _friends = List<String>.from(data["friends"]);
            _updatePotentialFriends(); // Aktualisiere potenzielle Freunde
          });
        } else {
          setState(() {
            _errorMessage = data["message"] ?? "Fehler beim Laden der Freunde";
          });
        }
      } else {
        setState(() {
          _errorMessage = "HTTP-Fehler: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Fehler: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updatePotentialFriends() {
    _potentialFriends = widget.allUsers.where((user) {
      return user.toLowerCase() != widget.currentUser.toLowerCase() &&
          !_friends.map((e) => e.toLowerCase()).contains(user.toLowerCase());
    }).toList();
  }

  Future<void> _addFriend(String friend) async {
    final url = Uri.parse('http://127.0.0.1:8000/api/friends/add_friend/');
    try {
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"username": widget.currentUser, "friend": friend}));
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        await _fetchFriends(); // Aktualisiert _friends und _potentialFriends
        _friendController.clear();
      } else {
        _showSnackBar(data["message"] ?? "Fehler beim Hinzufügen");
      }
    } catch (e) {
      _showSnackBar("Fehler: $e");
    }
  }

  Future<void> _removeFriend(String friend) async {
    final url = Uri.parse('http://127.0.0.1:8000/api/friends/remove_friend/');
    try {
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"username": widget.currentUser, "friend": friend}));
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        await _fetchFriends(); // Aktualisiert _friends und _potentialFriends
      } else {
        _showSnackBar(data["message"] ?? "Fehler beim Entfernen");
      }
    } catch (e) {
      _showSnackBar("Fehler: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showFriendsManagementModal() async {
    String query = "";
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return DraggableScrollableSheet(
              expand: false,
              builder: (context, scrollController) {
                // Filtere die Freunde anhand des Suchbegriffs query:
                List<String> filteredFriends = _friends
                    .where((friend) =>
                        friend.toLowerCase().contains(query.toLowerCase()))
                    .toList();
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: "Freunde suchen",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          modalSetState(() {
                            query = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filteredFriends.length,
                          itemBuilder: (context, index) {
                            String friend = filteredFriends[index];
                            return ListTile(
                              title: Text(friend),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await _removeFriend(friend);
                                  // Nach dem Entfernen: Aktualisiere sowohl den Modal- als auch den Hauptzustand
                                  modalSetState(() {
                                    // query bleibt unverändert, _fetchFriends() wird in _removeFriend() aufgerufen
                                  });
                                  setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _updatePotentialFriends();
                          setState(() {});
                        },
                        child: const Text("Schließen"),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (_errorMessage.isNotEmpty)
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red),
          ),
        const SizedBox(height: 8),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            // Verwende die aktuell aktualisierte Liste der potenziellen Freunde
            return _potentialFriends
                .where((option) => option
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()))
                .toList();
          },
          onSelected: (String selection) {
            // Nichts tun – das Hinzufügen erfolgt ausschließlich im onSubmitted-Callback
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted) {
            return TextField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              decoration: const InputDecoration(
                labelText: "Freund hinzufügen",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) async {
                // Hier verwenden wir die bereits aktualisierte Liste _potentialFriends
                if (value.isNotEmpty && _potentialFriends.contains(value)) {
                  await _addFriend(value);
                  fieldTextEditingController.clear(); // Eingabefeld leeren
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Dieser Benutzer existiert nicht oder wurde bereits hinzugefügt.")),
                  );
                }
              },
            );
          },
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _showFriendsManagementModal,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(
                255, 225, 225, 225), // Hintergrundfarbe des Buttons
            foregroundColor: const Color.fromARGB(
                255, 248, 127, 52), // Schrift- und Icon-Farbe
          ),
          child: const Text("Alle Freunde sehen"),
        ),
      ],
    );
  }
}
