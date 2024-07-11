import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:age_calculator/age_calculator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_test/utils/revenueCatProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_keyboard_size/flutter_keyboard_size.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../additionalPages/dreamUpSearch.dart';
import '../additionalPages/loginScreen.dart';
import '../main.dart';
import '../utils/currentUserData.dart';
import '../utils/firebaseUtils.dart';
import '../utils/imageEditingIsolate.dart';

//pods on mac updated

//region Global Variables
int currentIndex = 0;

List<Map<String, dynamic>> dreamUpList = [];

Map<String, List<Map<DateTime, DateTime>>> seenDreamUps = {};
Map<String, List<Map<DateTime, DateTime>>> seenDreamUpsCopy = {};

int backwardCount = 0;

bool isNewDreamUp = true;

bool currentlyFilling = false;

int loadingCounter = 4;

bool filterGender = false;
String filterType = '';

int ageRange = 3;

double currentSheetHeight = 0;

int adFrequency = 10;
int adCounter = 0;

List<Map<String, dynamic>> debugTable = [];

DateTime endPoint = DateTime(2000, 1, 1);

bool refreshing = false;
//endregion

//region UI Logic
class DreamUpThread extends StatefulWidget {
  const DreamUpThread({
    super.key,
  });

  @override
  State<DreamUpThread> createState() => _DreamUpThreadState();
}

