import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddOpportunityPage extends StatefulWidget {
  @override
  _AddOpportunityPageState createState() => _AddOpportunityPageState();
}

class _AddOpportunityPageState extends State<AddOpportunityPage> {
  final _formKey = GlobalKey<FormState>();
  String company = '';
  String section = '';
  String address = '';
  String description = '';
  String link = '';
  String type = '';
  bool isSubmitting = false;
  String errorMessage = '';

  final List<String> sectionsItems = [
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

  // Fonction pour envoyer les données au backend
  Future<void> addWork() async {
    final String apiUrl =
        "http://192.168.129.13:3000/works"; // URL de ton backend

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'company': company,
          'type': type,
          'section': section,
          'address': address,
          'description': description,
          'link': link,
        }),
      );

      if (response.statusCode == 201) {
        // Si l'ajout est réussi, on réinitialise le formulaire et on affiche un message
        setState(() {
          isSubmitting = false;
          errorMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opportunité ajoutée avec succès!')));
        Navigator.pop(context); // Retour à la page précédente
      } else {
        setState(() {
          isSubmitting = false;
          errorMessage = 'Erreur lors de l\'ajout de l\'opportunité.';
        });
      }
    } catch (e) {
      setState(() {
        isSubmitting = false;
        errorMessage = 'Erreur de connexion au serveur.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter une opportunité'),
        leading: IconButton(
          icon: Icon(
              Icons.arrow_back), // Flèche pour revenir à la page précédente
          onPressed: () {
            Navigator.pop(context); // Retourner à la page Opportunity
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Entreprise'),
                onChanged: (value) {
                  setState(() {
                    company = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom de l\'entreprise';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField(
                items: [
                  DropdownMenuItem(value: 'Stage', child: Text("stage")),
                  DropdownMenuItem(
                      value: 'Offre d\'emploi', child: Text("Offre d'emploi"))
                ],
                decoration: InputDecoration(labelText: 'Type'),
                onChanged: (value) {
                  setState(() {
                    type = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un type';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField(
                decoration: InputDecoration(labelText: 'Section'),
                menuMaxHeight:
                    300, // Limite la hauteur du menu déroulant à 200 pixels
                items: sectionsItems
                    .map((sec) => DropdownMenuItem(
                          value: sec,
                          child: Text(sec),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    section = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la section';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Ville'),
                onChanged: (value) {
                  setState(() {
                    address = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la ville';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                onChanged: (value) {
                  setState(() {
                    description = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la description';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Lien'),
                onChanged: (value) {
                  setState(() {
                    link = value;
                  });
                },
              ),
              SizedBox(height: 16),
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            isSubmitting = true;
                          });
                          addWork(); // Appel de la fonction pour ajouter l'opportunité
                        }
                      },
                child: isSubmitting
                    ? CircularProgressIndicator()
                    : Text('Ajouter l\'opportunité'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
