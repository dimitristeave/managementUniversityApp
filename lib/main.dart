import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:isibappmoodle/notifications/works_notifications.dart';
import 'package:isibappmoodle/views/assistance_get_view';
import 'package:isibappmoodle/views/assistance_view';
import 'package:isibappmoodle/views/auth_page.dart';
import 'package:isibappmoodle/views/help_page.dart';
import 'package:isibappmoodle/views/home_share_file_view.dart';
import 'package:isibappmoodle/views/Opportunity_Views/opportunity_page.dart';
import 'package:isibappmoodle/views/project_management.dart';
import 'package:isibappmoodle/views/suivi_view'; // Assurez-vous que ce fichier contient la page HomeShareFile
import 'package:isibappmoodle/views/project_management.dart'; // Assurez-vous que ce fichier contient la page HomeShareFile

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialisation de Firebase

  // Initialisez Awesome Notifications
  FirebaseAPI firebaseAPI = FirebaseAPI();
  firebaseAPI.initializeAwesomeNotifications();
  await firebaseAPI.initNotifications();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Supprime le bandeau de débogage
      title: 'ShareFile App',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Couleur principale de l'application
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home:
          AuthChecker(), // Vérifier l'état de la connexion avant de montrer une page
      routes: {
        '/auth': (context) => AuthPage(),
        '/home': (context) => HomeShareFile(),
        '/opportunity': (context) => OpportunityPage(),
        '/project_management': (context) => ProjectManagementPage(),
        '/help': (context) => HelpPage(),
        '/assistance': (context) => AssistancePage(),
        '/my_demands': (context) => AssistanceRequestsPage(),
        '/suivi': (context) => MyAssistanceRequestsPage(),
      },
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  // Fonction pour vérifier si l'utilisateur est connecté
  Future<User?> _getUser() async {
    User? user =
        FirebaseAuth.instance.currentUser; // Vérifie l'utilisateur actuel
    return user; // Retourne l'utilisateur si connecté, sinon null
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _getUser(), // Vérifier si l'utilisateur est connecté
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
                child:
                    CircularProgressIndicator()), // Afficher un chargement pendant la vérification
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          return HomeShareFile(); // Si connecté, rediriger vers la page HomeShareFile
        } else {
          return AuthPage(); // Si non connecté, rediriger vers la page de connexion
        }
      },
    );
  }
}
