import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:isibappmoodle/config/config';
import 'package:isibappmoodle/views/note_cours_par_matiere_view';


class SubjectsPage extends StatefulWidget {
  final String className;
  final String filiere;

  SubjectsPage({required this.className, required this.filiere});

  @override
  _SubjectsPageState createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  List<dynamic> subjects = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    final String apiUrl = "${Config.sander}/getSubjectsByClass"; // Remplacez par l'URL de votre API
    try {
      final response = await http.get(Uri.parse('$apiUrl?classe=${widget.className}&filiere=${widget.filiere}'));

      if (response.statusCode == 200) {
        setState(() {
          subjects = json.decode(response.body); // Parse la réponse JSON
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} - Matières'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Text(
                    "Erreur lors du chargement des matières.",
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : subjects.isEmpty
                  ? Center(
                      child: Text(
                        "Aucune matière trouvée pour cette classe.",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        final subject = subjects[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(subject['nom_matiere']),
                            subtitle: Text(
                                'Professeur : ${subject['nom_prof']} - Filière : ${subject['filiere']}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NotesPage(
                                    subjectName: subject['nom_matiere'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
