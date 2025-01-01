import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FirebaseAPI {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Demande les permissions pour afficher les notifications
    await _firebaseMessaging.requestPermission();

    // Obtenir le token FCM de l'appareil
    final fCMToken = await _firebaseMessaging.getToken();
    print('Token : $fCMToken');
  }

  void initializeAwesomeNotifications() {
    // Initialisation des notifications Awesome
    AwesomeNotifications().initialize(
      null, // Icône par défaut (null utilise l'icône de l'application)
      [
        NotificationChannel(
          channelKey:
              'key1', // Doit correspondre au channel utilisé dans les notifications
          channelName: 'Basic Notifications',
          channelDescription: 'Notification channel for general use',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance
              .High, // Importance haute pour les notifications
          channelShowBadge:
              true, // Affiche un badge sur l'icône de l'application
        ),
      ],
      debug: true,
    );
    configureFirebaseMessaging();
  }

  void configureFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message reçu en premier plan : ${message.notification?.title}');

      // Affichez une notification avec Awesome Notifications
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now()
              .millisecondsSinceEpoch
              .remainder(100000), // ID unique
          channelKey: 'key1', // Doit correspondre au channel défini
          title: message.notification?.title ?? 'Notification',
          body: message.notification?.body ?? 'Vous avez un nouveau message',
          notificationLayout: NotificationLayout.Default,
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification cliquée : ${message.notification?.title}');
      // Gérer la navigation ici si nécessaire
    });
  }
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Fonction pour nettoyer les caractères spéciaux et les accents
  String cleanTopicName(String section) {
    // Remplacer les espaces par des underscores
    String formattedSection = section.replaceAll(' ', '_');

    // Supprimer les accents en utilisant une approche manuelle
    formattedSection = _removeAccents(formattedSection);

    return formattedSection;
  }

  // Fonction pour supprimer les accents d'une chaîne de caractères
  String _removeAccents(String str) {
    final Map<String, String> accents = {
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ç': 'c',
      'è': 'e',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'ö': 'o',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ÿ': 'y'
    };

    accents.forEach((accented, replacement) {
      str = str.replaceAll(accented, replacement);
    });

    return str;
  }

  // Abonnement à un topic basé sur la section de l'utilisateur
  Future<void> subscribeToSection(String section) async {
    String formattedSection = cleanTopicName(section);
    await _firebaseMessaging
        .subscribeToTopic(formattedSection)
        .then((_) => print("Abonné au topic : $formattedSection"));
  }

  // Désabonnement du topic
  Future<void> unsubscribeFromSection(String section) async {
    String formattedSection = cleanTopicName(section);
    await _firebaseMessaging.unsubscribeFromTopic(formattedSection);
    print("Utilisateur désabonné du topic : $formattedSection");
  }
}
