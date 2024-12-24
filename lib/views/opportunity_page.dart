import 'package:flutter/material.dart';
import 'package:isibappmoodle/reutilisable/app_drawer.dart';

class OpportunityPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Opportunité'),
      ),
      drawer: AppDrawer(),
      body: Center(
        child: Text('Bienvenue dans la section Opportunité'),
      ),
    );
  }
}
