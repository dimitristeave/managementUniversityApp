import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isibappmoodle/reutilisable/app_drawer.dart';

class ProjectDetailsPage extends StatefulWidget {
  final String projectId;

  const ProjectDetailsPage({super.key, required this.projectId});

  @override
  _ProjectDetailsPageState createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _memberController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _taskDeadlineController = TextEditingController();

  Future<void> _addTask() async {
    if (_taskController.text.isNotEmpty &&
        _taskDeadlineController.text.isNotEmpty) {
      await _firestore.collection('tasks').add({
        'projectId': widget.projectId,
        'task': _taskController.text,
        'assignedTo': _memberController.text,
        'deadline': _taskDeadlineController.text,
        'status': 'Pending',
      });

      _taskController.clear();
      _taskDeadlineController.clear();
      _memberController.clear();
    }
  }

  Future<void> _updateProjectStatus(String newStatus) async {
    await _firestore.collection('projects').doc(widget.projectId).update({
      'status': newStatus,
      'completedDate':
          newStatus == 'Terminé' ? DateTime.now().toString() : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(title: const Text('Détails du projet')),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            _firestore.collection('projects').doc(widget.projectId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final project = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Nom du projet: ${project['name']}'),
                Text('Statut: ${project['status']}'),
                Text('Deadline: ${project['deadline']}'),
                if (project['status'] == 'En cours')
                  ElevatedButton(
                    onPressed: () => _updateProjectStatus('Terminé'),
                    child: const Text('Marquer comme terminé'),
                  ),
                const SizedBox(height: 20),
                // Ajout de membre et tâche
                TextField(
                  controller: _memberController,
                  decoration: const InputDecoration(labelText: 'Nom du membre'),
                ),
                TextField(
                  controller: _taskController,
                  decoration:
                      const InputDecoration(labelText: 'Nom de la tâche'),
                ),
                TextField(
                  controller: _taskDeadlineController,
                  decoration:
                      const InputDecoration(labelText: 'Deadline de la tâche'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Ajouter une tâche'),
                ),
                const SizedBox(height: 20),
                // Liste des tâches
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('tasks')
                        .where('projectId', isEqualTo: widget.projectId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final tasks = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return ListTile(
                            title: Text(task['task']),
                            subtitle: Text(
                              'Assigné à : ${task['assignedTo']}\nDeadline : ${task['deadline']}',
                            ),
                            trailing: Text(task['status']),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
