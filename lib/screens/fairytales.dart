import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:volume_controller/volume_controller.dart';

class fairytales extends StatefulWidget {
  const fairytales({Key? key}) : super(key: key);

  @override
  State<fairytales> createState() => _TaskState();
}

class _TaskState extends State<fairytales> {
  List _taskData = [];
  String _backgroundImagePath = '';
  final List<List<String>> _answers = [
    [
      'startDatetime',
      'answerDatetime',
      'task',
      'story',
      'character',
      'FirstCharacter',
      'SecondCharacter',
      'ThirdCharacter',
      'FourthCharacter'
    ]
  ];
  DateTime _startTime = DateTime.now();

  // int _currentTask = 0; // Счетчик заданий
  int _currentText = 4; // Для следующих тем
  int _currentQuestion = 0; // Счетчик вопросов
  bool _showVariants = false;
  bool _completed = false;

  int? _highlightedAnswer;
  bool _right = false;

  final playerText = AudioPlayer();
  final playerQuestion = AudioPlayer();
  final playerAnswer = AudioPlayer();

  Future<void> readTaskData() async {
    final String response =
        await rootBundle.loadString('assets/data/quiz-Space.data.json');
    final data = await jsonDecode(response);

    setState(() {
      _taskData = data['data'];
      //_backgroundImagePath = _taskData[3]['backgroundSource'];
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await readTaskData();
      await playerText.play(AssetSource(_taskData[4]['taskSource']));

      playerText.onPlayerComplete.listen((event) {
        print('TEXT COMPLETED');
        setState(() {
          playerQuestion.play(AssetSource(_taskData[_currentText]['Stories']
              [_currentQuestion]['storySource']));
        });
      });

      playerQuestion.onPlayerComplete.listen((event) {
        print('QUESTION COMPLETED');
        setState(() {
          _showVariants = true;
          //_backgroundImagePath = _taskData[4]['backgroundSource'];
          _startTime = DateTime.now();
        });
      });

      playerAnswer.onPlayerComplete.listen((event) async {
        print('ANSWER COMPLETED');
        setState(() {
          _showVariants = false;
          _currentQuestion++;
          if (_currentQuestion == _taskData[_currentText]['Stories'].length) {
            _currentText++;
            _currentQuestion = 0;
            if (_currentText == _taskData.length) {
              _completed = true;
            }
          }
        });
        if (_completed) {
          String csv =
              const ListToCsvConverter(fieldDelimiter: ';').convert(_answers);
          var date = DateFormat('dd-MM-yyyy hh-mm-ss').format(DateTime.now());
          var path = '/storage/emulated/0/Download/$date-results.csv';
          var file = await File(path).create();
          await file.writeAsString(csv);
          return;
        }
        await playerQuestion.setSource(AssetSource(_taskData[_currentText]
            ['Stories'][_currentQuestion]['storySource']));
        await playerAnswer.setSource(AssetSource(_taskData[_currentText]
            ['Stories'][_currentQuestion]['rightAnswerSource']));
        await playerText
            .setSource(AssetSource(_taskData[_currentText]['taskSource']));

        if (_currentQuestion != 0) {
          await playerQuestion.resume();
        } else {
          playerText.resume();
        }
      });
    });
  }

  void _repeatQuestion() async {
    setState(() {
      _showVariants = false;
      _right = false;
      _highlightedAnswer = null;
    });
    await playerQuestion.play(AssetSource(_taskData[_currentText]['Stories']
        [_currentQuestion]['questionSource']));
  }

