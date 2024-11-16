import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:problemm9/mqtt/mqtt_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final String broker = '3a88e4f60f124dde87fa46d504b7e065.s1.eu.hivemq.cloud';
  final int port = 8883;
  late MQTTClientWrapper mqttClient;

  List<FlSpot> heartbeatData = [];
  List<FlSpot> temperatureData = [];
  List<FlSpot> humidityData = [];

  double time = 0;

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

      mqttClient.subscribeToTopic('esp/heartbeat', _handleMessage);
      mqttClient.subscribeToTopic('esp/temperature', _handleMessage);
      mqttClient.subscribeToTopic('esp/humidity', _handleMessage);
    } catch (e) {
      print('Failed to initialize MQTT client: $e');
    }
  }

  void _handleMessage(String message, String topic) {
    setState(() {
      time += 1; // Simulate time increments for data points
      if (topic == 'esp/heartbeat') {
        double heartbeatValue = double.tryParse(message) ?? 0;
        heartbeatData.add(FlSpot(time, heartbeatValue));
      } else if (topic == 'esp/temperature') {
        double tempValue = double.tryParse(message) ?? 0;
        temperatureData.add(FlSpot(time, tempValue));
      } else if (topic == 'esp/humidity') {
        double humidityValue = double.tryParse(message) ?? 0;
        humidityData.add(FlSpot(time, humidityValue));
      }
    });
  }

  Widget _buildLineChart(List<FlSpot> spots, String title) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 200,
          width: 300,
          child: LineChart(
            LineChartData(
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 2,
                  color: Colors.blueAccent, // Updated to 'color'
                ),
              ],
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true), // Wrapped in AxisTitles
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true), // Wrapped in AxisTitles
                ),
              ),
              gridData: const FlGridData(show: true),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildLineChart(temperatureData, 'Temperature (°C)'),
          const SizedBox(height: 20),
          _buildLineChart(humidityData, 'Humidity (%)'),
          const SizedBox(height: 20),
          _buildLineChart(heartbeatData, 'Heartbeat (bpm)'),
        ],
      ),
    );
  }
}
