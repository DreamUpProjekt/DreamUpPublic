import 'dart:io';

import 'package:firebase_test/utils/firebaseUtils.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../utils/currentUserData.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({
    super.key,
  });

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  File? croppedImage;

  Future pickImage(bool fromGallery) async {
    final pickedImage = await ImagePicker().pickImage(
        source: fromGallery ? ImageSource.gallery : ImageSource.camera);

    if (pickedImage == null) return;

    final imageTemporary = File(pickedImage.path);

    await cropImage(imageTemporary);

    setState(() {});
  }

  Future<File?> cropImage(File? image) async {
    var cropped = await ImageCropper().cropImage(
        sourcePath: image!.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        aspectRatioPresets: [CropAspectRatioPreset.square]);

    setState(() {
      croppedImage = File(cropped!.path);
    });

    return null;
  }

  bool sending = false;

  String translateGender(Gender gender) {
    if (gender == Gender.male) {
      return 'männlich';
    } else if (gender == Gender.female) {
      return 'weiblich';
    } else if (gender == Gender.diverse) {
      return 'divers';
    } else {
      return 'Dein Geschlecht';
    }
  }

  Map<String, dynamic> userInfo = {};

  bool changeImage = false;

  bool somethingChanged() {
    return userInfo['name'] != CurrentUser.name ||
        userInfo['bio'] != CurrentUser.bio ||
        userInfo['gender'] !=
            CurrentUser().genderEnumToString(CurrentUser.gender) ||
        userInfo['birthday'] != CurrentUser.birthday.toString() ||
        croppedImage != null;
  }

  @override
  void initState() {
    super.initState();

    userInfo.addAll(
      {
        'name': CurrentUser.name,
        'bio': CurrentUser.bio,
        'gender': CurrentUser().genderEnumToString(CurrentUser.gender),
        'birthday': CurrentUser.birthday.toString(),
      },
    );
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
            Navigator.pop(
              context,
              true,
            );
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
          'Persönliche Informationen',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.width * 0.4,
                width: MediaQuery.of(context).size.width * 0.4,
                child: croppedImage == null
                    ? Image.file(
                        CurrentUser.imageFile!,
                      )
                    : Image.file(croppedImage!),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.width * 0.05,
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    changeImage ? changeImage = false : changeImage = true;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.width * 0.03,
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                  ),
                  color: Colors.white,
                  child: Text(
                    changeImage ? 'Abbrechen' : 'Bild ändern',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: changeImage,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.03,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await pickImage(false);

                            setState(() {
                              changeImage = false;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  MediaQuery.of(context).size.width * 0.03,
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.05,
                            ),
                            color: Colors.white,
                            child: const Text(
                              'Kamera',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.03,
                        ),
                        GestureDetector(
                          onTap: () async {
                            await pickImage(true);

                            setState(() {
                              changeImage = false;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  MediaQuery.of(context).size.width * 0.03,
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.05,
                            ),
                            color: Colors.white,
                            child: const Text(
                              'Galerie',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.1,
          ),
          Container(
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.05,
              bottom: MediaQuery.of(context).size.width * 0.02,
            ),
            child: const Text(
              'Über mich',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.push(
                context,
                changePage(
                  NameChangePage(
                    nameChanged: (value) {
                      userInfo['name'] = value;

                      setState(() {});
                    },
                    currentName: userInfo['name'],
                  ),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: MediaQuery.of(context).size.width * 0.05,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.3,
                    ),
                    margin: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width * 0.03,
                    ),
                    child: Text(
                      userInfo['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.black38,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.push(
                context,
                changePage(
                  BioChangePage(
                    bioChanged: (value) {
                      userInfo['bio'] = value;
                    },
                    currentBio: userInfo['bio'],
                  ),
                ),
              );

              setState(() {});
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: MediaQuery.of(context).size.width * 0.05,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Beschreibung',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.3,
                    ),
                    margin: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width * 0.03,
                    ),
                    child: Text(
                      userInfo['bio'],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.black38,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.push(
                context,
                changePage(
                  GenderChangePage(
                    changedGender: (gender) {
                      userInfo['gender'] =
                          CurrentUser().genderEnumToString(gender);
                    },
                    currentGender:
                        CurrentUser().stringToGenderEnum(userInfo['gender']),
                  ),
                ),
              );

              setState(() {});
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: MediaQuery.of(context).size.width * 0.05,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Geschlecht',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.3,
                    ),
                    margin: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width * 0.03,
                    ),
                    child: Text(
                      translateGender(
                        CurrentUser().stringToGenderEnum(
                          userInfo['gender'],
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.black38,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              DateTime? chosenDate = await showDatePicker(
                context: context,
                locale: const Locale(
                  'de',
                  'de-de',
                ),
                initialDate: DateTime.now(),
                firstDate: DateTime(DateTime.now().year - 100),
                lastDate: DateTime.now(),
                helpText: 'Wann ist dein Geburtstag?',
                cancelText: 'Abbrechen',
                confirmText: 'Bestätigen',
              );

              if (chosenDate != null) {
                userInfo['birthday'] = chosenDate.toString();

                setState(() {});
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: MediaQuery.of(context).size.width * 0.05,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Geburtstag',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.3,
                    ),
                    margin: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width * 0.03,
                    ),
                    child: Text(
                      DateFormat('dd.MM.yyyy', 'de_DE').format(
                        DateTime.parse(
                          userInfo['birthday'],
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.transparent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () async {
                if (!sending) {
                  sending = true;

                  setState(() {});

                  if (croppedImage != null) {
                    await FirebaseUtils.updateImageInStorage(croppedImage!);
                  }

                  await FirebaseUtils.updateUserInformation(userInfo);

                  sending = false;

                  Navigator.pop(context);
                }
              },
              child: Container(
                margin: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.05,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.width * 0.02,
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                ),
                decoration: BoxDecoration(
                  color: somethingChanged() ? Colors.blue : Colors.black26,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Visibility(
                      visible: sending,
                      child: Container(
                        margin: EdgeInsets.only(
                          right: MediaQuery.of(context).size.width * 0.02,
                        ),
                        child: const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      'Speichern',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NameChangePage extends StatefulWidget {
  final Function(String) nameChanged;
  final String currentName;
  const NameChangePage({
    super.key,
    required this.nameChanged,
    required this.currentName,
  });

  @override
  State<NameChangePage> createState() => _NameChangePageState();
}

class _NameChangePageState extends State<NameChangePage> {
  final nameController = TextEditingController();

  String name = '';

  @override
  void initState() {
    super.initState();

    name = widget.currentName;

    nameController.addListener(() {
      name = nameController.text.trim();

      print(name);

      setState(() {});
    });

    nameController.text = name;
  }

  @override
  void dispose() {
    nameController.dispose();

    super.dispose();
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
            Navigator.pop(context);
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
          'Name ändern',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SizedBox.expand(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width * 0.05,
            MediaQuery.of(context).size.width * 0.05,
            MediaQuery.of(context).size.width * 0.05,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Name',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  top: MediaQuery.of(context).size.width * 0.02,
                  bottom: MediaQuery.of(context).size.width * 0.05,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    width: 1,
                    color: Colors.black54,
                  ),
                  color: Colors.white,
                ),
                child: TextField(
                  controller: nameController,
                  onSubmitted: (text) {
                    name = text.trim();
                  },
                  enableSuggestions: true,
                  autocorrect: true,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: name,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.03,
                    ),
                  ),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    if (name != '' && name != widget.currentName) {
                      print('commiting name: $name');

                      widget.nameChanged(name);

                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.all(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.width * 0.02,
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                    ),
                    decoration: BoxDecoration(
                      color: name != '' && name != widget.currentName
                          ? Colors.blue
                          : Colors.black26,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'Speichern',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

class BioChangePage extends StatefulWidget {
  final Function(String) bioChanged;
  final String currentBio;
  const BioChangePage({
    super.key,
    required this.bioChanged,
    required this.currentBio,
  });

  @override
  State<BioChangePage> createState() => _BioChangePageState();
}

class _BioChangePageState extends State<BioChangePage> {
  final bioController = TextEditingController();

  String bio = '';

  @override
  void initState() {
    super.initState();

    bio = widget.currentBio;

    bioController.addListener(() {
      bio = bioController.text.trim();

      setState(() {});
    });

    bioController.text = bio;
  }

  @override
  void dispose() {
    bioController.dispose();

    super.dispose();
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
            Navigator.pop(context);
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
          'Beschreibung ändern',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SizedBox.expand(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width * 0.05,
            MediaQuery.of(context).size.width * 0.05,
            MediaQuery.of(context).size.width * 0.05,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Beschreibung',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.02,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      width: 1,
                      color: Colors.black54,
                    ),
                    color: Colors.white,
                  ),
                  child: TextField(
                    controller: bioController,
                    onSubmitted: (text) {
                      bio = text.trim();
                    },
                    enableSuggestions: true,
                    autocorrect: true,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Beschreibung',
                      contentPadding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.03,
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    if (bio != '' && bio != widget.currentBio) {
                      widget.bioChanged(bio);

                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.all(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.width * 0.02,
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                    ),
                    decoration: BoxDecoration(
                      color: bio != '' && bio != widget.currentBio
                          ? Colors.blue
                          : Colors.black26,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'Speichern',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

class GenderChangePage extends StatefulWidget {
  final Function(Gender) changedGender;
  final Gender currentGender;
  const GenderChangePage({
    super.key,
    required this.changedGender,
    required this.currentGender,
  });

  @override
  State<GenderChangePage> createState() => _GenderChangePageState();
}

class _GenderChangePageState extends State<GenderChangePage> {
  Gender userGender = Gender.none;

  bool changed() {
    return userGender != Gender.none && userGender != CurrentUser.gender;
  }

  @override
  void initState() {
    super.initState();

    userGender = widget.currentGender;
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
            Navigator.pop(context);
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
          'Geschlecht ändern',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SizedBox.expand(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width * 0.05,
            MediaQuery.of(context).size.width * 0.05,
            MediaQuery.of(context).size.width * 0.05,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: const Text('männlich'),
                leading: Radio(
                  value: Gender.male,
                  groupValue: userGender,
                  onChanged: (Gender? value) {
                    setState(() {
                      userGender = value!;
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('weiblich'),
                leading: Radio(
                  value: Gender.female,
                  groupValue: userGender,
                  onChanged: (Gender? value) {
                    setState(() {
                      userGender = value!;
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('divers'),
                leading: Radio(
                  value: Gender.diverse,
                  groupValue: userGender,
                  onChanged: (Gender? value) {
                    setState(() {
                      userGender = value!;
                    });
                  },
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    if (changed()) {
                      widget.changedGender(userGender);

                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.all(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.width * 0.02,
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                    ),
                    decoration: BoxDecoration(
                      color: changed() ? Colors.blue : Colors.black26,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'Speichern',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
