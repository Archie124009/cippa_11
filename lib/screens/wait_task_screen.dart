import 'package:eduapp/screens/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:eduapp/models/child.model.dart';
import 'package:eduapp/screens/prof.dart';
import 'package:eduapp/screens/RussianLanguage.dart';

import 'fish.dart';
import 'fairytales.dart';

class WaitForTheTask extends StatefulWidget {
  const WaitForTheTask({Key? key, required this.child}) : super(key: key);

  final Child child;

  @override
  State<WaitForTheTask> createState() => _WaitForTheTaskState();
}

int _taskNum = 0;

class _WaitForTheTaskState extends State<WaitForTheTask> {
  final List<Map<String, dynamic>> activities = [
    {
      'title': 'Космос',
      'description': 'Узнай о космосе и космических объектах.',
      'taskNum': 0,
    },
    {
      'title': 'Слова',
      'description': 'Узнай о словах, связанных с водой.',
      'taskNum': 1,
    },
    {
      'title': 'Рыбки',
      'description': 'Давайте посчитаем рыбок.',
      'taskNum': 2,
    },
    {
      'title': 'Путешествие в мир сказок',
      'description': 'Давайте отправимся в мир сказок.',
      'taskNum': 3,
    },
    {
      'title': 'Профориентация',
      'description': 'Давайте изучим разные профессии.',
      'taskNum': 4,
    },
    {
      'title': 'Волшебный микрофон',
      'description': 'Давайте составим рассказ о животных.',
      'taskNum': 5,
    },
  ];

  void startTask(int taskNum) {
    if (taskNum == 0) {
      _taskNum = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Task()),
      );
    } else if (taskNum == 1) {
      _taskNum = 1;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Russianlanguage()),
      );
    } else if (taskNum == 2) {
      _taskNum = 2;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const fish()),
      );
    } else if (taskNum == 3) {
      _taskNum = 3;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const fairytales()),
      );
    } else if (taskNum == 4) {
      _taskNum = 4;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Prof()),
      );
    } else if (taskNum == 5) {
      _taskNum = 5;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const fairytales()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/backgrounds/app.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 160.0), // Добавляет отступ сверху
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(2, (rowIndex) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        // Отступ между рядами кнопок
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (colIndex) {
                            int taskIndex = rowIndex * 3 + colIndex;
                            if (taskIndex >= activities.length)
                              return Container();
                            final activity = activities[taskIndex];

                            return Padding(
                              padding: const EdgeInsets.all(15.0),
                              // Отступ между кнопками в ряду
                              child: OutlinedButton(
                                onPressed: () => startTask(activity['taskNum']),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.black12,
                                    width: 6,
                                  ),
                                  fixedSize: const Size(275, 195),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 12.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        activity['title'],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 20.0,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
