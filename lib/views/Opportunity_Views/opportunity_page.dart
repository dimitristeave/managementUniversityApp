import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:isibappmoodle/models/work_model.dart'; // Assurez-vous que la classe Work est correctement importée
import 'package:isibappmoodle/notifications/works_notifications.dart';
import 'package:isibappmoodle/reutilisable/app_drawer.dart';
import 'package:isibappmoodle/views/Opportunity_Views/work_detail_page.dart';
import 'package:isibappmoodle/views/Opportunity_Views/add_opportunity_page.dart';
import 'package:isibappmoodle/views/Opportunity_Views/edit_opportunity_page.dart'; // Import de la page d'édition

class OpportunityPage extends StatefulWidget {
  @override
  _OpportunityPageState createState() => _OpportunityPageState();
}

class _OpportunityPageState extends State<OpportunityPage> {
  bool isLoading = true;
  List<Work> works = [];
  List<Work> filteredWorks = [];
  String errorMessage = '';
  String searchQuery = '';
  String selectedSection = 'Toutes';

  final List<String> sectionsItems = [
    'Toutes',
    'BA1',
    'BA2',
    'BA3',
    'MA1 Informatique',
    'MA1 Electronique',
    'MA1 Physique Nucléaire et Médicale',
    'MA1 Chimie',
    'MA1 Electromécanique',
    'MA1 Aéronautique',
    'MA2 Informatique',
    'MA2 Electronique',
    'MA2 Physique Nucléaire et Médicale',
    'MA2 Chimie',
    'MA2 Electromécanique',
    'MA2 Aéronautique',
  ];

  @override
  void initState() {
    super.initState();
    fetchWorks();
  }

  Future<String> getUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid; // L'ID de l'utilisateur
    } else {
      throw Exception("Utilisateur non connecté");
    }
  }

  // Fonction pour récupérer les opportunités depuis le serveur
  Future<void> fetchWorks() async {
    final String apiUrl = "http://192.168.129.13:3000/works";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          works = data.map((json) => Work.fromJson(json)).toList();
          filteredWorks = works;
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

  // Fonction pour filtrer les opportunités
  void filterWorks() {
    setState(() {
      filteredWorks = works.where((work) {
        final matchesQuery =
            work.company.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesSection =
            selectedSection == 'Toutes' || work.section == selectedSection;
        return matchesQuery && matchesSection;
      }).toList();
    });
  }

  // Fonction pour supprimer une opportunité
  Future<void> _deleteWork(String workId) async {
    final String apiUrl = "http://192.168.129.13:3000/works/$workId";
    try {
      final response = await http.delete(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          works.removeWhere((work) => work.id == workId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opportunité supprimée avec succès.')));
      } else {
        throw Exception('Erreur lors de la suppression.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  bool isSubscribed = false; // Variable pour savoir si l'utilisateur est abonné
  final NotificationService _notificationService = NotificationService();

  void _showSectionSelectionDialog() async {
    // Initialisation locale de la sélection
    Map<String, bool> selectedSections = {
      for (var section in sectionsItems.skip(1)) section: false
    };

    print(selectedSections);

    // Montre le popup
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text("Choisissez les sections"),
              content: SingleChildScrollView(
                child: Column(
                  children: sectionsItems.skip(1).map((section) {
                    return CheckboxListTile(
                      title: Text(section),
                      value: selectedSections[section],
                      onChanged: (bool? value) {
                        // Utiliser le StateSetter du StatefulBuilder
                        setStateDialog(() {
                          selectedSections[section] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Sauvegarde les sections choisies
                    await _saveUserNotificationPreferences(selectedSections);
                    Navigator.pop(context);
                  },
                  child: Text("Enregistrer"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveUserNotificationPreferences(
      Map<String, bool> selectedSections) async {
    final selectedTopics = selectedSections.entries
        .where((entry) => entry.value)
        .map((e) => e.key);

    // Appel backend pour sauvegarder
    final String apiUrl = "http://192.168.129.13:3000/preferences";
    final userId = await getUserId();

    final body = json.encode({
      "userId": userId, // Remplacez par l'ID utilisateur
      "topics": selectedTopics.toList(),
    });

    print(body);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        print("Préférences utilisateur sauvegardées avec succès.");
        // Abonnement aux topics choisis
        await _subscribeToSelectedTopics(selectedTopics);
      } else {
        throw Exception("Erreur lors de la sauvegarde des préférences.");
      }
    } catch (e) {
      print("Erreur : $e");
    }
  }

  Future<void> _subscribeToSelectedTopics(Iterable<String> topics) async {
    for (String topic in topics) {
      await _notificationService.subscribeToSection(topic);
    }

    // Désabonne des topics non sélectionnés
    for (String topic
        in sectionsItems.skip(1).where((item) => !topics.contains(item))) {
      await _notificationService.unsubscribeFromSection(topic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Opportunités'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddOpportunityPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: _showSectionSelectionDialog,
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Rechercher par nom',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 16.0),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                          filterWorks();
                        },
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField(
                        value: selectedSection,
                        items: sectionsItems
                            .map((section) => DropdownMenuItem(
                                  value: section,
                                  child: Text(section),
                                ))
                            .toList(),
                        decoration: InputDecoration(
                          labelText: 'Filtrer par section',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                        ),
                        isExpanded: true,
                        onChanged: (value) {
                          setState(() {
                            selectedSection = value!;
                          });
                          filterWorks();
                        },
                        menuMaxHeight: 300,
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredWorks.length,
                          itemBuilder: (context, index) {
                            final work = filteredWorks[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              child: ListTile(
                                title: Text(
                                  work.company,
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle:
                                    Text('${work.section} - ${work.address}'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          WorkDetailPage(work: work),
                                    ),
                                  );
                                },
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'Modifier') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                EditOpportunityPage(
                                                    work: work)),
                                      ).then((value) {
                                        if (value == true) {
                                          fetchWorks(); // Recharge les données si la modification a réussi
                                        }
                                      });
                                    } else if (value == 'Supprimer') {
                                      _deleteWork(work.id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                        value: 'Modifier',
                                        child: Text('Modifier')),
                                    PopupMenuItem(
                                        value: 'Supprimer',
                                        child: Text('Supprimer')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
