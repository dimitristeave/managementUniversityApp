import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isibappmoodle/reutilisable/app_drawer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:isibappmoodle/config/config';

class TaskDetailPage extends StatefulWidget {
  final String taskId;
  final String memberId;
  final String currentUserId;

  const TaskDetailPage({
    super.key,
    required this.taskId,
    required this.memberId,
    required this.currentUserId,
  });

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  Map<String, dynamic>? _taskData;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _improvementController = TextEditingController();
  double _progress = 0;
  bool _isLoading = false;
  bool _isAssignedUser = false;
  String? _selectedImagePath;
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadTaskData();
    _loadComments();
  }

  Future<void> _loadTaskData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.sander}/api/tasks/${widget.taskId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _taskData = json.decode(response.body);
          _progress = _taskData?['progress']?.toDouble() ?? 0;
          _checkUserPermissions();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement de la tâche: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _checkUserPermissions() {
    setState(() {
      _isAssignedUser = widget.currentUserId == _taskData?['assignedTo'];
    });
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadComments() async {
    try {
      final comments = await fetchComments();
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des commentaires: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchComments() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.sander}/commentsTask?taskId=${widget.taskId}'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((comment) => comment as Map<String, dynamic>).toList();
      } else {
        print("Failed to fetch comments: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching comments: $e");
      return [];
    }
  }

  Future<void> addComment({
    required String userId,
    required String title,
    required String content,
    required String section,
    String? imagePath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.sander}/commentsTask'),
      );

      request.fields.addAll({
        'userId': userId,
        'title': title,
        'content': content,
        'section': section,
      });

      if (imagePath != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        );
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        _showSuccessSnackBar('Commentaire ajouté avec succès');
        _loadComments();
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'ajout du commentaire: $e');
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedImagePath = result.files.single.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTaskCompleted = _taskData?['status'] == 'completed';

    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text(_taskData?['name'] ?? 'Détails de la tâche'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTaskInfo(),
                  const SizedBox(height: 24),
                  _buildImprovementsSection(isTaskCompleted),
                  const SizedBox(height: 24),
                  _buildCommentsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildTaskInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description: ${_taskData?['description'] ?? ''}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text('Status: ${_taskData?['status'] ?? ''}'),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementsSection(bool isTaskCompleted) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Points d\'amélioration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (!isTaskCompleted && !_isAssignedUser) ...[
              TextField(
                controller: _improvementController,
                decoration: const InputDecoration(
                  labelText: 'Suggérer une amélioration',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (_improvementController.text.isEmpty) {
                        _showErrorSnackBar(
                            'Le commentaire ne peut pas être vide');
                        return;
                      }

                      await addComment(
                        userId: widget.currentUserId,
                        title: 'Amélioration pour la tâche ${widget.taskId}',
                        content: _improvementController.text,
                        section: 'improvement',
                        imagePath: _selectedImagePath,
                      );

                      _improvementController.clear();
                      setState(() {
                        _selectedImagePath = null;
                      });
                    },
                    child: const Text('Ajouter une suggestion'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _pickImage,
                  ),
                  if (_selectedImagePath != null)
                    Expanded(
                      child: Text(
                        'Image sélectionnée: ${_selectedImagePath!.split('/').last}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commentaires',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _comments.isEmpty
                ? Text(
                    'Aucun commentaire disponible pour cette tâche.',
                    style: TextStyle(color: Colors.grey),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return ListTile(
                        title: Text(comment['content'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comment['createdAt']?.toString() ?? ''),
                            if (comment['imageUrl'] != null)
                              Image.network(
                                comment['imageUrl'],
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
