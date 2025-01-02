import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:isibappmoodle/reutilisable/app_drawer.dart';
import 'package:intl/intl.dart'; // Pour formater la date

class AddProjectPage extends StatefulWidget {
  const AddProjectPage({super.key});

  @override
  _AddProjectPageState createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDeadline; // Variable pour stocker la date sélectionnée

  Future<void> _addProject() async {
    final name = _nameController.text;
    final deadline = _selectedDeadline != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDeadline!)
        : '';

    if (name.isNotEmpty && deadline.isNotEmpty) {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/projects'),
        headers: {'Content-Type': 'application/json'},
        body: '{"name": "$name", "deadline": "$deadline"}',
      );

      if (response.statusCode == 201) {
        Navigator.pop(context); // Retour à la page précédente après l'ajout
      } else {
        // Gestion d'erreur
        print('Failed to add project');
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Date initiale (aujourd'hui)
      firstDate: DateTime(2000), // Première date sélectionnable
      lastDate: DateTime(2101), // Dernière date sélectionnable
    );

    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked; // Mise à jour de la date sélectionnée
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(title: const Text('Ajouter un projet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom du projet'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDeadline != null
                        ? 'Date limite : ${DateFormat('yyyy-MM-dd').format(_selectedDeadline!)}'
                        : 'Date de fin',
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Sélectionner une date'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _addProject,
                child: const Text('Ajouter le projet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