class _DreamUpThreadState extends State<DreamUpThread>
    with TickerProviderStateMixin {
  final PageController pageController = PageController(
    initialPage: currentIndex,
    viewportFraction: 1,
  );

  double connectInitSize = 0;

  bool showDebugTool = false;

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Map<String, List<Map<DateTime, DateTime>>> deepCopyMap(
      Map<String, List<Map<DateTime, DateTime>>> original) {
    return original.map((key, value) => MapEntry(
        key,
        value
            .map((innerMap) => innerMap
                .map((innerKey, innerValue) => MapEntry(innerKey, innerValue)))
            .toList()));
  }

  Future<void> setFilterQueries(String filter) async {
    DreamUpAlgorithmManager.QueryList.clear();

    print('filtering by $filter');

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.4,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.width * 0.2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width * 0.05,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );

    if (DreamUpAlgorithmManager.PremiumTypes.contains(filter)) {
      List<String> prefs =
          CurrentUser().gendersToStringList(CurrentUser.genderPrefs);

      if (prefs.isEmpty) {
        prefs = [
          'female',
          'male',
          'diverse',
        ];
      }

      Query query = FirebaseFirestore.instance
          .collection('vibes')
          .where('type', isEqualTo: filter)
          .where('creatorGender', whereIn: prefs)
          .orderBy('createdOn', descending: true)
          .startAfter([Timestamp.fromDate(logInTime)]).limit(1);

      DreamUpAlgorithmManager.QueryList.add(query);

      print('adding query to query list');
    } else {
      Query query = FirebaseFirestore.instance
          .collection('vibes')
          .where('type', isEqualTo: filter)
          .orderBy('createdOn', descending: true)
          .startAfter([Timestamp.fromDate(logInTime)]).limit(1);

      DreamUpAlgorithmManager.QueryList.add(query);

      print('adding query to query list');
    }

    dreamUpList.clear();

    loadingCounter = 4;

    backwardCount = 0;

    currentIndex = 0;

    DreamUpAlgorithmManager.filtering = true;

    await fillDreamUpList();

    print('filled dreamUp list');

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void resetQueries() {
    DreamUpAlgorithmManager.QueryList.clear();

    seenDreamUpsCopy.clear();

    for (String type in DreamUpAlgorithmManager.Types) {
      Query query = FirebaseFirestore.instance
          .collection('vibes')
          .where('type', isEqualTo: type)
          .orderBy('createdOn', descending: true)
          .startAfter([Timestamp.fromDate(logInTime)]).endBefore(
              [Timestamp.fromDate(endPoint)]).limit(1);

      DreamUpAlgorithmManager.QueryList.add(query);
    }
  }

  Future<void> refreshDreamUps() async {
    dreamUpList.clear();

    seenDreamUpsCopy.clear();
    seenDreamUpsCopy = deepCopyMap(seenDreamUps);

    loadingCounter = 4;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.4,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.width * 0.2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width * 0.05,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );

    await getDreamUpQueries();

    isNewDreamUp = true;

    await fillDreamUpList();

    isNewDreamUp = false;

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> pauseAndLoadDreamUps() async {
    print('got in pause and load');

    loadingCounter = 4;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.4,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.width * 0.2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width * 0.05,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );

    while (currentlyFilling) {
      await Future.delayed(Duration.zero);
    }

    print('filling done');

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    refreshing = false;

    pageController.animateToPage(
      currentIndex + 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> initDreamUps() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.4,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.width * 0.2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width * 0.05,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );

    await getDreamUpQueries();

    print('got dreamUp queries!');

    loadingCounter = 4;

    backwardCount = 0;

    await fillDreamUpList();

    print('filled dreamUp list');

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> getDreamUpQueries() async {
    DreamUpAlgorithmManager.QueryList.clear();

    for (var type in DreamUpAlgorithmManager.Types) {
      print('processing $type');

      bool onList =
          seenDreamUps.containsKey(type) && seenDreamUps[type]!.isNotEmpty;

      if (onList) {
        print('$type in seenDreamUpsCopy');

        var last = seenDreamUps[type]!.last;

        var lastLog = last.keys.first;
        var lastCreation = last.values.first;

        AggregateQuerySnapshot aggregation = await FirebaseFirestore.instance
            .collection('vibes')
            .where('type', isEqualTo: type)
            .orderBy('createdOn', descending: true)
            .startAfter([Timestamp.fromDate(logInTime)])
            .endBefore([Timestamp.fromDate(lastLog)])
            .count()
            .get();

        int amount = aggregation.count ?? 0;

        if (amount > 0) {
          print('new dreamUps of $type');

          Query query = FirebaseFirestore.instance
              .collection('vibes')
              .where('type', isEqualTo: type)
              .orderBy('createdOn', descending: true)
              .startAfter([Timestamp.fromDate(logInTime)]).endBefore(
                  [Timestamp.fromDate(lastLog)]).limit(1);

          print('querying dreamups from $logInTime to $lastLog');

          DreamUpAlgorithmManager.QueryList.add(query);

          Map<DateTime, DateTime> entry = {
            logInTime: logInTime,
          };

          seenDreamUps[type]!.add(entry);
        } else {
          print('no new dreamUps of $type');

          if (seenDreamUps[type]!.length > 1) {
            print(
                'several entries of $type --> framing lastCreation and secondLastLogin');

            var secondLast =
                seenDreamUps[type]![seenDreamUps[type]!.length - 2];

            var secondLastLog = secondLast.keys.first;

            Query query = FirebaseFirestore.instance
                .collection('vibes')
                .where('type', isEqualTo: type)
                .orderBy('createdOn', descending: true)
                .startAfter([Timestamp.fromDate(lastCreation)]).endBefore(
                    [Timestamp.fromDate(secondLastLog)]).limit(1);

            print('querying dreamups from $lastCreation to $secondLastLog');

            DreamUpAlgorithmManager.QueryList.add(query);
          } else {
            print('one entry of $type --> framing lastCreation and endPoint');

            Query query = FirebaseFirestore.instance
                .collection('vibes')
                .where('type', isEqualTo: type)
                .orderBy('createdOn', descending: true)
                .startAfter([Timestamp.fromDate(lastCreation)]).endBefore(
                    [Timestamp.fromDate(endPoint)]).limit(1);

            print('querying dreamups from $lastCreation to end');

            DreamUpAlgorithmManager.QueryList.add(query);
          }

          seenDreamUps[type]!.remove(last);

          Map<DateTime, DateTime> entry = {
            logInTime: lastCreation,
          };

          seenDreamUps[type]!.add(entry);
        }
      } else {
        print('$type not in seenDreamUpsCopy');

        Query query = FirebaseFirestore.instance
            .collection('vibes')
            .where('type', isEqualTo: type)
            .orderBy('createdOn', descending: true)
            .startAfter([Timestamp.fromDate(logInTime)]).endBefore(
                [Timestamp.fromDate(endPoint)]).limit(1);

        print('querying dreamups from $logInTime to end');

        DreamUpAlgorithmManager.QueryList.add(query);

        Map<DateTime, DateTime> entry = {
          logInTime: logInTime,
        };

        if (!seenDreamUps.containsKey(type)) {
          seenDreamUps.addAll({
            type: [entry]
          });
        }
      }
    }

    print('seenDreamUps: $seenDreamUps');

    if (seenDreamUpsCopy.isEmpty) {
      seenDreamUpsCopy = deepCopyMap(seenDreamUps);
    }
  }

  bool canAdd(String creator) {
    bool add = true;

    if (userLoggedIn && creator == FirebaseAuth.instance.currentUser!.uid) {
      add = false;
    } else if (CurrentUser.requestedCreators.contains(creator)) {
      add = false;
    }

    return add;
  }

  Future<void> updateDebugTable() async {
    debugTable.clear();

    var dreamUps = await FirebaseFirestore.instance
        .collection('vibes')
        .where('type', whereIn: ['Freundschaft', 'Aktion'])
        .orderBy('createdOn', descending: false)
        .get();

    for (var doc in dreamUps.docs) {
      var data = doc.data();

      String state() {
        String state = 'default';

        if (data['creator'] == FirebaseAuth.instance.currentUser!.uid) {
          state = 'own';
        } else if (CurrentUser.requestedCreators.contains(data['creator'])) {
          state = 'contacted';
        }

        return state;
      }

      var entry = {
        'id': data['id'],
        'title': data['title'],
        'type': data['type'],
        'count': 0,
        'state': state(),
      };

      debugTable.add(entry);
    }
  }

  Future<void> hardResetDreamUps() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.4,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.width * 0.2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width * 0.05,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );

    await abortFilling();

    dreamUpList.clear();
    seenDreamUps.clear();
    seenDreamUpsCopy.clear();
    LoadedImages.clear();

    await DefaultCacheManager().emptyCache();

    DreamUpAlgorithmManager.filtering = false;
    filterType = '';
    applyFilter = false;

    currentIndex = 0;
    backwardCount = 0;

    await updateDebugTable();

    logInTime = DateTime.now();

    isNewDreamUp = true;

    await getDreamUpQueries();

    loadingCounter = 4;

    await fillDreamUpList();

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> softResetDreamUps() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.4,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.width * 0.2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width * 0.05,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );

    await abortFilling();

    dreamUpList.clear();
    seenDreamUpsCopy.clear();
    LoadedImages.clear();

    await DefaultCacheManager().emptyCache();

    DreamUpAlgorithmManager.filtering = false;
    filterType = '';
    applyFilter = false;

    currentIndex = 0;
    backwardCount = 0;

    await getDreamUpQueries();

    loadingCounter = 4;

    isNewDreamUp = true;

    await fillDreamUpList();

    isNewDreamUp = false;

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> abortFilling() async {
    loadingCounter = 0;
    shouldAbort = true;

    while (currentlyFilling) {
      await Future.delayed(Duration.zero);
    }

    shouldAbort = false;

    print('filling was aborted');
  }

  bool shouldAbort = false;

  Future<void> fillDreamUpList() async {
    if (!currentlyFilling) {
      currentlyFilling = true;

      while (loadingCounter > 0) {
        if (shouldAbort) {
          print('Process aborted');
          break;
        }

        if (DreamUpAlgorithmManager.QueryList.isEmpty) {
          print('no more dreamUps available --> resetting queries');

          if (!DreamUpAlgorithmManager.filtering) {
            resetQueries();
          } else {
            print('filtered type is empty --> break');

            loadingCounter = 0;

            break;
          }
        }

        int index = Random().nextInt(DreamUpAlgorithmManager.QueryList.length);

        var query = DreamUpAlgorithmManager.QueryList[index];

        var docs = await query.get();

        if (docs.docs.isEmpty) {
          if (!DreamUpAlgorithmManager.filtering) {
            String type = DreamUpAlgorithmManager.Types[index];

            bool onList = seenDreamUpsCopy.containsKey(type) &&
                seenDreamUpsCopy[type]!.isNotEmpty;

            if (onList) {
              seenDreamUpsCopy[type]!.removeLast();

              int length = seenDreamUpsCopy[type]!.length;

              if (length == 0) {
                /// keine mehr da --> query von liste entfernen

                DreamUpAlgorithmManager.QueryList.remove(query);

                print('no more dreamUps of $type');
              } else if (length == 1) {
                /// lastCreation bis endPoint

                var last = seenDreamUpsCopy[type]!.last;

                var lastCreation = last.values.first;

                DreamUpAlgorithmManager.QueryList[index] =
                    DreamUpAlgorithmManager.QueryList[index].startAfter([
                  Timestamp.fromDate(lastCreation)
                ]).endBefore([Timestamp.fromDate(endPoint)]);

                print('was last entry of $type --> lastCreation till endPoint');
              } else {
                /// lastCreation bis secondLastLog

                var last = seenDreamUpsCopy[type]!.last;

                var lastCreation = last.values.first;

                var secondLast =
                    seenDreamUpsCopy[type]![seenDreamUpsCopy[type]!.length - 2];

                var secondLastLog = secondLast.keys.first;

                DreamUpAlgorithmManager.QueryList[index] =
                    DreamUpAlgorithmManager.QueryList[index].startAfter([
                  Timestamp.fromDate(lastCreation)
                ]).endBefore([Timestamp.fromDate(secondLastLog)]);
              }
            } else {
              print(
                  '$type not in seenDreamUps --> removing from queryList (although no idea how this is possible');

              DreamUpAlgorithmManager.QueryList.remove(query);

              print('no more dreamUps of $type');
            }
          } else {
            print('filtered type is empty');

            loadingCounter = 0;
          }
        } else {
          for (var doc in docs.docs) {
            if (shouldAbort) {
              print('Process aborted');
              break;
            }

            var data = doc.data() as Map<String, dynamic>;

            String type = data['type'];
            String title = data['title'];
            String creator = data['creator'];
            Timestamp createdOn = data['createdOn'] as Timestamp;

            print('got a dreamUp:');
            print('title: $title');
            print('type: $type');

            if (canAdd(creator)) {
              await loadImageAndCache(data);

              print('cached images');

              dreamUpList.add(data);

              print('dreamUps on list: ${dreamUpList.length}');

              if (mounted) {
                setState(() {});
              }

              loadingCounter--;
            } else {
              print('my dramUp or from connected --> not adding');
            }

            DreamUpAlgorithmManager.QueryList[index] = DreamUpAlgorithmManager
                .QueryList[index]
                .startAfter([createdOn]);
          }
        }
      }

      currentlyFilling = false;
    }
  }

  Future<void> loadImageAndCache(
    Map<String, dynamic> data,
  ) async {
    var image = CachedNetworkImageProvider(
      data['imageLink'],
      errorListener: (object) {
        print('image error!');
      },
    );

    await precacheImage(image, context);

    if (!LoadedImages.containsKey(data['id'])) {
      LoadedImages[data['id']] = image;
    }

    var cachedImage =
        await DefaultCacheManager().getSingleFile(data['imageLink']);
    var path = await appDirectory;

    File compressedFile = await compressImage(cachedImage, path, data['id']);
    var uiImage = await compute(blurImage, compressedFile);

    await cacheBlurredImage(uiImage, path, data['id']);
  }

  Future<File> compressImage(
    File cachedImage,
    String path,
    String id,
  ) async {
    File compressedFile =
        await File('$path/compressedImage/$id.jpg').create(recursive: true);
    await FlutterImageCompress.compressAndGetFile(
      cachedImage.path,
      compressedFile.path,
      minHeight: 200,
      minWidth: 200,
      quality: 0,
    );
    return compressedFile;
  }

  Future<void> cacheBlurredImage(
    img.Image uiImage,
    String path,
    String id,
  ) async {
    File file = await File('$path/blurredImage/$id').create(recursive: true);
    file.writeAsBytesSync(img.encodePng(uiImage), mode: FileMode.append);

    var blurredImage = Image.file(
      file,
      width: screenWidth,
      height: screenWidth,
    ).image;

    if (mounted) {
      await precacheImage(blurredImage, context);
    }

    if (!BlurImages.containsKey(id)) {
      BlurImages[id] = blurredImage;
    }
  }

  final DraggableScrollableController connectDragController =
      DraggableScrollableController();

  bool applyFilter = false;

  bool descriptionExpanded = false;

  Future contactCreator(String message) async {
    var creatorId = dreamUpList[currentIndex]['creator'];

    if (!CurrentUser.requestedCreators.contains(creatorId)) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.4,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            height: MediaQuery.of(context).size.width * 0.2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.05,
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );

      var id = dreamUpList[currentIndex]['id'];

      var requestChat = FirebaseFirestore.instance.collection('chats').doc();

      var creatorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(dreamUpList[currentIndex]['creator'])
          .get();
      var creatorInfo = creatorDoc.data()!;

      var name = creatorInfo['name'];

      Map<String, dynamic> chatInfo = {
        'id': requestChat.id,
        'images': {
          FirebaseAuth.instance.currentUser?.uid: CurrentUser.imageLink,
          dreamUpList[currentIndex]['creator']: creatorInfo['imageLink'],
        },
        'lastAction': DateTime.now(),
        'lastSender': FirebaseAuth.instance.currentUser?.uid,
        'lastLogin': {
          FirebaseAuth.instance.currentUser?.uid: DateTime.now(),
          dreamUpList[currentIndex]['creator']: DateTime.now(),
        },
        'names': [
          name,
          CurrentUser.name,
        ],
        'new': true,
        'onlineUsers': [],
        'participants': [
          dreamUpList[currentIndex]['creator'],
        ],
        'users': {
          dreamUpList[currentIndex]['creator']: null,
          FirebaseAuth.instance.currentUser?.uid: null,
        },
        'isRequest': true,
        'publicKeys': {
          FirebaseAuth.instance.currentUser?.uid: CurrentUser.publicKey,
          creatorInfo['id']: creatorInfo['publicEncryptionKey'],
        },
      };

      await requestChat.set(chatInfo);

      DateTime now = DateTime.now();

      DateTime imageTime =
          DateTime(now.year, now.month, now.day, now.hour, now.minute, 0);
      DateTime messageTime =
          DateTime(now.year, now.month, now.day, now.hour, now.minute, 1);
      DateTime systemTime =
          DateTime(now.year, now.month, now.day, now.hour, now.minute, 2);

      var imageDoc = FirebaseFirestore.instance
          .collection('chats')
          .doc(requestChat.id)
          .collection('messages')
          .doc();

      Map<String, dynamic> imageContent = {
        'content': dreamUpList[currentIndex]['imageLink'],
        'createdOn': imageTime,
        'creatorId': FirebaseAuth.instance.currentUser?.uid,
        'imageSubText': dreamUpList[currentIndex]['title'],
        'messageId': imageDoc.id,
        'type': 'image',
      };

      var messageDoc = FirebaseFirestore.instance
          .collection('chats')
          .doc(requestChat.id)
          .collection('messages')
          .doc();

      Map<String, dynamic> messageContent = {
        'content': message,
        'createdOn': messageTime,
        'creatorId': FirebaseAuth.instance.currentUser?.uid,
        'messageId': messageDoc.id,
        'type': 'text',
      };

      var systemDoc = FirebaseFirestore.instance
          .collection('chats')
          .doc(requestChat.id)
          .collection('messages')
          .doc();

      Map<String, dynamic> systemMessage = {
        'content': '',
        'createdOn': systemTime,
        'creatorId': FirebaseAuth.instance.currentUser?.uid,
        'messageId': systemDoc.id,
        'type': 'system',
      };

      await imageDoc.set(imageContent);
      await messageDoc.set(messageContent);

      await systemDoc.set(systemMessage);

      CurrentUser.requestedCreators.add(
        creatorId,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('requestedCreators')
          .add(
        {
          'userId': creatorId,
          'userName': name,
        },
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(creatorId)
          .collection('requestedCreators')
          .add(
        {
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'userName': CurrentUser.name,
        },
      );

      if (creatorInfo['fake'] != null) {
        if (creatorInfo['fake']) {
          var mail = creatorInfo['email'];

          var entry = FirebaseFirestore.instance.collection('contacts').doc();

          var content = {
            'contacter': FirebaseAuth.instance.currentUser?.email,
            'time': DateTime.now(),
            'target': mail,
            'message': message,
          };

          await entry.set(content);
        }
      }

      var token = creatorInfo['firebaseToken'];
      var settings = creatorInfo['notificationSettings'];
      int noteCount = creatorInfo['notificationCount'] ?? 0;

      await FirebaseUtils.sendConnectionMessage(
        recipientToken: token,
        recipientId: creatorInfo['id'],
        recipientNoteCount: noteCount,
        senderName: CurrentUser.name,
        senderId: FirebaseAuth.instance.currentUser!.uid,
        chatId: requestChat.id,
        notificationSettings: settings,
        dreamUpTitle: dreamUpList[currentIndex]['title'],
      );

      int count = 0;

      List<int> indexes = [];

      for (int i = 0; i < dreamUpList.length; i++) {
        var thisVibe = dreamUpList[i];

        if (thisVibe['creator'] == creatorId && thisVibe['id'] != id) {
          if (i <= currentIndex) {
            count++;
          }

          indexes.add(i);
        }
      }

      var reverse = indexes.reversed;

      for (var index in reverse) {
        dreamUpList.removeAt(index);
      }

      currentIndex = max(0, currentIndex - count);

      Fluttertoast.showToast(msg: 'request sent');

      int puffer = dreamUpList.length - currentIndex;
      loadingCounter = puffer > 4 ? 0 : 4 - puffer;

      await fillDreamUpList();

      Navigator.pop(context);

      setState(() {});
    } else {
      Fluttertoast.showToast(
        msg: 'Wie es aussieht, wurde dieser DreamUp gerade gelöscht!',
      );
    }
  }

  void reloadImages() {
    for (var image in LoadedImages.keys) {
      precacheImage(
        LoadedImages[image]!,
        context,
        size: Size(
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.width,
        ),
      );
    }

    for (var image in BlurImages.keys) {
      precacheImage(
        BlurImages[image]!,
        context,
        size: Size(
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.width,
        ),
      );
    }
  }

  TextEditingController contactController = TextEditingController();

  /// real ios Ad ID: "ca-app-pub-4065112952668940/4344940007"
  /// real android Ad ID: "ca-app-pub-4065112952668940/2512983582"

  final interstitialAdId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  InterstitialAd? _interstitialAd;

  /// Loads an interstitial ad.
  void loadAd() {
    final isPremium = Provider.of<RevenueCatProvider>(context, listen: false)
        .isSubscriptionActive;

    if (isPremium) {
      print('User is premium, not loading ads');
      return;
    }

    InterstitialAd.load(
        adUnitId: interstitialAdId,
        request: const AdRequest(
          nonPersonalizedAds: true,
        ),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                print('ad is shown on fullscreen');
              },
              onAdImpression: (ad) {
                print('got impression on ad');
              },
              onAdFailedToShowFullScreenContent: (ad, err) {
                print('could not show ad, error: $err');
              },
              onAdDismissedFullScreenContent: (ad) {
                print('ad closed --> loading again');

                ad.dispose();
                loadAd();
              },
              onAdClicked: (ad) {
                print('clicked ad');
              },
            );

            debugPrint('$ad loaded.');
            // Keep a reference to the ad so you can show it later.
            _interstitialAd = ad;
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
  }

  Widget LoginDialog() {
    return Dialog(
      insetPadding: EdgeInsets.all(
        MediaQuery.of(context).size.width * 0.05,
      ),
      child: Container(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width * 0.05,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Um das zu tun, musst du dich bei DreamUp anmelden.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.width * 0.05,
            ),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  changePage(
                    const LoginPage(),
                  ),
                );

                print('awaited navigator, is called now');

                if (userLoggedIn) {
                  if (!ModalRoute.of(context)!.isCurrent) {
                    Navigator.pop(context);
                  }

                  await softResetDreamUps();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(
                    7,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: const Text(
                  'Zum Login',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateSeenDreamUps(String type, DateTime loginTime, DateTime createdOn) {
    int length = seenDreamUps[type]!.length;

    var last = seenDreamUps[type]!.last;
    var lastLogin = last.keys.first;

    if (length == 1) {
      last[lastLogin] = createdOn;

      print('normally updated');
    } else if (length > 1) {
      var secondLast = seenDreamUps[type]![seenDreamUps[type]!.length - 2];
      var secondLastLogin = secondLast.keys.first;
      var secondLastCreation = secondLast.values.first;

      if (createdOn.isBefore(secondLastLogin)) {
        seenDreamUps[type]!.removeLast();

        Map<DateTime, DateTime> entry = {logInTime: secondLastCreation};

        seenDreamUps[type]!.add(entry);

        print('removed last entry and replaced');
      } else {
        last[lastLogin] = createdOn;

        print('normally updated');
      }
    } else {
      print('no entries of $type in seenDreamUps --> how???');
    }

    // List<Map<DateTime, DateTime>> typeList =
    //     seenDreamUps.putIfAbsent(type, () => []);
    //
    // Map<DateTime, DateTime> newEntry = {
    //   loginTime: createdOn,
    // };
    //
    // if (typeList.isNotEmpty) {
    //   var lastEntry = typeList.last;
    //   if (loginTime != lastEntry.keys.first) {
    //     typeList.add(newEntry);
    //   } else {
    //     typeList.removeLast();
    //     if (typeList.isNotEmpty) {
    //       var secondLastEntry = typeList.last;
    //       if (createdOn.isBefore(secondLastEntry.values.first)) {
    //         typeList.last = newEntry;
    //       } else {
    //         print('something is wrong!');
    //       }
    //     } else {
    //       typeList.add(newEntry);
    //     }
    //   }
    // } else {
    //   typeList.add(newEntry);
    // }
    //
    // print(seenDreamUps);
  }

  Future createUser({required String mail, required int number}) async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    final FirebaseAuth auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final id = user?.uid;

    var newUser = users.doc(id);

    final json = {
      'email': mail,
      'id': id,
      'imageLink':
          'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FuserPlaceholder.png?alt=media&token=1a4e6423-446d-48b5-8bbf-466900c350ec',
      'name': 'User $number',
      'fake': true,
    };

    await newUser.set(json);
  }

  Future createFakeUsers() async {
    for (int i = 0; i < 50; i++) {
      int index = i + 1;

      String mail = 'test@user$index.senthinel';
      String password = 'testuser$index';

      print(mail);
      print(password);

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: mail,
        password: password,
      );

      await createUser(mail: mail, number: index);

      print('$index/50');
    }
  }

  @override
  void initState() {
    super.initState();

    contactController.addListener(() {
      setState(() {});
    });

    currentlyFilling = false;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      reloadImages();

      print('loading Counter: $loadingCounter');

      if (loadingCounter > 0 && loadingCounter < 4) {
        print('cotinue filling');

        await fillDreamUpList();
      }

      if (dreamUpList.isEmpty) {
        await initDreamUps();
      }
    });
  }

  @override
  void dispose() {
    currentlyFilling = false;

    print('disposing thread!');

    connectDragController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<HomeBarControlProvider>(context, listen: true);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black87,
      resizeToAvoidBottomInset: false,
      body: dreamUpList.isEmpty
          ? Container()
          : Stack(
              children: [
                Positioned.fill(
                  child: MainScreenBackground(
                    key: Key(dreamUpList[currentIndex]['id']),
                  ),
                ),
                Positioned.fill(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scroll) {
                      if (scroll is ScrollUpdateNotification) {
                        if (currentIndex == 0 &&
                            scroll.dragDetails != null &&
                            scroll.metrics.pixels <=
                                -MediaQuery.of(context).size.height * 0.1 &&
                            !descriptionExpanded) {
                          if (!DreamUpAlgorithmManager.filtering &&
                              !refreshing) {
                            refreshing = true;

                            Future.delayed(
                              Duration.zero,
                              () async {
                                await refreshDreamUps().then(
                                  (_) {
                                    print('done refreshing');

                                    refreshing = false;
                                  },
                                );
                              },
                            );
                          }
                        }

                        if (scroll.metrics.pixels >=
                                scroll.metrics.maxScrollExtent + 20 &&
                            currentIndex + 1 == dreamUpList.length &&
                            !refreshing) {
                          if (!DreamUpAlgorithmManager.filtering) {
                            print('should go in pause and load');

                            refreshing = true;

                            Future.delayed(
                              Duration.zero,
                              () async {
                                await pauseAndLoadDreamUps();
                              },
                            );
                          } else {
                            print('filtering is over');

                            refreshing = true;

                            Future.delayed(
                              Duration.zero,
                              () async {
                                dreamUpList.clear();

                                currentIndex = 0;
                                backwardCount = 0;

                                applyFilter = false;
                                DreamUpAlgorithmManager.filtering = false;

                                filterType = '';

                                await initDreamUps().then(
                                  (_) {
                                    print('done refreshing');

                                    refreshing = false;

                                    setState(() {});
                                  },
                                );
                              },
                            );
                          }
                        }
                      }

                      return true;
                    },
                    child: PageView.builder(
                      padEnds: false,
                      scrollDirection: Axis.vertical,
                      controller: pageController,
                      physics: descriptionExpanded
                          ? const NeverScrollableScrollPhysics()
                          : const CustomScrollPhysics(),
                      itemCount: dreamUpList.length,
                      itemBuilder: (BuildContext context, int index) {
                        if (isNewDreamUp &&
                            !DreamUpAlgorithmManager.filtering) {
                          print('this is called!');

                          var newVibe = dreamUpList[currentIndex];

                          String id = newVibe['id'];
                          String type = newVibe['type'];
                          DateTime createdOn =
                              (newVibe['createdOn'] as Timestamp).toDate();

                          updateSeenDreamUps(type, logInTime, createdOn);

                          Future.delayed(
                            Duration.zero,
                            () {
                              var dreamUp = debugTable
                                  .firstWhereOrNull((map) => map['id'] == id);

                              if (dreamUp != null) {
                                dreamUp['count']++;
                              }

                              setState(() {});
                            },
                          );

                          isNewDreamUp = false;
                        }

                        return DreamUpScrollItem(
                          key: Key(dreamUpList[currentIndex]['id']),
                          showLoginDialog: () async {
                            showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (context) {
                                return LoginDialog();
                              },
                            );
                          },
                          expandDescription: (expand) {
                            descriptionExpanded = expand;

                            setState(() {});
                          },
                          connectionDragController: connectDragController,
                          vibeData: dreamUpList[index],
                        );
                      },
                      onPageChanged: (ind) async {
                        var oldIndex = currentIndex;
                        bool goingForward;

                        currentIndex = ind;

                        setState(() {});

                        if (currentIndex > oldIndex) {
                          goingForward = true;

                          if (oldIndex == 0 && currentIndex != 1) {
                            goingForward = false;
                          }
                        } else {
                          goingForward = false;

                          if (currentIndex == 0 && oldIndex != 1) {
                            goingForward = true;
                          }
                        }

                        if (goingForward && backwardCount < 1) {
                          if (!DreamUpAlgorithmManager.filtering) {
                            isNewDreamUp = true;
                          }

                          adCounter++;
                        }

                        if (goingForward && backwardCount > 0) {
                          backwardCount--;
                        } else if (!goingForward) {
                          backwardCount++;
                        }

                        if (goingForward) {
                          loadingCounter++;

                          fillDreamUpList();
                        }

                        if (userLoggedIn) {
                          final isPremium = Provider.of<RevenueCatProvider>(
                                  context,
                                  listen: false)
                              .isSubscriptionActive;

                          if (!isPremium) {
                            if (adCounter % adFrequency == 0) {
                              _interstitialAd?.show();
                            }
                          }
                        } else {
                          if (adCounter % adFrequency == 0) {
                            _interstitialAd?.show();
                          }
                        }

                        setState(() {});
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: Duration.zero,
                    opacity: 1 - currentSheetHeight / 0.8,
                    child: SizedBox(
                      height: 50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (userLoggedIn) {
                                Navigator.push(
                                  context,
                                  changePage(
                                    const DreamUpSearchPage(),
                                  ),
                                );
                              } else {
                                showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (context) {
                                    return LoginDialog();
                                  },
                                );
                              }
                            },
                            child: Container(
                              color: Colors.transparent,
                              width: MediaQuery.of(context).size.width * 0.15,
                              child: const Center(
                                child: DecoratedIcon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 10,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (!refreshing) {
                                refreshing = true;

                                await hardResetDreamUps();

                                refreshing = false;
                              }
                            },
                            child: Container(
                              height: 50,
                              width: MediaQuery.of(context).size.width * 0.6,
                              color: Colors.transparent,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (userLoggedIn) {
                                applyFilter
                                    ? applyFilter = false
                                    : applyFilter = true;

                                setState(() {});
                              } else {
                                showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (context) {
                                    return LoginDialog();
                                  },
                                );
                              }
                            },
                            child: Container(
                              color: Colors.transparent,
                              width: MediaQuery.of(context).size.width * 0.15,
                              child: Center(
                                child: DecoratedIcon(
                                  DreamUpAlgorithmManager.filtering
                                      ? Icons.filter_alt
                                      : Icons.filter_alt_outlined,
                                  color: DreamUpAlgorithmManager.filtering
                                      ? Colors.blue
                                      : Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 10,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 50,
                  left: 0,
                  child: Container(
                    color: Colors.transparent,
                    height: 50,
                    width: 70,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showDebugTool
                              ? showDebugTool = false
                              : showDebugTool = true;
                        });
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 55,
                  left: MediaQuery.of(context).size.width * 0.025,
                  child: Visibility(
                    visible: showDebugTool,
                    child: GestureDetector(
                      onTap: () async {
                        showDebugTool = false;

                        setState(() {});
                      },
                      child: Container(
                        color: Colors.white.withOpacity(0.7),
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.4,
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${debugTable.fold(0, (sum, map) => sum + (map['count'] as int))}/${debugTable.length} DreamUps seen',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    showDebugTool = false;

                                    setState(() {});
                                  },
                                  child: const Icon(
                                    Icons.cancel,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Aktionen',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.only(
                                        left: 10,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: debugTable
                                            .where((map) =>
                                                map['type'] == 'Aktion')
                                            .toList()
                                            .map<Widget>((entry) {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                entry['title'],
                                                style: TextStyle(
                                                  color: entry['state'] ==
                                                          'connected'
                                                      ? Colors.red
                                                      : entry['state'] == 'own'
                                                          ? Colors.blueAccent
                                                          : Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                entry['count'].toString(),
                                                style: TextStyle(
                                                  color: entry['state'] ==
                                                          'connected'
                                                      ? Colors.red
                                                      : entry['state'] == 'own'
                                                          ? Colors.blueAccent
                                                          : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const Text(
                                      'Freundschaften',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.only(
                                        left: 10,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: debugTable
                                            .where((map) =>
                                                map['type'] == 'Freundschaft')
                                            .toList()
                                            .map<Widget>((entry) {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                entry['title'],
                                                style: TextStyle(
                                                  color: entry['state'] ==
                                                          'connected'
                                                      ? Colors.red
                                                      : entry['state'] == 'own'
                                                          ? Colors.blueAccent
                                                          : Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                entry['count'].toString(),
                                                style: TextStyle(
                                                  color: entry['state'] ==
                                                          'connected'
                                                      ? Colors.red
                                                      : entry['state'] == 'own'
                                                          ? Colors.blueAccent
                                                          : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Visibility(
                    visible: applyFilter,
                    child: GestureDetector(
                      onTap: () {
                        applyFilter = false;

                        setState(() {});
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Stack(
                          children: [
                            Positioned(
                              top: MediaQuery.of(context).padding.top + 55,
                              right: MediaQuery.of(context).size.width * 0.025,
                              child: DreamUpFilterWidget(
                                filterVibes: (String type, bool gender) async {
                                  filterType = type;

                                  if (!refreshing) {
                                    refreshing = true;

                                    DreamUpAlgorithmManager.filtering = true;

                                    currentlyFilling = false;
                                    loadingCounter = 0;

                                    dreamUpList.clear();
                                    currentIndex = 0;

                                    seenDreamUpsCopy.clear();

                                    await setFilterQueries(type);

                                    refreshing = false;

                                    applyFilter = false;
                                    setState(() {});
                                  }
                                },
                                resetVibes: () async {
                                  if (!refreshing) {
                                    refreshing = true;

                                    await softResetDreamUps();

                                    refreshing = false;
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      setState(() {
                        currentSheetHeight = notification.extent;
                        connectInitSize = notification.extent;
                      });

                      if (notification.extent == 0 && connectInitSize != 0) {
                        connectInitSize = 0;
                        currentSheetHeight = 0;

                        provider.showHomeBar();
                      }

                      if (notification.extent <= 0.1) {
                        provider.showHomeBar();
                      }

                      if (notification.extent <= 0.02) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      }

                      return true;
                    },
                    child: DraggableScrollableSheet(
                      maxChildSize: 0.8,
                      minChildSize: 0,
                      initialChildSize: connectInitSize,
                      controller: connectDragController,
                      snap: true,
                      builder: (context, scrollController) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(
                                MediaQuery.of(context).size.width * 0.05,
                              ),
                              topLeft: Radius.circular(
                                MediaQuery.of(context).size.width * 0.05,
                              ),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, -1),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.width * 0.1,
                            left: MediaQuery.of(context).size.width * 0.05,
                            right: MediaQuery.of(context).size.width * 0.05,
                          ),
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: dreamUpList.isNotEmpty &&
                                  (dreamUpList[currentIndex]['creator'] !=
                                          FirebaseAuth
                                              .instance.currentUser?.uid ||
                                      !userLoggedIn)
                              ? Column(
                                  children: [
                                    Expanded(
                                      child: SingleChildScrollView(
                                        padding: EdgeInsets.zero,
                                        controller: scrollController,
                                        physics: const BouncingScrollPhysics(),
                                        child: SizedBox(
                                          height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.8 -
                                              MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.1,
                                          child: Column(
                                            children: [
                                              Text(
                                                'Hier kannst du den Ersteller von \n"${dreamUpList[currentIndex]['title']}"\nkontaktieren.',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.05,
                                              ),
                                              Center(
                                                child: SizedBox(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.3,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.3,
                                                  child: ClipOval(
                                                    child: Image(
                                                      image: dreamUpList
                                                                  .isNotEmpty &&
                                                              LoadedImages
                                                                  .isNotEmpty
                                                          ? LoadedImages[
                                                              dreamUpList[
                                                                      currentIndex]
                                                                  ['id']]!
                                                          : Image.asset(
                                                                  'assets/images/ucImages/ostseeQuadrat.jpg')
                                                              .image,
                                                      fit: BoxFit.fill,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.05,
                                              ),
                                              dreamUpList[currentIndex][
                                                              'keyQuestions'] !=
                                                          null &&
                                                      dreamUpList[currentIndex]
                                                              ['keyQuestions']
                                                          .isNotEmpty
                                                  ? SingleChildScrollView(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                            'Der Ersteller möchte wissen:',
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              color: Colors
                                                                  .black54,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: (dreamUpList[
                                                                            currentIndex]
                                                                        [
                                                                        'keyQuestions']
                                                                    as List<
                                                                        dynamic>)
                                                                .map<Widget>(
                                                                  (question) =>
                                                                      Container(
                                                                    margin:
                                                                        const EdgeInsets
                                                                            .only(
                                                                      top: 10,
                                                                    ),
                                                                    child: Text(
                                                                      question,
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        color: Colors
                                                                            .black54,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                                .toList(),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : CurrentUser
                                                          .requestedCreators
                                                          .contains(dreamUpList[
                                                                  currentIndex]
                                                              ['id'])
                                                      ? const Text(
                                                          'Du hast diesen User bereits kontaktiert.',
                                                          textAlign:
                                                              TextAlign.start,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 18,
                                                            color:
                                                                Colors.black54,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        )
                                                      : const Text(
                                                          'Schreibe dem Ersteller eine kurze Nachricht.',
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            color:
                                                                Colors.black54,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                              Expanded(
                                                child: Container(),
                                              ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(7),
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                      ),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        horizontal:
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.03,
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextField(
                                                              enableSuggestions:
                                                                  true,
                                                              autocorrect: true,
                                                              enabled: !CurrentUser
                                                                  .requestedCreators
                                                                  .contains(
                                                                      dreamUpList[
                                                                              currentIndex]
                                                                          [
                                                                          'id']),
                                                              controller:
                                                                  contactController,
                                                              textCapitalization:
                                                                  TextCapitalization
                                                                      .sentences,
                                                              onChanged:
                                                                  (text) {
                                                                setState(() {});
                                                              },
                                                              decoration:
                                                                  InputDecoration(
                                                                border:
                                                                    InputBorder
                                                                        .none,
                                                                hintText: CurrentUser
                                                                        .requestedCreators
                                                                        .contains(dreamUpList[currentIndex]
                                                                            [
                                                                            'id'])
                                                                    ? 'Du hast diesen Ersteller bereits kontaktiert'
                                                                    : 'Deine Nachricht',
                                                              ),
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () async {
                                                              contactController
                                                                  .text = '';

                                                              setState(() {});
                                                            },
                                                            child: CurrentUser
                                                                    .requestedCreators
                                                                    .contains(dreamUpList[
                                                                            currentIndex]
                                                                        ['id'])
                                                                ? Container()
                                                                : AnimatedContainer(
                                                                    duration:
                                                                        Duration(
                                                                      milliseconds:
                                                                          animationSpeed,
                                                                    ),
                                                                    color: Colors
                                                                        .transparent,
                                                                    width: 20,
                                                                    margin:
                                                                        EdgeInsets
                                                                            .only(
                                                                      left: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.01,
                                                                    ),
                                                                    child:
                                                                        AnimatedOpacity(
                                                                      duration:
                                                                          Duration(
                                                                        milliseconds:
                                                                            (animationSpeed * 0.5).toInt(),
                                                                      ),
                                                                      opacity:
                                                                          1,
                                                                      child:
                                                                          const Icon(
                                                                        Icons
                                                                            .cancel_outlined,
                                                                        size:
                                                                            20,
                                                                      ),
                                                                    ),
                                                                  ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      await contactCreator(
                                                              contactController
                                                                  .text)
                                                          .then((value) {
                                                        contactController.text =
                                                            '';

                                                        connectDragController
                                                            .animateTo(
                                                          0,
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      250),
                                                          curve: Curves
                                                              .fastOutSlowIn,
                                                        );
                                                      });
                                                    },
                                                    child: AnimatedContainer(
                                                      duration: Duration(
                                                        milliseconds:
                                                            animationSpeed,
                                                      ),
                                                      height: CurrentUser
                                                              .requestedCreators
                                                              .contains(dreamUpList[
                                                                      currentIndex]
                                                                  ['id'])
                                                          ? 0
                                                          : 50,
                                                      width: CurrentUser
                                                              .requestedCreators
                                                              .contains(dreamUpList[
                                                                      currentIndex]
                                                                  ['id'])
                                                          ? 0
                                                          : 50,
                                                      color: Colors.transparent,
                                                      padding: EdgeInsets.only(
                                                        left: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.02,
                                                      ),
                                                      child: Center(
                                                        child: AnimatedOpacity(
                                                          duration: Duration(
                                                            milliseconds:
                                                                animationSpeed,
                                                          ),
                                                          opacity: CurrentUser
                                                                  .requestedCreators
                                                                  .contains(
                                                                      dreamUpList[
                                                                              currentIndex]
                                                                          [
                                                                          'id'])
                                                              ? 0
                                                              : 1,
                                                          child: const Icon(
                                                            Icons.send,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.02 +
                                                    MediaQuery.of(context)
                                                        .padding
                                                        .bottom,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView(
                                  controller: scrollController,
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class MainScreenBackground extends StatefulWidget {
  const MainScreenBackground({
    super.key,
  });

  @override
  State<MainScreenBackground> createState() => _MainScreenBackgroundState();
}

class _MainScreenBackgroundState extends State<MainScreenBackground> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.width,
                width: MediaQuery.of(context).size.width,
                child: Image(
                  image: dreamUpList.isNotEmpty && BlurImages.isNotEmpty
                      ? BlurImages[dreamUpList[currentIndex]['id']]!
                      : Image.asset('assets/images/ucImages/ostseeQuadrat.jpg')
                          .image,
                  fit: BoxFit.fill,
                  height: MediaQuery.of(context).size.width,
                  width: MediaQuery.of(context).size.width,
                  gaplessPlayback: true,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 3,
                child: Transform.rotate(
                  angle: 180 * pi / 180,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: Image(
                      image: dreamUpList.isNotEmpty && BlurImages.isNotEmpty
                          ? BlurImages[dreamUpList[currentIndex]['id']]!
                          : Image.asset(
                              'assets/images/ucImages/ostseeQuadrat.jpg',
                            ).image,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.width * 0.7,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [
                  0,
                  1,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: SizedBox(
            height: MediaQuery.of(context).size.width,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [
                        0.4,
                        1,
                      ],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image(
                    image: dreamUpList.isNotEmpty && LoadedImages.isNotEmpty
                        ? LoadedImages[dreamUpList[currentIndex]['id']]!
                        : Image.asset(
                                'assets/images/ucImages/ostseeQuadrat.jpg')
                            .image,
                    fit: BoxFit.fill,
                    height: MediaQuery.of(context).size.width,
                    width: MediaQuery.of(context).size.width,
                    gaplessPlayback: true,
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [
                        0,
                        0.5,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DreamUpFilterWidget extends StatefulWidget {
  final void Function(String filterType, bool filterGender) filterVibes;
  final void Function() resetVibes;

  const DreamUpFilterWidget({
    super.key,
    required this.filterVibes,
    required this.resetVibes,
  });

  @override
  State<DreamUpFilterWidget> createState() => _DreamUpFilterWidgetState();
}

class _DreamUpFilterWidgetState extends State<DreamUpFilterWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(-1, 1),
            color: Colors.black54,
          ),
        ],
      ),
      width: MediaQuery.of(context).size.width * 0.7,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // GestureDetector(
          //   onTap: () {
          //     filterGender = !filterGender;
          //
          //     setState(() {});
          //   },
          //   child: Container(
          //     color: Colors.transparent,
          //     child: Row(
          //       children: [
          //         Checkbox(
          //           value: filterGender,
          //           onChanged: (bool? value) {
          //             filterGender = !filterGender;
          //
          //             setState(() {});
          //           },
          //         ),
          //         Text(
          //           'Dein Geschlecht',
          //           style: TextStyle(
          //             color: Colors.black87,
          //             fontWeight: 'gender' == filterType
          //                 ? FontWeight.bold
          //                 : FontWeight.normal,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          // Container(
          //   width: MediaQuery.of(context).size.width * 0.7,
          //   color: Colors.black54,
          //   height: 1,
          // ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: DreamUpAlgorithmManager.Types.map<Widget>((type) {
              return GestureDetector(
                onTap: () {
                  filterType != type ? filterType = type : filterType = '';

                  setState(() {});
                },
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Radio(
                        value: type,
                        toggleable: true,
                        groupValue: filterType,
                        onChanged: (String? value) {
                          filterType != type
                              ? filterType = value!
                              : filterType = '';

                          setState(() {});
                        },
                      ),
                      Text(
                        type,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: type == filterType
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          Consumer<RevenueCatProvider>(
            builder: (context, revenueCatProvider, _) {
              return Visibility(
                visible: revenueCatProvider.isSubscriptionActive,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      DreamUpAlgorithmManager.PremiumTypes.map<Widget>((type) {
                    return GestureDetector(
                      onTap: () {
                        filterType != type
                            ? filterType = type
                            : filterType = '';

                        setState(() {});
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Radio(
                              value: type,
                              toggleable: true,
                              groupValue: filterType,
                              onChanged: (String? value) {
                                filterType != type
                                    ? filterType = value!
                                    : filterType = '';

                                setState(() {});
                              },
                            ),
                            Text(
                              type,
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: type == filterType
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          Center(
            child: GestureDetector(
              onTap: () async {
                filterType != '' || filterGender
                    ? widget.filterVibes(filterType, filterGender)
                    : widget.resetVibes();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(250),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                margin: const EdgeInsets.only(
                  bottom: 15,
                  top: 15,
                ),
                child: const Text(
                  'Filtern',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DreamUpScrollItem extends StatefulWidget {
  final void Function() showLoginDialog;
  final void Function(bool expand) expandDescription;
  final DraggableScrollableController connectionDragController;
  final Map<String, dynamic> vibeData;

  const DreamUpScrollItem({
    super.key,
    required this.showLoginDialog,
    required this.expandDescription,
    required this.connectionDragController,
    required this.vibeData,
  });

  @override
  State<DreamUpScrollItem> createState() => _DreamUpScrollItemState();
}

class _DreamUpScrollItemState extends State<DreamUpScrollItem>
    with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  int counter = 0;

  bool hasKeyQuestions = true;

  final scrollController = ScrollController();

  late final Map<String, dynamic> vibeData;

  GlobalKey textKey = GlobalKey();
  GlobalKey readMoreKey = GlobalKey();

  double? textHeight;
  double? scrollerHeight;
  double? readMoreHeight;

  bool needsScroller = true;

  bool descriptionExpanded = false;

  String getGender(String? originalGender) {
    String gender = '';

    if (originalGender == 'male') {
      gender = 'männlich';
    } else if (originalGender == 'female') {
      gender = 'weiblich';
    } else if (originalGender == 'diverse') {
      gender = 'divers';
    } else if (originalGender == null) {
      gender = 'unbekannt';
    }

    return gender;
  }

  String getAge(DateTime birthday) {
    String age = '';

    var years = AgeCalculator.age(
      birthday,
    ).years;

    int myAge = AgeCalculator.age(
      CurrentUser.birthday,
    ).years;

    if (myAge == 0) {
      age = 'unbekannt';
    } else if (years > myAge + ageRange) {
      age = 'älter';
    } else if (years < myAge - ageRange) {
      age = 'jünger';
    } else {
      age = 'dein Alter';
    }

    return age;
  }

  double containerHeight() {
    double value = 0;

    var minHeight = MediaQuery.of(context).size.width * 0.15 + 10;
    var maxHeight = MediaQuery.of(context).size.width;

    value = (1 - (currentSheetHeight / 0.8)) * maxHeight +
        (currentSheetHeight / 0.8) * minHeight;

    return value;
  }

  @override
  void initState() {
    super.initState();

    vibeData = widget.vibeData;

    if (widget.vibeData['keyQuestions'] != null &&
        widget.vibeData['keyQuestions'].isNotEmpty) {
      hasKeyQuestions = true;
    } else {
      hasKeyQuestions = false;
    }

    scrollController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var textContext = textKey.currentContext;
      var readMoreContext = readMoreKey.currentContext;

      if (textContext != null) {
        textHeight = textContext.size!.height;
      }

      if (readMoreContext != null) {
        readMoreHeight = readMoreContext.size!.height;
      }

      if (vibeData['audioLink'] != null) {
        needsScroller = false;
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<HomeBarControlProvider>(context, listen: true);

    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: Duration(
              milliseconds: currentSheetHeight > 0 ? 0 : animationSpeed,
            ),
            height: currentSheetHeight > 0
                ? containerHeight()
                : descriptionExpanded
                    ? MediaQuery.of(context).padding.top + 50
                    : MediaQuery.of(context).size.width,
          ),
          Container(
            margin: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.05,
            ),
            width: MediaQuery.of(context).size.width * 0.9,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vibeData['title'],
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                Text(
                  (userLoggedIn && vibeData['creator'] == currentUser)
                      ? 'dein DreamUp'
                      : userLoggedIn
                          ? '${getGender(vibeData['creatorGender'])}, ${getAge((vibeData['creatorBirthday'].toDate()))}'
                          : getGender(vibeData['creatorGender']),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        offset: Offset(1, 1),
                      ),
                    ],
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.1,
              vertical: MediaQuery.of(context).size.width * 0.05,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    if (userLoggedIn) {
                      if (dreamUpList[currentIndex]['creator'] != currentUser) {
                        widget.connectionDragController
                            .animateTo(
                              0.8,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.fastOutSlowIn,
                            )
                            .then((value) => provider.hideHomeBar());
                      }
                    } else {
                      widget.showLoginDialog();
                    }
                  },
                  child: SizedBox(
                    height: 25,
                    width: 25,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 1,
                          bottom: 4,
                          child: Transform.rotate(
                            angle: -24 * pi / 180,
                            child: Opacity(
                              opacity: 1 - (currentSheetHeight / 0.8),
                              child: DecoratedIcon(
                                Icons.send_rounded,
                                color: Colors.white.withOpacity(0.8),
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 5,
                                    offset: Offset(
                                      1,
                                      1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Opacity(
              opacity: 1 - (currentSheetHeight / 0.8),
              child: Container(
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.1,
                  right: MediaQuery.of(context).size.width * 0.1,
                ),
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {
                    if (needsScroller) {
                      if (descriptionExpanded) {
                        descriptionExpanded = false;

                        widget.expandDescription(false);
                      } else {
                        descriptionExpanded = true;

                        widget.expandDescription(true);
                      }

                      counter++;

                      setState(() {});
                    }
                  },
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    key: Key(
                      counter.toString(),
                    ),
                    physics: descriptionExpanded
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    children: [
                      Column(
                        key: textKey,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            vibeData['content'],
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 5,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          vibeData['hashtags'] != null
                              ? Container(
                                  margin: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Wrap(
                                    spacing: MediaQuery.of(context).size.width *
                                        0.02,
                                    runSpacing:
                                        MediaQuery.of(context).size.width *
                                            0.02,
                                    children: (vibeData['hashtags']
                                            as List<dynamic>)
                                        .map<Widget>(
                                          (hashtag) => Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(200),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.02,
                                              vertical: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.01,
                                            ),
                                            child: Text(
                                              hashtag,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black
                                                    .withOpacity(0.8),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: needsScroller,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (descriptionExpanded) {
                    descriptionExpanded = false;

                    widget.expandDescription(false);
                  } else {
                    descriptionExpanded = true;

                    widget.expandDescription(true);
                  }

                  counter++;

                  setState(() {});
                },
                child: Container(
                  key: readMoreKey,
                  color: Colors.transparent,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.02,
                    bottom: MediaQuery.of(context).size.width * 0.05,
                  ),
                  child: Text(
                    descriptionExpanded ? 'read less' : 'read more',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 10,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: homeBarHeight,
          ),
        ],
      ),
    );
  }
}
//endregion

//region Business Logic
class DreamUpAlgorithmManager {
  static bool filtering = false;

  static List<String> Types = [
    'Aktion',
    'Freundschaft',
  ];

  static List<String> PremiumTypes = [
    'Date',
    'Beziehung',
  ];

  static List<Query> QueryList = [];
}

class CustomScrollPhysics extends ScrollPhysics {
  const CustomScrollPhysics({super.parent});

  @override
  ScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 0;

  @override
  double get minFlingDistance => 5;

  double frictionFactor(double overscrollFraction) =>
      0.52 * pow(1 - overscrollFraction, 2);

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    if (!position.outOfRange) {
      return offset;
    }

    final double overscrollPastStart =
        max(position.minScrollExtent - position.pixels, 0.0);
    final double overscrollPastEnd =
        max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast = max(overscrollPastStart, overscrollPastEnd);
    final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) ||
        (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
        ? frictionFactor(
            (overscrollPast - offset.abs()) / position.viewportDimension)
        : frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;

    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  static double _applyFriction(
      double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) {
        return absDelta * gamma;
      }
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) => 0.0;

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Tolerance tolerance = toleranceFor(position); // Verwende toleranceFor
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity.sign *
        min(0.000816 * pow(existingVelocity.abs(), 1.967).toDouble(), 40000.0);
  }

  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}
//endregion
