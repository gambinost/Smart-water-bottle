import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '/mqtt/mqtt_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  late MQTTClientWrapper mqttService;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Topics for MQTT
  final String topicReminder = 'flutter/reminder';
  final String topicReminderState = 'flutter/reminder_state';
  final String topicWaterReminder = 'esp/water_reminder';

  bool _isTimerActive = false;
  TimeOfDay? _selectedAlarmTime;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    mqttService = MQTTClientWrapper(
      host: '3a88e4f60f124dde87fa46d504b7e065.s1.eu.hivemq.cloud',
      port: 8883,
      topic: topicReminder,
    );
    _initializeMQTTClient();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/iconn'); // Use your app logo here

  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

  @override
  void dispose() {
    mqttService.disconnectMQTT();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMQTTClient() async {
    try {
      await mqttService.prepareMqttClient();
      mqttService.subscribeToTopic(topicWaterReminder, _handleWaterReminder);
      print('Subscribed to topic: $topicWaterReminder');
    } catch (e) {
      print('Failed to initialize MQTT client: $e');
    }
  }

  void _handleWaterReminder(String message, String topic) {
    if (message.toLowerCase() == 'yes') {
      _showReminderDialog('It\'s time to drink water!');
      _showReminderNotification('It\'s time to drink water!');
    }
  }

  Future<void> _showReminderNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'reminder_channel',
      'Reminder Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Water Reminder',
      message,
      platformChannelSpecifics,
      payload: 'water_reminder',
    );
  }

  void _publishMessage(String topic, String message) {
    mqttService.publishMessage(topic, message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Published: $message to $topic')),
    );
  }

  void _startTimer(int minutes, int seconds) {
    setState(() {
      _isTimerActive = true;

      String formattedTime =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      _publishMessage(topicReminder, formattedTime);
    });
  }

  void _stopTimer() {
    setState(() {
      _isTimerActive = false;
      _countdownTimer?.cancel();
      _publishMessage(topicReminderState, 'turned off');
    });
  }

  Future<void> _selectAlarmTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedAlarmTime ?? TimeOfDay.now(),
    );

    if (picked != null && picked != _selectedAlarmTime) {
      setState(() {
        _selectedAlarmTime = picked;
        _setAlarm();
      });
    }
  }

  void _setAlarm() {
    if (_selectedAlarmTime != null) {
      final now = DateTime.now();
      var selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedAlarmTime!.hour,
        _selectedAlarmTime!.minute,
      );

      // If the selected time is in the past (but not exactly the current time), schedule it for the next day
      if (selectedDateTime.isBefore(now)) {
        selectedDateTime = selectedDateTime.add(const Duration(days: 1));
      }

      final timeUntilAlarm = selectedDateTime.difference(now);

      _countdownTimer?.cancel(); // Cancel any existing timers

      // Debug log
      print('Alarm scheduled for: ${selectedDateTime.toLocal()}');

      // Set a new timer
      _countdownTimer = Timer(timeUntilAlarm, () {
        print('Alarm triggered at: ${DateTime.now().toLocal()}');
        _alarmTriggered();
      });
    }
  }

  void _alarmTriggered() {
    _showReminderNotification('It\'s time to drink water!');
    _showReminderDialog('It\'s time to drink water!');
  }

  void _showReminderDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reminder'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder'),
        backgroundColor: const Color(0xFF86B9D6),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 30,
          onPressed: () {
            Navigator.pushNamed(context, '/homepage');
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/spongepop.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF86B9D6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color.fromARGB(255, 59, 129, 170),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () {
                              if (_isTimerActive) {
                                _stopTimer();
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    int minutes = 0;
                                    int seconds = 0;
                                    return AlertDialog(
                                      title: const Text('Set reminder'),
                                      content: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  labelText: 'Minutes'),
                                              onChanged: (value) {
                                                minutes =
                                                    int.tryParse(value) ?? 0;
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: TextField(
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  labelText: 'Seconds'),
                                              onChanged: (value) {
                                                seconds =
                                                    int.tryParse(value) ?? 0;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _startTimer(minutes, seconds);
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Start'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            child: Text(_isTimerActive
                                ? 'Turn Off Reminder'
                                : 'Set Reminder'),
                          ),
                          const Divider(
                            height: 56.0,
                            color: Colors.black,
                            thickness: 2.0,
                          ),
                          const Text(
                            'Set Alarm Time',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          ListTile(
                            title: Text(
                              _selectedAlarmTime != null
                                  ? 'Alarm set for: ${_selectedAlarmTime!.format(context)}'
                                  : 'No alarm set',
                            ),
                            trailing: const Icon(Icons.access_alarm),
                            onTap: _selectAlarmTime,
                          ),
                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}