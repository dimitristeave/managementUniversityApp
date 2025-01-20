import 'package:flutter/material.dart';
import 'package:isibappmoodle/reutilisable/app_drawer.dart';
import 'package:isibappmoodle/views/ajouter_matiere_view.dart';
import 'package:isibappmoodle/views/matiere_par_classe_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeShareFile extends StatelessWidget {
  final List<String> classes = ["BAC 1", "BAC 2", "BAC 3", "Bloc C", "Master 1", "Master 2"];
  final List<String> filieres = ["Info", "Electronique", "Mécanique", "Physique Nucléaire", "Chimie", "Electricité"];

  HomeShareFile({super.key});

  void showFilieresDialog(BuildContext context, String className) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Choisissez une filière",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 20),
                ...filieres.map((filiere) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubjectsPage(
                            className: className,
                            filiere: filiere,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      filiere,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      },
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
          'ShareFile - Accueil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Ajouter une matière',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddSubjectForm()),
                );
              },
            ),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              return Container(
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
                    onTap: () {
                      if (classes[index] == "Master 1" || classes[index] == "Master 2") {
                        showFilieresDialog(context, classes[index]);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectsPage(
                              className: classes[index],
                              filiere: filieres[index],
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            const Color(0xFF1976D2).withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school,
                              size: 40,
                              color: const Color(0xFF1976D2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              classes[index],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}