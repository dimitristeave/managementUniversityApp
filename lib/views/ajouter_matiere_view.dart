import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:isibappmoodle/config/config';

class AddSubjectForm extends StatefulWidget {
  @override
  _AddSubjectFormState createState() => _AddSubjectFormState();
}

class _AddSubjectFormState extends State<AddSubjectForm> {
  final _formKey = GlobalKey<FormState>();

  // Dropdown values
  String? selectedClass;
  String? selectedFiliere;

  // Classes disponibles
  final List<String> classes = [
    "BAC 1",
    "BAC 2",
    "BAC 3",
    "Bloc C",
    "Master 1",
    "Master 2"
  ];

  // Filières disponibles
  final List<String> filieres = [
    "Commun",
    "Info",
    "Electronique",
    "Mécanique",
    "Physique Nucléaire",
    "Chimie",
    "Electricité"
  ];

  // Controllers pour les champs texte
  final TextEditingController subjectNameController = TextEditingController();
  final TextEditingController subjectIdController = TextEditingController();
  final TextEditingController professorNameController = TextEditingController();

  @override
  void dispose() {
    subjectNameController.dispose();
    professorNameController.dispose();
    super.dispose();
  }

  // Fonction pour soumettre le formulaire
  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Récupération des données du formulaire
      final String subjectName = subjectNameController.text.trim();
      final String subjectId = subjectIdController.text.trim();
      final String professorName = professorNameController.text.trim();

      // Construction des données pour l'API
      final Map<String, dynamic> data = {
        "classe": selectedClass,
        "filiere": selectedFiliere,
        "nom_matiere": subjectName,
        "id_matiere": subjectId,
        "nom_prof": professorName,
      };

      try {
        // Envoi des données via une requête POST
        final response = await http.post(
          Uri.parse("${Config.sander}/addSubject"), // URL de l'API
          headers: {"Content-Type": "application/json"},
          body: json.encode(data),
          
        );
        print(data);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Matière ajoutée avec succès !")),
          );
          // Réinitialiser le formulaire
          _formKey.currentState!.reset();
          setState(() {
            selectedClass = null;
            selectedFiliere = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur lors de l'ajout : ${response.body}")),
          );
        }
      } catch (e) {
        print("Erreur lors de l'envoi : $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec de la connexion au serveur.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajouter une Matière"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown pour la classe
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Classe",
                    border: OutlineInputBorder(),
                  ),
                  value: selectedClass,
                  items: classes.map((String className) {
                    return DropdownMenuItem<String>(
                      value: className,
                      child: Text(className),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedClass = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? "Veuillez choisir une classe" : null,
                ),
                SizedBox(height: 16),

                // Dropdown pour la filière
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Filière",
                    //border: OutlineInputBorder(),
                  ),
                  value: selectedFiliere,
                  items: filieres.map((String filiereName) {
                    return DropdownMenuItem<String>(
                      value: filiereName,
                      child: Text(filiereName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFiliere = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? "Veuillez choisir une filière" : null,
                ),
                SizedBox(height: 16),

                // Champ pour le nom de la matière
                TextFormField(
                  controller: subjectNameController,
                  decoration: InputDecoration(
                    labelText: "Nom de la matière",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? "Veuillez entrer un nom de matière"
                          : null,
                ),
                SizedBox(height: 16),

                // Champ pour l id de la matiere
                TextFormField(
                  controller: subjectIdController,
                  decoration: InputDecoration(
                    labelText: "ID de la matiere",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? "Veuillez entrer l'ID de la matiere"
                          : null,
                ),
                SizedBox(height: 16),

                // Champ pour le nom du professeur
                TextFormField(
                  controller: professorNameController,
                  decoration: InputDecoration(
                    labelText: "Nom du professeur",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? "Veuillez entrer un nom de professeur"
                          : null,
                ),
                SizedBox(height: 24),

                // Bouton de soumission
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitForm,
                    child: Text("Ajouter"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
