import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/mqtt/mqtt_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String broker = '3a88e4f60f124dde87fa46d504b7e065.s1.eu.hivemq.cloud';
  final int port = 8883;

  late MQTTClientWrapper mqttClient;
  String heartbeat = '0';
  String temperature = '0';
  String humidity = '0';

  bool isMixerOn = false;

  @override
  void initState() {
    super.initState();
    mqttClient = MQTTClientWrapper(
      host: broker,
      port: port,
    );
    _initializeMQTTClient();
  }

  Future<void> _initializeMQTTClient() async {
    try {
      await mqttClient.prepareMqttClient();
// the subscriptions made in this screen and the actions needed when recieved
      mqttClient.subscribeToTopic('esp/heartbeat', _handleMessage);
      mqttClient.subscribeToTopic('esp/temperature', _handleMessage);
      mqttClient.subscribeToTopic('esp/humidity', _handleMessage);

      mqttClient.subscribeToTopic('esp/heartbeat/alert', _handleAlertMessage);
      mqttClient.subscribeToTopic('esp/temperature/alert', _handleAlertMessage);
      mqttClient.subscribeToTopic('esp/humidity/alert', _handleAlertMessage);
    } catch (e) {
      print('Failed to initialize MQTT client: $e');
    }
  }

// i had a problem showing readings for each topic separately so this function helps in
  // knowing the topic and sending the message accordingly
  void _handleMessage(String message, String topic) {
    setState(() {
      if (topic == 'esp/heartbeat') {
        heartbeat = message;
      } else if (topic == 'esp/temperature') {
        temperature = message;
      } else if (topic == 'esp/humidity') {
        humidity = message;
      }
    });
  }

// handling each alert differently based on the topic subscribed
  void _handleAlertMessage(String message, String topic) {
    if (topic == 'esp/heartbeat/alert') {
      _showAlertDialog(
          'Heartbeat Alert: Your heart beats are raising. It is better for you to take a break.');
    } else if (topic == 'esp/temperature/alert') {
      _showAlertDialog(
          'Temperature Alert: The temperature is rising. It is better to drink some water.');
    } else if (topic == 'esp/humidity/alert') {
      _showAlertDialog('Humidity Alert');
    }
  }

  void _showAlertDialog(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          backgroundColor: Colors.white,
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

// disconnect when we go out of the screen
  @override
  void dispose() {
    mqttClient.disconnectMQTT();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
        centerTitle: true,
      ),
      // used for the navigation drawer (like the sidebar)
      drawer: Drawer(
        child: Container(
          color: Colors.blueGrey[800],
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blueGrey[900],
                ),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              ListTile(
                // showing the user information via FIREBASE
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text('Show User Info',
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context); // Close the drawer
                  User? user = FirebaseAuth.instance.currentUser;
                  DocumentSnapshot userInfo = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .get();
                  Map<String, dynamic> data =
                      userInfo.data() as Map<String, dynamic>;
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("User Information"),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: [
                              Text("Email: ${data['email']}"),
                              Text("National ID: ${data['national ID']}"),
                              Text("Age: ${data['age']}"),
                              Text("Gender: ${data['gender']}"),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Exit"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ListTile(
                // loging out of the account so you have to login again
                leading: const Icon(Icons.remove_circle_outline, color: Colors.white),
                title: const Text('Logout', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pushNamed(context, '/login');
                },
              ),
              ListTile(
                // deleting the account from FIRESTORE and returning to the login page
                leading: const Icon(Icons.delete_forever, color: Colors.white),
                title: const Text('Delete Account',
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  User? user = FirebaseAuth.instance.currentUser;
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .delete();
                    await user?.delete();
                    print("User deleted successfully");
                  } catch (e) {
                    print("Failed to delete user: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("user deleted successfully"),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }

                  Navigator.pushNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/spongepop.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: ListView(
              // Replaced Column with ListView
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSensorCard('BPM', heartbeat),
                          const SizedBox(width: 5),
                          _buildSensorCard('Temperature', temperature),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSensorCard('Humidity', humidity),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Mixer',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white)),
                          Switch(
                            value: isMixerOn,
                            onChanged: (bool value) {
                              setState(() {
                                isMixerOn = value;
                                if (isMixerOn) {
                                  _publishMixerMessage();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/reminder');
                        },
                        child: const Text('Go to Reminders'),
                      ), 
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.arrow_back),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(String label, String value) {
    // the widget of our cards for setting the shape and design we will be using
    return Card(
      color: Colors.black54,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

// publishing the mixer and turning it on
  void _publishMixerMessage() {
    mqttClient.publishMessage('flutter/mixer', 'ON');
  }
}
