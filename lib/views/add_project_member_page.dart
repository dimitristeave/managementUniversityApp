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
  List<Map<String, dynamic>> _availableMembers = [];
  String? _selectedEmail;
  String? _projectName;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
    _loadAvailableMembers();
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
      }
    } catch (e) {
      print('Erreur lors du chargement du projet: $e');
    }
  }

  Future<void> _loadAvailableMembers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
            '${Config.sander}/projects/${widget.projectId}/members/available'),
      );

      if (response.statusCode == 200) {
        final List members = json.decode(response.body);
        setState(() {
          _availableMembers = members
              .map((member) => {
                    'email': member['email'],
                    'name': member['name'] ?? member['email'] ?? 'Sans nom',
                  })
              .toList();
        });
      } else {
        throw Exception('Échec du chargement des membres disponibles');
      }
    } catch (e) {
      _showErrorMessage('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMemberToProject() async {
    if (_selectedEmail == null) {
      _showErrorMessage('Veuillez sélectionner un membre');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Config.sander}/api/projects/${widget.projectId}/members'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': _selectedEmail}),
      );

      if (response.statusCode == 200) {
        // Récupérer le nom du projet
        final projectResponse = await http.get(
          Uri.parse('${Config.sander}/api/projects/${widget.projectId}'),
        );

        if (projectResponse.statusCode == 200) {
          final projectData = json.decode(projectResponse.body);
          await NotificationService.showProjectInviteNotification(
            projectName: projectData['name'],
            userEmail: _selectedEmail!,
          );
        }

        _showSuccessMessage('Membre ajouté avec succès');
        Navigator.pop(context, true);
      } else {
        throw Exception('Échec de l\'ajout du membre');
      }
    } catch (e) {
      _showErrorMessage('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un membre au projet'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sélectionner un membre',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          if (_availableMembers.isEmpty)
                            const Text('Aucun membre disponible')
                          else
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Membre',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedEmail,
                              items: _availableMembers.map((member) {
                                return DropdownMenuItem<String>(
                                  value: member['email'],
                                  child: Text(member['email']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedEmail = value;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        _selectedEmail != null ? _addMemberToProject : null,
                    child: const Text('Ajouter au projet'),
                  ),
                ],
              ),
            ),
    );
  }
}
