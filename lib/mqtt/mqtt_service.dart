import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTClientWrapper {
  late MqttServerClient
      client; // this is the instance that handle the mqtt communications
  Function(String, String)?
      onMessageReceived; // callback function that gets executed when a message is received
  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;
  final String host;
  final int port;
  final String? topic; // Optional if not needed in every context

  MQTTClientWrapper({
    required this.host,
    required this.port,
    this.topic, // Optional topic parameter
  });

  // prepares and connect the mqtt client . without it there is no connection
  Future<void> prepareMqttClient() async {
    _setupMqttClient();
    await _connectClient(); // using await because ofc we can't go through the remaining parts of the code without this part being finished first
  }

// connecting with the email and pass and throwing exceptions if there is something wrong with the credentials or the connection state in the if statements
  Future<void> _connectClient() async {
    try {
      print('Client connecting....');
      connectionState = MqttCurrentConnectionState
          .CONNECTING; //using the connection state  we declared above to insure the connection but this time it is .connecting not idle
      await client.connect('darkooo142@gmail.com', 'Moamen4172');
    } on Exception catch (e) {
      print('Client exception - $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.CONNECTED;
      print('Client connected');
    } else {
      print(
          'ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }
  }

// configuring the mqtt client before connecting
  void _setupMqttClient() {
    client = MqttServerClient.withPort(host, 'clientId', port);
    client.secure = true;
    client.securityContext = SecurityContext.defaultContext;
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
  }

// subscribing to a certain topic and printing when message is received
//the payload is the actual content or data of the message being sent or received, such as text or binary data.
// It is separate from the message metadata like the topic or QoS level.
  void subscribeToTopic(
      String topicName, Function(String, String) onMessageReceived) {
    print('Subscribing to the $topicName topic'); // Debug print
    client.subscribe(topicName, MqttQos.atMostOnce);

    // Listen for incoming messages and handle them based on the topic
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (var message in messages) {
        final MqttPublishMessage recMess =
            message.payload as MqttPublishMessage;
        final String receivedTopic = message.topic;
        final String receivedMessage =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        print('Received message: $receivedMessage from topic: $receivedTopic'); // Debug print

        // Only call the callback function if the received topic matches the topic we're subscribing to
        if (receivedTopic == topicName) {
          onMessageReceived(receivedMessage, receivedTopic);
        }
      }
    });
  }

//publishing the message to a certain topic
  void publishMessage(String topic, String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    print('Publishing message "$message" to topic $topic');
    client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;
  }

  void _onDisconnected() {
    print('OnDisconnected client callback - Client disconnection');
    connectionState = MqttCurrentConnectionState.DISCONNECTED;
  }

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    print('OnConnected client callback - Client connection was successful');
  }

  void disconnectMQTT() {
    try {
      client.disconnect();
    } catch (e) {
      print('Disconnection error: $e');
    }
  }
}

// the connection status we choose according to the function
enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING
}

enum MqttSubscriptionState {
  IDLE,
  SUBSCRIBED
} // subscription status we choose idle still setting it and subscribe is done
