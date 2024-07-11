import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:path_provider/path_provider.dart';

import '../additionalPages/chat.dart';
import '../main.dart';
import '../utils/currentUserData.dart';

//region UI Logic
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({
    super.key,
  });

  static const route = '/contacts';

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  String showCorrectTime(DateTime time) {
    String hour = time.hour.toString();
    String minute =
        time.minute < 10 ? '0${time.minute}' : time.minute.toString();

    String correctTime = '';

    if (time.day == DateTime.now().day - 1) {
      correctTime = 'Gestern';
    } else if (time.day == DateTime.now().day) {
      correctTime = '$hour:$minute';
    } else {
      correctTime =
          '${time.day}.${time.month}.${time.year.toString()[2]}${time.year.toString()[3]}';
    }

    return correctTime;
  }

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  late TabController controller;

  int index = 0;

  @override
  void initState() {
    super.initState();

    controller = TabController(
      length: 2,
      vsync: this,
    );

    controller.addListener(() {
      setState(() {
        index = controller.index;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/GlassBackground.jpg',
              fit: BoxFit.fill,
            ),
          ),
          ColorfulSafeArea(
            bottom: false,
            top: true,
            color: Colors.transparent,
            overflowRules: const OverflowRules.only(bottom: true),
            filter: ImageFilter.blur(sigmaY: 5, sigmaX: 5),
            child: Scaffold(
              extendBody: true,
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: TabBar(
                      enableFeedback: false,
                      controller: controller,
                      tabs: [
                        Container(
                          height: 50,
                          color: Colors.transparent,
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Text(
                                  ' Chats ',
                                ),
                                Positioned(
                                  right: -5,
                                  top: 0,
                                  child: userLoggedIn
                                      ? StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('chats')
                                              .where('participants',
                                                  arrayContainsAny: [
                                                    currentUser
                                                  ])
                                              .where('new', isEqualTo: true)
                                              .where('lastSender',
                                                  isNotEqualTo: currentUser)
                                              .where('isRequest',
                                                  isEqualTo: false)
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              if (snapshot
                                                  .data!.docs.isNotEmpty) {
                                                return const CircleAvatar(
                                                  radius: 4,
                                                  backgroundColor: Colors.blue,
                                                );
                                              } else {
                                                return Container();
                                              }
                                            } else {
                                              return Container();
                                            }
                                          },
                                        )
                                      : Container(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          height: 50,
                          color: Colors.transparent,
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Text(
                                  ' Anfragen ',
                                ),
                                Positioned(
                                  right: -5,
                                  top: 0,
                                  child: userLoggedIn
                                      ? StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('chats')
                                              .where(
                                                'participants',
                                                arrayContainsAny: [currentUser],
                                              )
                                              .where('isRequest',
                                                  isEqualTo: true)
                                              .where('new', isEqualTo: true)
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              if (snapshot
                                                  .data!.docs.isNotEmpty) {
                                                return const CircleAvatar(
                                                  radius: 4,
                                                  backgroundColor: Colors.blue,
                                                );
                                              } else {
                                                return Container();
                                              }
                                            } else {
                                              return Container();
                                            }
                                          },
                                        )
                                      : Container(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      indicatorColor: Colors.black87,
                      indicatorWeight: 2,
                      indicatorPadding: const EdgeInsets.only(
                        bottom: -1,
                      ),
                      labelColor: Colors.black87,
                      labelStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Foundry Context W03',
                      ),
                      unselectedLabelColor: Colors.black54,
                    ),
                  ),
                  Container(
                    height: 1,
                    color: Colors.black26,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: controller,
                      physics: const BouncingScrollPhysics(),
                      children: userLoggedIn
                          ? [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('chats')
                                    .where(
                                      'participants',
                                      arrayContainsAny: [currentUser],
                                    )
                                    .where('isRequest', isEqualTo: false)
                                    .orderBy('lastAction', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return Container();
                                  return ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.width *
                                          0.05,
                                    ),
                                    itemCount: snapshot.data!.docs.length,
                                    itemBuilder: (context, index) {
                                      var doc = snapshot.data!.docs[index];

                                      var chat =
                                          doc.data() as Map<String, dynamic>;

                                      var id = chat['id'];
                                      var users =
                                          chat['participants'] as List<dynamic>;
                                      var usersCopy = List.from(users);
                                      usersCopy.remove(currentUser);
                                      var partnerId = usersCopy[0];

                                      var info =
                                          chat['shownInformation'] as Map?;

                                      bool nameUnlocked = false;
                                      bool imageUnlocked = false;

                                      if (info != null) {
                                        var partnerInfo =
                                            info[partnerId] as Map?;

                                        if (partnerInfo != null &&
                                            info.containsKey(currentUser)) {
                                          nameUnlocked =
                                              partnerInfo['name'] == true;
                                          imageUnlocked =
                                              partnerInfo['image'] == true;
                                        }
                                      }

                                      var images = chat['images'] as Map;
                                      var partnerImage = images[partnerId];
                                      var names =
                                          chat['names'] as List<dynamic>;
                                      var namesCopy = List.from(names);
                                      namesCopy.remove(CurrentUser.name);
                                      var partnerName = nameUnlocked
                                          ? namesCopy[0]
                                          : 'Nutzer';
                                      var logIns = chat['lastLogin'] as Map;
                                      var myLastLogin =
                                          (logIns[currentUser] as Timestamp)
                                              .toDate();
                                      var lastAction =
                                          (chat['lastAction'] as Timestamp)
                                              .toDate();
                                      var lastSender = chat['lastSender'];
                                      var type = chat['lastType'];
                                      var lastMessage = chat['lastMessage'];

                                      bool isNew =
                                          lastAction.isAfter(myLastLogin) &&
                                              lastSender != currentUser;

                                      return SwipeActionCell(
                                        key: ObjectKey(doc.id),
                                        trailingActions: <SwipeAction>[
                                          SwipeAction(
                                            title: "Löschen",
                                            onTap: (value) async {
                                              var request =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('chats')
                                                      .where('users',
                                                          isEqualTo: {
                                                    currentUser: null,
                                                    partnerId: null
                                                  }).get();
                                              var doc = request.docs.first;

                                              await FirebaseFirestore.instance
                                                  .collection('chats')
                                                  .doc(doc.id)
                                                  .delete();

                                              var myRequested =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc(currentUser)
                                                      .collection(
                                                          'requestedCreators')
                                                      .where('userId',
                                                          isEqualTo: partnerId)
                                                      .get();
                                              var myDoc =
                                                  myRequested.docs.first;

                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(currentUser)
                                                  .collection(
                                                      'requestedCreators')
                                                  .doc(myDoc.id)
                                                  .delete();

                                              var otherRequested =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc(partnerId)
                                                      .collection(
                                                          'requestedCreators')
                                                      .where('userId',
                                                          isEqualTo:
                                                              currentUser)
                                                      .get();

                                              var otherDoc =
                                                  otherRequested.docs.first;

                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(partnerId)
                                                  .collection(
                                                      'requestedCreators')
                                                  .doc(otherDoc.id)
                                                  .delete();

                                              CurrentUser.requestedCreators
                                                  .remove(partnerId);

                                              final path = await appDirectory;

                                              var chatDirectory =
                                                  Directory('$path/chats/$id/');

                                              if (chatDirectory.existsSync()) {
                                                await chatDirectory.delete(
                                                  recursive: true,
                                                );
                                              }

                                              setState(() {});
                                            },
                                            color: Colors.red,
                                          ),
                                        ],
                                        backgroundColor: Colors.transparent,
                                        child: GestureDetector(
                                          onTap: () async {
                                            var refresh = await Navigator.push(
                                              context,
                                              goToChat(
                                                id,
                                                partnerName,
                                                partnerId,
                                              ),
                                            );

                                            if (refresh) {
                                              setState(() {});
                                            }
                                          },
                                          child: Container(
                                            color: Colors.transparent,
                                            margin: EdgeInsets.symmetric(
                                              vertical: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.015,
                                            ),
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.15,
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.05,
                                                ),
                                                SizedBox(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.12,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.12,
                                                  child: ClipOval(
                                                    child: imageUnlocked
                                                        ? CachedNetworkImage(
                                                            imageUrl:
                                                                partnerImage,
                                                            placeholder:
                                                                (context,
                                                                    string) {
                                                              return Image
                                                                  .asset(
                                                                'assets/uiComponents/profilePicturePlaceholder.jpg',
                                                                fit:
                                                                    BoxFit.fill,
                                                              );
                                                            },
                                                          )
                                                        : Image.asset(
                                                            'assets/uiComponents/profilePicturePlaceholder.jpg',
                                                            fit: BoxFit.fill,
                                                          ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.05,
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              partnerName,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            showCorrectTime(
                                                                lastAction),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: isNew
                                                                  ? Colors
                                                                      .blueAccent
                                                                  : Colors.black
                                                                      .withOpacity(
                                                                          0.7),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.005,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: type ==
                                                                    'infoRequest'
                                                                ? Text(
                                                                    'Eine neue Informationsanfrage',
                                                                    maxLines: 1,
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.7),
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                  )
                                                                : type == 'text'
                                                                    ? Text(
                                                                        lastMessage,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style:
                                                                            TextStyle(
                                                                          color: Colors
                                                                              .black
                                                                              .withOpacity(0.7),
                                                                          fontSize:
                                                                              14,
                                                                        ),
                                                                      )
                                                                    : Row(
                                                                        children: [
                                                                          Visibility(
                                                                            visible:
                                                                                lastSender == currentUser,
                                                                            child:
                                                                                Text(
                                                                              'Du: ',
                                                                              style: TextStyle(
                                                                                color: Colors.black.withOpacity(0.7),
                                                                                fontSize: 14,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Icon(
                                                                            Icons.image,
                                                                            color:
                                                                                Colors.black.withOpacity(0.7),
                                                                            size:
                                                                                16,
                                                                          ),
                                                                          Text(
                                                                            'Foto',
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.black.withOpacity(0.7),
                                                                              fontSize: 14,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                          ),
                                                          Visibility(
                                                            visible: isNew,
                                                            child: CircleAvatar(
                                                              backgroundColor:
                                                                  Colors
                                                                      .blueAccent,
                                                              radius: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.02,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.05,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('chats')
                                    .where(
                                      'participants',
                                      arrayContainsAny: [currentUser],
                                    )
                                    .where('isRequest', isEqualTo: true)
                                    .orderBy('lastAction', descending: true)
                                    .snapshots(),
                                builder: (context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (!snapshot.hasData) return Container();
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.width *
                                          0.05,
                                    ),
                                    itemCount: snapshot.data!.docs.length,
                                    itemBuilder: (context, index) {
                                      var doc = snapshot.data!.docs[index];

                                      var chat =
                                          doc.data() as Map<String, dynamic>;

                                      var id = chat['id'];

                                      var partnerId = chat['lastSender'];
                                      var partnerImage =
                                          'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FuserPlaceholder.png?alt=media&token=1a4e6423-446d-48b5-8bbf-466900c350ec&_gl=1*1g9i9yi*_ga*ODE3ODU3OTY4LjE2OTI2OTU2NzA.*_ga_CW55HF8NVT*MTY5ODkxNDQwMS4yMy4xLjE2OTg5MTUyNzEuNTkuMC4w';
                                      var partnerName = 'Nutzer';

                                      DateTime time =
                                          (chat['lastAction'] as Timestamp)
                                              .toDate();

                                      bool isNew = chat['new'];

                                      return GestureDetector(
                                        onTap: () async {
                                          var refresh = await Navigator.push(
                                            context,
                                            goToChat(
                                              id,
                                              partnerName,
                                              partnerId,
                                            ),
                                          );

                                          if (refresh) {
                                            setState(() {});
                                          }
                                        },
                                        child: Container(
                                          color: Colors.transparent,
                                          margin: EdgeInsets.symmetric(
                                            vertical: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.015,
                                          ),
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.15,
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.05,
                                              ),
                                              CircleAvatar(
                                                backgroundImage:
                                                    CachedNetworkImageProvider(
                                                  partnerImage,
                                                ),
                                                backgroundColor:
                                                    Colors.transparent,
                                                radius: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.06,
                                              ),
                                              SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.05,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            partnerName,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          showCorrectTime(time),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isNew
                                                                ? Colors
                                                                    .blueAccent
                                                                : Colors.black
                                                                    .withOpacity(
                                                                        0.7),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.005,
                                                    ),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            'Eine neue Chatanfrage',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.7),
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ),
                                                        Visibility(
                                                          visible: isNew,
                                                          child: CircleAvatar(
                                                            backgroundColor:
                                                                Colors
                                                                    .blueAccent,
                                                            radius: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.02,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.05,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ]
                          : [
                              Container(),
                              Container(),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
//endregion

//region Operations
Route goToChat(
  String chatId,
  String name,
  String partnerId,
) {
  return MaterialPageRoute(
    builder: (context) => ChatWidget(
      partnerName: name,
      chatId: chatId,
      partnerId: partnerId,
    ),
  );
}
//endregion
