import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart';
import '../mainScreens/contacts.dart';

class LocalNotificationUtils {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('ic_launcher');

    var initializationSettingsIOS = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('received a notification!');

        if (response.payload != null) {
          Map<String, dynamic> data = json.decode(response.payload!);
          _handleMessageData(data);
        }
      },
    );
  }

  void _handleMessageData(Map<String, dynamic> data) {
    if (data['chatId'] != null &&
        data['partnerId'] != null &&
        data['partnerName'] != null) {
      comingFromNote = true;

      print('there is data: $data');

      Navigator.push(
        navigatorKey.currentContext!,
        goToChat(
          data['chatId'],
          data['partnerName'],
          data['partnerId'],
        ),
      );
    } else {
      print('received note, but not with chat information');
    }
  }

  notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'channelId',
        'channelName',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@drawable/ic_launcher'),
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payLoad,
  }) async {
    return notificationsPlugin.show(
      id,
      title,
      body,
      await notificationDetails(),
      payload: payLoad,
    );
  }
}
