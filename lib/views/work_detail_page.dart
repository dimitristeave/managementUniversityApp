import 'package:flutter/material.dart';
import 'package:isibappmoodle/models/work_model..dart';
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium // headline5 est encore valide
                ),
            SizedBox(height: 8),
            Text(
              'Section: ${work.section}',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge, // Remplacer bodyText1 par bodyLarge
            ),
            SizedBox(height: 8),
            Text(
              'Adresse: ${work.address}',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge, // Remplacer bodyText1 par bodyLarge
            ),
            SizedBox(height: 16),
            Text(
              'Description:',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium, // Remplacer bodyText2 par bodyMedium
            ),
            SizedBox(height: 8),
            Text(
              work.description,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge, // Remplacer bodyText1 par bodyLarge
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _launchURL(work.link),
              child: Text('Voir l\'offre'),
            ),
          ],
        ),
      ),
    );
  }
}
