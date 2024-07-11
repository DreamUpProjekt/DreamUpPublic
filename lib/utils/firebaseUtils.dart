import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import 'currentUserData.dart';

class FirebaseUtils {
  static Future<void> sendFCMMessage({
    required String recipientToken,
    required String recipientId,
    required int recipientNoteCount,
    required String senderName,
    required String senderId,
    required String message,
    required String chatId,
    required Map notificationSettings,
  }) async {
    const String serverKey =
        '*********************************';
    final Uri fcmUrl = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    final playSound = notificationSettings['playSound'] ?? true;
    final sound = playSound ? 'default' : null;

    final notification = {
      'title': 'Neue Nachricht von $senderName',
      'body': _truncateMessage(message),
      if (sound != null) 'sound': sound,
      'badge': recipientNoteCount + 1,
    };

    final data = {
      'to': recipientToken,
      'notification': notification,
      'data': {
        'chatId': chatId,
        'partnerId': senderId,
        'partnerName': senderName,
      },
    };

    final response = await http.post(
      fcmUrl,
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      print('Failed to send FCM message: ${response.body}');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(recipientId)
        .update({'notificationCount': FieldValue.increment(1)});

    print('note counter incremented');
  }

  static Future<void> sendConnectionMessage({
    required String recipientToken,
    required String recipientId,
    required int recipientNoteCount,
    required String senderName,
    required String senderId,
    required String chatId,
    required Map notificationSettings,
    required String dreamUpTitle,
  }) async {
    const String serverKey =
        '*********************************';
    final Uri fcmUrl = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    final playSound = notificationSettings['playSound'] ?? true;
    final sound = playSound ? 'default' : null;

    final notification = {
      'title': 'Neue Connect-Anfrage',
      'body': dreamUpTitle,
      if (sound != null) 'sound': sound,
      'badge': recipientNoteCount + 1,
    };

    final data = {
      'to': recipientToken,
      'notification': notification,
      'data': {
        'chatId': chatId,
        'partnerId': senderId,
        'partnerName': senderName,
      }, // Include chat ID in the data payload
    };

    print(data);

    final response = await http.post(
      fcmUrl,
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      print('Failed to send FCM message: ${response.body}');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(recipientId)
        .update({'notificationCount': FieldValue.increment(1)});

    print('note counter incremented');
  }

  static Future<void> sendConfirmationMessage({
    required String recipientToken,
    required String recipientId,
    required int recipientNoteCount,
    required String senderName,
    required String senderId,
    required String chatId,
    required Map notificationSettings,
  }) async {
    const String serverKey =
        '*********************************';
    final Uri fcmUrl = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    final playSound = notificationSettings['playSound'] ?? true;
    final sound = playSound ? 'default' : null;

    final notification = {
      'title': 'Du wurdest bestätigt',
      'body': 'Deine Chatanfrage wurde bestätigt',
      if (sound != null) 'sound': sound,
      'badge': recipientNoteCount + 1,
    };

    final data = {
      'to': recipientToken,
      'notification': notification,
      'data': {
        'chatId': chatId,
        'partnerId': senderId,
        'partnerName': senderName,
      },
    };

    print(data);

    final response = await http.post(
      fcmUrl,
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      print('Failed to send FCM message: ${response.body}');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(recipientId)
        .update({'notificationCount': FieldValue.increment(1)});

    print('note counter incremented');
  }

  static String _truncateMessage(String message) {
    const maxLength = 50;
    return message.length > maxLength
        ? '${message.substring(0, maxLength)}...'
        : message;
  }

  static Future<void> updateImageInStorage(File file) async {
    try {
      const placeholderImage =
          '*********************************';

      var ref = 'userImages/${FirebaseAuth.instance.currentUser?.uid}';

      final FirebaseStorage storage = FirebaseStorage.instance;

      bool placeholder = CurrentUser.imageLink == placeholderImage;

      if (!placeholder) {
        await storage.refFromURL(CurrentUser.imageLink).delete();
      }

      final TaskSnapshot uploadTask = await storage.ref(ref).putFile(file);

      final updatedLink = await uploadTask.ref.getDownloadURL();

      CurrentUser.imageLink = updatedLink;

      CurrentUser.imageFile =
          await CurrentUser().getUserImage(overwriteIfExists: true);
      CurrentUser.blurredImage =
          await CurrentUser().getBlurredImage(overwriteIfExists: true);

      print('changed image in storage');
    } catch (e) {
      print('Error updating user image: $e');
    }
  }

  static Future<void> updateUserInformation(Map<String, dynamic> data) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      DateTime birthday = DateTime.parse(data['birthday']);

      await firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .update(data);

      CurrentUser.name = data['name'];
      CurrentUser.bio = data['bio'];
      CurrentUser.gender = CurrentUser().stringToGenderEnum(data['gender']);
      CurrentUser.birthday = birthday;

      print('user data updated');
    } catch (e) {
      print('Error occured while updating user data: $e');
    }
  }

  static Future<void> createUser({
    required String mail,
    required String password,
    required String name,
    required String bio,
    required DateTime birthday,
    required Gender gender,
  }) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: mail.trim(),
      password: password.trim(),
    );

    CollectionReference users = FirebaseFirestore.instance.collection('users');

    final FirebaseAuth auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final id = user?.uid;

    var newUser = users.doc(id);

    final json = {
      'email': mail,
      'id': id,
      'imageLink':
          '*********************************',
      'name': name,
      'bio': bio,
      'birthday': birthday,
      'gender': CurrentUser().genderEnumToString(gender),
      'notificationSettings': {
        'showBadges': true,
        'playSound': true,
      },
    };

    await newUser.set(json);

    print('new user created');
  }
}
