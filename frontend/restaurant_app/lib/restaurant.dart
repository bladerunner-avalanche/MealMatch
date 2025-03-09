import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Restaurant {
  final int id;
  final String name;
  final String city;
  final String cuisineStyle;
  final double? rating;
  final String priceRange;
  final int? numberOfReviews;
  final String reviews;
  final String urlTa;
  final String idTa;

  Restaurant({
    required this.id,
    required this.name,
    required this.city,
    required this.cuisineStyle,
    this.rating,
    required this.priceRange,
    this.numberOfReviews,
    required this.reviews,
    required this.urlTa,
    required this.idTa,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      cuisineStyle: json['cuisine_style'] as String? ?? '',
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      priceRange: json['price_range'] as String? ?? '',
      numberOfReviews: json['number_of_reviews'] != null
          ? int.tryParse(json['number_of_reviews'].toString())
          : null,
      reviews: json['reviews'] as String? ?? '',
      urlTa: json['url_ta'] as String? ?? '',
      idTa: json['id_ta'] as String? ?? '',
    );
  }
}

Future<List<Restaurant>> searchRestaurants(
    {required String query, required int page, required int pageSize}) async {
  final response = await http.get(Uri.parse(
      'http://127.0.0.1:8000/api/restaurants/?search=$query&page=$page&page_size=$pageSize'));
  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<dynamic> results = data['results'];
    return results.map((json) => Restaurant.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load restaurants');
  }
}

class RestaurantListScreen extends StatefulWidget {
  @override
  _RestaurantListScreenState createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  List<Restaurant> _restaurants = [];
  String _searchQuery = '';
  int _currentPage = 1;
  int _pageSize = 10;
  bool _isLoading = false;
  bool _hasNextPage = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasNextPage &&
        !_isLoading) {
      _loadRestaurants();
    }
  }

  Future<void> _loadRestaurants() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final fetchedRestaurants = await searchRestaurants(
          query: _searchQuery, page: _currentPage, pageSize: _pageSize);

      setState(() {
        if (_currentPage == 1) {
          _restaurants = fetchedRestaurants;
        } else {
          _restaurants.addAll(fetchedRestaurants);
        }

        _hasNextPage = fetchedRestaurants.length == _pageSize;
        if (_hasNextPage) {
          _currentPage++;
        }
      });
    } catch (e) {
      print('Fehler: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
    _loadRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Restaurants',
          style: TextStyle(
            color: const Color.fromARGB(255, 248, 127, 52),
            fontWeight: FontWeight.bold,
          ), // Titeltext wird orange),
        ),
        backgroundColor: const Color.fromARGB(
            255, 252, 197, 42), // Gelb als Hintergrundfarbe
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Nach Restaurants suchen...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: _onSearch,
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_restaurants.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _restaurants.length + (_hasNextPage ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _restaurants.length) {
          final restaurant = _restaurants[index];
          return Card(
            child: ListTile(
              title: Text(restaurant.name),
              subtitle: Text(restaurant.city),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RestaurantDetailsScreen(
                      restaurant: restaurant,
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class RestaurantDetailsScreen extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailsScreen({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          restaurant.name,
          style: const TextStyle(
            color: Color.fromARGB(255, 248, 127, 52), // Orange Schriftfarbe
          ),
        ),
        backgroundColor:
            const Color.fromARGB(255, 252, 197, 42), // Gelber Hintergrund
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stadt: ${restaurant.city}'),
            Text('Küche: ${restaurant.cuisineStyle}'),
            Text('Bewertung: ${restaurant.rating ?? 'Keine Angabe'}'),
            Text('Preisspanne: ${restaurant.priceRange}'),
            Text(
                'Anzahl Bewertungen: ${restaurant.numberOfReviews ?? 'Keine Angabe'}'),
          ],
        ),
      ),
    );
  }
}
