import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isibappmoodle/reutilisable/app_drawer.dart';

class AddProjectPage extends StatefulWidget {
  const AddProjectPage({super.key});

  @override
  _AddProjectPageState createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addProject() async {
    if (_nameController.text.isNotEmpty &&
        _deadlineController.text.isNotEmpty) {
      await _firestore.collection('projects').add({
        'name': _nameController.text,
        'status': 'En cours', // Statut initial
        'deadline': _deadlineController.text,
        'completedDate':
            null, // La date de complétion est null tant que le projet n'est pas terminé
      });

      Navigator.pop(context); // Retour à la page précédente après l'ajout
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
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom du projet'),
            ),
            TextField(
              controller: _deadlineController,
              decoration: const InputDecoration(labelText: 'Date limite'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addProject,
              child: const Text('Ajouter le projet'),
            ),
          ],
        ),
      ),
    );
  }
}
