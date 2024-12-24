import 'package:flutter/material.dart';
import 'package:isibappmoodle/reutilisable/app_drawer.dart';

class HelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aide'),
      ),
      drawer: AppDrawer(),
      body: Center(
        child: Text('Bienvenue dans la section Aide'),
      ),
    );
  }
}
