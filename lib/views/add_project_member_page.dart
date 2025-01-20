import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:isibappmoodle/views/notification_service.dart';
import 'package:isibappmoodle/config/config';

class AddProjectMemberPage extends StatefulWidget {
  final String projectId;

  const AddProjectMemberPage({super.key, required this.projectId});

  @override
  _AddProjectMemberPageState createState() => _AddProjectMemberPageState();
}

class _AddProjectMemberPageState extends State<AddProjectMemberPage> {
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _availableMembers = [];
  String? _selectedEmail;
  String? _projectName;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
    _loadAvailableMembers();
  }

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

  Future<void> _loadProjectData() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.sander}/api/projects/${widget.projectId}'),
      );
      if (response.statusCode == 200) {
        final projectData = json.decode(response.body);
        setState(() {
          _projectName = projectData['name'];
        });
      } else {
        throw Exception('Erreur lors du chargement du projet');
      }
    } catch (e) {
      _showSnackBar('Erreur lors du chargement du projet: $e');
    }
  }

  Future<void> _loadAvailableMembers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.sander}/api/projects/${widget.projectId}/members/available'),
      );

      if (response.statusCode == 200) {
        final List members = json.decode(response.body);
        setState(() {
          _availableMembers = members.map((member) => {
            'email': member['email'],
            'name': member['name'] ?? member['email'] ?? 'Sans nom',
          }).toList();
        });
      } else {
        throw Exception('Échec du chargement des membres disponibles');
      }
    } catch (e) {
      _showSnackBar('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMemberToProject() async {
    if (_selectedEmail == null) {
      _showSnackBar('Veuillez sélectionner un membre');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await http.post(
        Uri.parse('${Config.sander}/api/projects/${widget.projectId}/members'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': _selectedEmail}),
      );

      if (response.statusCode == 200) {
        await NotificationService.showProjectInviteNotification(
          projectName: _projectName ?? 'Projet',
          userEmail: _selectedEmail!,
        );
        _showSnackBar('Membre ajouté avec succès', isError: false);
        Navigator.pop(context, true);
      } else {
        throw Exception('Échec de l\'ajout du membre');
      }
    } catch (e) {
      _showSnackBar('Erreur: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: const Text(
          'Ajouter un membre',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ajouter un nouveau membre",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      if (_projectName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Projet: $_projectName",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Sélectionner un membre",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_availableMembers.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Aucun membre disponible',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Sélectionner un membre',
                                      labelStyle: TextStyle(color: Colors.grey.shade700),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                    value: _selectedEmail,
                                    items: _availableMembers.map((member) {
                                      return DropdownMenuItem<String>(
                                        value: member['email'],
                                        child: Text(member['email']),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _selectedEmail = value);
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _selectedEmail == null || _isSubmitting
                              ? null
                              : _addMemberToProject,
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
                                  'Ajouter au projet',
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
}