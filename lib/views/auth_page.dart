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
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _message = "L'email et le mot de passe sont requis.";
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
        // Exemple : utiliser ce token pour une authentification Firebase
        // await FirebaseAuth.instance.signInWithCustomToken(idToken);

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
