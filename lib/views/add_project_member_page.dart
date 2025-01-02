import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddProjectMemberPage extends StatefulWidget {
  final String projectId;

  const AddProjectMemberPage({Key? key, required this.projectId})
      : super(key: key);

  @override
  _AddProjectMemberPageState createState() => _AddProjectMemberPageState();
}

class _AddProjectMemberPageState extends State<AddProjectMemberPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableMembers = [];
  String? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    _loadAvailableMembers();
  }

  Future<void> _loadAvailableMembers() async {
    setState(() => _isLoading = true);
    try {
      // Charger la liste des membres disponibles
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:3000/api/members/available/${widget.projectId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _availableMembers = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      _showErrorMessage('Erreur lors du chargement des membres: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMemberToProject() async {
    if (_selectedMemberId == null) {
      _showErrorMessage('Veuillez sélectionner un membre');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(
            'http://10.0.2.2:3000/api/projects/${widget.projectId}/members'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'memberId': _selectedMemberId,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true);
        _showSuccessMessage('Membre ajouté avec succès');
      } else {
        throw Exception('Échec de l\'ajout du membre');
      }
    } catch (e) {
      _showErrorMessage('Erreur lors de l\'ajout du membre: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                              value: _selectedMemberId,
                              items: _availableMembers.map((member) {
                                return DropdownMenuItem<String>(
                                  value: member['id'],
                                  child: Text(
                                      '${member['name']} (${member['email']})'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedMemberId = value;
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
                        _selectedMemberId != null ? _addMemberToProject : null,
                    child: const Text('Ajouter au projet'),
                  ),
                ],
              ),
            ),
    );
  }
}
