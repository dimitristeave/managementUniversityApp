import 'package:flutter/material.dart';
import 'package:isibappmoodle/reutilisable/app_drawer.dart';

class ProjectManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion de Projet'),
      ),
      drawer: AppDrawer(),
      body: Center(
        child: Text('Bienvenue dans la section Gestion de Projet'),
      ),
    );
  }
}
