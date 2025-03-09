import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CreatePostScreen extends StatefulWidget {
  final String username;
  const CreatePostScreen({Key? key, required this.username}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postTextController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile; // Für mobile Geräte
  Uint8List? _webImageBytes; // Für Flutter Web
  String _errorMessage = "";
  bool _isLoading = false;

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        Uint8List bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    // Für Flutter Web gibt es derzeit keine native Unterstützung zur Webcam-Steuerung.
    // Daher wird hier direkt die Galerie gewählt.
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Direkte Webcam-Aufnahme wird auf Flutter Web nicht unterstützt. Bitte wählen Sie ein Bild aus der Galerie.")));
      await _pickImageFromGallery();
    } else {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  void _showImageSourceDialog() {
    if (kIsWeb) {
      // Auf Flutter Web nur Galerie-Option anbieten
      _pickImageFromGallery();
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Bildquelle wählen"),
              content: const Text(
                  "Wählen Sie, ob Sie ein Bild aufnehmen oder aus der Galerie auswählen möchten."),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                    child: const Text("Kamera")),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                    child: const Text("Galerie")),
              ],
            );
          });
    }
  }

  Future<void> _createPost() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });
    String base64Image = "";
    if (kIsWeb && _webImageBytes != null) {
      base64Image = base64Encode(_webImageBytes!);
    } else if (!kIsWeb && _imageFile != null) {
      List<int> imageBytes = await _imageFile!.readAsBytes();
      base64Image = base64Encode(imageBytes);
    }
    var payload = {
      "username": widget.username,
      "post_text": _postTextController.text,
      "image_data": base64Image,
    };
    final url = Uri.parse('http://127.0.0.1:8000/api/posts/create_post/');
    try {
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(payload));
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        Navigator.pop(context, true); // Erfolgreich, kehre zum Feed zurück
      } else {
        setState(() {
          _errorMessage = data["message"] ?? "Post-Erstellung fehlgeschlagen";
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

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Container();
    if (kIsWeb) {
      if (_webImageBytes != null) {
        imageWidget = Image.memory(_webImageBytes!);
      }
    } else {
      if (_imageFile != null) {
        imageWidget = Image.file(_imageFile!);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Neuen Post erstellen",
          style: TextStyle(
            color: const Color.fromARGB(255, 248, 127, 52),
            fontWeight: FontWeight.bold,
          ), // Titeltext wird orange),
        ),
        backgroundColor: const Color.fromARGB(
            255, 252, 197, 42), // Gelb als Hintergrundfarbe
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _showImageSourceDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(
                    255, 225, 225, 225), // Hintergrundfarbe des Buttons
                foregroundColor: const Color.fromARGB(
                    255, 248, 127, 52), // Schrift- und Icon-Farbe
              ),
              child: const Text("Bild hinzufügen"),
            ),
            if (_webImageBytes != null || _imageFile != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: imageWidget,
              ),
            TextField(
              controller: _postTextController,
              decoration: const InputDecoration(labelText: "Text zum Post"),
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(
                          255, 225, 225, 225), // Hintergrundfarbe des Buttons
                      foregroundColor: const Color.fromARGB(
                          255, 248, 127, 52), // Schrift- und Icon-Farbe
                    ),
                    child: const Text("Post erstellen"),
                  ),
          ],
        ),
      ),
    );
  }
}
