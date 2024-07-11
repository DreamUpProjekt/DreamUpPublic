import 'package:auto_size_text/auto_size_text.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_test/additionalPages/userInfoGetterPage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../main.dart';
import '../utils/contactSupport.dart';
import '../utils/currentUserData.dart';
import '../utils/encrypting.dart';
import '../utils/forgotPassword.dart';

//region Global Variables
String video = 'assets/videos/JacobVersionCropped.mp4';
//endregion

//region UI Logic
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String status = 'signUp';
  bool typing = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late FocusNode passwordFocus;

  bool isPasswordVisible = false;

  Future signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      print(e);

      if (!ModalRoute.of(context)!.isCurrent) {
        if (mounted) Navigator.pop(context);
      }

      if (e.code == 'user-disabled') {
        showDialog(
          context: context,
          builder: (context) {
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Du wurdest gesperrt!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.05,
                    ),
                    const Text(
                      'Wie es aussieht, bist du von unserem System gesperrt worden. Wende dich bei Fragen bitte an unseren Support!',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactSupportPage(),
                          ),
                        );
                      },
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: const Text(
                          'Support kontaktieren',
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
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.02,
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
          },
        );
      } else if (e.code == 'user-not-found') {
        showDialog(
          context: context,
          builder: (context) {
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Nutzer nicht gefunden!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.05,
                    ),
                    const Text(
                      'Mit der angegebenen Mail-Adresse ist kein Account verknüpft!',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        status = 'signUp';

                        if (mounted) {
                          setState(() {});
                        }

                        Navigator.pop(context);
                      },
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.05,
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
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.02,
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
          },
        );
      } else if (e.code == 'wrong-password') {
        showDialog(
          context: context,
          builder: (context) {
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Falsches Passwort!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.05,
                    ),
                    const Text(
                      'Das von dir angegebene Passwort ist nicht korrekt. Bitte überprüfe es auf mögliche Schreibfehler!',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: const Text(
                          'Passwort zurücksetzen',
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
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.02,
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
          },
        );
      } else if (e.code == 'invalid-email') {
        showDialog(
          context: context,
          builder: (context) {
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Ungültige E-Mail!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.05,
                    ),
                    const Text(
                      'Die von dir angegebene E-Mail Adresse scheint nicht gültig zu sein. Bitte gib eine gültige Adresse an!',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactSupportPage(),
                          ),
                        );
                      },
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: const Text(
                          'Support kontaktieren',
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
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.02,
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
          },
        );
      }
    }
  }

  final Future<SharedPreferences> prefs = SharedPreferences.getInstance();

  String mail = '';
  String password = '';
  bool isSaving = false;
  bool existing = false;

  bool keyBoardOpen = false;

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  final CarouselController carouselController = CarouselController();

  @override
  void initState() {
    super.initState();

    emailController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));

    passwordFocus = FocusNode();

    prefs.then((value) {
      mail = value.getString('mail') ?? '';
      password = value.getString('password') ?? '';
      isSaving = value.getBool('saving') ?? false;

      if (mounted && mail != '' && password != '') {
        existing = true;

        emailController.text = mail;
        passwordController.text = password;

        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double padding = MediaQuery.of(context).size.width / 6 / 4;

    return Scaffold(
      backgroundColor: Colors.grey,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: AssetPlayerWidget(),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();

                    if (mounted) {
                      setState(() {
                        typing = false;
                      });
                    }
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).padding.top,
                  ),
                  Visibility(
                    visible: !typing,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width * 0.1,
                        right: MediaQuery.of(context).size.width * 0.1,
                        top: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Do things \nyou enjoy.',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: <Shadow>[
                                Shadow(
                                  offset: Offset(3.0, 3.0),
                                  blurRadius: 3.0,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'But do them \ntogether.',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: <Shadow>[
                                Shadow(
                                  offset: Offset(3.0, 3.0),
                                  blurRadius: 3.0,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();

                        if (mounted) {
                          setState(() {
                            typing = false;
                          });
                        }
                      },
                      child: CarouselSlider(
                        carouselController: carouselController,
                        items: [
                          Container(
                            alignment: Alignment.bottomCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.width / 7,
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      !existing ? status = 'signUp' : 'signIn';

                                      if (mounted) {
                                        setState(() {});
                                      }

                                      if (!existing) {
                                        status = 'signUp';

                                        emailController.text = '';
                                        passwordController.text = '';

                                        if (mounted) {
                                          setState(() {});
                                        }

                                        carouselController.animateToPage(1);
                                      } else {
                                        status = 'signIn';

                                        if (mounted) {
                                          setState(() {});
                                        }

                                        carouselController.animateToPage(1);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      enableFeedback: false,
                                      backgroundColor: const Color(0xFF1E1E1E),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      !existing ? 'SIGN UP' : 'LOGIN',
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.width * 0.03,
                                ),
                                SizedBox(
                                  height: MediaQuery.of(context).size.width / 7,
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: TextButton(
                                    onPressed: () {
                                      !existing ? status = 'signIn' : 'signUp';

                                      if (mounted) {
                                        setState(() {});
                                      }

                                      if (!existing) {
                                        status = 'signIn';

                                        if (mounted) {
                                          setState(() {});
                                        }

                                        carouselController.animateToPage(1);
                                      } else {
                                        status = 'signUp';

                                        emailController.text = '';
                                        passwordController.text = '';

                                        if (mounted) {
                                          setState(() {});
                                        }

                                        carouselController.animateToPage(1);
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      enableFeedback: false,
                                    ),
                                    child: Text(
                                      !existing ? 'LOGIN' : 'SIGN UP',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
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
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.width * 0.1,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            alignment: Alignment.bottomCenter,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    carouselController.animateToPage(2);
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.width *
                                          0.05,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                    ),
                                    height: MediaQuery.of(context).size.width *
                                        0.175,
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        MediaQuery.of(context).size.width *
                                            0.03,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.mail_rounded,
                                          size: 30,
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05,
                                        ),
                                        Text(
                                          status == 'signUp'
                                              ? 'SignUp mit Email'
                                              : 'Login mit Email',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.width * 0.1,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            alignment: Alignment.bottomCenter,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      height: padding * 0.5,
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width / 7,
                                      width: MediaQuery.of(context).size.width -
                                          padding * 4,
                                      child: TextField(
                                        style: const TextStyle(
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black87,
                                              blurRadius: 10,
                                              offset: Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                        autocorrect: false,
                                        maxLines: 1,
                                        onTap: () {
                                          if (mounted) {
                                            setState(() {
                                              typing = true;
                                            });
                                          }
                                        },
                                        controller: emailController,
                                        cursorColor: Colors.white,
                                        decoration: InputDecoration(
                                          hoverColor: Colors.white,
                                          focusColor: Colors.white,
                                          prefixIconColor: Colors.white,
                                          labelText: 'Email',
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black87,
                                                blurRadius: 10,
                                                offset: Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.mail,
                                            color: Colors.white,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        onSubmitted: (string) {
                                          passwordFocus.requestFocus();
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      height: padding,
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width / 7,
                                      width: MediaQuery.of(context).size.width -
                                          padding * 4,
                                      child: TextField(
                                        focusNode: passwordFocus,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black87,
                                              blurRadius: 10,
                                              offset: Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                        autocorrect: false,
                                        onTap: () {
                                          if (mounted) {
                                            setState(() {
                                              typing = true;
                                            });
                                          }
                                        },
                                        onSubmitted: (string) {
                                          if (mounted) {
                                            setState(() {
                                              typing = false;
                                            });
                                          }

                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                        },
                                        controller: passwordController,
                                        cursorColor: Colors.white,
                                        decoration: InputDecoration(
                                          prefixIconColor: Colors.white,
                                          labelText: 'Passwort',
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black87,
                                                blurRadius: 10,
                                                offset: Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.vpn_key_rounded,
                                            color: Colors.white,
                                          ),
                                          suffixIcon: passwordController
                                                  .text.isEmpty
                                              ? Container(
                                                  width: 0,
                                                )
                                              : IconButton(
                                                  icon: isPasswordVisible
                                                      ? const Icon(
                                                          Icons.visibility_off,
                                                          color: Colors.white,
                                                        )
                                                      : const Icon(
                                                          Icons.visibility,
                                                          color: Colors.white,
                                                        ),
                                                  onPressed: () => setState(
                                                    () => isPasswordVisible =
                                                        !isPasswordVisible,
                                                  ),
                                                ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                                color: Colors.white, width: 3),
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                                color: Colors.white, width: 3),
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                        ),
                                        obscureText: !isPasswordVisible,
                                        keyboardType:
                                            TextInputType.visiblePassword,
                                        textInputAction: TextInputAction.done,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        if (mounted) {
                                          setState(() {
                                            isSaving = !isSaving;
                                          });
                                        }

                                        final SharedPreferences sharedPrefs =
                                            await prefs;
                                        sharedPrefs.setBool('saving', isSaving);
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                        padding: EdgeInsets.only(
                                          bottom: padding,
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width -
                                                padding * 4,
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: isSaving,
                                              onChanged: (value) async {
                                                if (mounted) {
                                                  setState(() {
                                                    isSaving = value!;
                                                  });
                                                }

                                                final SharedPreferences
                                                    sharedPrefs = await prefs;
                                                sharedPrefs.setBool(
                                                    'saving', value!);
                                              },
                                              side: const BorderSide(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                              shape: const CircleBorder(),
                                              activeColor: Colors.white,
                                              checkColor: Colors.black,
                                              focusColor: Colors.white,
                                              hoverColor: Colors.white,
                                            ),
                                            const Text(
                                              'Einlogdaten speichern',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black87,
                                                    blurRadius: 10,
                                                    offset: Offset(1, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (context) => Dialog(
                                            insetPadding: EdgeInsets.symmetric(
                                              horizontal: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.4,
                                            ),
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.2,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.2,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                padding: EdgeInsets.all(
                                                  MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.05,
                                                ),
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );

                                        if (status == 'signIn') {
                                          try {
                                            await signIn();

                                            if (FirebaseAuth
                                                    .instance.currentUser !=
                                                null) {
                                              print('User is logged in');
                                              userLoggedIn = true;

                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(FirebaseAuth.instance
                                                      .currentUser?.uid)
                                                  .update({
                                                'firebaseToken': firebaseToken,
                                              });

                                              print('updated firebase token');

                                              await CurrentUser().getUserData();

                                              var encryption = Encryption();
                                              await encryption.loadPrivateKey(
                                                  passwordController.text
                                                      .trim());

                                              print('now poppin context');

                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                            }
                                          } catch (e) {
                                            print('SignIn failed: $e');
                                          }
                                        } else if (status == 'signUp') {
                                          await Navigator.push(
                                            context,
                                            changePage(
                                              UserInfoPage(
                                                mail: emailController.text,
                                                password:
                                                    passwordController.text,
                                              ),
                                            ),
                                          ).then((_) async {
                                            print('Signed up and returned');

                                            if (FirebaseAuth
                                                    .instance.currentUser !=
                                                null) {
                                              print('User is logged in');
                                              userLoggedIn = true;

                                              await CurrentUser().getUserData();

                                              var encryption = Encryption();
                                              await encryption
                                                  .generateEncryptionKeys(
                                                      passwordController.text
                                                          .trim());

                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                            }
                                          });
                                        }
                                      },
                                      child: Container(
                                        margin: EdgeInsets.only(
                                          left: padding * 2,
                                          right: padding * 2,
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          child: Container(
                                            color: const Color(0xFF5E70EC),
                                            padding: EdgeInsets.symmetric(
                                              vertical: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.05,
                                            ),
                                            child: Center(
                                              child: AutoSizeText(
                                                status == 'signUp'
                                                    ? 'Registrieren'
                                                    : 'Einloggen',
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.1,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        options: CarouselOptions(
                          height: double.infinity,
                          viewportFraction: 1,
                          enableInfiniteScroll: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//endregion

//region Widgets
class AssetPlayerWidget extends StatefulWidget {
  const AssetPlayerWidget({super.key});

  @override
  _AssetPlayerWidgetState createState() => _AssetPlayerWidgetState();
}

class _AssetPlayerWidgetState extends State<AssetPlayerWidget> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.asset(video)
      ..addListener(_onVideoControllerUpdate)
      ..setLooping(true)
      ..setVolume(1)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      })
      ..play();
  }

  void _onVideoControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onVideoControllerUpdate);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayerWidget(controller: controller);
  }
}

class VideoPlayerWidget extends StatelessWidget {
  final VideoPlayerController controller;

  const VideoPlayerWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: buildVideo(),
    );
  }

  Widget buildVideo() => buildVideoPlayer();

  Widget buildVideoPlayer() => VideoPlayer(controller);
}

//endregion
