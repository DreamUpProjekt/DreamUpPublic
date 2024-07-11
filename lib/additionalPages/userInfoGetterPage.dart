import 'package:firebase_test/utils/firebaseUtils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../utils/currentUserData.dart';

class UserInfoPage extends StatefulWidget {
  final String mail;
  final String password;
  const UserInfoPage({
    super.key,
    required this.mail,
    required this.password,
  });

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  int index = 0;
  final PageController controller = PageController();

  String name = '';
  String bio = '';
  DateTime? birthday;
  Gender gender = Gender.none;

  List<Widget> pages = [];

  List<Widget> activePages = [];

  bool canGoForward() {
    bool forward = false;

    if (index == 0) {
      if (name != '') {
        forward = true;
      }
    } else if (index == 1) {
      if (bio != '') {
        forward = true;
      }
    } else if (index == 2) {
      if (birthday != null) {
        forward = true;
      }
    } else if (index == 3) {
      if (gender != Gender.none) {
        forward = true;
      }
    }

    return forward;
  }

  bool canGoBack() {
    if (index > 0) {
      return true;
    } else {
      return false;
    }
  }

  void addPage() async {
    FocusManager.instance.primaryFocus?.unfocus();

    index++;

    print(index);

    if (index == 4) {
      print('all done!');

      await FirebaseUtils.createUser(
        mail: widget.mail,
        password: widget.password,
        name: name,
        bio: bio,
        birthday: birthday!,
        gender: gender,
      ).then(
        (_) {
          print('user in info page created');

          Navigator.pop(context);

          return;
        },
      );
    }

    if (activePages.length == index) {
      activePages.add(pages[index]);
    }

    setState(() {});

    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();

    pages = [
      NamePage(
        setName: (value) {
          name = value;

          print(name);

          setState(() {});
        },
      ),
      BioPage(
        setBio: (value) {
          bio = value;

          print(bio);

          setState(() {});
        },
      ),
      BirthdayPage(
        setBirthday: (value) {
          birthday = value;

          print(birthday);

          setState(() {});
        },
      ),
      GenderPage(
        setGender: (value) {
          gender = value;

          print(gender);

          setState(() {});
        },
      ),
    ];

    activePages.add(pages[0]);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: controller,
                itemCount: activePages.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (value) {
                  setState(() {
                    index = value;
                  });
                },
                itemBuilder: (context, index) {
                  return activePages[index];
                },
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Container(
                height: 70,
                width: MediaQuery.of(context).size.width,
                color: Colors.transparent,
                child: Center(
                  child: SmoothPageIndicator(
                    controller: controller,
                    count: 4,
                    effect: const ScaleEffect(
                      activeDotColor: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Container(
                height: 70,
                width: MediaQuery.of(context).size.width,
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (canGoBack()) {
                          controller.animateToPage(
                            index - 1,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 30),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color:
                              canGoBack() ? Colors.blueAccent : Colors.black26,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text(
                          'Zurück',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (canGoForward()) {
                          addPage();
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 30),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: canGoForward()
                              ? Colors.blueAccent
                              : Colors.black26,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text(
                          'Weiter',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
    );
  }
}

class NamePage extends StatefulWidget {
  final Function(String) setName;
  const NamePage({
    super.key,
    required this.setName,
  });

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  final TextEditingController nameController = TextEditingController();

  String name = '';

  @override
  void initState() {
    super.initState();

    nameController.addListener(() {
      name = nameController.text.trim();
      setState(() {});

      widget.setName(name);
    });
  }

  @override
  void dispose() {
    nameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                margin: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 50),
                color: Colors.transparent,
                alignment: Alignment.center,
                child: const Text(
                  'Wie lautet dein Name?',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            color: Colors.transparent,
            child: Center(
              child: TextField(
                controller: nameController,
                onSubmitted: (text) {
                  name = text;
                  widget.setName(name);

                  FocusManager.instance.primaryFocus?.unfocus();
                },
                autocorrect: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Dein Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BioPage extends StatefulWidget {
  final Function(String) setBio;
  const BioPage({
    super.key,
    required this.setBio,
  });

  @override
  State<BioPage> createState() => _BioPageState();
}

class _BioPageState extends State<BioPage> {
  final TextEditingController bioController = TextEditingController();

  String bio = '';

  @override
  void initState() {
    super.initState();

    bioController.addListener(() {
      bio = bioController.text;

      setState(() {});
      widget.setBio(bio);
    });
  }

  @override
  void dispose() {
    bioController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                margin: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 50),
                color: Colors.transparent,
                alignment: Alignment.center,
                child: const Text(
                  'Erzähl etwas über dich',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            color: Colors.transparent,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: TextField(
                  controller: bioController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  autocorrect: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Deine Bio',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BirthdayPage extends StatefulWidget {
  final Function(DateTime) setBirthday;
  const BirthdayPage({
    super.key,
    required this.setBirthday,
  });

  @override
  State<BirthdayPage> createState() => _BirthdayPageState();
}

class _BirthdayPageState extends State<BirthdayPage> {
  DateTime? birthday;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            margin:
                EdgeInsets.only(top: MediaQuery.of(context).padding.top + 50),
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Theme(
              data: Theme.of(context),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Wann ist dein Geburtstag?',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Foundry Context W03',
                      ),
                    ),
                    WidgetSpan(
                      child: IconButton(
                        onPressed: () {
                          print('info pressed');

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text(
                                'Wofür benötigen wir dein Geburtsdatum?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                ),
                              ),
                              content: const Text(
                                'In DreamUp geben wir dir verschiedene Informationen an die Hand, die in Bezug auf andere User für dich relevant sein könnten. Eine dieser Informationen ist die, ob der Ersteller eines DreamUps in deiner Altersspanne liegt oder aber älter, bzw. jünger ist, als du. Um diese Einordnung treffen zu können, benötigen wir dein Geburtsdatum.',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    'Alles klar!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.info_rounded,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  birthday != null
                      ? DateFormat('dd.MM.yyyy', 'de_DE').format(birthday!)
                      : '',
                  style: const TextStyle(fontSize: 22),
                ),
                SizedBox(height: birthday != null ? 15 : 0),
                GestureDetector(
                  onTap: () async {
                    DateTime? chosenDate = await showDatePicker(
                      context: context,
                      locale: const Locale('de', 'de_DE'),
                      initialDate: DateTime(DateTime.now().year - 18,
                          DateTime.now().month, DateTime.now().day),
                      firstDate: DateTime(DateTime.now().year - 100),
                      lastDate: DateTime.now(),
                      helpText: 'Wann ist dein Geburtstag?',
                      cancelText: 'Abbrechen',
                      confirmText: 'Bestätigen',
                    );

                    if (chosenDate != null) {
                      setState(() {
                        birthday = chosenDate;
                      });

                      widget.setBirthday(birthday!);
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color:
                          birthday == null ? Colors.blueAccent : Colors.white,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        width: 2,
                        color: Colors.blueAccent,
                      ),
                    ),
                    child: Text(
                      birthday == null
                          ? 'Geburtstag festlegen'
                          : 'Geburtstag ändern',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            birthday == null ? Colors.white : Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }
}

class GenderPage extends StatefulWidget {
  final Function(Gender) setGender;
  const GenderPage({
    super.key,
    required this.setGender,
  });

  @override
  State<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends State<GenderPage> {
  Gender gender = Gender.none;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            margin:
                EdgeInsets.only(top: MediaQuery.of(context).padding.top + 50),
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Theme(
              data: Theme.of(context),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Wähle dein Geschlecht',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Foundry Context W03',
                      ),
                    ),
                    WidgetSpan(
                      child: IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text(
                                'Wofür benötigen wir dein Geschlecht?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                ),
                              ),
                              content: const Text(
                                'Genau wie das Alter, ist auch das Geschlecht eines DreamUp-Erstellers wichtig, wenn es darum geht, ob man einen DreamUp miteinander teilen möchte oder nicht. Für diese Erhebung benötigen wir dein Geschlecht. Außerdem erlaubt diese Angabe dir, dir nur DreamUps von Usern deines Geschlechtes anzeigen zu lassen.',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    'Alles klar!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.info_rounded,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      gender = Gender.male;
                    });

                    widget.setGender(gender);
                  },
                  child: ListTile(
                    title: const Text('männlich'),
                    leading: Radio(
                      value: Gender.male,
                      groupValue: gender,
                      onChanged: (Gender? value) {
                        setState(() {
                          gender = value!;
                        });

                        widget.setGender(gender);
                      },
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      gender = Gender.female;
                    });

                    widget.setGender(gender);
                  },
                  child: ListTile(
                    title: const Text('weiblich'),
                    leading: Radio(
                      value: Gender.female,
                      groupValue: gender,
                      onChanged: (Gender? value) {
                        setState(() {
                          gender = value!;
                        });

                        widget.setGender(gender);
                      },
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      gender = Gender.diverse;
                    });

                    widget.setGender(gender);
                  },
                  child: ListTile(
                    title: const Text('divers'),
                    leading: Radio(
                      value: Gender.diverse,
                      groupValue: gender,
                      onChanged: (Gender? value) {
                        setState(() {
                          gender = value!;
                        });

                        widget.setGender(gender);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }
}
