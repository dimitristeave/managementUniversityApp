import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isibappmoodle/reutilisable/app_drawer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskDetailPage extends StatefulWidget {
  final String taskId;
  final String memberId;

  const TaskDetailPage({Key? key, required this.taskId, required this.memberId})
      : super(key: key);

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  Map<String, dynamic>? _taskData;
  final TextEditingController _commentController = TextEditingController();
  double _progress = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTaskData();
  }

  // Ajoutez ces méthodes
  void _showSuccessSnackBar(String message) {
    if (!mounted) return; // Vérifier si le widget est toujours monté

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return; // Vérifier si le widget est toujours monté

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Nouvelle méthode pour ouvrir les URLs
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      _showErrorSnackBar('Impossible d\'ouvrir le fichier: $e');
    }
  }

  Future<void> _loadTaskData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/tasks/${widget.taskId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _taskData = json.decode(response.body);
          _progress = _taskData?['progress']?.toDouble() ?? 0;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement de la tâche: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        File file = File(result.files.single.path!);

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://10.0.2.2:3000/api/tasks/${widget.taskId}/files'),
        );

        request.files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );

        var response = await request.send();
        if (response.statusCode == 200) {
          _showSuccessSnackBar('Fichier uploadé avec succès');
          _loadTaskData();
        } else {
          throw Exception('Échec de l\'upload');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'upload: $e');
    }
  }

  Future<void> _updateProgress() async {
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/api/tasks/${widget.taskId}/progress'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'progress': _progress,
          'status': _progress == 100 ? 'completed' : 'in-progress',
          'comment': _commentController.text,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Progression mise à jour');
        _commentController.clear();
        _loadTaskData();
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la mise à jour: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildProgressSection(),
                  const SizedBox(height: 24),
                  _buildFilesSection(),
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
            Text('Deadline: ${_taskData?['deadline'] ?? ''}'),
            Text('Status: ${_taskData?['status'] ?? ''}'),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progression',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Slider(
              value: _progress,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${_progress.round()}%',
              onChanged: (value) {
                setState(() => _progress = value);
              },
            ),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Ajouter un commentaire',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateProgress,
              child: const Text('Mettre à jour la progression'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesSection() {
    final files = _taskData?['files'] as List? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fichiers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: _uploadFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Uploader'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return ListTile(
                  leading: const Icon(Icons.file_present),
                  title: Text(file['filename']),
                  subtitle: Text(file['uploadedAt']),
                  onTap: () => _launchURL(file['url']),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    final comments = _taskData?['comments'] as List? ?? [];

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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return ListTile(
                  title: Text(comment['content']),
                  subtitle: Text(comment['timestamp']),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
