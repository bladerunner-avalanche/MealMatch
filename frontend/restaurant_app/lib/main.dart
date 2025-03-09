//backend server starten im bash:
//1. cd Desktop\MM1\backend\restaurant_recommender
//2. python manage.py runserver

//App starten im Terminal:
//1. cd frontend\restaurant_app
//2. flutter run

//neuer Backend Ordner erstellen: python manage.py startapp "Name des Ordners"

//Pfade anpassen - diese befinden sich in den Frontend-Dateien unter frontend/restaurant_app/lib sowie frontend/pubspec.yaml
//1. Desktop/MM1/...  - jenachdem wo das Projekt gespeichert wird
//2. http://... - IP Adresse des Servers anpassen

//Das Machine Learning Model befindet sich unter backend/recommender/recommender.py ganz am Ende des Codes

import 'package:flutter/material.dart';
//import 'home_screen.dart';
import 'login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MealMatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Ändere den Hintergrund der gesamten App
        scaffoldBackgroundColor: const Color.fromARGB(255, 232, 232, 232),
      ),
      home: const LoginScreen(),
      //home: HomeScreen(),
      // Konfiguration für Web-Favicon
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0)), // Für konsistente Textgröße
          child: child!,
        );
      },
    );
  }
}
