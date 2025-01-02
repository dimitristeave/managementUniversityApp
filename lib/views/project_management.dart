import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:isibappmoodle/reutilisable/app_drawer.dart';
import 'package:isibappmoodle/views/add_project_page.dart';
import 'package:isibappmoodle/views/project_details_page.dart';

class ProjectManagementPage extends StatefulWidget {
  const ProjectManagementPage({super.key});

  @override
  _ProjectManagementPageState createState() => _ProjectManagementPageState();
}

class _ProjectManagementPageState extends State<ProjectManagementPage> {
  List<dynamic> ongoingProjects = [];
  List<dynamic> completedProjects = [];

  Future<void> fetchProjects() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2:3000/api/projects'));

    if (response.statusCode == 200) {
      final List<dynamic> projects = json.decode(response.body);
      setState(() {
        ongoingProjects = projects
            .where((project) => project['status'] == 'En cours')
            .toList();
        completedProjects = projects
            .where((project) => project['status'] == 'Terminé')
            .toList();
      });
    } else {
      throw Exception('Failed to load projects');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text('Gestion de Projet'),
      ),
      body: ongoingProjects.isEmpty && completedProjects.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Projets en cours',
                      style: TextStyle(fontSize: 18)),
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
                                  projectId: project['id'],
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
