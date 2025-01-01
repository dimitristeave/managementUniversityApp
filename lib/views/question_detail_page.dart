import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isibappmoodle/config/config';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class QuestionDetailPage extends StatefulWidget {
  final Map<String, dynamic> question;

  QuestionDetailPage({required this.question});

  @override
  _QuestionDetailPageState createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> {
  List<Map<String, dynamic>> answers = [];
  bool isLoading = true;
  String answerContent = '';
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchAnswers();
  }




  Future<void> updateAnswer(String answerId, String newContent) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.sander}/questions/${widget.question['id']}/answers/$answerId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': newContent}),
      );

      if (response.statusCode == 200) {
        fetchAnswers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Réponse modifiée avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la modification de la réponse')),
        );
      }
    } catch (error) {
      print("Erreur lors de la modification: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Une erreur est survenue')),
      );
    }
  }


  Future<void> fetchAnswers() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.sander}/questions/${widget.question['id']}/answers'),
      );

      if (response.statusCode == 200) {
        List<dynamic> answersData = json.decode(response.body);
        List<Map<String, dynamic>> updatedAnswers = [];

        for (var answer in answersData) {
          // Récupérer les informations de l'utilisateur, y compris la photo de profil
          final userResponse = await http.get(
            Uri.parse('${Config.sander}/user/${answer['userId']}'),
          );

          if (userResponse.statusCode == 200) {
            Map<String, dynamic> userData = json.decode(userResponse.body);
            answer['userPhotoURL'] = userData['photoURL'];
          }

          updatedAnswers.add(answer);
        }

        setState(() {
          answers = updatedAnswers;
          isLoading = false;
        });
      }
    } catch (error) {
      print("Erreur: $error");
      setState(() => isLoading = false);
    }
  }

  Future<void> submitAnswer() async {
    if (answerContent.isEmpty) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final response = await http.post(
        Uri.parse(
            '${Config.sander}/questions/${widget.question['id']}/answers'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': user.uid,
          'content': answerContent,
        }),
      );

      if (response.statusCode == 200) {
        setState(() => answerContent = '');
        fetchAnswers();
      }
    } catch (error) {
      print("Erreur: $error");
    }
  }

  Future<void> rateAnswer(String answerId, double rating) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.sander}/questions/${widget
            .question['id']}/answers/$answerId/rate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _auth.currentUser?.uid,
          'rating': rating,
        }),
      );

      if (response.statusCode == 200) {
        fetchAnswers();
      }
    } catch (error) {
      print("Erreur: $error");
    }
  }

  Future<void> deleteAnswer(String answerId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Config.sander}/questions/${widget
            .question['id']}/answers/$answerId'),
      );

      if (response.statusCode == 200) {
        fetchAnswers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Réponse supprimée avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de la suppression de la réponse')),
        );
      }
    } catch (error) {
      print("Erreur lors de la suppression: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Une erreur est survenue')),
      );
    }
  }

  Widget _buildRatingBar(String answerId, double currentRating,
      int totalRatings) {
    return Row(
      children: [
        RatingBar.builder(
          initialRating: currentRating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 20,
          itemBuilder: (context, _) =>
              Icon(
                Icons.star,
                color: Colors.amber,
              ),
          onRatingUpdate: (rating) {
            rateAnswer(answerId, rating);
          },
        ),
        SizedBox(width: 8),
        Text(
          '($totalRatings votes)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }





  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final timestamp = question['createdAt'] != null
        ? (question['createdAt'] as Map)['_seconds']
        : null;
    final date = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
        : DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text('Détail de la question'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question['title'] ?? 'Sans titre',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
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
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16),
                            SizedBox(width: 4),
                            Text(question['userEmail'] ?? 'Anonyme'),
                            SizedBox(width: 8),
                            Text('le ${date.day}/${date.month}/${date.year}'),
                          ],
                        ),
                        Divider(height: 32),
                        Text(
                          'Réponses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLoading)
                    Center(child: CircularProgressIndicator())
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: answers.length,
                      itemBuilder: (context, index) {
                        final answer = answers[index];
                        final isMyAnswer = answer['userId'] == _auth.currentUser?.uid;

                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Photo de profil
                                    CircleAvatar(
                                      backgroundImage: answer['userPhotoURL'] != null
                                          ? NetworkImage(answer['userPhotoURL'])
                                          : null,
                                      child: answer['userPhotoURL'] == null
                                          ? Icon(Icons.person)
                                          : null,
                                      radius: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            answer['userEmail'] ?? 'Anonyme',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(answer['content']),
                                        ],
                                      ),
                                    ),
                                    if (isMyAnswer)
                                      PopupMenuButton(
                                        itemBuilder: (context) =>
                                        [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit),
                                                SizedBox(width: 8),
                                                Text('Modifier'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Supprimer',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) async {
                                          if (value == 'edit') {
                                            String updatedContent = answer['content'];
                                            await showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text('Modifier la réponse'),
                                                content: TextField(
                                                  maxLines: null,
                                                  decoration: InputDecoration(hintText: 'Votre réponse...'),
                                                  onChanged: (value) => updatedContent = value,
                                                  controller: TextEditingController(text: answer['content']),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: Text('Annuler'),
                                                    onPressed: () => Navigator.of(context).pop(),
                                                  ),
                                                  TextButton(
                                                    child: Text('Enregistrer'),
                                                    onPressed: () {
                                                      updateAnswer(answer['id'], updatedContent);
                                                      Navigator.of(context).pop();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          } else if (value == 'delete') {
                                            await deleteAnswer(answer['id']);
                                          }
                                        },
                                      ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                _buildRatingBar(
                                    answer['id'],
                                    answer['averageRating']?.toDouble() ?? 0.0,
                                    answer['totalRatings'] ?? 0
                                ),
                                SizedBox(height: 8),
                                // Affichage du rôle de l'utilisateur
                                Row(
                                  children: [
                                    Icon(
                                      answer['userRole'] == 'professor' ? Icons.school : Icons.person,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      answer['userRole'] == 'professor' ? 'Professeur' : 'Étudiant',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Theme
                    .of(context)
                    .scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Votre réponse...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                      onChanged: (value) => answerContent = value,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: submitAnswer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}