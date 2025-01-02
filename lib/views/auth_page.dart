import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:isibappmoodle/config/config';
import 'package:isibappmoodle/views/home_share_file_view.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin =
      true; // Détermine si on est sur la page de connexion ou d'inscription
  String _message = "";
  String? _selectedClasse; // Section sélectionnée par l'utilisateur
  String? _selectedFiliere;

  // Liste des sections disponibles
  final List<String> _classe = [
    "BAC 1",
    "BAC 2",
    "BAC 3",
    "Bloc C",
    "Master 1",
    "Master 2"
  ];

  final List<String> _filiere = [
    "Commun",
    "Info",
    "Electronique",
    "Mécanique",
    "Physique Nucléaire",
    "Chimie",
    "Electricité"
  ];

  // Fonction pour se connecter
  Future<void> _signIn() async {
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _message = 'Connexion réussie!';
      });

      // Rediriger vers la page d'accueil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeShareFile()),
      );
    } catch (e) {
      setState(() {
        _message = 'Erreur de connexion: $e';
      });
    }
  }

  // Fonction pour s'inscrire via l'API backend
  Future<void> _signUp() async {
    final String email = _emailController.text;
    final String password = _passwordController.text;

    // Vérification des champs
    if (email.isEmpty ||
        password.isEmpty ||
        _selectedClasse == null ||
        _selectedFiliere == null) {
      setState(() {
        _message =
            "L'email, le mot de passe et la section sont requis pour l'inscription.";
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
            "${Config.sander}/signup"), // Remplace par l'URL de ton backend
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
          'classe': _selectedClasse,
          'filiere': _selectedFiliere,
        }),
      );

      if (response.statusCode == 201) {
        // Une fois l'utilisateur créé, on tente de se connecter
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        setState(() {
          _message = 'Inscription et connexion réussies!';
        });

        // Rediriger vers la page d'accueil après inscription et connexion
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeShareFile()),
        );
      } else {
        setState(() {
          _message = 'Erreur d\'inscription: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Erreur de communication avec le serveur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Se connecter' : 'S\'inscrire'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Entrez votre email',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                hintText: 'Entrez votre mot de passe',
              ),
              obscureText: true,
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedClasse,
                decoration: const InputDecoration(
                  labelText: 'Classe',
                  border: OutlineInputBorder(),
                ),
                items: _classe
                    .map((section) => DropdownMenuItem<String>(
                          value: section,
                          child: Text(section),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClasse = value;
                  });
                },
                menuMaxHeight:
                    200, // Limite la hauteur de la liste déroulante à 200 pixels
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedFiliere,
                decoration: const InputDecoration(
                  labelText: 'Filiere',
                  border: OutlineInputBorder(),
                ),
                items: _filiere
                    .map((section) => DropdownMenuItem<String>(
                          value: section,
                          child: Text(section),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFiliere = value;
                  });
                },
                menuMaxHeight:
                    200, // Limite la hauteur de la liste déroulante à 200 pixels
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLogin ? _signIn : _signUp,
              child: Text(_isLogin ? 'Se connecter' : 'S\'inscrire'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              child: Text(_isLogin
                  ? 'Pas encore de compte ? Inscrivez-vous'
                  : 'Vous avez un compte ? Connectez-vous'),
            ),
            const SizedBox(height: 16),
            Text(_message),
          ],
        ),
      ),
    );
  }
}