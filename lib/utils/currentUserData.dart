import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../mainScreens/thread.dart';
import 'encrypting.dart';
import 'imageEditingIsolate.dart';

enum Gender {
  none,
  female,
  male,
  diverse,
}

class CurrentUser {
  static String mail = '';
  static String name = '';
  static String bio = '';
  static DateTime birthday = DateTime.now();
  static Gender gender = Gender.none;
  static List<Gender> genderPrefs = [];
  static List<String> requestedCreators = [];
  static String imageLink = '';
  static File? imageFile;
  static File? blurredImage;
  static RSAPrivateKey? privateKey;
  static String publicKey = '';

  static bool showNoteBadges = true;
  static bool playNoteSound = true;
  static bool vibrateOnNote = true;

  static List<dynamic> recentlySearched = [];

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> getUserData() async {
    try {
      print('getting user data');

      if (FirebaseAuth.instance.currentUser == null) {
        gotUserData = true;

        print('user not logged in --> got tempSeenDreamUps');

        return;
      }

      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      var data = userDoc.data();

      await getFromDatabase(data!);

      gotUserData = true;

      print('got user data');
    } catch (e) {
      print('Error in getUserData: $e');
    }
  }

  static void deleteUserInfo() {
    mail = '';
    name = '';
    bio = '';
    birthday = DateTime.now();
    gender = Gender.diverse;
    genderPrefs.clear();
    requestedCreators.clear();
    imageLink = '';
    imageFile = null;
    blurredImage = null;
    privateKey = null;
    publicKey = '';

    gotUserData = false;

    dreamUpList.clear();
    seenDreamUps.clear();
  }

