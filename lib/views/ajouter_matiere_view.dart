import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:isibappmoodle/config/config';

class AddSubjectForm extends StatefulWidget {
  const AddSubjectForm({super.key});

  @override
  _AddSubjectFormState createState() => _AddSubjectFormState();
}

class _AddSubjectFormState extends State<AddSubjectForm> {
  final _formKey = GlobalKey<FormState>();
  String? selectedClass;
  String? selectedFiliere;
  bool _isSubmitting = false;

  final List<String> classes = [
    "BAC 1",
    "BAC 2",
    "BAC 3",
    "Bloc C",
    "Master 1",
    "Master 2"
  ];

  final List<String> filieres = [
    "Commun",
    "Info",
    "Electronique",
    "Mécanique",
    "Physique Nucléaire",
    "Chimie",
    "Electricité"
  ];

  final TextEditingController subjectNameController = TextEditingController();
  final TextEditingController subjectIdController = TextEditingController();
  final TextEditingController professorNameController = TextEditingController();

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

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final Map<String, dynamic> data = {
        "classe": selectedClass,
        "filiere": selectedFiliere,
        "nom_matiere": subjectNameController.text.trim(),
        "id_matiere": subjectIdController.text.trim(),
        "nom_prof": professorNameController.text.trim(),
      };

      final response = await http.post(
        Uri.parse("${Config.sander}/addSubject"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Matière ajoutée avec succès !", isError: false);
        _formKey.currentState!.reset();
        setState(() {
          selectedClass = null;
          selectedFiliere = null;
          subjectNameController.clear();
          subjectIdController.clear();
          professorNameController.clear();
        });
      } else {
        throw Exception("Erreur lors de l'ajout : ${response.body}");
      }
    } catch (e) {
      _showSnackBar("Erreur lors de l'ajout de la matière: $e");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
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
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          floatingLabelStyle: const TextStyle(color: Color(0xFF1976D2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          errorStyle: const TextStyle(color: Colors.red),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
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
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          errorStyle: const TextStyle(color: Colors.red),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: const Text(
          "Ajouter une Matière",
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Informations de la matière",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDropdown(
                    label: "Classe",
                    value: selectedClass,
                    items: classes,
                    onChanged: (value) => setState(() => selectedClass = value),
                    validator: (value) => value == null ? "Veuillez choisir une classe" : null,
                  ),
                  _buildDropdown(
                    label: "Filière",
                    value: selectedFiliere,
                    items: filieres,
                    onChanged: (value) => setState(() => selectedFiliere = value),
                    validator: (value) => value == null ? "Veuillez choisir une filière" : null,
                  ),
                  _buildFormField(
                    label: "Nom de la matière",
                    controller: subjectNameController,
                    validator: (value) => value?.isEmpty ?? true
                        ? "Veuillez entrer le nom de la matière"
                        : null,
                  ),
                  _buildFormField(
                    label: "ID de la matière",
                    controller: subjectIdController,
                    validator: (value) => value?.isEmpty ?? true
                        ? "Veuillez entrer l'ID de la matière"
                        : null,
                  ),
                  _buildFormField(
                    label: "Nom du professeur",
                    controller: professorNameController,
                    validator: (value) => value?.isEmpty ?? true
                        ? "Veuillez entrer le nom du professeur"
                        : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : submitForm,
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
                              'Ajouter la matière',
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
      ),
    );
  }

  @override
  void dispose() {
    subjectNameController.dispose();
    subjectIdController.dispose();
    professorNameController.dispose();
    super.dispose();
  }
}