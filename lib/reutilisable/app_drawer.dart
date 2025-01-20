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
      child: Container(
        color: Colors.white, // Couleur de fond blanc
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1976D2), // Bleu principal
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.menu,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Moodle Isib',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person_outline,
              text: 'Profil',
              onTap: () => Navigator.pushReplacementNamed(context, '/profil'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.home_outlined,
              text: 'Accueil',
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.business_center_outlined,
              text: 'Opportunité',
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/opportunity'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.task_alt_outlined,
              text: 'Gestion de Projet',
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/project_management'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.forum_outlined,
              text: 'Ecole Forum',
              onTap: () => Navigator.pushReplacementNamed(context, '/help'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.support_agent_outlined,
              text: 'Demander Assistance',
              onTap: () => Navigator.pushReplacementNamed(context, '/assistance'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.track_changes_outlined,
              text: 'Suivi Mes Demandes',
              onTap: () => Navigator.pushReplacementNamed(context, '/suivi'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.inbox_outlined,
              text: 'Demandes reçues',
              onTap: () => Navigator.pushReplacementNamed(context, '/my_demands'),
            ),
            const Divider(), // Ligne de séparation
            _buildDrawerItem(
              context,
              icon: Icons.logout_outlined,
              text: 'Se déconnecter',
              onTap: () async => await _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1976D2)), // Icône bleue
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87, // Texte noir
        ),
      ),
      onTap: onTap,
    );
  }
}
