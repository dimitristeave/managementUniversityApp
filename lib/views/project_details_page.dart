import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isibappmoodle/reutilisable/app_drawer.dart';
import 'package:isibappmoodle/views/add_project_member_page.dart';
import 'package:isibappmoodle/views/task_detail_page.dart';
import 'package:isibappmoodle/views/notification_service.dart';
import 'package:isibappmoodle/config/config';

class ProjectDetailsPage extends StatefulWidget {
  final String projectId;

  const ProjectDetailsPage({super.key, required this.projectId});

  @override
  _ProjectDetailsPageState createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _assignedToController = TextEditingController();
  final TextEditingController _taskDeadlineController = TextEditingController();
  final TextEditingController _newMemberController = TextEditingController();
  String? _selectedMemberId;
  Map<String, dynamic>? _projectData;
  bool _isLoading = false;
  List<dynamic> _members = [];

  @override
  void initState() {
    super.initState();
    _loadProjectData();
    _loadProjectMembers();
  }

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.sander}/api/projects/${widget.projectId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _projectData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Échec du chargement du projet');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement du projet: $e');
    }
  }

  Future<void> _loadProjectMembers() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.sander}/api/projects/${widget.projectId}/members'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _members = json.decode(response.body);
        });
      } else {
        throw Exception('Échec du chargement des membres');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des membres: $e');
    }
  }

  Future<void> _addTask() async {
    _assignedToController.text = _selectedMemberId ?? '';

    if (!_validateTaskInputs()) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Config.sander}/api/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'projectId': widget.projectId,
          'taskName': _taskController.text,
          'assignedTo': _selectedMemberId,
          'deadline': _taskDeadlineController.text,
          'status': 'En cours',
        }),
      );

      if (response.statusCode == 201) {
        _clearTaskInputs();
        await _loadProjectData();
        _showSuccessSnackBar('Tâche ajoutée avec succès');
      } else {
        throw Exception('Échec de l\'ajout de la tâche');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'ajout de la tâche: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMember() async {
    if (_newMemberController.text.isEmpty) {
      _showErrorSnackBar('Veuillez entrer un nom de membre');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(
            '${Config.sander}/api/projects/${widget.projectId}/addMember'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _newMemberController.text,
        }),
      );

      if (response.statusCode == 200) {
        _newMemberController.clear();
        await _loadProjectMembers();
        _showSuccessSnackBar('Membre ajouté avec succès');
      } else {
        throw Exception('Échec de l\'ajout du membre');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'ajout du membre: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProjectStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('${Config.sander}/api/projects/${widget.projectId}/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        await _loadProjectData();
        _showSuccessSnackBar('Statut du projet mis à jour');
      } else {
        throw Exception('Échec de la mise à jour du statut');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la mise à jour du statut: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateTaskInputs() {
    if (_taskController.text.isEmpty ||
        _assignedToController.text.isEmpty ||
        _taskDeadlineController.text.isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs');
      return false;
    }
    return true;
  }

  void _clearTaskInputs() {
    setState(() {
      _taskController.clear();
      _assignedToController.clear();
      _taskDeadlineController.clear();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
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
      drawer: AppDrawer(),
      appBar: AppBar(
        title: const Text('Détails du projet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjectData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projectData == null
              ? const Center(child: Text('Aucune donnée disponible'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProjectInfo(),
                      const SizedBox(height: 24),
                      _buildTaskForm(),
                      const SizedBox(height: 24),
                      _buildTasksList(),
                      const SizedBox(height: 24),
                      _buildMembersList(),
                      const SizedBox(height: 24),
                      _buildAddMemberForm(),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddProjectMemberPage(projectId: widget.projectId),
            ),
          );
          if (result == true) {
            _loadProjectMembers(); // Recharger la liste des membres
          }
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildProjectInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projet: ${_projectData?['name'] ?? 'Inconnu'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Statut: ${_projectData?['status'] ?? 'Non défini'}'),
            Text('Deadline: ${_projectData?['deadline'] ?? 'Non défini'}'),
            if (_projectData?['status'] == 'En cours')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed: () => _updateProjectStatus('Terminé'),
                  icon: const Icon(Icons.check),
                  label: const Text('Marquer comme terminé'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nouvelle tâche',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _taskController,
              decoration: const InputDecoration(
                labelText: 'Nom de la tâche',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Assigné à',
                border: OutlineInputBorder(),
              ),
              value: _selectedMemberId,
              items: _members.map((member) {
                return DropdownMenuItem<String>(
                  value: member['email'],
                  child: Text(member['email']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMemberId = value;
                  _assignedToController.text = value ?? '';
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _taskDeadlineController,
              decoration: InputDecoration(
                labelText: 'Deadline de la tâche',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(_taskDeadlineController),
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addTask,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter la tâche'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    final tasks = _projectData?['tasks'] as List? ?? [];
    final currentUser = FirebaseAuth.instance.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tâches',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...tasks.map((task) {
          final taskName = task['taskName'] ?? 'Sans nom';
          final deadline = task['deadline'] ?? 'Non définie';
          final assignedTo = task['assignedTo'] ?? 'Non assigné';
          final status = task['status'] ?? 'En cours';
          final taskId =
              task['id'] ?? ''; // Assurez-vous que 'id' existe dans la réponse

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tâche: $taskName',
                      style: const TextStyle(fontSize: 16)),
                  Text('Assigné à: $assignedTo'),
                  Text('Deadline: $deadline'),
                  Text('Statut: $status'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Navigation vers la page TaskDetailPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailPage(
                            taskId: taskId,
                            memberId: assignedTo,
                            currentUserId: currentUser?.uid ?? '',
                          ),
                        ),
                      );
                    },
                    child: const Text('Voir les détails'),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMembersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Membres du projet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._members.map((member) {
          final email = member['email'];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(email),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAddMemberForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ajouter un membre',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newMemberController,
              decoration: const InputDecoration(
                labelText: 'Nom du membre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addMember,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter le membre'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (selectedDate != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }
}