  static deleteAccount(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.05,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(
                    height: MediaQuery.of(context).size.width * 0.05,
                  ),
                  const Text(
                    'Alle deine Daten werden gelöscht...',
                  ),
                ],
              ),
            ),
          );
        });

    var createdVibesRef = await FirebaseFirestore.instance
        .collection('vibes')
        .where('creator', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .get();

    for (var vibe in createdVibesRef.docs) {
      var data = vibe.data();

      if (data['imageLink'] !=
          'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FostseeQuadrat.jpg?alt=media&token=cece7d52-6d24-463f-9ac7-ea55ed35086a') {
        var imageRef =
            FirebaseStorage.instance.ref('vibeMedia/images/${vibe.id}');

        await imageRef.delete();
      }

      if (data['audioLink'] != '') {
        var audioRef =
            FirebaseStorage.instance.ref('vibeMedia/audios/${vibe.id}');

        await audioRef.delete();
      }

      if ((data['hashtags'] as List<dynamic>).isNotEmpty) {
        for (var hashtag in data['hashtags']) {
          var databaseHashtagRef = await FirebaseFirestore.instance
              .collection('hashtags')
              .where('hashtag', isEqualTo: hashtag)
              .get();

          var databaseHashtags = databaseHashtagRef.docs;

          for (var databaseHashtag in databaseHashtags) {
            var hashtagData = databaseHashtag.data();

            if (hashtagData['useCount'] > 1) {
              await FirebaseFirestore.instance
                  .collection('hashtags')
                  .doc(databaseHashtag.id)
                  .update(
                {
                  'useCount': FieldValue.increment(-1),
                },
              );
            } else {
              await FirebaseFirestore.instance
                  .collection('hashtags')
                  .doc(databaseHashtag.id)
                  .delete();
            }
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('vibes')
          .doc(vibe.id)
          .delete();
    }

    var userRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();
    var doc = userRef.data();

    if (doc!['imageLink'] !=
        'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FuserPlaceholder.png?alt=media&token=1a4e6423-446d-48b5-8bbf-466900c350ec') {
      var imageRef = FirebaseStorage.instance
          .ref('userImages/${FirebaseAuth.instance.currentUser?.uid}');

      await imageRef.delete();
    }

    var chatRef = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants',
            arrayContains: FirebaseAuth.instance.currentUser?.uid)
        .get();

    for (var chat in chatRef.docs) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chat.id)
          .delete();

      try {
        await FirebaseStorage.instance
            .ref('chatMedia/${chat.id}/images')
            .listAll()
            .then((value) {
          for (var element in value.items) {
            FirebaseStorage.instance.ref(element.fullPath).delete();
          }
        });
      } catch (error) {
        print('file not found');
      }

      try {
        await FirebaseStorage.instance
            .ref('chatMedia/${chat.id}/audios')
            .listAll()
            .then((value) {
          for (var element in value.items) {
            FirebaseStorage.instance.ref(element.fullPath).delete();
          }
        });
      } catch (error) {
        print('file not found');
      }
    }

    final Future<SharedPreferences> prefs = SharedPreferences.getInstance();

    final SharedPreferences sharedPrefs = await prefs;

    await sharedPrefs.remove('mail');
    await sharedPrefs.remove('password');
    await sharedPrefs.setBool('saving', false);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .delete();

    await FirebaseAuth.instance.currentUser?.delete();

    deleteUserInfo();
  }

  Future<File> getUserImage({bool overwriteIfExists = false}) async {
    final directory = await appDirectory;
    final path =
        '$directory/${FirebaseAuth.instance.currentUser?.uid}/profilePicture';

    bool existing = await File(path).exists();

    if (!existing || overwriteIfExists) {
      await Dio().download(
        CurrentUser.imageLink,
        path,
      );

      print('Profile picture downloaded!');
    } else {
      print('Image file found');
    }

    return File(path);
  }

  Future<File> getBlurredImage({bool overwriteIfExists = false}) async {
    try {
      final directory = await appDirectory;
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final path = '$directory/$userId/blurredPicture.png';
      final tempFilePath = '$directory/tempFile/$userId.jpg';

      print('Checking if blurred image exists at path: $path');

      bool existing = await File(path).exists();

      if (!existing || overwriteIfExists) {
        print('Blurred image does not exist');

        await Directory('$directory/tempFile').create(recursive: true);

        print('Creating temp file at path: $tempFilePath');

        File compressedFile = await File(tempFilePath).create(recursive: true);

        print('Temp file created, compressing image');

        var compressed = await FlutterImageCompress.compressAndGetFile(
          CurrentUser.imageFile!.path,
          compressedFile.path,
          minHeight: 200,
          minWidth: 200,
          quality: 0,
        );

        print('Compressed to path: ${compressed?.path}');

        if (compressed == null) {
          print('Compression failed');
          throw Exception('Image compression failed');
        }

        File imageFile = File(compressed.path);

        print('Image file path after compression: ${imageFile.path}');

        var uiImage = await compute(blurImage, imageFile);

        print('UI image created');

        var blurredImageDirectory = Directory(path);
        if (await blurredImageDirectory.exists()) {
          await blurredImageDirectory.delete(recursive: true);
        }

        print('Creating new blurred image file at path: $path');

        File file = await File(path).create(recursive: true);

        print('New file path: ${file.path}');

        file.writeAsBytesSync(
          img.encodePng(uiImage),
          mode: FileMode.write,
        );

        await compressedFile.delete();

        print('Image was blurred and saved');
      } else {
        print('Blurred file found at path: $path');
      }

      return File(path);
    } catch (e) {
      print('Error in getBlurredImage: $e');
      rethrow;
    }
  }

  Future<void> getFromDatabase(Map<String, dynamic> jsonFile) async {
    mail = jsonFile['email'];

    name = jsonFile['name'];
    bio = jsonFile['bio'];

    birthday = (jsonFile['birthday'] as Timestamp).toDate();

    gender = stringToGenderEnum(jsonFile['gender']);
    genderPrefs = stringsToGenders(jsonFile['genderPrefs'] as List<dynamic>);

    requestedCreators = await getRequestedCreators();

    publicKey = jsonFile['publicEncryptionKey'];

    final encryption = Encryption();
    await encryption.loadPrivateKey('');

    imageLink = jsonFile['imageLink'];
    imageFile = await getUserImage();
    blurredImage = await getBlurredImage();

    bool settingsExist = jsonFile['notificationSettings'] != null;

    if (settingsExist) {
      var settings = jsonFile['notificationSettings'] as Map;

      showNoteBadges = settings['showBadges'];
      playNoteSound = settings['playSound'];
      vibrateOnNote = settings['activateVibration'];
    } else {
      showNoteBadges = true;
      playNoteSound = true;
      vibrateOnNote = true;
    }

    seenDreamUps = convertSeenVibes(jsonFile);

    List<dynamic> dynamicList = jsonFile['debugTable'];
    debugTable = dynamicList
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    print('debugTable: $debugTable');

    print('got data from firestore');
  }

  Future<List<String>> getRequestedCreators() async {
    List<String> list = [];

    var requested = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('requestedCreators')
        .get();

    for (var doc in requested.docs) {
      var data = doc.data();

      print('got requested: ${data['userId']}');

      list.add(data['userId']);
    }

    return list;
  }

  String genderEnumToString(Gender gender) {
    switch (gender) {
      case Gender.female:
        return 'female';
      case Gender.male:
        return 'male';
      case Gender.diverse:
        return 'diverse';
      case Gender.none:
        return '';
    }
  }

  Gender stringToGenderEnum(String genderString) {
    switch (genderString) {
      case 'female':
        return Gender.female;
      case 'male':
        return Gender.male;
      case 'diverse':
        return Gender.diverse;
      case '':
        return Gender.none;
      default:
        throw Exception('Ungültiger Geschlechts-String: $genderString');
    }
  }

  List<String> gendersToStringList(List<Gender> genders) {
    if (genders.isEmpty) return [];

    return genders.map((gender) {
      switch (gender) {
        case Gender.female:
          return 'female';
        case Gender.male:
          return 'male';
        case Gender.diverse:
          return 'diverse';
        case Gender.none:
          return '';
      }
    }).toList();
  }

  List<Gender> stringsToGenders(List<dynamic> genderStrings) {
    return genderStrings.map((dynamic genderString) {
      switch (genderString) {
        case 'female':
          return Gender.female;
        case 'male':
          return Gender.male;
        case 'diverse':
          return Gender.diverse;
        case '':
          return Gender.none;
        default:
          throw ArgumentError('Ungültige Geschlechtsangabe: $genderString');
      }
    }).toList();
  }

  Future<void> saveSeenVibesToFile(
      Map<String, List<Map<DateTime, DateTime>>> seenVibes) async {
    final directory = await appDirectory;
    final file = File('$directory/tempSeenDreamUps');

    Map<String, List<Map<String, String>>> seenVibesToSave = {};
    seenVibes.forEach((type, typeList) {
      List<Map<String, String>> convertedTypeList = typeList.map((entry) {
        return entry.map((key, value) => MapEntry(
              key.toIso8601String(),
              value.toIso8601String(),
            ));
      }).toList();
      seenVibesToSave[type] = convertedTypeList;
    });

    final jsonString = jsonEncode(seenVibesToSave);
    await file.writeAsString(jsonString);

    print('saved seenDreamUps');
  }

  Future<Map<String, List<Map<DateTime, DateTime>>>>
      loadSeenVibesFromFile() async {
    final directory = await appDirectory;
    final file = File('$directory/tempSeenDreamUps');

    if (await file.exists()) {
      final jsonString = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      Map<String, List<Map<DateTime, DateTime>>> localSeenVibes = {};
      jsonMap.forEach((type, typeList) {
        List<Map<String, dynamic>> typeListDynamic =
            List<Map<String, dynamic>>.from(typeList);

        List<Map<DateTime, DateTime>> convertedTypeList =
            typeListDynamic.map((entry) {
          String loginTimeString = entry.keys.first;
          String createdOnString = entry.values.first;

          DateTime loginTime = DateTime.parse(loginTimeString);
          DateTime createdOn = DateTime.parse(createdOnString);

          return {loginTime: createdOn};
        }).toList();

        localSeenVibes[type] = convertedTypeList;
      });

      return localSeenVibes;
    } else {
      return {};
    }
  }

  Map<String, List<Map<DateTime, DateTime>>> convertSeenVibes(
      Map<String, dynamic> userData) {
    Map<String, List<Map<DateTime, DateTime>>> seenVibes = {};

    try {
      if (userData.containsKey('seenDreamUps')) {
        print('seenDreamUps found');

        Map<String, dynamic> seenVibesData = userData['seenDreamUps'];

        print(seenVibesData);

        seenVibesData.forEach((type, typeList) {
          List<Map<String, dynamic>> typeListDynamic =
              List<Map<String, dynamic>>.from(typeList);

          List<Map<DateTime, DateTime>> convertedTypeList =
              typeListDynamic.map((entry) {
            String loginTimeString = entry.keys.first;
            var createdOnValue = entry.values.first;

            DateTime loginTime = DateTime.parse(loginTimeString);
            DateTime createdOn;

            if (createdOnValue is String) {
              createdOn = DateTime.parse(createdOnValue);
            } else if (createdOnValue is Timestamp) {
              createdOn = createdOnValue.toDate();
            } else {
              throw Exception('Unsupported type for createdOn');
            }

            return {loginTime: createdOn};
          }).toList();

          seenVibes[type] = convertedTypeList;
        });

        print(seenVibes);
      } else {
        print("seenDreamUps-Feld existiert nicht in den Benutzerdaten.");
      }
    } catch (e) {
      print('An error occurred while loading seenDreamUps: $e');
    }

    return seenVibes;
  }

  Future<void> updateSeenDreamUps() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    Map<String, List<Map<String, Timestamp>>> seenVibesToSave = {};

    seenDreamUps.forEach((type, typeList) {
      List<Map<String, Timestamp>> convertedTypeList = typeList.map((entry) {
        return entry.map((key, value) => MapEntry(
              key.toIso8601String(),
              Timestamp.fromDate(value),
            ));
      }).toList();

      seenVibesToSave[type] = convertedTypeList;
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .update({
      'seenDreamUps': seenVibesToSave,
      'debugTable': debugTable,
    });

    print('updated');
  }
}
