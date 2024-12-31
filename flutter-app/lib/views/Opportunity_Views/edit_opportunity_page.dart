import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:isibappmoodle/config/config';
import 'dart:convert';

import 'package:isibappmoodle/models/work_model.dart';

class EditOpportunityPage extends StatefulWidget {
  final Work work;
  final String uid;

  EditOpportunityPage({
    required this.work,
    required this.uid,
  });

  @override
  _EditOpportunityPageState createState() => _EditOpportunityPageState();
}

class _EditOpportunityPageState extends State<EditOpportunityPage> {
  final _formKey = GlobalKey<FormState>();
  late String company, section, address, description, link, type;

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

  @override
  void initState() {
    super.initState();
    company = widget.work.company;
    section = widget.work.section;
    address = widget.work.address;
    description = widget.work.description;
    link = widget.work.link;
    type = widget.work.type;
  }

  Future<void> updateWork() async {
    final String apiUrl = "${Config.sander}/works/${widget.work.id}";

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Uid': widget.uid,
        },
        body: json.encode({
          'company': company,
          'section': section,
          'address': address,
          'description': description,
          'link': link,
          'type': type,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opportunité mise à jour avec succès!')));
        Navigator.pop(context, true);
      } else {
        throw Exception('Erreur lors de la mise à jour.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Modifier une opportunité')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Champ pour l'entreprise
              TextFormField(
                initialValue: company,
                decoration: InputDecoration(labelText: 'Entreprise'),
                onChanged: (value) => company = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le champ Entreprise est requis';
                  }
                  return null;
                },
              ),
              // Champ pour la section avec la sélection initiale
              DropdownButtonFormField(
                value: section, // Définir la valeur initiale
                decoration: InputDecoration(labelText: 'Section'),
                menuMaxHeight: 300, // Limite la hauteur du menu déroulant
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
              // Champ pour l'adresse
              TextFormField(
                initialValue: address,
                decoration: InputDecoration(labelText: 'Adresse'),
                onChanged: (value) => address = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le champ Adresse est requis';
                  }
                  return null;
                },
              ),
              // Champ pour la description
              TextFormField(
                initialValue: description,
                decoration: InputDecoration(labelText: 'Description'),
                onChanged: (value) => description = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le champ Description est requis';
                  }
                  return null;
                },
              ),
              // Champ pour le lien
              TextFormField(
                initialValue: link,
                decoration: InputDecoration(labelText: 'Lien'),
                onChanged: (value) => link = value,
              ),
              // Champ pour le type avec la sélection initiale
              DropdownButtonFormField(
                value: type, // Définir la valeur initiale
                items: [
                  DropdownMenuItem(value: 'Stage', child: Text("Stage")),
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
              // Bouton pour mettre à jour
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    updateWork();
                  }
                },
                child: Text('Mettre à jour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
