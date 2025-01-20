import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isibappmoodle/config/config';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String email = '';
  String classe = '';
  String filiere = '';
  String role = '';
  String photoURL = '';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final response =
          await http.get(Uri.parse('${Config.sander}/user/${user.uid}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          email = data['email'] ?? '';
          classe = data['classe'] ?? '';
          filiere = data['filiere'] ?? '';
          role = data['role'] ?? '';
          photoURL = data['photoURL'] ?? '';
        });
      } else {
        print(
            'Erreur lors de la récupération des données utilisateur : ${response.statusCode}');
      }
    }
  }

  Future<void> _changeProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final User? user = _auth.currentUser;
      if (user != null) {
        final request = http.MultipartRequest(
            'POST', Uri.parse('${Config.sander}/user/${user.uid}/photo'));
        request.files
            .add(await http.MultipartFile.fromPath('photo', image.path));
        final response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final decodedData = jsonDecode(responseData);
          setState(() {
            photoURL = decodedData['photoURL'];
          });
        } else {
          print(
              'Erreur lors du changement de photo de profil : ${response.statusCode}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        title: const Text(
          'Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1976D2).withOpacity(0.2),
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 75,
                    backgroundImage:
                        photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                    backgroundColor: Colors.grey.shade50,
                    child: photoURL.isEmpty
                        ? const Icon(Icons.person,
                            size: 75, color: Color(0xFF1976D2))
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _changeProfilePhoto,
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'Changer la photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: const Color(0xFF1976D2).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem('Email', email),
                        const SizedBox(height: 16),
                        _buildInfoItem('Classe', classe),
                        const SizedBox(height: 16),
                        _buildInfoItem('Filière', filiere),
                        const SizedBox(height: 16),
                        _buildInfoItem('Rôle', role),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1976D2),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.isEmpty ? 'Non spécifié' : value,
            style: TextStyle(
              fontSize: 16,
              color: value.isEmpty ? Colors.grey : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}