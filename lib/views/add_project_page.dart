import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:isibappmoodle/reutilisable/app_drawer.dart';
import 'package:intl/intl.dart';
import 'package:isibappmoodle/config/config';

class AddProjectPage extends StatefulWidget {
  const AddProjectPage({super.key});

  @override
  _AddProjectPageState createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDeadline;
  bool _isSubmitting = false;

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF1976D2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _addProject() async {
    if (_nameController.text.isEmpty || _selectedDeadline == null) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.sander}/api/projects'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "name": _nameController.text.trim(),
          "deadline": DateFormat('yyyy-MM-dd').format(_selectedDeadline!),
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        _showSnackBar('Projet ajouté avec succès', isError: false);
        Navigator.pop(context);
      } else {
        throw Exception('Échec de l\'ajout du projet');
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'ajout du projet: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Widget _buildFormField(String label, {TextEditingController? controller}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          floatingLabelStyle: const TextStyle(color: Color(0xFF1976D2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: const Text(
          'Ajouter un projet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1976D2).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nouveau projet",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 24),
                _buildFormField('Nom du projet', controller: _nameController),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(
                      _selectedDeadline == null
                          ? 'Sélectionner une date limite'
                          : 'Date limite: ${DateFormat('dd/MM/yyyy').format(_selectedDeadline!)}',
                      style: TextStyle(
                        color: _selectedDeadline == null
                            ? Colors.grey.shade700
                            : Colors.black,
                      ),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _addProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Ajouter le projet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}