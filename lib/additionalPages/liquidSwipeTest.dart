import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class LiquidSwipeTest extends StatefulWidget {
  final Function(bool) onButtonPressed;

  const LiquidSwipeTest({super.key, required this.onButtonPressed});

  @override
  State<LiquidSwipeTest> createState() => _LiquidSwipeTestState();
}

class _LiquidSwipeTestState extends State<LiquidSwipeTest> {
  int index = 0;

  late LiquidController liquidController;

  double iconPosition = 0.6; // Standardposition des Icons

  final pages = [
    SizedBox.expand(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: screenWidth,
                  child: Center(
                    child: Container(
                      height: 160,
                      width: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                const Text(
                  'Echte',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  'Freundschaften',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Expanded(
                  child: SizedBox(
                    width: screenWidth * 0.6,
                    child: const Text(
                      'In DreamUp findest du echte Freundschaften und Aktionen. Hier findest du, was du dir schon immer gewünscht hast.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
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
    SizedBox.expand(
      child: Container(
        color: Colors.deepPurple,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: screenWidth,
                  child: Center(
                    child: Container(
                      height: 160,
                      width: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                const Text(
                  'Erstelle',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  'deinen DreamUp',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Expanded(
                  child: SizedBox(
                    width: screenWidth * 0.6,
                    child: const Text(
                      'Worauf hattest du schon immer mal Lust? Weleche Dinge würdest du dir in deiner Freundschaft wünschen? Erstelle einen DreamUp und sprich über deinen Wunsch.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
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
    SizedBox.expand(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: screenWidth,
                  child: Center(
                    child: Container(
                      height: 160,
                      width: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                const Text(
                  'Du brauchst',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  'Kein Foto von dir',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Expanded(
                  child: SizedBox(
                    width: screenWidth * 0.6,
                    child: const Text(
                      'In DreamUp geht es nicht um Aussehen, sondern nur um deinen persönlichen Wunsch. Lade stattdessen ein BIld hoch, welches dein Hobby oder deinen Wunsch untermalt.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
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
    SizedBox.expand(
      child: Container(
        color: Colors.deepPurple,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: screenWidth,
                  child: Center(
                    child: Container(
                      height: 160,
                      width: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                const Text(
                  'Erhalte Messages von',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  'Gleichgesinnten',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Expanded(
                  child: SizedBox(
                    width: screenWidth * 0.6,
                    child: const Text(
                      'In DreamUp gibt es weder Ablehnung, noch Bewertungen. Sieh dir einfach die DreamUps der anderen an und gefällt dir eine Vorstellung, kannst du der anderen Person schreiben.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
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
    SizedBox.expand(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: screenWidth,
                  child: Center(
                    child: Container(
                      height: 160,
                      width: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                const Text(
                  'Bleib anonym',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  'Du entscheidest',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Expanded(
                  child: SizedBox(
                    width: screenWidth * 0.6,
                    child: const Text(
                      'Niemand weiß, wer du bist. Du entscheidest, wem du wann, welche Informationen preisgibst.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
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
  ];

  double xValue = 0;
  double yValue = 60;

  Future<void> saveSawExplanation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sawExplanation', true);
  }

  @override
  void initState() {
    liquidController = LiquidController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: LiquidSwipe(
              liquidController: liquidController,
              pages: pages,
              positionSlideIcon: iconPosition,
              slideIconWidget: const SizedBox(
                height: 40,
                width: 40,
              ),
              slidePercentCallback: (x, y) {
                if (x != 0) {
                  xValue = x;

                  setState(() {});
                }
              },
              waveType: WaveType.liquidReveal,
              onPageChangeCallback: (value) {
                index = value;

                xValue = 0;

                setState(() {});
              },
              fullTransitionValue: 1000,
              enableSideReveal: true,
              enableLoop: false,
            ),
          ),
          Positioned(
            bottom: 50,
            child: Visibility(
              visible: index == 4,
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    widget.onButtonPressed(true);

                    await saveSawExplanation();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Center(
                      child: Text(
                        "Los geht's",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: MediaQuery.of(context).size.height * 0.6 - 20,
            child: Visibility(
              visible: index != 4,
              child: IgnorePointer(
                ignoring: true,
                child: Opacity(
                  opacity: xValue > 0 ? 0 : 1,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
