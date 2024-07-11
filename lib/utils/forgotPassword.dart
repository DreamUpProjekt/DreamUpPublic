import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'currentUserData.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late TextEditingController mailController;

  @override
  void initState() {
    super.initState();

    mailController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });

    mailController.text = CurrentUser.mail;
  }

  @override
  void dispose() {
    mailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'Passwort zurücksetzen',
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
              top: MediaQuery.of(context).size.width * 0.05,
              right: MediaQuery.of(context).size.width * 0.05,
              left: MediaQuery.of(context).size.width * 0.05,
            ),
            child: const Text(
              'Bitte gib die Mail Adresse an, welche mit deinem Account verknüpft ist. Wir schicken dir einen Link zu, über welchen du dein Passwort zurücksetzen kannst. \nSollte die Mail dich nicht erreichen, schaue bitte auch in Deinem Spam-Ordner nach.',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
              vertical: MediaQuery.of(context).size.width * 0.05,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: TextField(
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                controller: mailController,
                autocorrect: true,
                enableSuggestions: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: CurrentUser.mail,
                ),
              ),
            ),
          ),
          Visibility(
            visible: mailController.text.isNotEmpty,
            child: Row(
              children: [
                Expanded(
                  child: Container(),
                ),
                GestureDetector(
                  onTap: () async {
                    try {
                      await FirebaseAuth.instance
                          .sendPasswordResetEmail(
                              email: mailController.text.trim())
                          .then((value) {
                        Fluttertoast.cancel();

                        Fluttertoast.showToast(msg: 'Mail wurde gesendet!');

                        setState(() {});

                        Navigator.pop(context);
                      });
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'user-not-found') {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                child: Container(
                                  padding: EdgeInsets.all(
                                    MediaQuery.of(context).size.width * 0.05,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Center(
                                        child: Text(
                                          'Ungültige Mail-Adresse!',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                      const Text(
                                        'Wir konnten keinen Account finden, zu dem die angegebene Mail gehört. Bitte überprüfe Deine EIngabe auf Schreibfehler oder erstelle einen neuen Account.',
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);

                                          Navigator.pop(context);

                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                          color: Colors.transparent,
                                          alignment: Alignment.centerLeft,
                                          padding: EdgeInsets.symmetric(
                                            vertical: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                          ),
                                          child: const Text(
                                            'Account erstellen',
                                            style: TextStyle(
                                              color: Colors.blueAccent,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.02,
                                            horizontal: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.02,
                                            ),
                                            color: Colors.grey,
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'OK',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 7,
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'Bestätigen',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.05,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
