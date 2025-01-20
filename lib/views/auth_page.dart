import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:isibappmoodle/config/config';
import 'package:isibappmoodle/views/home_share_file_view.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _selectedClasse;
  String? _selectedFiliere;

  final List<String> _classe = [
    "BAC 1", "BAC 2", "BAC 3", "Bloc C", "Master 1", "Master 2"
  ];

  final List<String> _filiere = [
    "Commun", "Info", "Electronique", "Mécanique", 
    "Physique Nucléaire", "Chimie", "Electricité"
  ];

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF1976D2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      _showSnackBar('Connexion réussie!', isError: false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeShareFile()),
      );
    } catch (e) {
      _showSnackBar('Erreur de connexion: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _selectedClasse == null ||
        _selectedFiliere == null) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("${Config.sander}/signup"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
          'classe': _selectedClasse,
          'filiere': _selectedFiliere,
        }),
      );

      if (response.statusCode == 201) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;
        _showSnackBar('Inscription réussie!', isError: false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeShareFile()),
        );
      } else {
        throw Exception("Erreur d'inscription : ${response.body}");
      }
    } catch (e) {
      _showSnackBar('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            isPassword ? Icons.lock_outline : Icons.email_outlined,
            color: Colors.grey.shade600,
          ),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          floatingLabelStyle: const TextStyle(color: Color(0xFF1976D2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF1976D2)),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1976D2).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo ou image ici si nécessaire
                Icon(
                  Icons.school,
                  size: 64,
                  color: const Color(0xFF1976D2),
                ),
                const SizedBox(height: 24),
                Text(
                  _isLogin ? 'Connexion' : 'Inscription',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildFormField(
                  label: 'Email',
                  controller: _emailController,
                ),
                _buildFormField(
                  label: 'Mot de passe',
                  controller: _passwordController,
                  isPassword: true,
                ),
                if (!_isLogin) ...[
                  _buildDropdown(
                    label: 'Classe',
                    value: _selectedClasse,
                    items: _classe,
                    onChanged: (value) => setState(() => _selectedClasse = value),
                  ),
                  _buildDropdown(
                    label: 'Filière',
                    value: _selectedFiliere,
                    items: _filiere,
                    onChanged: (value) => setState(() => _selectedFiliere = value),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : (_isLogin ? _signIn : _signUp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isLogin ? 'Se connecter' : 'S\'inscrire',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? 'Pas encore de compte ? Inscrivez-vous'
                        : 'Vous avez un compte ? Connectez-vous',
                    style: const TextStyle(color: Color(0xFF1976D2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}