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
  String? _selectedSection; // Section sélectionnée par l'utilisateur

  // Liste des sections disponibles
  final List<String> _sections = [
    'BA1',
    'BA2',
    'BA3',
    'MA1 Informatique',
    'MA1 Electronique',
    'MA1 Physique Nucléaire et Médicale',
    'MA1 Chimie',
    'MA1 Electromécanique',
    'MA1 Aéronautique',
    'MA2 Informatique',
    'MA2 Electronique',
    'MA2 Physique Nucléaire et Médicale',
    'MA2 Chimie',
    'MA2 Electromécanique',
    'MA2 Aéronautique',
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
    if (email.isEmpty || password.isEmpty || _selectedSection == null) {
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
          'section': _selectedSection,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final idToken = data['idToken'];
        final role = data['role'];

        // Inscription réussie, rediriger ou traiter le token
        setState(() {
          _message = 'Inscription réussie!';
        });

        // Sauvegarder le token ou utiliser pour l'authentification Firebase si nécessaire

        // Rediriger vers la page d'accueil
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
                value: _selectedSection,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  border: OutlineInputBorder(),
                ),
                items: _sections
                    .map((section) => DropdownMenuItem<String>(
                          value: section,
                          child: Text(section),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSection = value;
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
