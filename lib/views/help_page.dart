import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:isibappmoodle/config/config';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:isibappmoodle/views/home_share_file_view.dart';
import 'question_detail_page.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  String? currentSection;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = true;
  bool hasError = false;
  List<Map<String, dynamic>> questions = [];
  String questionTitle = '';
  String questionContent = '';
  String? selectedSection;
  User? currentUser;
  File? _selectedImage;

  final List<Map<String, String>> sections = [
    {"id": "0", "name": "BA1"},
    {"id": "1", "name": "BA2"},
    {"id": "2", "name": "BA3"},
    {"id": "3", "name": "MA1 Informatique"},
    {"id": "4", "name": "MA1 Electronique"},
    {"id": "5", "name": "MA1 Physique Nucléaire et Médicale"},
    {"id": "6", "name": "MA1 Chimie"},
    {"id": "7", "name": "MA1 Electromécanique"},
    {"id": "8", "name": "MA1 Aéronautique"},
    {"id": "9", "name": "MA2 Informatique"},
    {"id": "10", "name": "MA2 Electronique"},
    {"id": "11", "name": "MA2 Physique Nucléaire et Médicale"},
    {"id": "12", "name": "MA2 Chimie"},
    {"id": "13", "name": "MA2 Electromécanique"},
    {"id": "14", "name": "MA2 Aéronautique"},
  ];

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    fetchQuestions();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF1976D2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> fetchQuestions() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('${Config.sander}/questions'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          questions = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception('Erreur serveur');
      }
    } catch (error) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      _showSnackBar('Erreur lors du chargement des questions');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la sélection de l\'image');
    }
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final timestamp = question['createdAt'] != null
        ? (question['createdAt'] as Map)['_seconds']
        : null;
    final date = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
        : DateTime.now();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuestionDetailPage(question: question),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                    child: Icon(
                      question['userRole'] == 'professor'
                          ? Icons.school
                          : Icons.person,
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question['title'] ?? 'Sans titre',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question['userEmail'] ?? 'Anonyme',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${date.day}/${date.month}/${date.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      question['userRole'] == 'professor'
                          ? 'Professeur'
                          : 'Étudiant',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                question['content'] ?? '',
                style: const TextStyle(fontSize: 16),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (question['imageUrl'] != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    question['imageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.school,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    getSectionName(question['section']),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> addQuestion() async {
    if (currentUser == null) {
      _showSnackBar('Vous devez être connecté pour poser une question');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Poser une question",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_selectedImage != null)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              color: Colors.white,
                              onPressed: () {
                                setModalState(() => _selectedImage = null);
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        "Section",
                        (String? value) {
                          setModalState(() => selectedSection = value);
                        },
                        sections.map((section) {
                          return DropdownMenuItem(
                            value: section["id"],
                            child: Text(section["name"]!),
                          );
                        }).toList(),
                        selectedSection,
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        "Titre de la question",
                        (String value) {
                          setModalState(() => questionTitle = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        "Contenu de la question",
                        (String value) {
                          setModalState(() => questionContent = value);
                        },
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.image),
                              label: const Text("Ajouter une image"),
                              onPressed: () async {
                                await _pickImage();
                                setModalState(() {});
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1976D2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (questionTitle.isNotEmpty &&
                                  questionContent.isNotEmpty &&
                                  selectedSection != null)
                              ? () {
                                  Navigator.pop(context);
                                  uploadQuestionToServer();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Publier",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormField(
    String label,
    Function(String?) onChanged,
    List<DropdownMenuItem<String>> items,
    String? value,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextFormField(
    String label,
    Function(String) onChanged, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> uploadQuestionToServer() async {
    try {
      if (currentUser == null) {
        _showSnackBar('Vous devez être connecté');
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.sander}/questions'),
      );

      request.fields.addAll({
        'userId': currentUser!.uid,
        'title': questionTitle,
        'content': questionContent,
        'section': selectedSection!,
      });

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImage!.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        _showSnackBar('Question publiée avec succès', isError: false);
        setState(() => _selectedImage = null);
        await fetchQuestions();
      } else {
        throw Exception('Erreur lors de la publication');
      }
    } catch (e) {
      _showSnackBar('Erreur: $e');
    }
  }

  String getSectionName(String? sectionId) {
    if (sectionId == null) return "Section non spécifiée";
    final section = sections.firstWhere(
      (section) => section["id"] == sectionId,
      orElse: () => {"id": "", "name": "Section non trouvée"},
    );
    return section["name"]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeShareFile()),
          ),
        ),
        title: const Text(
          'Forum d\'entraide',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: addQuestion,
            tooltip: 'Poser une question',
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Filtrer par section",
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    labelStyle: TextStyle(color: Colors.grey.shade700),
                  ),
                  value: currentSection,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text("Toutes les sections"),
                    ),
                    ...sections.map((section) {
                      return DropdownMenuItem(
                        value: section["id"],
                        child: Text(section["name"]!),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => currentSection = value),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                      ),
                    )
                  : hasError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Color(0xFF1976D2),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Erreur lors du chargement",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: fetchQuestions,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("Réessayer"),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF1976D2),
                          onRefresh: fetchQuestions,
                          child: questions.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.question_answer_outlined,
                                        size: 64,
                                        color: Color(0xFF1976D2),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Aucune question disponible",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.add),
                                        label: const Text("Poser une question"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1976D2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: addQuestion,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  itemCount: questions.length,
                                  itemBuilder: (context, index) {
                                    final question = questions[index];
                                    if (currentSection != null &&
                                        question['section'] != currentSection) {
                                      return const SizedBox.shrink();
                                    }
                                    return _buildQuestionCard(question);
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        onPressed: addQuestion,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
