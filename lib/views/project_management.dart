import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isibappmoodle/reutilisable/app_drawer.dart';
import 'package:isibappmoodle/views/add_project_page.dart';
import 'package:isibappmoodle/views/project_details_page.dart';

class ProjectManagementPage extends StatelessWidget {
  const ProjectManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: const Text('Gestion de Projet'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('projects').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final projects = snapshot.data!.docs;
          final ongoingProjects = projects
              .where((project) => project['status'] == 'En cours')
              .toList();
          final completedProjects = projects
              .where((project) => project['status'] == 'Terminé')
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Projets en cours', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: ListView.builder(
                    itemCount: ongoingProjects.length,
                    itemBuilder: (context, index) {
                      final project = ongoingProjects[index];
                      return ListTile(
                        title: Text(project['name']),
                        subtitle: Text('Deadline : ${project['deadline']}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectDetailsPage(
                                projectId: project.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Anciens projets', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: ListView.builder(
                    itemCount: completedProjects.length,
                    itemBuilder: (context, index) {
                      final project = completedProjects[index];
                      return ListTile(
                        title: Text(project['name']),
                        subtitle:
                            Text('Terminé le : ${project['completedDate']}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProjectPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
