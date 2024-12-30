import 'package:flutter/material.dart';
import 'package:isibappmoodle/models/work_model.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkDetailPage extends StatelessWidget {
  final Work work; // Paramètre pour recevoir l'opportunité sélectionnée

  WorkDetailPage({required this.work});

  // Fonction pour lancer l'URL dans le navigateur
  Future<void> _launchURL(String url) async {
    final Uri _url = Uri.parse(url); // Convertir l'URL en Uri
    launchUrl(_url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de l\'opportunité'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(work.company,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                )),
            SizedBox(height: 12),
            Text(
              'Section : ${work.section}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 12),
            Text(
              'Type d\'annonce : ${work.type}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 12),
            Text(
              'Adresse : ${work.address}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 16),
            Text(
              'Description :',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 8),
            Text(
              work.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 16),
            if (work.link
                .isNotEmpty) // Afficher le bouton uniquement si le lien n'est pas vide
              Center(
                child: SizedBox(
                  width: double.infinity, // Le bouton prendra toute la largeur
                  child: ElevatedButton(
                    onPressed: () => _launchURL(work.link),
                    child: Text('Voir l\'offre'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
