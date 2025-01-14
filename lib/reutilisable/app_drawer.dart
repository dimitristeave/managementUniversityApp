import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      // Déconnexion de l'utilisateur via Firebase
      await FirebaseAuth.instance.signOut();

      // Redirection vers la page de connexion
      Navigator.pushReplacementNamed(context, '/auth');
    } catch (e) {
      // Afficher une erreur si la déconnexion échoue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la déconnexion : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/profil');
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Accueil'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Opportunité'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/opportunity');
            },
          ),
          ListTile(
            leading: const Icon(Icons.task),
            title: const Text('Gestion de Projet'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/project_management');
            },
          ),
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: const Text('Ecole Forum'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/help');
            },
          ),
          ListTile(
            leading: const Icon(Icons.network_cell),
            title: const Text('Demander Assistance'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/assistance');
            },
          ),
          ListTile(
            leading: const Icon(Icons.network_cell),
            title: const Text('Suivi Mes Demandes'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/suivi');
            },
          ),
          ListTile(
            leading: const Icon(Icons.network_cell),
            title: const Text('Demandes reçues'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/my_demands');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Se déconnecter'),
            onTap: () async {
              await _logout(context);
            },
          ),
        ],
      ),
    );
  }
}
