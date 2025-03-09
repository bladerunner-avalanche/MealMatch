import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:multi_select_flutter/multi_select_flutter.dart';

class CreateGroupScreen extends StatefulWidget {
  final String currentUsername;
  final List<String> allUsers;
  const CreateGroupScreen(
      {Key? key, required this.currentUsername, required this.allUsers})
      : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  List<String> _selectedUsers = [];
  List<String> _fetchedUsers = [];
  bool _isLoading = false;
  String _message = "";
  Color _messageColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/auth/get_users/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            _fetchedUsers = List<String>.from(data["users"]);
          });
        }
      }
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty) {
      setState(() {
        _message = "Gruppenname ist erforderlich.";
        _messageColor = Colors.red;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _message = "";
    });

    List<String> finalMembers = List.from(_selectedUsers);
    if (!finalMembers.contains(widget.currentUsername)) {
      finalMembers.add(widget.currentUsername);
    }
    finalMembers = List.from({...finalMembers});

    final url =
        Uri.parse('http://127.0.0.1:8000/api/recommender/create_group/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "group_name": _groupNameController.text,
          "created_by": widget.currentUsername,
          "members": finalMembers,
        }),
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        setState(() {
          _message = "Gruppe erstellt!";
          _messageColor = Colors.green;
        });
        Navigator.pop(context, true);
      } else {
        setState(() {
          _message = data["message"] ?? "Fehler bei der Erstellung.";
          _messageColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _message = "Fehler: $e";
        _messageColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allUsersList =
        _fetchedUsers.isNotEmpty ? _fetchedUsers : widget.allUsers;
    final selectableUsers =
        allUsersList.where((user) => user != widget.currentUsername).toList();

    final items = selectableUsers
        .map((user) => MultiSelectItem<String>(user, user))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Gruppe erstellen",
          style: TextStyle(
            color: const Color.fromARGB(255, 248, 127, 52),
            // Titeltext wird orange),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(
            255, 252, 197, 42), // Gelb als Hintergrundfarbe
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MultiSelectDialogField(
              items: items,
              title: const Text("Mitglieder auswählen"),
              buttonText: const Text("Mitglieder auswählen"),
              searchable: true,
              onConfirm: (values) {
                setState(() {
                  _selectedUsers = values.cast<String>();
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(labelText: "Gruppenname"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createGroup,
              child: const Text("Gruppe erstellen"),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(_message, style: TextStyle(color: _messageColor)),
            ],
            if (_isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
