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
  bool _isSubmitting = false;
  List<dynamic> _members = [];

  @override
  void initState() {
    super.initState();
    _loadProjectData();
    _loadProjectMembers();
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
      _showSnackBar('Erreur lors du chargement du projet: $e');
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
      _showSnackBar('Erreur lors du chargement des membres: $e');
    }
  }

  Future<void> _addTask() async {
    if (!_validateTaskInputs()) return;

    setState(() => _isSubmitting = true);
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
        _showSnackBar('Tâche ajoutée avec succès', isError: false);
      } else {
        throw Exception('Échec de l\'ajout de la tâche');
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'ajout de la tâche: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _addMember() async {
    if (_newMemberController.text.isEmpty) {
      _showSnackBar('Veuillez entrer un email');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await http.post(
        Uri.parse('${Config.sander}/api/projects/${widget.projectId}/addMember'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _newMemberController.text,
        }),
      );

      if (response.statusCode == 200) {
        _newMemberController.clear();
        await _loadProjectMembers();
        _showSnackBar('Membre ajouté avec succès', isError: false);
      } else {
        throw Exception('Échec de l\'ajout du membre');
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'ajout du membre: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateProjectStatus(String newStatus) async {
    setState(() => _isSubmitting = true);
    try {
      final response = await http.put(
        Uri.parse('${Config.sander}/api/projects/${widget.projectId}/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        await _loadProjectData();
        _showSnackBar('Statut du projet mis à jour', isError: false);
      } else {
        throw Exception('Échec de la mise à jour du statut');
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la mise à jour du statut: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  bool _validateTaskInputs() {
    if (_taskController.text.isEmpty ||
        _selectedMemberId == null ||
        _taskDeadlineController.text.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs');
      return false;
    }
    return true;
  }

  void _clearTaskInputs() {
    setState(() {
      _taskController.clear();
      _selectedMemberId = null;
      _taskDeadlineController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Text(
          'Projet: ${_projectData?['name'] ?? 'Chargement...'}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProjectData,
            tooltip: 'Rafraîchir',
          ),
        ],
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
        child: _buildMainContent(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddProjectMemberPage(projectId: widget.projectId),
            ),
          );
          if (result == true) {
            _loadProjectMembers();
          }
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
        ),
      );
    }

    if (_projectData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Color(0xFF1976D2),
            ),
            const SizedBox(height: 16),
            const Text(
              "Aucune donnée disponible",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadProjectData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Réessayer",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
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
    );
  }

  Widget _buildProjectInfo() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: const Color(0xFF1976D2).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Informations du projet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Statut', _projectData?['status'] ?? 'Non défini'),
            const SizedBox(height: 8),
            _buildInfoRow('Deadline', _projectData?['deadline'] ?? 'Non défini'),
            if (_projectData?['status'] == 'En cours') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _updateProjectStatus('Terminé'),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Mise à jour...' : 'Marquer comme terminé',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildTaskForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: const Color(0xFF1976D2).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nouvelle tâche",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 24),
            _buildFormField(
              "Nom de la tâche",
              controller: _taskController,
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedMemberId,
                decoration: InputDecoration(
                  labelText: 'Assigné à',
                  labelStyle: TextStyle(color: Colors.grey.shade700),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: _members.map((member) {
                  return DropdownMenuItem<String>(
                    value: member['email'],
                    child: Text(member['email']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedMemberId = value);
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _addTask,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'Ajout en cours...' : 'Ajouter la tâche',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(
    String label, {
    TextEditingController? controller,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
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

  Widget _buildDateField() {
    return _buildFormField(
      'Date limite',
      controller: _taskDeadlineController,
      readOnly: true,
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
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
          setState(() {
            _taskDeadlineController.text =
                DateFormat('yyyy-MM-dd').format(picked);
          });
        }
      },
    );
  }

  Widget _buildTasksList() {
    final tasks = _projectData?['tasks'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tâches",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 16),
        if (tasks.isEmpty)
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: Color(0xFF1976D2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucune tâche pour le moment',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskItem(task);
            },
          ),
      ],
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final taskId = task['id'] ?? '';
    final status = task['status'] ?? 'En cours';
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF1976D2).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            task['taskName'] ?? 'Sans nom',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Assigné à: ${task['assignedTo'] ?? 'Non assigné'}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              Text(
                'Date limite: ${task['deadline'] ?? 'Non définie'}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status == 'Terminé'
                  ? Colors.green.withOpacity(0.1)
                  : const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: status == 'Terminé'
                    ? Colors.green
                    : const Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailPage(
                            taskId: taskId,
                            memberId: task['assignedTo'] ?? '',
                            currentUserId: currentUser?.uid ?? '',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, color: Colors.white),
                    label: const Text(
                      'Voir les détails',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Membres du projet",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 16),
        if (_members.isEmpty)
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.group_outlined,
                  size: 48,
                  color: Color(0xFF1976D2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucun membre pour le moment',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              return _buildMemberItem(member);
            },
          ),
      ],
    );
  }

  Widget _buildMemberItem(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
            child: Text(
              member['email'].toString().substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member['email'] ?? '',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMemberForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: const Color(0xFF1976D2).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ajouter un membre",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 24),
            _buildFormField(
              "Email du membre",
              controller: _newMemberController,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _addMember,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.person_add, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'Ajout en cours...' : 'Ajouter le membre',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    _assignedToController.dispose();
    _taskDeadlineController.dispose();
    _newMemberController.dispose();
    super.dispose();
  }
}