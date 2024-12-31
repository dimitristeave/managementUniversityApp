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

  Future<void> fetchAnswers() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.sander}/questions/${widget.question['id']}/answers'),
      );

      if (response.statusCode == 200) {
        setState(() {
          answers = List<Map<String, dynamic>>.from(json.decode(response.body));
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
        Uri.parse('${Config.sander}/questions/${widget.question['id']}/answers'),
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
        Uri.parse('${Config.sander}/questions/${widget.question['id']}/answers/$answerId/rate'),
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

  Widget _buildRatingBar(String answerId, double currentRating, int totalRatings) {
    return Row(
      children: [
        RatingBar.builder(
          initialRating: currentRating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 20,
          itemBuilder: (context, _) => Icon(
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
      body: SingleChildScrollView(
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
                            children: [
                              Expanded(child: Text(answer['content'])),
                              if (isMyAnswer)
                                PopupMenuButton(
                                  itemBuilder: (context) => [
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
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Supprimer',
                                              style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      // TODO: Implement edit
                                    } else if (value == 'delete') {
                                      // TODO: Implement delete
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
                          Row(
                            children: [
                              Icon(Icons.person, size: 12, color: Colors.grey),
                              SizedBox(width: 4),
                              Text(
                                answer['userEmail'] ?? 'Anonyme',
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
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).viewInsets.bottom + 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
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
    );
  }
}