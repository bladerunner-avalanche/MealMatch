import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FeedScreen extends StatefulWidget {
  final String currentUser;
  const FeedScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  FeedScreenState createState() => FeedScreenState();
}

class FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allPosts = [];
  List<dynamic> _friendPosts = [];
  List<String> _friendList = [];
  bool _isLoadingPosts = false;
  bool _isLoadingFriends = false;
  String _errorMessage = "";
  int _selectedIndex = 0; // 0 = Alle Posts, 1 = Freundes‑Posts

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPosts();
    _fetchFriendList();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });
    final url = Uri.parse('http://127.0.0.1:8000/api/posts/list_posts/');
    try {
      // Hier wird GET verwendet – stelle sicher, dass dein Backend GET-Requests erlaubt.
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            _allPosts = data["posts"];
            _filterFriendPosts();
          });
        } else {
          setState(() {
            _errorMessage = data["message"] ?? "Fehler beim Laden der Posts";
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
    }
    setState(() {
      _isLoadingPosts = false;
    });
  }

  Future<void> _fetchFriendList() async {
    setState(() {
      _isLoadingFriends = true;
    });
    // Hier verwenden wir POST, da dein get_friends-Endpoint POST erwartet.
    final url = Uri.parse(
        'http://127.0.0.1:8000/api/friends/get_friends/?username=${widget.currentUser}');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": widget.currentUser}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            _friendList = List<String>.from(data["friends"]);
            _filterFriendPosts();
          });
        } else {
          setState(() {
            _errorMessage =
                data["message"] ?? "Fehler beim Laden der Freundesliste";
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
    }
    setState(() {
      _isLoadingFriends = false;
    });
  }

  void _filterFriendPosts() {
    setState(() {
      _friendPosts = _allPosts.where((post) {
        String postUser = post["username"]?.toString() ?? "";
        return _friendList
            .map((e) => e.toLowerCase())
            .contains(postUser.toLowerCase());
      }).toList();
    });
  }

  Future<void> refreshPosts() async {
    await _fetchPosts();
    await _fetchFriendList();
  }

  Widget _buildPostsList(List<dynamic> posts) {
    if (posts.isEmpty) {
      return const Center(child: Text("Keine Posts vorhanden"));
    }
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        Widget imageWidget = Container();
        if (post["image_data"] != null &&
            post["image_data"].toString().isNotEmpty) {
          try {
            // Verwende dart:typed_data, um das Base64-Image in Uint8List zu dekodieren.
            Uint8List imageBytes = base64Decode(post["image_data"]);
            imageWidget = Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              width: double.infinity,
            );
          } catch (e) {
            imageWidget = const SizedBox();
          }
        }
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("User: ${post["username"]}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                imageWidget,
                const SizedBox(height: 8.0),
                Text(post["post_text"] ?? ""),
                const SizedBox(height: 4.0),
                Text("Gepostet am: ${post["timestamp"]}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPosts || _isLoadingFriends) {
      return Scaffold(
        appBar: AppBar(title: const Text("Feed")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Feed")),
        body: Center(child: Text(_errorMessage)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Feed",
          style: TextStyle(
            color: const Color.fromARGB(255, 248, 127, 52),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 252, 197, 42),
      ),
      body: Column(
        // Verwende Column, um die ToggleButtons und den Inhalt anzuordnen
        children: [
          Center(
            // Zentriere die ToggleButtons
            child: ToggleButtons(
              isSelected: [_selectedIndex == 0, _selectedIndex == 1],
              onPressed: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              borderRadius: BorderRadius.circular(8.0),
              selectedColor: const Color.fromARGB(2255, 248, 127, 52),
              fillColor: Color.fromARGB(255, 225, 225, 225),
              color: Colors.black,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Alle Posts"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Freundes-Posts"),
                ),
              ],
            ),
          ),
          Expanded(
            // Verwende Expanded, um den restlichen Platz zu füllen
            child: RefreshIndicator(
              onRefresh: refreshPosts,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsList(
                          _selectedIndex == 0 ? _allPosts : _friendPosts),
                      _buildPostsList(
                          _selectedIndex == 1 ? _friendPosts : _allPosts),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
