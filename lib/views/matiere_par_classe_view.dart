import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:isibappmoodle/config/config';
import 'package:isibappmoodle/views/note_cours_par_matiere_view.dart';

class SubjectsPage extends StatefulWidget {
  final String className;
  final String filiere;

  const SubjectsPage({super.key, required this.className, required this.filiere});

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
    const String apiUrl = "${Config.sander}/getSubjectsByClass";
    try {
      final response = await http.get(
        Uri.parse('$apiUrl?classe=${widget.className}&filiere=${widget.filiere}')
      );

      if (response.statusCode == 200) {
        setState(() {
          subjects = json.decode(response.body);
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
        print(e);
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Text(
          '${widget.className} - Matières',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
                          size: 60,
                          color: Color(0xFF1976D2),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Erreur lors du chargement des matières",
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: fetchSubjects,
                          child: const Text(
                            'Réessayer',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : subjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              size: 60,
                              color: Color(0xFF1976D2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Aucune matière trouvée pour ${widget.className}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1976D2),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(
                                  color: const Color(0xFF1976D2).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subject['nom_matiere'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1976D2),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            subject['nom_prof'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(
                                            Icons.school,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            subject['filiere'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}