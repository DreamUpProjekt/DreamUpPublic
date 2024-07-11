import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../additionalPages/creationSteps.dart';
import '../additionalPages/loginScreen.dart';
import '../main.dart';
import '../utils/revenueCatProvider.dart';
import '../widgets/paywallWidget.dart';

//region Global Variables
List<VideoPlayerController> _controllers = [];
//endregion

//region UI Logic
class CreationOpeningScreen extends StatefulWidget {
  final bool fromProfile;

  const CreationOpeningScreen({
    super.key,
    required this.fromProfile,
  });

  @override
  State<CreationOpeningScreen> createState() => _CreationOpeningScreenState();
}

class _CreationOpeningScreenState extends State<CreationOpeningScreen> {
  Future<void> fetchOffers() async {
    try {
      final offerings =
          await Provider.of<RevenueCatProvider>(context, listen: false)
              .fetchOffers();
      if (offerings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine möglichen Subscriptions gefunden!'),
          ),
        );
      } else {
        final offer = offerings.first;
        print('Offer: $offer');

        final packages = offerings
            .map((offer) => offer.availablePackages)
            .expand((pair) => pair)
            .toList();

        showModalBottomSheet(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          context: context,
          builder: (context) => PaywallWidget(
            title: 'Abo abschließen',
            description: 'Schließe ein Premium Abo ab!',
            packages: packages,
            onClickedPackage: (package) async {
              await Provider.of<RevenueCatProvider>(context, listen: false)
                  .purchasePackage(package)
                  .then((value) async {
                Navigator.pop(context);
              });
            },
          ),
        );
      }
    } on PlatformException catch (e) {
      print('An error occurred while fetching offers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while fetching offers: $e'),
        ),
      );
    }
  }

  String category = '';
  bool clickedPremium = false;

  int _currentIndex = 0;

  final PageController _pageController =
      PageController(initialPage: 0, viewportFraction: 0.8);

  @override
  void initState() {
    super.initState();

    print('is calling init state!');

    _pageController.addListener(() {
      int nextPage = _pageController.page!.round();
      if (_currentIndex != nextPage) {
        setState(() {
          _currentIndex = nextPage;
        });
      }
      _playCurrentVideo();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var first = VideoPlayerController.asset(
        'assets/videos/FriendshipVideo.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      )
        ..setLooping(true)
        ..setVolume(0);

      print('got first video');

      await first.initialize();

      print('initialized');

      _controllers.add(first);

      _playCurrentVideo();

      setState(() {});

      _initializeControllers();
    });
  }

  Future<void> _initializeControllers() async {
    _controllers.add(
      VideoPlayerController.asset(
        'assets/videos/JacobVersionCropped.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      )
        ..setLooping(true)
        ..setVolume(0),
    );

    _controllers.add(
      VideoPlayerController.asset(
        'assets/videos/DateVideo.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      )
        ..setLooping(true)
        ..setVolume(0),
    );

    _controllers.add(
      VideoPlayerController.asset(
        'assets/videos/DateVideo.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      )
        ..setLooping(true)
        ..setVolume(0),
    );

    for (int i = 1; i < _controllers.length; i++) {
      var controller = _controllers[i];
      await controller.initialize();
    }
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
              onTap: () {
                Navigator.push(
                  context,
                  changePage(
                    const LoginPage(),
                  ),
                );
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

  void _playCurrentVideo() {
    for (int i = 0; i < _controllers.length; i++) {
      if (i == _currentIndex) {
        _controllers[i].play();
      } else {
        _controllers[i]
          ..pause()
          ..seekTo(Duration.zero);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();

    for (var controller in _controllers) {
      controller.dispose();
    }

    _controllers.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            CreationBackground(
              index: _currentIndex,
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.4 +
                  MediaQuery.of(context).padding.bottom +
                  MediaQuery.of(context).size.width * 0.2 +
                  (MediaQuery.of(context).size.width * 2) / 15 +
                  spacing,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  children: [
                    const Text(
                      'Dream Up',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            offset: Offset(1, 1),
                            blurRadius: 5,
                          )
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.width * 0.08,
                      ),
                      height: 1,
                      color: Colors.white,
                      width: MediaQuery.of(context).size.width * 0.8,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: homeBarHeight +
                  spacing +
                  MediaQuery.of(context).size.width * 0.1,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                width: MediaQuery.of(context).size.width,
                child: PageView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  controller: _pageController,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 20,
                            sigmaY: 20,
                          ),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width * 0.05,
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width * 0.075,
                            ),
                            child: Column(
                              children: [
                                const AutoSizeText(
                                  'Freundschaft',
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  color: Colors.white,
                                  height: 2,
                                  margin: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.width *
                                        0.075,
                                    bottom: MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                const Text(
                                  'Wünsch dir genau die Freundschaft, die du in deinem Leben brauchst. Hier findest du sie.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.width * 0.05,
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (userLoggedIn) {
                                      category = 'Freundschaft';

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CreationStepPage(
                                            vibeType: category,
                                          ),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                      vertical:
                                          MediaQuery.of(context).size.width *
                                              0.03,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(250),
                                    ),
                                    child: const Text(
                                      'DreamUp erstellen',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 20,
                            sigmaY: 20,
                          ),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.4),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  MediaQuery.of(context).size.width * 0.05,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: Offset(1, 1),
                                  ),
                                ]),
                            padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width * 0.075,
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Aktion',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  color: Colors.white,
                                  height: 2,
                                  margin: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.width *
                                        0.075,
                                    bottom: MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                const Text(
                                  'Wünsch dir genau die Aktion, die du in deinem Leben brauchst. Hier findest du sie.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.width * 0.05,
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (userLoggedIn) {
                                      category = 'Aktion';

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CreationStepPage(
                                            vibeType: category,
                                          ),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                      vertical:
                                          MediaQuery.of(context).size.width *
                                              0.03,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(250),
                                    ),
                                    child: const Text(
                                      'DreamUp erstellen',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: Stack(
                          children: [
                            BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 20,
                                sigmaY: 20,
                              ),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.7,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width * 0.05,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.8),
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      spreadRadius: 1,
                                      blurRadius: 10,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(
                                  MediaQuery.of(context).size.width * 0.075,
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Beziehung',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Container(
                                      color: Colors.white,
                                      height: 2,
                                      margin: EdgeInsets.only(
                                        top: MediaQuery.of(context).size.width *
                                            0.075,
                                        bottom:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(),
                                    ),
                                    const Text(
                                      'Wünsch dir genau die Beziehung, die du in deinem Leben brauchst. Hier findest du sie.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                    ),
                                    Expanded(
                                      child: Container(),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        if (userLoggedIn) {
                                          category = 'Beziehung';

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CreationStepPage(
                                                vibeType: category,
                                              ),
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
                                        padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05,
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.03,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(250),
                                        ),
                                        child: const Text(
                                          'DreamUp erstellen',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Consumer<RevenueCatProvider>(
                                builder: (context, revenueCatProvider, _) {
                                  return Visibility(
                                    visible: userLoggedIn
                                        ? !revenueCatProvider
                                            .isSubscriptionActive
                                        : true,
                                    child: GestureDetector(
                                      onTap: () {
                                        clickedPremium = true;

                                        setState(() {});
                                      },
                                      child: Container(
                                        color: Colors.black.withOpacity(0.7),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.lock_outline_rounded,
                                                color: Colors.white,
                                                size: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.3,
                                              ),
                                              const Text(
                                                'Premium',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: Stack(
                          children: [
                            BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 20,
                                sigmaY: 20,
                              ),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.7,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width * 0.05,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.8),
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      spreadRadius: 1,
                                      blurRadius: 10,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(
                                  MediaQuery.of(context).size.width * 0.075,
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Date',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Container(
                                      color: Colors.white,
                                      height: 2,
                                      margin: EdgeInsets.only(
                                        top: MediaQuery.of(context).size.width *
                                            0.075,
                                        bottom:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(),
                                    ),
                                    const Text(
                                      'Wünsch dir genau das Date, das du in deinem Leben brauchst. Hier findest du es.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                    ),
                                    Expanded(
                                      child: Container(),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        if (userLoggedIn) {
                                          category = 'Aktion';

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CreationStepPage(
                                                vibeType: category,
                                              ),
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
                                        padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05,
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.03,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(250),
                                        ),
                                        child: const Text(
                                          'DreamUp erstellen',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Consumer<RevenueCatProvider>(
                                builder: (context, revenueCatProvider, _) {
                                  return Visibility(
                                    visible: userLoggedIn
                                        ? !revenueCatProvider
                                            .isSubscriptionActive
                                        : true,
                                    child: GestureDetector(
                                      onTap: () {
                                        clickedPremium = true;

                                        setState(() {});
                                      },
                                      child: Container(
                                        color: Colors.black.withOpacity(0.7),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.lock_outline_rounded,
                                                color: Colors.white,
                                                size: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.3,
                                              ),
                                              const Text(
                                                'Premium',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
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
            Visibility(
              visible: clickedPremium,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.1,
                  ),
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width * 0.05,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Diese Art von Wishes kannst du nur mit einem Premiumupgrade erstellen.',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.width * 0.05,
                      ),
                      GestureDetector(
                        onTap: () async {
                          await fetchOffers();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          color: Colors.blueAccent,
                          child: const Text(
                            'Premium abschließen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.width * 0.025,
                      ),
                      GestureDetector(
                        onTap: () async {
                          clickedPremium = false;

                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          color: Colors.blueAccent.withOpacity(0.1),
                          child: const Text(
                            'Abbrechen',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 18,
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
              left: 0,
              top: MediaQuery.of(context).padding.top,
              child: Visibility(
                visible: widget.fromProfile,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
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
          ],
        ),
      ),
    );
  }
}

class CreationBackground extends StatelessWidget {
  final int index;

  const CreationBackground({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    if (_controllers.isNotEmpty) {
      var controller = _controllers[index];

      return Positioned.fill(
        child: VideoPlayer(controller),
      );
    } else {
      return Container();
    }
  }
}
//endregion
