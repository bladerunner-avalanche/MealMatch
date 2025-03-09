import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MyPostsGrid extends StatefulWidget {
  final String username;
  const MyPostsGrid({Key? key, required this.username}) : super(key: key);

  @override
  _MyPostsGridState createState() => _MyPostsGridState();
}

class _MyPostsGridState extends State<MyPostsGrid> {
  List<dynamic> _myPosts = [];
  bool _isLoading = false;
  String _errorMessage = "";

  // Lädt alle Posts vom Backend und filtert diese, sodass nur die eigenen Posts angezeigt werden.
  Future<void> fetchMyPosts() async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse('http://127.0.0.1:8000/api/posts/list_posts/');
    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        List<dynamic> posts = data["posts"];
        List<dynamic> myPosts =
            posts.where((post) => post["username"] == widget.username).toList();
        setState(() {
          _myPosts = myPosts;
        });
      } else {
        setState(() {
          _errorMessage = data["message"] ?? "Fehler beim Laden der Posts.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Fehler: $e";
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Löscht einen Post über den Backend-Endpoint und lädt die Posts neu.
  Future<void> _deletePost(String postId) async {
    final url = Uri.parse('http://127.0.0.1:8000/api/posts/delete_post/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "post_id": postId,
          "username":
              widget.username, // Nur der Ersteller darf den Post löschen.
        }),
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post erfolgreich gelöscht")),
        );
        fetchMyPosts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler: ${data["message"]}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMyPosts();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Drei Spalten
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _myPosts.length,
      itemBuilder: (context, index) {
        final post = _myPosts[index];
        Widget imageWidget = Container();
        if (post["image_data"] != null &&
            post["image_data"].toString().isNotEmpty) {
          try {
            Uint8List imageBytes = base64Decode(post["image_data"]);
            imageWidget = Image.memory(
              imageBytes,
              fit: BoxFit.cover,
            );
          } catch (e) {
            imageWidget = const SizedBox();
          }
        }
        return GestureDetector(
          onLongPress: () {
            // Zeige einen Bestätigungsdialog zum Löschen
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Post löschen"),
                content:
                    const Text("Möchtest du diesen Post wirklich löschen?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Abbrechen"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deletePost(post["post_id"].toString());
                    },
                    child: const Text("Löschen"),
                  ),
                ],
              ),
            );
          },
          child: Card(
            child: imageWidget,
          ),
        );
      },
    );
  }
}
