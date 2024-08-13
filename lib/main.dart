import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

void main() {
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Silent Scheduler',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Silent Scheduler'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification response here
      },
    );
  }

  void _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if (await Permission.accessNotificationPolicy.isDenied) {
      await Permission.accessNotificationPolicy.request();
    }
  }

  void _scheduleSilentMode() {
    final now = TimeOfDay.now();
    final startTime = tz.TZDateTime.now(tz.local).add(Duration(
        hours: _startTime.hour - now.hour, minutes: _startTime.minute - now.minute));
    final endTime = tz.TZDateTime.now(tz.local).add(Duration(
        hours: _endTime.hour - now.hour, minutes: _endTime.minute - now.minute));

    flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Silent Mode ON',
        'Your phone is now in silent mode',
        startTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'silent_mode_channel',
            'Silent Mode',
            channelDescription: 'Channel for Silent Mode notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);

    flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        'Silent Mode OFF',
        'Your phone is now back to normal mode',
        endTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'normal_mode_channel',
            'Normal Mode',
            channelDescription: 'Channel for Normal Mode notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Select Start Time:'),
            ElevatedButton(
              onPressed: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _startTime,
                );
                if (picked != null && picked != _startTime) {
                  setState(() {
                    _startTime = picked;
                  });
                }
              },
              child: Text(_startTime.format(context)),
            ),
            const Text('Select End Time:'),
            ElevatedButton(
              onPressed: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _endTime,
                );
                if (picked != null && picked != _endTime) {
                  setState(() {
                    _endTime = picked;
                  });
                }
              },
              child: Text(_endTime.format(context)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scheduleSilentMode,
              child: const Text('Schedule Silent Mode'),
            ),
          ],
        ),
      ),
    );
  }
}
