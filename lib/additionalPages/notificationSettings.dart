import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_test/utils/currentUserData.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool showBadges = true;
  bool playSound = true;
  bool activateVibration = true;

  Future<void> updateNoteSettings() async {
    var settings = {
      'notificationSettings': {
        'showBadges': showBadges,
        'playSound': playSound,
        'activateVibration': activateVibration,
      },
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .update(settings);

    CurrentUser.showNoteBadges = showBadges;
    CurrentUser.playNoteSound = playSound;
    CurrentUser.vibrateOnNote = activateVibration;

    print('note settings updated');
  }

  bool edited() {
    bool changed = false;

    if (showBadges != CurrentUser.showNoteBadges ||
        playSound != CurrentUser.playNoteSound ||
        activateVibration != CurrentUser.vibrateOnNote) {
      changed = true;
    }

    print('settings changed: $changed');

    return changed;
  }

  @override
  void initState() {
    super.initState();

    showBadges = CurrentUser.showNoteBadges;
    playSound = CurrentUser.playNoteSound;
    activateVibration = CurrentUser.vibrateOnNote;
  }

  @override
  void dispose() async {
    super.dispose();

    if (edited()) {
      await updateNoteSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.95),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context, true);
          },
          child: Container(
            color: Colors.transparent,
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Benachrichtungseinstellungen',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.width * 0.05,
              top: MediaQuery.of(context).size.width * 0.05,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.05,
                    bottom: MediaQuery.of(context).size.width * 0.02,
                  ),
                  child: const Text(
                    'In-App Benachrichtigungen',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                          vertical: MediaQuery.of(context).size.width * 0.05,
                        ),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_rounded,
                              color: Colors.black38,
                              size: 20,
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.02,
                            ),
                            const Text(
                              'Badges anzeigen',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Container(),
                            ),
                            SizedBox(
                              height: 15,
                              child: CupertinoSwitch(
                                value: showBadges,
                                onChanged: (value) {
                                  showBadges = value;

                                  setState(() {});
                                },
                                activeColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                          vertical: MediaQuery.of(context).size.width * 0.05,
                        ),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.volume_down_rounded,
                              color: Colors.black38,
                              size: 20,
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.02,
                            ),
                            const Text(
                              'Ton abspielen',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Container(),
                            ),
                            SizedBox(
                              height: 15,
                              child: CupertinoSwitch(
                                value: playSound,
                                onChanged: (value) {
                                  playSound = value;

                                  setState(() {});
                                },
                                activeColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Container(
                      //   padding: EdgeInsets.symmetric(
                      //     horizontal: MediaQuery.of(context).size.width * 0.05,
                      //     vertical: MediaQuery.of(context).size.width * 0.05,
                      //   ),
                      //   color: Colors.transparent,
                      //   child: Row(
                      //     children: [
                      //       const Icon(
                      //         Icons.vibration_rounded,
                      //         color: Colors.black38,
                      //         size: 20,
                      //       ),
                      //       SizedBox(
                      //         width: MediaQuery.of(context).size.width * 0.02,
                      //       ),
                      //       const Text(
                      //         'Vibration aktivieren',
                      //         style: TextStyle(
                      //           fontSize: 16,
                      //           fontWeight: FontWeight.bold,
                      //         ),
                      //       ),
                      //       Expanded(
                      //         child: Container(),
                      //       ),
                      //       SizedBox(
                      //         height: 15,
                      //         child: CupertinoSwitch(
                      //           value: activateVibration,
                      //           onChanged: (value) {
                      //             activateVibration = value;
                      //
                      //             setState(() {});
                      //           },
                      //           activeColor: Colors.green,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
