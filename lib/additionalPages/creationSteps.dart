import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/currentUserData.dart';

//region Global Variables
int maxKeyQuestions = 3;
//endregion

//region UI Logic
class CreationStepPage extends StatefulWidget {
  final String vibeType;

  const CreationStepPage({
    super.key,
    required this.vibeType,
  });

  @override
  State<CreationStepPage> createState() => _CreationStepPageState();
}

class _CreationStepPageState extends State<CreationStepPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  String description = '';
  String title = '';
  File? croppedImage;
  List<Map<String, String>> messages = [];

  ImageProvider placeholderImage =
      Image.asset('assets/images/ucImages/ostseeQuadrat.jpg').image;

  Future pickImage(bool fromGallery) async {
    File? image;

    final pickedImage = await ImagePicker().pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
      maxHeight: 1080,
      maxWidth: 1080,
    );

    if (pickedImage == null) return;

    final imageTemporary = File(pickedImage.path);
    image = imageTemporary;

    await cropImage(image);

    setState(() {});
  }

  Future<File?> cropImage(File? image) async {
    var cropped = await ImageCropper().cropImage(
      sourcePath: image!.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      aspectRatioPresets: [CropAspectRatioPreset.square],
    );

    setState(() {
      croppedImage = File(cropped!.path);
    });

    return null;
  }

  bool loading = false;

  void showImageDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(
          MediaQuery.of(context).size.width * 0.05,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  pickImage(false).then(
                    (value) => Navigator.pop(context),
                  );
                },
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.05,
                    bottom: MediaQuery.of(context).size.width * 0.025,
                  ),
                  child: const Text(
                    'Kamera öffnen',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  pickImage(true).then(
                    (value) => Navigator.pop(context),
                  );
                },
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.width * 0.05,
                    top: MediaQuery.of(context).size.width * 0.025,
                  ),
                  child: const Text(
                    'Gallerie öffnen',
                    style: TextStyle(
                      fontSize: 18,
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

  Future checkCameraPermission() async {
    var status = await Permission.camera.status;

    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  Future checkGalleryPermission() async {
    var status = await Permission.storage.status;

    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> createDreamUp() async {
    loading = true;

    setState(() {});

    var vibe = FirebaseFirestore.instance.collection('vibes').doc();

    var id = vibe.id;

    String imageLink = '';

    Map<String, dynamic> dreamUpData = {
      'id': id,
      'fake': false,
      'content': description != '' ? description : 'Test-Beschreibung',
      'title': title != '' ? title : 'Test-Title',
      'type': 'Aktion',
      'aiMessages': messages,
    };

    if (croppedImage != null) {
      try {
        var ref = 'vibeMedia/images/$id';

        final FirebaseStorage storage = FirebaseStorage.instance;

        final TaskSnapshot uploadTask =
            await storage.ref(ref).putFile(croppedImage!);

        final updatedLink = await uploadTask.ref.getDownloadURL();

        imageLink = updatedLink;
      } on FirebaseException catch (e) {
        print('an error occured while putting the image to storage: $e');
      }

      imageLink = await FirebaseStorage.instance
          .ref('vibeMedia/images/$id')
          .getDownloadURL();

      dreamUpData.addAll({
        'imageLink': imageLink,
      });
    } else {
      imageLink =
          '*********************************';

      dreamUpData.addAll({
        'imageLink':
            '*********************************'
      });
    }

    var currentUser = FirebaseAuth.instance.currentUser?.uid;

    dreamUpData.addAll(
      {
        'creator': currentUser,
        'creatorBirthday': CurrentUser.birthday,
        'creatorGender': CurrentUser().genderEnumToString(CurrentUser.gender),
        'createdOn': DateTime.now(),
      },
    );

    dreamUpData.addAll({'city': 'Berlin'});

    var splitTitle = dreamUpData['title'].toLowerCase().split(' ');

    List<String> searchCharacters = [];

    for (var split in splitTitle) {
      var characters = split.trim().split('');

      String previous = '';

      for (int i = 0; i < characters.length; i++) {
        String entry = previous + characters[i];

        searchCharacters.add(entry);

        previous = entry;
      }
    }

    dreamUpData.addAll({'searchCharacters': searchCharacters});

    try {
      await vibe.set(dreamUpData).then((value) {
        setState(() {
          loading = false;
        });

        Navigator.pop(context);
      });
    } catch (e) {
      print('an error occured while creating a dreamUp: $e');
    }
  }

  int tabIndex = 0;

  late TabController tabController;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
    ]);

    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    tabController = TabController(
      length: 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    tabController.dispose();

    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + 0.05 * sin(_controller.value * 2 * pi),
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/images/AI GIF 2.gif',
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width,
                ),
              ),
            ),
            Positioned.fill(
              child: TabBarView(
                controller: tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  DescriptionWidget(
                    key: const PageStorageKey('description'),
                    getDreamUpText: (text, mess) {
                      print('text: $text');
                      print('messages: $mess');

                      setState(() {
                        description = text;
                        messages = mess;
                      });

                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                  TitleWidget(
                    key: const PageStorageKey('title'),
                    getDreamUpTitle: (text) {
                      setState(() {
                        title = text;
                        tabIndex++;
                      });

                      tabController.animateTo(tabIndex);

                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                  Container(
                    key: const PageStorageKey('image'),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.4,
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                    color: Colors.blueGrey.withOpacity(0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.width * 0.05,
                          ),
                          child: const Center(
                            child: Text(
                              'Wähle ein Bild',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: croppedImage == null,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      await checkCameraPermission();

                                      pickImage(false);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                      width: MediaQuery.of(context).size.width *
                                          0.4,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width *
                                              0.02,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Kamera',
                                          style: TextStyle(
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      checkGalleryPermission();

                                      pickImage(true);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                      width: MediaQuery.of(context).size.width *
                                          0.4,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width *
                                              0.02,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Gallerie',
                                          style: TextStyle(
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  croppedImage = null;

                                  setState(() {
                                    tabIndex++;
                                  });

                                  tabController.animateTo(tabIndex);
                                },
                                child: Container(
                                  margin: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                  padding: EdgeInsets.all(
                                    MediaQuery.of(context).size.width * 0.03,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width * 0.02,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Überspringen',
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        croppedImage == null
                            ? Container()
                            : Container(
                                margin: EdgeInsets.only(
                                  top: MediaQuery.of(context).size.width * 0.05,
                                ),
                                height: MediaQuery.of(context).size.width * 0.9,
                                width: MediaQuery.of(context).size.width * 0.9,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: Image.file(
                                      croppedImage!,
                                      fit: BoxFit.fill,
                                    ).image,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width * 0.05,
                                  ),
                                ),
                              ),
                        Visibility(
                          visible: croppedImage != null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  croppedImage = null;

                                  setState(() {});
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.width *
                                        0.05,
                                    right: MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                  child: const Text(
                                    'Bearbeiten',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    tabIndex++;
                                  });

                                  tabController.animateTo(tabIndex);
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.width *
                                        0.05,
                                    left: MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                  child: const Text(
                                    'Weiter',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    key: const PageStorageKey('overview'),
                    color: Colors.blueGrey.withOpacity(0),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        croppedImage != null
                            ? Container(
                                margin: EdgeInsets.only(
                                  top: MediaQuery.of(context).size.width * 0.05,
                                ),
                                height: MediaQuery.of(context).size.width * 0.9,
                                width: MediaQuery.of(context).size.width * 0.9,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: Image.file(
                                      croppedImage!,
                                      fit: BoxFit.fill,
                                    ).image,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width * 0.05,
                                  ),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: MediaQuery.of(context).padding.top,
              child: SizedBox(
                height: 50,
                width: 50,
                child: GestureDetector(
                  onTap: () {
                    if (tabIndex > 0) {
                      setState(() {
                        tabIndex--;
                      });

                      tabController.animateTo(tabIndex);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 50,
              child: Visibility(
                visible: tabIndex == 3,
                child: GestureDetector(
                  onTap: () async {
                    await createDreamUp();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Erstellen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Visibility(
                          visible: loading,
                          child: Container(
                            margin: const EdgeInsets.only(
                              left: 10,
                            ),
                            height: 20,
                            width: 20,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
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
    );
  }
}
//endregion

class DescriptionWidget extends StatefulWidget {
  final Function(String, List<Map<String, String>>) getDreamUpText;

  const DescriptionWidget({
    super.key,
    required this.getDreamUpText,
  });

  @override
  State<DescriptionWidget> createState() => _DescriptionWidgetState();
}

class _DescriptionWidgetState extends State<DescriptionWidget>
    with
        SingleTickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  bool isKeyboardVisible = false;

  final List<Map<String, String>> _messages = [];

  final String blurredKey =
      '';
  final String initialPrompt =
      'Du bist ein virtueller Assistent, der mir hilft, einen "DreamUp" zu formulieren. Ein DreamUp ist eine individuelle Wunschvorstellung davon, was ich gerne erleben würde oder wie ich mir eine ideale Freundschaft vorstelle. Deine Aufgabe ist es, ein Gespräch mit mir zu führen, mir Fragen zu stellen und aus meinen Antworten Informationen zu sammeln. Gestalte das Gespräch so natürlich wie möglich. Frage zuerst danach, ob ich eher nach einer Freundschaft oder einer Aktivität suche. Passe deine weiteren Fragen basierend auf dieser Antwort an. Handelt es sich um eine Aktivität, versuche so viele Details wie möglich darüber herauszufinden. Handelt es sich um eine Freundschaft, frage danach, was ich mir dabei besonders wünsche oder auf keinen Fall möchte. Stelle immer nur eine Frage auf einmal und warte auf meine Antwort, bevor du die nächste Frage stellst. Setze das Gespräch so lange fort, wie ich darauf eingehe, und stelle Rückfragen, um die Antworten zu präzisieren und ein möglichst genaues Bild meiner Vorstellungen zu bekommen. Formuliere keinen abschließenden Text, bis du dazu aufgefordert wirst. Ich werde dir mitteilen, wann du aufhören sollst, Fragen zu stellen und die gesammelten Informationen zusammenzufassen.';
  String creationPrompt =
      "Ab jetzt hörst du auf, Fragen zu stellen. Das Sammeln von Informationen ist beendet. Schreibe basierend auf den Informationen aus den anderen Nachrichten einen zusammengefassten Text in der Ich-Perspektive, ohne Einleitung, Danksagung oder Erklärung. Der Text soll sofort mit dem entsprechenden Inhalt beginnen und meinen persönlichen Wunsch oder mein Ziel ausdrücken. Schreib am Anfang, ob ich eine Freundschaft oder eine Aktivität suche und nenne diese gegebenenfalls. Hier sind die gesammelten Informationen: ";

  late TextEditingController _controller;

  int messageCount = 0;

  String currentMessage = '';

  String completedText = '';

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController()
      ..addListener(() {
        setState(() {});
      });

    _sendInitialPrompt();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _controller.dispose();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final value = WidgetsBinding
            .instance.platformDispatcher.views.first.viewInsets.bottom >
        0.0;
    setState(() {
      isKeyboardVisible = value;
    });
  }

  Future<void> _sendInitialPrompt() async {
    try {
      const int chunkSize = 500;
      for (int i = 0; i < initialPrompt.length; i += chunkSize) {
        print(initialPrompt.substring(
            i,
            i + chunkSize > initialPrompt.length
                ? initialPrompt.length
                : i + chunkSize));
      }

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo-0125',
          'messages': [
            {'role': 'system', 'content': initialPrompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('got response: $data');

        setState(() {
          _messages.add({
            'role': 'system',
            'content': initialPrompt,
          });
          _messages.add({
            'role': 'assistant',
            'content': data['choices'][0]['message']['content'],
          });

          currentMessage = _messages.last['content']!;
        });
      } else {
        print(
            'Failed to send initial prompt. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('An error occurred while sending initial prompt: $e');
    }
  }

  Future<void> _sendMessage(String message) async {
    try {
      setState(() {
        _messages.add({'role': 'user', 'content': message});
      });

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo-0125',
          'messages': [
            ..._messages
                .map((msg) => {'role': msg['role'], 'content': msg['content']}),
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('got response: $data');

        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': data['choices'][0]['message']['content'],
          });
          messageCount++;

          print(_messages.last['content']);

          currentMessage = _messages.last['content']!;
        });
      } else {
        print('Failed to send message. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('An error occurred while chatting with AI: $e');
    }
  }

  Future<void> _createDreamUpText() async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();

      String information = _messages.map((msg) => msg['content']).join(" ");

      String finalPrompt =
          "$creationPrompt$information Beispiel (nur zur Verdeutlichung des Formats, nicht im Text verwenden): 'Ich suche nach einer Freundschaft, die darauf basiert, tiefgründige Gespräche zu führen. Religion ist dabei mein Steckenpferd, doch ich bin auch offen für andere Themen. Wichtig ist, dass mein Gesprächspartner auch Zeit für mich hat und das Ganze regelmäßig stattfinden kann.'";

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo-0125',
          'messages': [
            {
              'role': 'user',
              'content': finalPrompt,
            },
          ],
          'temperature': 0.6,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('got response: $data');

        var content = data['choices'][0]['message']['content'];

        print(content);

        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': content,
          });

          currentMessage = content;

          completedText = content;
        });

        widget.getDreamUpText(content, _messages);
      } else {
        print(
            'Failed to create DreamUp text. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('An error occurred while generating the DreamUp text: $e');
    }
  }

  Future<void> _recreateDreamUpText() async {
    _messages.removeLast();
    _messages.removeLast();

    await _createDreamUpText();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 200,
                  ),
                  color: Colors.transparent,
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                  ),
                  height: isKeyboardVisible
                      ? 0
                      : MediaQuery.of(context).size.width * 0.75,
                  child: Center(
                    child: GestureDetector(
                      onTap: () async {
                        //if (messageCount < 3) return;

                        completedText != ''
                            ? await _recreateDreamUpText()
                            : await _createDreamUpText();
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.width * 0.5,
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  //   alignment: Alignment.topRight,
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.end,
                  //     crossAxisAlignment: CrossAxisAlignment.center,
                  //     children: [
                  //       Container(
                  //         margin: const EdgeInsets.only(
                  //           right: 20,
                  //           top: 20,
                  //         ),
                  //         child: Text(
                  //           '$messageCount/3',
                  //           style: const TextStyle(
                  //             fontSize: 16,
                  //             color: Colors.white,
                  //           ),
                  //         ),
                  //       ),
                  //       GestureDetector(
                  //         onTap: () async {
                  //           if (messageCount < 3) return;
                  //
                  //           completedText != ''
                  //               ? await _recreateDreamUpText()
                  //               : await _createDreamUpText();
                  //         },
                  //         child: Container(
                  //           margin: const EdgeInsets.only(
                  //             right: 20,
                  //             top: 20,
                  //           ),
                  //           padding: const EdgeInsets.symmetric(
                  //             vertical: 7,
                  //             horizontal: 10,
                  //           ),
                  //           decoration: BoxDecoration(
                  //             color: messageCount < 3
                  //                 ? Colors.grey
                  //                 : Colors.blueAccent,
                  //             borderRadius: BorderRadius.circular(7),
                  //           ),
                  //           child: Text(
                  //             completedText != ''
                  //                 ? 'Text Erneuern'
                  //                 : 'Text Erstellen',
                  //             style: const TextStyle(
                  //               color: Colors.white,
                  //               fontSize: 18,
                  //               fontWeight: FontWeight.bold,
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                      ),
                      color: Colors.transparent,
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.all(8),
                            child: AnimatedTextKit(
                              animatedTexts: [
                                TypewriterAnimatedText(
                                  currentMessage,
                                  cursor: '',
                                  textAlign: TextAlign.center,
                                  textStyle: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                  speed: const Duration(
                                    milliseconds: 25,
                                  ),
                                ),
                              ],
                              totalRepeatCount: 1,
                              isRepeatingAnimation: false,
                              key: ValueKey(currentMessage),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: Colors.black26,
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    autocorrect: true,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Nachricht',
                      hintStyle: TextStyle(
                        color: Colors.black87,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              GestureDetector(
                onTap: () {
                  if (_controller.text.isEmpty) return;

                  FocusManager.instance.primaryFocus?.unfocus();

                  _sendMessage(_controller.text);
                  _controller.clear();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        _controller.text.isNotEmpty ? Colors.blue : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TitleWidget extends StatefulWidget {
  final Function(String) getDreamUpTitle;
  const TitleWidget({
    super.key,
    required this.getDreamUpTitle,
  });

  @override
  State<TitleWidget> createState() => _TitleWidgetState();
}

class _TitleWidgetState extends State<TitleWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController()
      ..addListener(() {
        setState(() {});
      });

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Container(
              color: Colors.blueGrey.withOpacity(0),
              child: const Center(
                child: Text(
                  'Wähle einen passenden Titel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: Colors.black26,
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    autocorrect: true,
                    decoration: const InputDecoration(
                      hintText: 'Titel',
                      hintStyle: TextStyle(
                        color: Colors.black87,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              GestureDetector(
                onTap: () {
                  widget.getDreamUpTitle(_controller.text.trim());
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        _controller.text.isNotEmpty ? Colors.blue : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
