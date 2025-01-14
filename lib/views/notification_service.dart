import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationService {
  static Future<void> init() async {
    await AwesomeNotifications().initialize(
      null, // pas d'icône par défaut
      [
        NotificationChannel(
          channelKey: 'project_notifications',
          channelName: 'Notifications de projet',
          channelDescription: 'Notifications pour les projets et tâches',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
      ],
    );

    // Demander les permissions
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> showProjectInviteNotification({
    required String projectName,
    required String userEmail,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'project_notifications',
        title: 'Nouveau projet',
        body: 'Vous avez été ajouté au projet: $projectName',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  static Future<void> showTaskAssignedNotification({
    required String taskName,
    required String projectName,
    required String userEmail,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'project_notifications',
        title: 'Nouvelle tâche assignée',
        body:
            'Vous avez été assigné à la tâche "$taskName" dans le projet "$projectName"',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}
