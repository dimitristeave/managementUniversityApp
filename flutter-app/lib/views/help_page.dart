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
  List<Map<String, dynamic>> getFilteredQuestions() {
    if (currentSection == null) {
      return questions;
    }
    return questions.where((q) => q['section'] == currentSection).toList();
  }
  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.sander}/questions'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          questions = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      print("Erreur: $error");
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> addQuestion() async {
    String localQuestionTitle = '';
    String localQuestionContent = '';
    String? localSelectedSection;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Vous devez être connecté pour poser une question"))
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Poser une question",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_selectedImage != null)
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setModalState(() {
                                _selectedImage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.image),
                      label: Text("Ajouter une image"),
                      onPressed: () async {
                        await _pickImage();
                        setModalState(() {}); // Rafraîchir le modal
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Section",
                        border: OutlineInputBorder(),
                        hintText: "Choisissez votre section",
                      ),
                      value: localSelectedSection,
                      items: sections.map((section) {
                        return DropdownMenuItem(
                          value: section["id"],
                          child: Text(section["name"]!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          localSelectedSection = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Titre de la question",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          localQuestionTitle = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Contenu de la question",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        setModalState(() {
                          localQuestionContent = value;
                        });
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                      onPressed: (localQuestionTitle.isNotEmpty &&
                          localQuestionContent.isNotEmpty &&
                          localSelectedSection != null)
                          ? () {
                        setState(() {
                          questionTitle = localQuestionTitle;
                          questionContent = localQuestionContent;
                          selectedSection = localSelectedSection;
                        });
                        uploadQuestionToServer();
                        Navigator.pop(context);
                      }
                          : null,
                      child: Text("Publier"),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> uploadQuestionToServer() async {
    try {
      if (currentUser == null) {
        print("Aucun utilisateur connecté");
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.sander}/questions'),
      );

      request.fields['userId'] = currentUser!.uid;
      request.fields['title'] = questionTitle;
      request.fields['content'] = questionContent;
      request.fields['section'] = selectedSection!;

      if (_selectedImage != null) {
        var imageFile = await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        );
        request.files.add(imageFile);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print("Question publiée avec succès");
        setState(() {
          _selectedImage = null;
        });
        fetchQuestions();
      } else {
        print("Erreur lors de la publication: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Erreur: $e");
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeShareFile()),
          ),
        ),
        title: Text('Forum d\'entraide'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: addQuestion,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Filtrer par section",
                border: OutlineInputBorder(),
              ),
              value: currentSection,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text("Toutes les sections"),
                ),
                ...sections.map((section) {
                  return DropdownMenuItem(
                    value: section["id"],
                    child: Text(section["name"]!),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  currentSection = value;
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : hasError
                ? Center(child: Text("Erreur lors du chargement des questions"))
                : getFilteredQuestions().isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.question_answer_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Aucune question disponible",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: addQuestion,
                    child: Text("Poser une question"),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: getFilteredQuestions().length,
              itemBuilder: (context, index) {
                final question = getFilteredQuestions()[index];
                final timestamp = question['createdAt'] != null
                    ? (question['createdAt'] as Map)['_seconds']
                    : null;
                final date = timestamp != null
                    ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
                    : DateTime.now();

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          question['title'] ?? 'Sans titre',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(question['content'] ?? ''),
                            if (question['imageUrl'] != null)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Image.network(
                                  question['imageUrl'],
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.school, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  getSectionName(question['section']),
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.person, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  question['userEmail'] ?? 'Anonyme',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  question['userRole'] == 'professor'
                                      ? Icons.school
                                      : Icons.person_outline,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  question['userRole'] == 'professor'
                                      ? 'Professeur'
                                      : 'Étudiant',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            Text(
                              'Posté le ${date.day}/${date.month}/${date.year}',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuestionDetailPage(question: question),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  }
