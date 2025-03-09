import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File; // Wird nur auf mobilen Plattformen verwendet
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:http/http.dart' as http;
import 'my_posts_grid.dart';
import 'friends_list_widget.dart'; // Ensure this import is correct and the file exists

// Callback-Typ, um aktualisierte Profilwerte an das übergeordnete Widget zu melden.
typedef ProfileUpdateCallback = void Function(
    String newUsername,
    String newProfilePicture,
    String newFavoriteCuisines,
    String newDietaryPreferences);

class ProfileScreen extends StatefulWidget {
  final String username;
  final String profilePicture;
  final String favoriteCuisines;
  final String dietaryPreferences;
  final ProfileUpdateCallback onProfileUpdated;
  const ProfileScreen({
    Key? key,
    required this.username,
    required this.profilePicture,
    required this.favoriteCuisines,
    required this.dietaryPreferences,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();

  // Für Web: Bytes; für Mobile: File
  Uint8List? _imageBytes;
  File? _profileImage;

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _cuisineOptions = [
    'Italian',
    'Chinese',
    'Mexican',
    'Indian',
    'Japanese',
    'French',
    'Mediterranean',
    'Thai',
  ];
  late List<String> _selectedCuisines;

  // Neue Optionen für diätetische Präferenzen
  final List<String> _dietaryOptions = [
    "Vegetarian Friendly",
    "Gluten Free Options",
    "Vegan Options",
    "Fast Food",
    "Central European"
  ];
  late List<String> _selectedDietary;

  // Liste aller echten Nutzer aus der users.csv (wird über den Backend-Endpoint geladen)
  List<String> _allUsers = [];
  bool _isUsersLoading = false;
  String _message = '';

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _selectedCuisines = widget.favoriteCuisines.isNotEmpty
        ? widget.favoriteCuisines.split(',')
        : [];
    _selectedDietary = widget.dietaryPreferences.isNotEmpty
        ? widget.dietaryPreferences.split(',')
        : []; // Hier hinzugefügt
    fetchAllUsers();
    _usernameController.addListener(_onFieldChangedDebounced);
    _passwordController.addListener(_onFieldChangedDebounced);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFieldChangedDebounced() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _updateProfile();
    });
  }

  Future<void> fetchAllUsers() async {
    setState(() {
      _isUsersLoading = true;
    });
    final url = Uri.parse('http://127.0.0.1:8000/api/friends/get_all_users/');
    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        setState(() {
          _allUsers = List<String>.from(data["users"]);
        });
      } else {
        setState(() {
          _allUsers = [];
        });
      }
    } catch (e) {
      setState(() {
        _allUsers = [];
      });
      print("Fehler beim Abrufen aller Nutzer: $e");
    }
    setState(() {
      _isUsersLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      } else {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
      _updateProfile();
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    Uint8List? imageBytes;
    if (kIsWeb && _imageBytes != null) {
      imageBytes = _imageBytes;
    } else if (!kIsWeb && _profileImage != null) {
      imageBytes = await _profileImage!.readAsBytes();
    }
    String base64Image = imageBytes != null ? base64Encode(imageBytes) : "";
    final updatedProfilePic =
        base64Image.isNotEmpty ? base64Image : widget.profilePicture;
    String favCuisines = _selectedCuisines.join(',');
    if (favCuisines.isEmpty) {
      favCuisines = widget.favoriteCuisines;
    }
    String dietaryPrefs = _selectedDietary.join(',');

    final url = Uri.parse('http://127.0.0.1:8000/api/auth/update_profile/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": widget.username,
          "new_username": _usernameController.text.isNotEmpty
              ? _usernameController.text
              : null,
          "new_password": _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
          "profile_picture": updatedProfilePic,
          "favorite_cuisines": favCuisines,
          "dietary_preferences": dietaryPrefs,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        widget.onProfileUpdated(
            _usernameController.text.isNotEmpty
                ? _usernameController.text
                : widget.username,
            updatedProfilePic,
            favCuisines,
            dietaryPrefs);
        // Keine Erfolgsmeldung anzeigen
      } else {
        setState(() {
          _message = data["message"] ?? "Update fehlgeschlagen.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Fehler: $e";
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? displayImage;
    if (kIsWeb) {
      if (_imageBytes != null) {
        displayImage = MemoryImage(_imageBytes!);
      } else if (widget.profilePicture.isNotEmpty) {
        try {
          displayImage = MemoryImage(base64Decode(widget.profilePicture));
        } catch (e) {
          displayImage = null;
        }
      }
    } else {
      if (_profileImage != null) {
        displayImage = FileImage(_profileImage!);
      } else if (widget.profilePicture.isNotEmpty) {
        try {
          displayImage = MemoryImage(base64Decode(widget.profilePicture));
        } catch (e) {
          displayImage = null;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profil",
          style: TextStyle(
            color: const Color.fromARGB(255, 248, 127, 52),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(
            255, 252, 197, 42), // Gelb als Hintergrundfarbe
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profilbild (Tippe zum Ändern)
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: displayImage,
                  child: displayImage == null
                      ? const Icon(Icons.camera_alt, size: 50)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration:
                  const InputDecoration(labelText: "Neuer Benutzername"),
              onChanged: (_) => _onFieldChanged(),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Neues Passwort"),
              obscureText: true,
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 20),
            MultiSelectDialogField(
              items: _cuisineOptions
                  .map((cuisine) => MultiSelectItem<String>(cuisine, cuisine))
                  .toList(),
              title: const Text("Lieblingsküchen auswählen"),
              buttonText: const Text("Lieblingsküchen auswählen"),
              searchable: true,
              listType: MultiSelectListType.CHIP,
              initialValue: _selectedCuisines,
              onConfirm: (values) {
                setState(() {
                  _selectedCuisines = values.cast<String>();
                });
                _updateProfile();
              },
              chipDisplay: MultiSelectChipDisplay(
                chipColor: Colors.transparent,
                textStyle: const TextStyle(color: Colors.black),
                items: const [],
              ),
            ),
            const SizedBox(height: 20),
            // Neuer Abschnitt: Diätetische Präferenzen als MultiSelect
            //const Text("Diätetische Präferenzen:",
            //    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            MultiSelectDialogField(
              items: _dietaryOptions
                  .map((option) => MultiSelectItem<String>(option, option))
                  .toList(),
              title: const Text("Sonstige Präferenzen auswählen"),
              buttonText: const Text("Sonstige Präferenzen auswählen"),
              searchable: true,
              listType: MultiSelectListType.CHIP,
              initialValue: _selectedDietary,
              onConfirm: (values) {
                setState(() {
                  _selectedDietary = values.cast<String>();
                });
                _updateProfile();
              },
              chipDisplay: MultiSelectChipDisplay(
                chipColor: Colors.transparent,
                textStyle: const TextStyle(color: Colors.black),
                items: const [],
              ),
            ),
            const SizedBox(height: 20),
            // Freundeslisten-Bereich
            const Text("Freundesliste:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _isUsersLoading
                ? const Center(child: CircularProgressIndicator())
                : FriendListScreen(
                    currentUser: _usernameController.text,
                    allUsers: _allUsers,
                  ),
            const SizedBox(height: 20),
            const Text("Meine Posts:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            MyPostsGrid(username: _usernameController.text),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(),
            if (_message.isNotEmpty)
              Center(
                child: Text(
                  _message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            // Keine Statusnachricht mehr
          ],
        ),
      ),
    );
  }

  void _onFieldChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _updateProfile();
    });
  }
}