  void _checkAnswer(int answerIndex) {
    final answer = _taskData[_currentText]['Stories'][_currentQuestion]
        ['answers'][answerIndex];
    final rightAnswer =
        _taskData[_currentText]['Stories'][_currentQuestion]['rightAnswer'];
    final taskText = _taskData[_currentText]['taskText'];
    final questionText =
        _taskData[_currentText]['Stories'][_currentQuestion]['questionText'];

    setState(() {
      _highlightedAnswer = answerIndex;
      _answers.add([
        _startTime.toString(),
        DateTime.now().toString(),
        taskText,
        questionText,
        answer.toString(),
        rightAnswer.toString()
      ]);
    });
    if (answer == rightAnswer) {
      setState(() {
        _right = true;
      });
      playerAnswer.play(AssetSource(_taskData[_currentText]['Stories']
          [_currentQuestion]['rightAnswerSource']));
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _highlightedAnswer = null;
        });
      });
    } else {
      setState(() {
        _right = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Путешествие в мир сказок'),
        backgroundColor: !_showVariants
            ? Colors.blue
            : _currentQuestion % 2 == 0
                ? Colors.amber
                : Colors.indigo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            playerQuestion.stop();
            playerText.stop();
            playerAnswer.stop();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_down),
            onPressed: () async {
              VolumeController()
                  .setVolume(await VolumeController().getVolume() + 0.1);
            },
          ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () async {
              VolumeController()
                  .setVolume(await VolumeController().getVolume() - 0.1);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: _showVariants
              ? BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_backgroundImagePath),
                    fit: BoxFit.cover,
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!_showVariants & !_completed)
                const SpinKitChasingDots(
                  color: Colors.blue,
                  size: 80.0,
                ),
              if (_showVariants) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => _checkAnswer(0),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.blue,
                        side: BorderSide(
                          color: (_highlightedAnswer == 0)
                              ? ((_right) ? Colors.green : Colors.red)
                              : Colors.black12,
                          width: (_highlightedAnswer == 0) ? 6 : 1,
                        ),
                        fixedSize: const Size(300, 180),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 36.0, vertical: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _taskData[_currentText]['Stories']
                                      [_currentQuestion]['answers'][0]
                                  .toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26.0,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            //Отступ между текстом и картинкой
                            // Image.asset(
                            //   _taskData[_currentText]['questions'][_currentQuestion]['button_images'][0].toString(),
                            //   height: 50,
                            // ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24.0),
                    OutlinedButton(
                      onPressed: () => _checkAnswer(1),
                      style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.deepPurple,
                          side: BorderSide(
                            color: (_highlightedAnswer == 1)
                                ? ((_right) ? Colors.green : Colors.red)
                                : Colors.black12,
                            width: (_highlightedAnswer == 1) ? 6 : 1,
                          ),
                          fixedSize: const Size(300, 180)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 36.0, vertical: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _taskData[_currentText]['Stories']
                                      [_currentQuestion]['answers'][1]
                                  .toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26.0,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            //Отступ между текстом и картинкой
                            // Image.asset(
                            //   _taskData[_currentText]['questions'][_currentQuestion]['button_images'][1].toString(),
                            //   height: 50,
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ), //Верхний ряд с двумя кнопками
                const Row(
                  children: <Widget>[
                    SizedBox(height: 32), // Пространство шириной 10 пикселей
                  ],
                ), // Расстояние между строками
                const SizedBox(height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  OutlinedButton(
                    onPressed: () => _checkAnswer(2),
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.orange,
                        side: BorderSide(
                          color: (_highlightedAnswer == 2)
                              ? ((_right) ? Colors.green : Colors.red)
                              : Colors.black12,
                          width: (_highlightedAnswer == 2) ? 6 : 1,
                        ),
                        fixedSize: const Size(300, 180)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36.0, vertical: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _taskData[_currentText]['questions']
                                    [_currentQuestion]['answers'][2]
                                .toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26.0,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          //Отступ между текстом и картинкой
                          Image.asset(
                            _taskData[_currentText]['questions']
                                    [_currentQuestion]['button_images'][2]
                                .toString(),
                            height: 50,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24.0),
                  OutlinedButton(
                    onPressed: () => _checkAnswer(3),
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.pinkAccent,
                        side: BorderSide(
                          color: (_highlightedAnswer == 3)
                              ? ((_right) ? Colors.green : Colors.red)
                              : Colors.black12,
                          width: (_highlightedAnswer == 3) ? 6 : 1,
                        ),
                        fixedSize: const Size(300, 180)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36.0, vertical: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _taskData[_currentText]['questions']
                                    [_currentQuestion]['answers'][3]
                                .toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26.0,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          //Отступ между текстом и картинкой
                          Image.asset(
                            _taskData[_currentText]['questions']
                                    [_currentQuestion]['button_images'][3]
                                .toString(),
                            height: 50,
                          ),
                        ],
                      ),
                    ),
                  ),
                ]), //Верхний ряд с двумя кнопками

                ElevatedButton(
                  onPressed: _repeatQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentQuestion % 2 == 0
                        ? Colors.amber
                        : Colors.indigo,
                  ),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 36.0, vertical: 12.0),
                    child: Text(
                      'Послушать еще раз',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
              if (_completed) ...[
                const Center(
                    child: Text(
                  'Поздравляем, вы справились! Позовте воспитателя',
                  style: TextStyle(fontSize: 22),
                )),
                const SizedBox(height: 24.0),
                Center(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 36.0, vertical: 12.0),
                      child: Text(
                        'Закончить',
                        style: TextStyle(fontSize: 26.0),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
