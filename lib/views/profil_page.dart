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

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        title: const Text('Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 75,
                backgroundImage:
                    photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                child: photoURL.isEmpty
                    ? const Icon(Icons.person, size: 75)
                    : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _changeProfilePhoto,
                icon: const Icon(Icons.edit),
                label: const Text('Changer la photo'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              const SizedBox(height: 30),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Email:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(email, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      const Text('Classe:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(classe, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      const Text('Filière:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(filiere, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      const Text('Rôle:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(role, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
