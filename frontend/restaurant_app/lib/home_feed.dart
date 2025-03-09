import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'groups_dashboard.dart';
import 'restaurant.dart'; // Stelle sicher, dass dein Widget (z. B. RestaurantListScreen) korrekt definiert ist.
import 'profile_screen.dart';
import 'create_post_screen.dart';

// Angepasster Callback-Typ mit 4 Parametern
typedef ProfileUpdateCallback = void Function(
    String newUsername,
    String newProfilePicture,
    String newFavoriteCuisines,
    String newDietaryPreferences);

class HomeFeed extends StatefulWidget {
  final String username;
  final String profilePicture;
  final String favoriteCuisines;
  final String dietaryPreferences; // Neuer Parameter
  final String accountType; // "user" oder "company"

  const HomeFeed({
    Key? key,
    required this.username,
    required this.profilePicture,
    required this.favoriteCuisines,
    required this.dietaryPreferences,
    required this.accountType,
  }) : super(key: key);

  @override
  _HomeFeedState createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  int _currentIndex = 0;
  late String _username;
  late String _profilePicture;
  late String _favoriteCuisines;
  late String _dietaryPreferences; // Neue Variable
  late String _accountType;

  @override
  void initState() {
    super.initState();
    _username = widget.username;
    _profilePicture = widget.profilePicture;
    _favoriteCuisines = widget.favoriteCuisines;
    _dietaryPreferences = widget.dietaryPreferences;
    _accountType = widget.accountType;
  }

  // Callback, um aktualisierte Profilwerte von ProfileScreen zu erhalten.
  void _updateProfileInfo(String newUsername, String newProfilePicture,
      String newFavoriteCuisines, String newDietaryPreferences) {
    setState(() {
      _username = newUsername;
      _profilePicture = newProfilePicture;
      _favoriteCuisines = newFavoriteCuisines;
      _dietaryPreferences = newDietaryPreferences;
    });
  }

  // Globaler Key für den FeedScreen, um diesen bei Bedarf zu refreshen.
  final GlobalKey<FeedScreenState> _feedKey = GlobalKey<FeedScreenState>();

  @override
  Widget build(BuildContext context) {
    // Erstelle die Liste der Seiten – der Gruppen-Dashboard wird nur hinzugefügt, wenn _accountType nicht "company" ist.
    final List<Widget> _children = [
      FeedScreen(key: _feedKey, currentUser: _username),
      if (_accountType.toLowerCase() != 'company')
        GroupsDashboard(currentUsername: _username),
      RestaurantListScreen(), // Stelle sicher, dass dieses Widget korrekt definiert ist.
      ProfileScreen(
        username: _username,
        profilePicture: _profilePicture,
        favoriteCuisines: _favoriteCuisines,
        dietaryPreferences: _dietaryPreferences,
        onProfileUpdated: _updateProfileInfo,
      ),
    ];

    // Erstelle die BottomNavigationBar-Items – auch hier wird der Gruppen-Tab nur für normale User angezeigt.
    final List<BottomNavigationBarItem> bottomItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
      if (_accountType.toLowerCase() != 'company')
        const BottomNavigationBarItem(
            icon: Icon(Icons.group), label: 'Gruppen'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.restaurant), label: 'Restaurants'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
    ];

    // Passe den aktuellen Index an, falls er den möglichen Items nicht mehr entspricht.
    if (_currentIndex >= bottomItems.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed, // Feste Darstellung
        backgroundColor: const Color.fromARGB(255, 252, 197, 42), // Leiste gelb
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color.fromARGB(255, 248, 127, 52),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: bottomItems,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 30.0,
        selectedFontSize: 0.0,
        unselectedFontSize: 0.0,
      ),
      // FloatingActionButton nur im Feed-Tab anzeigen
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.grey[800],
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePostScreen(username: _username),
                  ),
                );
                if (result == true && _feedKey.currentState != null) {
                  _feedKey.currentState!.refreshPosts();
                }
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
