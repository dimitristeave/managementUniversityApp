import 'package:flutter/material.dart';
import 'package:isibappmoodle/views/ajouter_matiere_view.dart';
import 'package:isibappmoodle/views/matiere_par_classe_view.dart';

class HomeShareFile extends StatelessWidget {
  // Liste des classes
  final List<String> classes = [
    "BAC 1",
    "BAC 2",
    "BAC 3",
    "Bloc C",
    "Master 1",
    "Master 2"
  ];

  // Liste des filières pour les Masters
  final List<String> filieres = [
    "Info",
    "Electronique",
    "Mécanique",
    "Physique Nucléaire",
    "Chimie",
    "Electricité"
  ];

  void showFilieresDialog(BuildContext context, String className) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Choisissez une filière"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: filieres.map((filiere) {
              return ListTile(
                title: Text(filiere),
                onTap: () {
                  Navigator.pop(context); // Ferme le dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectsPage(
                        className: className,
                        filiere: filiere,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ShareFile - Accueil'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Ajouter une matière',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddSubjectForm(), // Navigue vers le formulaire
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Nombre de colonnes
            crossAxisSpacing: 16, // Espace entre colonnes
            mainAxisSpacing: 16, // Espace entre les rangées
          ),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                if (classes[index] == "Master 1" ||
                    classes[index] == "Master 2") {
                  // Affiche le dialog pour choisir une filière
                  showFilieresDialog(context, classes[index]);
                } else {
                  // Navigation directe pour les autres classes
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectsPage(
                          className: classes[index], filiere: filieres[index]),
                    ),
                  );
                }
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    classes[index],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
