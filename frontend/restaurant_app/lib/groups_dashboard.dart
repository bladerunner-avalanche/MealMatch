import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'create_group_screen.dart';
import 'group_detail_screen.dart';

class GroupsDashboard extends StatefulWidget {
  final String currentUsername;
  const GroupsDashboard({Key? key, required this.currentUsername})
      : super(key: key);

  @override
  _GroupsDashboardState createState() => _GroupsDashboardState();
}

class _GroupsDashboardState extends State<GroupsDashboard> {
  List<dynamic> _groups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse('http://127.0.0.1:8000/api/recommender/list_groups/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": widget.currentUsername}),
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        setState(() {
          _groups = data["groups"];
        });
      }
    } catch (e) {
      print("Error fetching groups: $e");
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _navigateToCreateGroup() async {
    bool? created = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CreateGroupScreen(
              currentUsername: widget.currentUsername, allUsers: [])),
    );
    if (created == true) {
      _fetchGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gruppen',
          style: TextStyle(
            color: const Color.fromARGB(255, 248, 127, 52),
            fontWeight: FontWeight.bold,
          ), // Titeltext wird orange
        ),
        backgroundColor: const Color.fromARGB(
            255, 252, 197, 42), // Gelb als Hintergrundfarbe
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _navigateToCreateGroup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(
                  255, 225, 225, 225), // Hintergrundfarbe des Buttons
              foregroundColor: const Color.fromARGB(
                  255, 248, 127, 52), // Schrift- und Icon-Farbe
            ),
            child: const Text("Gruppe erstellen"),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      var group = _groups[index];
                      return ListTile(
                        title: Text(group["group_name"] ?? ""),
                        subtitle: Text("Mitglieder: ${group["members"]}"),
                        onTap: () async {
                          // Use async/await and Navigator.push to get the result
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GroupDetailScreen(
                                    group: group,
                                    currentUser: widget.currentUsername)),
                          );

                          // Check the result and refresh if needed
                          if (result == true) {
                            _fetchGroups();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
