import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:eduapp/screens/wait_task_screen.dart';

import 'models/child.model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // make app fullscreen
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // lock landscape mode
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft]);

  // start kiosk mode
  //await startKioskMode();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Смарт Той',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WaitForTheTask(child: Child(id: '1', groupId: '1', name: 'Имя', secondName: 'Фамилия', teacherName: 'Мария Ивановна')),
    );
  }
}