import 'package:flutter/material.dart';
import 'package:isibappmoodle/views/home_share_file_view.dart'; // Assurez-vous que ce fichier contient la page HomeShareFile

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Supprime le bandeau de débogage
      title: 'ShareFile App',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Couleur principale de l'application
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeShareFile(), // Écran d'accueil de l'application
    );
  }
}
