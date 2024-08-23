import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Prof extends StatefulWidget {
  const Prof({Key? key}) : super(key: key);

  @override
  State<Prof> createState() => _TaskState();
}

class _TaskState extends State<Prof> {
  List _taskData = [];
  String _backgroundImagePath = '';
  String _ansImageSource = '';
  final List<List<String>> _answers = [
    [
      'startDatetime',
      'answerDatetime',
      'task',
      'question',
      'answer',
      'rightAnswer'
    ]
  ];
  DateTime _startTime = DateTime.now();

  // int _currentTask = 0; // Счетчик заданий
  int _currentText = 5; // Для следующих тем
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
      _backgroundImagePath =
          _taskData[5]['questions'][_currentQuestion]['backgroundSource'];
      _ansImageSource = _taskData[_currentText]['questions'][_currentQuestion]
          ['ansImageSource'];
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await readTaskData();
      await playerText.play(AssetSource(_taskData[5]['taskSource']));

      playerText.onPlayerComplete.listen((event) {
        print('TEXT COMPLETED');
        setState(() {
          _backgroundImagePath =
              _taskData[5]['questions'][_currentQuestion]['imageSource'];
          playerQuestion.play(AssetSource(_taskData[_currentText]['questions']
              [_currentQuestion]['questionSource']));
        });
      });

      playerQuestion.onPlayerComplete.listen((event) {
        print('QUESTION COMPLETED');
        setState(() {
          _showVariants = true;
          _ansImageSource = _taskData[_currentText]['questions']
              [_currentQuestion]['ansImageSource'];
          _backgroundImagePath =
              _taskData[5]['questions'][_currentQuestion]['imageSource'];
          _startTime = DateTime.now();
        });
      });

      playerAnswer.onPlayerComplete.listen((event) async {
        print('ANSWER COMPLETED');
        setState(() {
          _showVariants = false;
          _currentQuestion++;
          _backgroundImagePath =
              _taskData[5]['questions'][_currentQuestion]['imageSource'];
          if (_currentQuestion == _taskData[_currentText]['questions'].length) {
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
            ['questions'][_currentQuestion]['questionSource']));
        await playerAnswer.setSource(AssetSource(_taskData[_currentText]
            ['questions'][_currentQuestion]['rightAnswerSource']));
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
    await playerQuestion.play(AssetSource(_taskData[_currentText]['questions']
        [_currentQuestion]['questionSource']));
  }

  void _checkAnswer(int answerIndex) {
    final answer = _taskData[_currentText]['questions'][_currentQuestion]
        ['answers'][answerIndex];
    final rightAnswer =
        _taskData[_currentText]['questions'][_currentQuestion]['rightAnswer'];
    final taskText = _taskData[_currentText]['taskText'];
    final questionText =
        _taskData[_currentText]['questions'][_currentQuestion]['questionText'];

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
        _ansImageSource = _taskData[_currentText]['questions'][_currentQuestion]
            ['ansImageSource'];
      });
      playerAnswer.play(AssetSource(_taskData[_currentText]['questions']
          [_currentQuestion]['rightAnswerSource']));
      Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_ansImageSource),
            fit: BoxFit.cover,
          ),
        ),
      );
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
      // appBar: AppBar(
      //   title: const Text('Рыбки'),
      //   backgroundColor: !_showVariants ? Colors.blue : _currentQuestion % 2 == 0 ? Colors.amber : Colors.indigo,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () {
      //       playerQuestion.stop();
      //       playerText.stop();
      //       playerAnswer.stop();
      //       Navigator.pop(context);
      //     },
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.volume_down),
      //       onPressed: () async {
      //         VolumeController().setVolume(await VolumeController().getVolume() + 0.1);
      //       },
      //     ),
      //     IconButton(
      //       icon: const Icon(Icons.volume_up),
      //       onPressed: () async {
      //         VolumeController().setVolume(await VolumeController().getVolume() - 0.1);
      //       },
      //     ),
      //   ],
      // ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(_backgroundImagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!_showVariants & !_completed)
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(_backgroundImagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              //   const SpinKitChasingDots(
              //     color: Colors.blue,
              //     size: 80.0,
              //   ),
              if (_showVariants) ...[
                Row(
                  children: [
                    const SizedBox(width: 840.0, height: 400),
                    OutlinedButton(
                      onPressed: () => _checkAnswer(0),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: (_highlightedAnswer == 0)
                              ? ((_right) ? Colors.green : Colors.red)
                              : Colors.black12,
                          width: (_highlightedAnswer == 0) ? 6 : 1,
                        ),
                        fixedSize: const Size(150, 150),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2.0, vertical: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _taskData[_currentText]['questions']
                                      [_currentQuestion]['answers'][0]
                                  .toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                              ),
                            ),
                            // const SizedBox(height: 10), //Отступ между текстом и картинкой
                            // Image.asset(
                            //   _taskData[_currentText]['questions'][_currentQuestion]['button_images'][0].toString(),
                            //   height: 50,
                            // ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 61.0),
                    OutlinedButton(
                      onPressed: () => _checkAnswer(1),
                      style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: (_highlightedAnswer == 1)
                                ? ((_right) ? Colors.green : Colors.red)
                                : Colors.black12,
                            width: (_highlightedAnswer == 1) ? 6 : 1,
                          ),
                          fixedSize: const Size(150, 150)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _taskData[_currentText]['questions']
                                      [_currentQuestion]['answers'][1]
                                  .toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                              ),
                            ),
                            // const SizedBox(height: 10), //Отступ между текстом и картинкой
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
                    SizedBox(height: 0), // Пространство шириной 10 пикселей
                  ],
                ), // Расстояние между строками
                const SizedBox(height: 0),
                Row(
                  children: [
                    const SizedBox(width: 840.0, height: 150),
                    OutlinedButton(
                      onPressed: () => _checkAnswer(2),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: (_highlightedAnswer == 2)
                              ? ((_right) ? Colors.green : Colors.red)
                              : Colors.black12,
                          width: (_highlightedAnswer == 2) ? 6 : 1,
                        ),
                        fixedSize: const Size(150, 150),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2.0, vertical: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _taskData[_currentText]['questions']
                                      [_currentQuestion]['answers'][2]
                                  .toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                              ),
                            ),
                            // const SizedBox(height: 10), //Отступ между текстом и картинкой
                            // Image.asset(
                            //   _taskData[_currentText]['questions'][_currentQuestion]['button_images'][0].toString(),
                            //   height: 50,
                            // ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 61.0),
                    OutlinedButton(
                      onPressed: () => _checkAnswer(3),
                      style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: (_highlightedAnswer == 3)
                                ? ((_right) ? Colors.green : Colors.red)
                                : Colors.black12,
                            width: (_highlightedAnswer == 3) ? 6 : 1,
                          ),
                          fixedSize: const Size(150, 150)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _taskData[_currentText]['questions']
                                      [_currentQuestion]['answers'][3]
                                  .toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                              ),
                            ),
                            // const SizedBox(height: 10), //Отступ между текстом и картинкой
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
