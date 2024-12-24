import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
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
          DrawerHeader(
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
            leading: Icon(Icons.home),
            title: Text('Accueil'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading: Icon(Icons.work),
            title: Text('Opportunité'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/opportunity');
            },
          ),
          ListTile(
            leading: Icon(Icons.task),
            title: Text('Gestion de Projet'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/project_management');
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Aide'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/help');
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Se déconnecter'),
            onTap: () async {
              await _logout(context);
            },
          ),
        ],
      ),
    );
  }
}
