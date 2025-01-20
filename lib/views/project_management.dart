import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:isibappmoodle/reutilisable/app_drawer.dart';
import 'package:isibappmoodle/views/add_project_page.dart';
import 'package:isibappmoodle/views/project_details_page.dart';
import 'package:isibappmoodle/config/config';

class ProjectManagementPage extends StatefulWidget {
  const ProjectManagementPage({super.key});

  @override
  _ProjectManagementPageState createState() => _ProjectManagementPageState();
}

class _ProjectManagementPageState extends State<ProjectManagementPage> {
  List<dynamic> ongoingProjects = [];
  List<dynamic> completedProjects = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(Uri.parse('${Config.sander}/api/projects'));

      if (response.statusCode == 200) {
        final List<dynamic> projects = json.decode(response.body);
        setState(() {
          ongoingProjects = projects
              .where((project) => project['status'] == 'En cours')
              .toList();
          completedProjects = projects
              .where((project) => project['status'] == 'Terminé')
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Échec du chargement des projets');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      _showSnackBar('Erreur lors du chargement des projets: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: const Text(
          'Gestion de Projet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchProjects,
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProjectPage(),
            ),
          ).then((_) => fetchProjects());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMainContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
        ),
      );
    }

    if (hasError) {
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
              "Erreur lors du chargement",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchProjects,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Réessayer",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (ongoingProjects.isEmpty && completedProjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_open,
              size: 60,
              color: Color(0xFF1976D2),
            ),
            const SizedBox(height: 16),
            const Text(
              "Aucun projet disponible",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProjectPage(),
                  ),
                ).then((_) => fetchProjects());
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Créer un projet",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          _buildProjectsSection(
            'Projets en cours',
            ongoingProjects,
            const Color(0xFF1976D2),
          ),
          const SizedBox(height: 24),
          _buildProjectsSection(
            'Projets terminés',
            completedProjects,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection(
      String title, List<dynamic> projects, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 16),
        if (projects.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Aucun projet ${title.toLowerCase()}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              return _buildProjectCard(projects[index], accentColor);
            },
          ),
      ],
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project, Color accentColor) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailsPage(
                projectId: project['id'],
              ),
            ),
          ).then((_) => fetchProjects());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project['name'] ?? 'Sans nom',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      project['status'] ?? 'En cours',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    project['status'] == 'Terminé'
                        ? 'Terminé le : ${project['completedDate'] ?? 'Non spécifié'}'
                        : 'Deadline : ${project['deadline'] ?? 'Non spécifiée'}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (project['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  project['description'],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}