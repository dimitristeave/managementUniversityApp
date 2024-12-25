import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:isibappmoodle/models/work_model..dart';
import 'package:isibappmoodle/reutilisable/app_drawer.dart';
import 'package:isibappmoodle/views/work_detail_page.dart'; // Import de la page de détail du travail
import 'package:isibappmoodle/views/add_opportunity_page.dart';
import 'package:url_launcher/url_launcher.dart'; // Import de la page d'ajout d'opportunité

class OpportunityPage extends StatefulWidget {
  @override
  _OpportunityPageState createState() => _OpportunityPageState();
}

class _OpportunityPageState extends State<OpportunityPage> {
  bool isLoading = true;
  List<Work> works = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchWorks(); // Charge les opportunités dès le lancement
  }

  // Fonction pour récupérer les opportunités depuis le serveur
  Future<void> fetchWorks() async {
    final String apiUrl =
        "http://192.168.129.13:3000/works"; // Remplacez par l'URL de votre serveur

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          works = data.map((json) => Work.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Erreur lors de la récupération des opportunités.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion au serveur.';
        isLoading = false;
      });
    }
  }

  // Fonction pour lancer l'URL dans le navigateur
  Future<void> _launchURL(String url) async {
    final Uri _url = Uri.parse(url); // Convertir l'URL en Uri
    launchUrl(_url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Opportunité'),
        actions: [
          // Ajouter un bouton "Ajouter une opportunité" dans la AppBar
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Naviguer vers la page d'ajout d'opportunité
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddOpportunityPage()),
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : ListView.builder(
                  itemCount: works.length,
                  itemBuilder: (context, index) {
                    final work = works[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(work.company),
                        subtitle: Text('${work.section} - ${work.address}'),
                        onTap: () {
                          // Naviguer vers la page de détails lorsque l'on clique sur une offre
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkDetailPage(work: work),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
