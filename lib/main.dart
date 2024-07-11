import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_test/utils/currentUserData.dart';
import 'package:firebase_test/utils/localNotificationUtils.dart';
import 'package:firebase_test/utils/revenueCatProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'additionalPages/chat.dart';
import 'mainScreens/contacts.dart';
import 'mainScreens/creation.dart';
import 'mainScreens/profile.dart';
import 'mainScreens/thread.dart';

//region Global Variables
double spacing = 0;

double homeBarHeight = 0;

Map<String, CachedNetworkImageProvider> LoadedImages = {};
Map<String, ImageProvider> BlurImages = {};

int animationSpeed = 250;

DateTime logInTime = DateTime.now();

bool gotUserData = false;
final navigatorKey = GlobalKey<NavigatorState>();

double screenWidth = 0;

bool userLoggedIn = false;

bool sawExplanation = false;

bool comingFromNote = false;

String firebaseToken = '';
//endregion

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Platform.isAndroid
      ? await Firebase.initializeApp(
     
        )
      : await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");

  if (message.data['chatId'] != null &&
      message.data['partnerId'] != null &&
      message.data['partnerName'] != null) {
    comingFromNote = true;

    print('there is data: ${message.data}');

    Navigator.push(
      navigatorKey.currentContext!,
      goToChat(
        message.data['chatId'],
        message.data['partnerName'],
        message.data['partnerId'],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MobileAds.instance.initialize();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  Platform.isAndroid
      ? await Firebase.initializeApp(
   
        )
      : await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final db = FirebaseFirestore.instance;
  db.settings = const Settings(persistenceEnabled: false);

  await LocalNotificationUtils().initNotification();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => HomeBarControlProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatNetworkManager(),
        ),
        ChangeNotifierProvider(
          create: (_) => RevenueCatProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// region Business Logic
class HomeBarControlProvider extends ChangeNotifier {
  bool homeBarVisible = true;

  void hideHomeBar() {
    homeBarVisible = false;

    notifyListeners();
  }

  void showHomeBar() {
    homeBarVisible = true;

    notifyListeners();
  }
}
//endregion

//region UI Logic
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? token;

  void _handleMessage(RemoteMessage message) async {
    if (message.data['chatId'] != null &&
        message.data['partnerId'] != null &&
        message.data['partnerName'] != null) {
      comingFromNote = true;

      Navigator.push(
        navigatorKey.currentContext!,
        goToChat(
          message.data['chatId'],
          message.data['partnerName'],
          message.data['partnerId'],
        ),
      ).then((_) {
        if (navigatorKey.currentState!.canPop()) {
          Navigator.pop(navigatorKey.currentContext!);
        }
      });
    }
  }

  Future initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    await FirebaseMessaging.instance.getAPNSToken();

    String? deviceToken = await FirebaseMessaging.instance.getToken();

    firebaseToken = deviceToken ?? '';

    print("###### PRINT DEVICE TOKEN TO USE FOR PUSH NOTIFCIATION ######");
    print(deviceToken);
    print("############################################################");

    token = deviceToken ?? 'no token available';

    if (token != null) {
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({
          'firebaseToken': token,
        });
      }
    }

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print('there is an initial message: ${initialMessage.data}');
      _handleMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');

      print('Message payload: ${message.data}');

      final notification = message.notification;
      if (notification != null) {
        print('Message also contained a notification: $notification');
        print('Message title: ${notification.title}');
        print('Message body: ${notification.body}');

        try {
          print('will show notification');

          LocalNotificationUtils().showNotification(
            id: 1,
            title: notification.title,
            body: notification.body,
            payLoad: json.encode(message.data),
          );
        } catch (e) {
          print('an error occured while showing a badge: $e');
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();

    initFCM();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;

    userLoggedIn = FirebaseAuth.instance.currentUser != null;

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'DreamUp',
      showPerformanceOverlay: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale(
          'de',
          'de-de',
        ),
      ],
      theme: ThemeData(
        fontFamily: 'Foundry Context W03',
        useMaterial3: false,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int index = 0;

  bool animating = false;

  List<Widget> screens = [
    const DreamUpThread(),
    const CreationOpeningScreen(
      fromProfile: false,
    ),
    const Profile(),
    const ChatsScreen(),
  ];

  Future<void> updateActiveStatus() async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(currentChatId)
        .update({
      'onlineUsers':
          FieldValue.arrayRemove([FirebaseAuth.instance.currentUser?.uid]),
      'lastLogin.${FirebaseAuth.instance.currentUser?.uid}': DateTime.now(),
    });

    print('updated');
  }

  bool showRequests = false;

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    logInTime = DateTime.now();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (Platform.isIOS) {
      if (state == AppLifecycleState.inactive) {
        if (userLoggedIn) {
          await CurrentUser().updateSeenDreamUps();
        } else {
          await CurrentUser().saveSeenVibesToFile(seenDreamUps);
        }
      }
    } else if (Platform.isAndroid) {
      if (state == AppLifecycleState.paused) {
        if (userLoggedIn) {
          await CurrentUser().updateSeenDreamUps();
        } else {
          await CurrentUser().saveSeenVibesToFile(seenDreamUps);
        }
      }
    }
    if (currentChatId != '' && state != AppLifecycleState.resumed) {
      updateActiveStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    spacing = MediaQuery.of(context).padding.bottom;

    homeBarHeight = (MediaQuery.of(context).size.width * 2) / 15 + spacing;

    var provider = Provider.of<HomeBarControlProvider>(context, listen: true);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: true,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            gotUserData
                ? screens[index]
                : FutureBuilder(
                    future: CurrentUser().getUserData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return screens[index];
                      } else {
                        return const SizedBox.expand();
                      }
                    },
                  ),
            Visibility(
              visible: provider.homeBarVisible,
              child: SizedBox(
                height: homeBarHeight,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: Duration(milliseconds: animationSpeed),
                      top: 0,
                      left: -MediaQuery.of(context).size.width * 0.1,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 2,
                        height: (MediaQuery.of(context).size.width * 2) / 15 +
                            spacing,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedPositioned(
                              duration: Duration(milliseconds: animationSpeed),
                              curve: Curves.fastOutSlowIn,
                              top: 0,
                              left: getBarPosition(index, context),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 2,
                                height:
                                    (MediaQuery.of(context).size.width * 2) /
                                            15 +
                                        spacing,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    AnimatedPositioned(
                                      duration: Duration(
                                        milliseconds:
                                            (animationSpeed * 0.5).toInt(),
                                      ),
                                      top: !animating
                                          ? 0
                                          : (MediaQuery.of(context).size.width *
                                                  2) /
                                              15,
                                      curve: Curves.easeInOut,
                                      onEnd: () {
                                        animating = false;

                                        setState(() {});
                                      },
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          ClipOval(
                                            child: Container(
                                              height: (MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      2) /
                                                  19,
                                              width: (MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      2) /
                                                  19,
                                              decoration: BoxDecoration(
                                                color: index != 1
                                                    ? Colors.white
                                                        .withOpacity(0.35)
                                                    : Colors.grey
                                                        .withOpacity(0.7),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: AnimatedOpacity(
                                                  duration: Duration(
                                                    milliseconds:
                                                        (animationSpeed * 0.5)
                                                            .toInt(),
                                                  ),
                                                  opacity: animating ? 0 : 1,
                                                  child: animating
                                                      ? Container()
                                                      : getIcon(
                                                          context,
                                                          index,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: -MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.01,
                                            child: (userLoggedIn && index == 3)
                                                ? StreamBuilder(
                                                    stream: FirebaseFirestore
                                                        .instance
                                                        .collection('chats')
                                                        .where('participants',
                                                            arrayContainsAny: [
                                                              FirebaseAuth
                                                                  .instance
                                                                  .currentUser
                                                                  ?.uid
                                                            ])
                                                        .where('new',
                                                            isEqualTo: true)
                                                        .where('lastSender',
                                                            isNotEqualTo:
                                                                FirebaseAuth
                                                                    .instance
                                                                    .currentUser
                                                                    ?.uid)
                                                        .snapshots(),
                                                    builder: (context,
                                                        AsyncSnapshot<
                                                                QuerySnapshot>
                                                            snapshot) {
                                                      if (snapshot.hasData) {
                                                        var docs =
                                                            snapshot.data!.docs;

                                                        return Visibility(
                                                          visible:
                                                              docs.isNotEmpty,
                                                          child: CircleAvatar(
                                                            backgroundColor:
                                                                Colors
                                                                    .blueAccent,
                                                            radius: 10,
                                                            child: Center(
                                                              child: Text(
                                                                docs.length
                                                                    .toString(),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        );
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
                                    Positioned(
                                      bottom: 0,
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                2,
                                        alignment: Alignment.center,
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              2,
                                          height: (MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      2) /
                                                  15 +
                                              spacing,
                                          child: ClipPath(
                                            clipper: HomeBarClipper(),
                                            child: Container(
                                              color: index != 1
                                                  ? Colors.white
                                                      .withOpacity(0.35)
                                                  : Colors.grey
                                                      .withOpacity(0.7),
                                            ),
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
                    ),
                    Positioned(
                      top: 0,
                      child: Container(
                        height: (MediaQuery.of(context).size.width * 2) / 15,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: AnimatedOpacity(
                                duration:
                                    Duration(milliseconds: animationSpeed),
                                opacity: index == 0 ? 0 : 1,
                                child: GestureDetector(
                                  onTap: () {
                                    index = 0;

                                    animating = true;

                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    height: (MediaQuery.of(context).size.width *
                                            2) /
                                        13,
                                    child: const Icon(
                                      Icons.home_outlined,
                                      color: Color(0xFF323232),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AnimatedOpacity(
                                duration:
                                    Duration(milliseconds: animationSpeed),
                                opacity: index == 1 ? 0 : 1,
                                child: GestureDetector(
                                  onTap: () {
                                    index = 1;

                                    animating = true;

                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    height: (MediaQuery.of(context).size.width *
                                            2) /
                                        13,
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: Color(0xFF323232),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AnimatedOpacity(
                                duration:
                                    Duration(milliseconds: animationSpeed),
                                opacity: index == 2 ? 0 : 1,
                                child: GestureDetector(
                                  onTap: () {
                                    index = 2;

                                    animating = true;

                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    height: (MediaQuery.of(context).size.width *
                                            2) /
                                        13,
                                    child: const Icon(
                                      Icons.perm_identity_rounded,
                                      color: Color(0xFF323232),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AnimatedOpacity(
                                duration:
                                    Duration(milliseconds: animationSpeed),
                                opacity: index == 3 ? 0 : 1,
                                child: GestureDetector(
                                  onTap: () async {
                                    if (index == 3) {
                                      showRequests = !showRequests;

                                      setState(() {});
                                    }

                                    index = 3;

                                    animating = true;

                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    height: (MediaQuery.of(context).size.width *
                                            2) /
                                        13,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Positioned.fill(
                                          child: Icon(
                                            Icons.mail_outline_rounded,
                                            color: Color(0xFF323232),
                                          ),
                                        ),
                                        Positioned(
                                          top: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.01,
                                          right: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04,
                                          child: FirebaseAuth
                                                      .instance.currentUser !=
                                                  null
                                              ? StreamBuilder(
                                                  stream: FirebaseFirestore
                                                      .instance
                                                      .collection('chats')
                                                      .where('participants',
                                                          arrayContainsAny: [
                                                            FirebaseAuth
                                                                .instance
                                                                .currentUser
                                                                ?.uid
                                                          ])
                                                      .where('new',
                                                          isEqualTo: true)
                                                      .where('lastSender',
                                                          isNotEqualTo:
                                                              FirebaseAuth
                                                                  .instance
                                                                  .currentUser
                                                                  ?.uid)
                                                      .snapshots(),
                                                  builder: (context,
                                                      AsyncSnapshot<
                                                              QuerySnapshot>
                                                          snapshot) {
                                                    if (snapshot.hasData) {
                                                      var docs =
                                                          snapshot.data!.docs;

                                                      return Visibility(
                                                        visible:
                                                            docs.isNotEmpty,
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                              Colors.blueAccent,
                                                          radius: 10,
                                                          child: Center(
                                                            child: Text(
                                                              docs.length
                                                                  .toString(),
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
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
          ],
        ),
      ),
    );
  }
}

class Background extends StatefulWidget {
  final Widget child;

  const Background({super.key, required this.child});

  @override
  State<Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<Background> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          // image: getDetailUCs()[0].image.image,
          image:
              Image.asset('assets/images/GlassMorphismTestImage3.jpeg').image,
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class HomeBarClipper extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    double height = size.height - spacing;

    final path = Path();

    path.moveTo(size.width * 0.42, 0);

    path.cubicTo(size.width * 0.475, 0, size.width * 0.455, height * 0.9,
        size.width * 0.5, height * 0.9);

    path.cubicTo(size.width * 0.545, height * 0.9, size.width * 0.525, 0,
        size.width * 0.58, 0);

    path.lineTo(size.width, 0);

    path.lineTo(size.width, height + spacing);

    path.lineTo(0, height + spacing);

    path.lineTo(0, 0);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<dynamic> oldClipper) {
    return true;
  }
}
//endregion

//region Operations
double getBarPosition(int index, BuildContext context) {
  double position = 0;

  if (index == 0) {
    position = -MediaQuery.of(context).size.width * 0.775;
  } else if (index == 1) {
    position = -MediaQuery.of(context).size.width * 0.525;
  } else if (index == 2) {
    position = -MediaQuery.of(context).size.width * 0.275;
  } else if (index == 3) {
    position = -MediaQuery.of(context).size.width * 0.025;
  }

  return position;
}

Widget getIcon(BuildContext context, int index) {
  if (index == 0) {
    return const Icon(
      Icons.home_outlined,
      color: Color(0xFF323232),
    );
  } else if (index == 1) {
    return const Icon(
      Icons.add_rounded,
      color: Color(0xFF323232),
    );
  } else if (index == 2) {
    return const Icon(
      Icons.perm_identity_rounded,
      color: Color(0xFF323232),
    );
  } else if (index == 3) {
    return const Icon(
      Icons.mail_outline_rounded,
      color: Color(0xFF323232),
    );
  } else {
    return const Icon(
      Icons.notifications_none_rounded,
      color: Color(0xFF323232),
    );
  }
}

Route changePage(Widget destination) {
  return MaterialPageRoute(
    builder: (context) => destination,
  );
}
//endregion
