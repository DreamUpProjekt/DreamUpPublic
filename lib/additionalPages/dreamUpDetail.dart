import 'dart:io';
import 'dart:math';

import 'package:age_calculator/age_calculator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import '../mainScreens/thread.dart';
import '../utils/currentUserData.dart';
import '../utils/firebaseUtils.dart';
import '../utils/imageEditingIsolate.dart';
import 'dreamUpEdit.dart';

//region Global Variables
Map<String, dynamic> creatorInfo = {};
List<Map<String, dynamic>> creatorWishes = [];

bool loading = false;

ImageProvider? dreamUpImage;
ImageProvider? blurredImage;
//endregion

//region UI Logic
class DreamUpDetailPage extends StatefulWidget {
  final Map<String, dynamic> dreamUpData;

  const DreamUpDetailPage({
    super.key,
    required this.dreamUpData,
  });

  @override
  State<DreamUpDetailPage> createState() => _DreamUpDetailPageState();
}

class _DreamUpDetailPageState extends State<DreamUpDetailPage>
    with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  int counter = 0;

  bool hasKeyQuestions = true;

  final scrollController = ScrollController();

  bool needsScroller = true;

  bool descriptionExpanded = false;

  late DraggableScrollableController connectDragController;
  late DraggableScrollableController profileDragController;

  double connectInitSize = 0;

  double currentSheetHeight = 0;

  bool uploading = false;

  List<Map<String, dynamic>> contactInfo = [];

  Future contactCreator(String message) async {
    var creatorId = widget.dreamUpData['creator'];

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

      var id = widget.dreamUpData['id'];

      var requestChat = FirebaseFirestore.instance.collection('chats').doc();

      var creatorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.dreamUpData['creator'])
          .get();
      var creatorInfo = creatorDoc.data()!;

      var name = creatorInfo['name'];

      Map<String, dynamic> chatInfo = {
        'id': requestChat.id,
        'images': {
          currentUser: CurrentUser.imageLink,
          widget.dreamUpData['creator']: creatorInfo['imageLink'],
        },
        'lastAction': DateTime.now(),
        'lastSender': currentUser,
        'lastLogin': {
          currentUser: DateTime.now(),
          widget.dreamUpData['creator']: DateTime.now(),
        },
        'names': [
          name,
          CurrentUser.name,
        ],
        'new': true,
        'onlineUsers': [],
        'participants': [
          widget.dreamUpData['creator'],
        ],
        'users': {
          widget.dreamUpData['creator']: null,
          currentUser: null,
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
        'content': widget.dreamUpData['imageLink'],
        'createdOn': imageTime,
        'creatorId': currentUser,
        'imageSubText': widget.dreamUpData['title'],
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
        'creatorId': currentUser,
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
        'creatorId': currentUser,
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
          .doc(currentUser)
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
          'userId': currentUser,
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
        dreamUpTitle: widget.dreamUpData['title'],
      );

      int count = 0;

      List<int> indexes = [];

      for (int i = 0; i < dreamUpList.length; i++) {
        var thisVibe = widget.dreamUpData;

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

      contactInfo.clear();

      int puffer = dreamUpList.length - currentIndex;
      loadingCounter = puffer > 4 ? 0 : 4 - puffer;

      Navigator.pop(context);

      setState(() {});
    } else {
      Fluttertoast.showToast(
        msg: 'Wie es aussieht, wurde dieser DreamUp gerade gelöscht!',
      );
    }
  }

  bool showPopUp = false;

  bool myDreamUp = false;

  GlobalKey textKey = GlobalKey();
  GlobalKey readMoreKey = GlobalKey();

  double textHeight = 0;
  double scrollerHeight = 0;
  double readMoreHeight = 0;

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
    var myAge = AgeCalculator.age(
      CurrentUser.birthday,
    ).years;

    if (years > myAge + ageRange) {
      age = 'älter';
    } else if (years < myAge - ageRange) {
      age = 'jünger';
    } else {
      age = 'dein Alter';
    }

    return age;
  }

  TextEditingController contactController = TextEditingController();

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

    if (widget.dreamUpData['creator'] == currentUser) {
      myDreamUp = true;
    } else {
      myDreamUp = false;
    }

    connectDragController = DraggableScrollableController();
    profileDragController = DraggableScrollableController();

    if (widget.dreamUpData['keyQuestions'] != null &&
        widget.dreamUpData['keyQuestions'].isNotEmpty) {
      hasKeyQuestions = true;
    } else {
      hasKeyQuestions = false;
    }

    scrollController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.dreamUpData['content'] == '') {
        needsScroller = false;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    connectDragController.dispose();

    scrollController.dispose();

    dreamUpImage = null;
    blurredImage = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {
          if (showPopUp) {
            showPopUp = false;

            setState(() {});
          }
        },
        child: SizedBox.expand(
          child: Stack(
            children: [
              DreamUpDetailBackground(
                dreamUpData: widget.dreamUpData,
              ),
              SizedBox.expand(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: Duration(
                        milliseconds:
                            currentSheetHeight > 0 ? 0 : animationSpeed,
                      ),
                      height: currentSheetHeight > 0
                          ? containerHeight()
                          : descriptionExpanded
                              ? MediaQuery.of(context).size.width * 0.15 + 10
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
                            widget.dreamUpData['title'],
                            textAlign: TextAlign.start,
                            style: const TextStyle(
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
                            widget.dreamUpData['creator'] == currentUser
                                ? 'dein DreamUp'
                                : '${getGender(widget.dreamUpData['creatorGender'])}, ${getAge((widget.dreamUpData['creatorBirthday'].toDate()))}',
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
                              if (widget.dreamUpData['creator'] !=
                                  currentUser) {
                                connectDragController.animateTo(
                                  0.8,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.fastOutSlowIn,
                                );
                              } else {
                                Fluttertoast.showToast(
                                    msg: "Dies ist dein DreamUp!");
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
                                } else {
                                  descriptionExpanded = true;
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
                                      widget.dreamUpData['content'],
                                      textAlign: TextAlign.start,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black87,
                                            blurRadius: 5,
                                            offset: Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    widget.dreamUpData['hashtags'] != null
                                        ? Container(
                                            margin: EdgeInsets.only(
                                              top: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.05,
                                            ),
                                            alignment: Alignment.centerLeft,
                                            child: Wrap(
                                              spacing: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.02,
                                              runSpacing: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.02,
                                              children: (widget.dreamUpData[
                                                          'hashtags']
                                                      as List<dynamic>)
                                                  .map<Widget>(
                                                    (hashtag) => Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(200),
                                                      ),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        horizontal:
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.02,
                                                        vertical: MediaQuery.of(
                                                                    context)
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
                            } else {
                              descriptionExpanded = true;
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
                  ],
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
                        child: widget.dreamUpData['creator'] != currentUser
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
                                            MediaQuery.of(context).size.width *
                                                0.1,
                                        child: Column(
                                          children: [
                                            Text(
                                              'Hier kannst du den Ersteller von \n"${widget.dreamUpData['title']}"\nkontaktieren.',
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
                                                    image: LoadedImages
                                                            .containsKey(widget
                                                                    .dreamUpData[
                                                                'id'])
                                                        ? LoadedImages[widget
                                                            .dreamUpData['id']]!
                                                        : CachedNetworkImageProvider(
                                                            widget.dreamUpData[
                                                                'imageLink'],
                                                          ),
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
                                            widget.dreamUpData[
                                                            'keyQuestions'] !=
                                                        null &&
                                                    widget
                                                        .dreamUpData[
                                                            'keyQuestions']
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
                                                            color:
                                                                Colors.black54,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Column(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: (widget
                                                                          .dreamUpData[
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
                                                : CurrentUser.requestedCreators
                                                        .contains(widget
                                                            .dreamUpData['id'])
                                                    ? const Text(
                                                        'Du hast diesen User bereits kontaktiert.',
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          color: Colors.black54,
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
                                                          color: Colors.black54,
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
                                                          BorderRadius.circular(
                                                              7),
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          MediaQuery.of(context)
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
                                                                .contains(widget
                                                                        .dreamUpData[
                                                                    'id']),
                                                            controller:
                                                                contactController,
                                                            textCapitalization:
                                                                TextCapitalization
                                                                    .sentences,
                                                            onChanged: (text) {
                                                              setState(() {});
                                                            },
                                                            decoration:
                                                                InputDecoration(
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              hintText: CurrentUser
                                                                      .requestedCreators
                                                                      .contains(
                                                                          widget
                                                                              .dreamUpData['id'])
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
                                                                  .contains(
                                                                      widget.dreamUpData[
                                                                          'id'])
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
                                                                          (animationSpeed * 0.5)
                                                                              .toInt(),
                                                                    ),
                                                                    opacity: 1,
                                                                    child:
                                                                        const Icon(
                                                                      Icons
                                                                          .cancel_outlined,
                                                                      size: 20,
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
                                                    print('clicking');

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
                                                            .contains(widget
                                                                    .dreamUpData[
                                                                'id'])
                                                        ? 0
                                                        : 50,
                                                    width: CurrentUser
                                                            .requestedCreators
                                                            .contains(widget
                                                                    .dreamUpData[
                                                                'id'])
                                                        ? 0
                                                        : 50,
                                                    color: Colors.transparent,
                                                    padding: EdgeInsets.only(
                                                      left:
                                                          MediaQuery.of(context)
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
                                                                .contains(widget
                                                                        .dreamUpData[
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
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                child: AnimatedOpacity(
                  duration: Duration.zero,
                  opacity: 1 - currentSheetHeight / 0.8,
                  child: GestureDetector(
                    onTap: () {
                      if (currentSheetHeight == 0) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      height: 50,
                      width: 50,
                      child: const Center(
                        child: DecoratedIcon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
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
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top,
                right: 0,
                child: Visibility(
                  visible: myDreamUp,
                  child: AnimatedOpacity(
                    duration: Duration.zero,
                    opacity: 1 - currentSheetHeight / 0.8,
                    child: GestureDetector(
                      onTap: () {
                        if (currentSheetHeight == 0) {
                          showPopUp ? showPopUp = false : showPopUp = true;

                          setState(() {});
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                        height: 50,
                        width: 50,
                        child: const Center(
                          child: DecoratedIcon(
                            Icons.settings_rounded,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
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
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 50,
                right: 5,
                child: Visibility(
                  visible: showPopUp,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: Offset(
                            2,
                            2,
                          ),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            var changed = await Navigator.push(
                              context,
                              changePage(
                                DreamUpEditPage(
                                  dreamUpData: widget.dreamUpData,
                                  dreamUpImage: Image(
                                    image: dreamUpImage!,
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.width,
                                    fit: BoxFit.fill,
                                  ),
                                  blurredImage: Image(
                                    image: blurredImage!,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            );

                            if (changed) {
                              setState(() {});
                            }
                          },
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                            ),
                            child: const Text(
                              'DreamUp bearbeiten',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            var id = widget.dreamUpData['id'];

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .update(
                              {
                                'createdVibes': FieldValue.arrayRemove(
                                  [
                                    widget.dreamUpData['id'],
                                  ],
                                ),
                              },
                            );

                            List<dynamic>? vibeHashtags =
                                widget.dreamUpData['hashtags'];

                            if (vibeHashtags != null) {
                              for (var hashtag in vibeHashtags) {
                                var databaseHashtag = await FirebaseFirestore
                                    .instance
                                    .collection('hashtags')
                                    .where('hashtag', isEqualTo: hashtag)
                                    .get();

                                for (var dbHashtag in databaseHashtag.docs) {
                                  var data = dbHashtag.data();

                                  if (data['useCount'] < 2) {
                                    await FirebaseFirestore.instance
                                        .collection('hashtags')
                                        .doc(dbHashtag.id)
                                        .delete();
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection('hashtags')
                                        .doc(dbHashtag.id)
                                        .update(
                                      {
                                        'useCount': FieldValue.increment(-1),
                                      },
                                    );
                                  }
                                }
                              }
                            }

                            if (widget.dreamUpData['audioLink'] != null) {
                              var audioRef = FirebaseStorage.instance
                                  .refFromURL(widget.dreamUpData['audioLink']);

                              await audioRef.delete();
                            }

                            await FirebaseFirestore.instance
                                .collection('vibes')
                                .doc(id)
                                .delete();

                            await FirebaseFirestore.instance
                                .collection('deleted')
                                .add(
                              {
                                'deleteTime': DateTime.now(),
                                'id': id,
                              },
                            );

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser)
                                .update(
                              {
                                'createdVibes': FieldValue.arrayRemove(
                                  [id],
                                ),
                              },
                            );

                            var vibeInList = dreamUpList.firstWhereOrNull(
                                (element) => element['id'] == id);

                            if (vibeInList != null) {
                              var index = dreamUpList.indexOf(vibeInList);

                              if (index <= currentIndex) {
                                dreamUpList.remove(vibeInList);

                                if (currentIndex > 0) {
                                  currentIndex--;
                                }
                              }
                            }

                            Navigator.pop(context);
                          },
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                            ),
                            child: const Text(
                              'DreamUp löschen',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
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
    );
  }
}

class DreamUpDetailBackground extends StatefulWidget {
  final Map<String, dynamic> dreamUpData;

  const DreamUpDetailBackground({
    required this.dreamUpData,
    super.key,
  });

  @override
  State<DreamUpDetailBackground> createState() =>
      _DreamUpDetailBackgroundState();
}

class _DreamUpDetailBackgroundState extends State<DreamUpDetailBackground> {
  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      dreamUpImage =
          CachedNetworkImageProvider(widget.dreamUpData['imageLink']);

      var cachedImage = await DefaultCacheManager()
          .getSingleFile(widget.dreamUpData['imageLink']);

      var path = await appDirectory;

      File compressedFile =
          await File('$path/compressedImage/${widget.dreamUpData['id']}.jpg')
              .create(recursive: true);

      var compressed = await FlutterImageCompress.compressAndGetFile(
        cachedImage.path,
        compressedFile.path,
        minHeight: 200,
        minWidth: 200,
        quality: 0,
      );

      File imageFile = File(compressed!.path);

      File file = await File('$path/blurredImage/${widget.dreamUpData['id']}')
          .create(recursive: true);

      var uiImage = await compute(blurImage, imageFile);

      file.writeAsBytesSync(
        img.encodePng(uiImage),
        mode: FileMode.append,
      );

      blurredImage = Image.file(
        file,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width,
      ).image;

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return blurredImage != null
        ? Stack(
            children: [
              Positioned(
                top: 0,
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.width,
                      width: MediaQuery.of(context).size.width,
                      child: Image(
                        image: blurredImage!,
                        height: MediaQuery.of(context).size.width,
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.fill,
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
                            image: blurredImage!,
                            width: MediaQuery.of(context).size.width,
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
                          image: dreamUpImage!,
                          height: MediaQuery.of(context).size.width,
                          width: MediaQuery.of(context).size.width,
                          fit: BoxFit.fill,
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
          )
        : SizedBox.expand(
            child: Container(
              color: Colors.white,
            ),
          );
  }
}
//endregion
