import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database
import 'package:fl_chart/fl_chart.dart'; // Import FL Chart
import 'package:intl/intl.dart'; // Import for date formatting in tooltips

// Data model for the chart
class WeightData {
  final DateTime time;
  final double weight;

  WeightData(this.time, this.weight);
}

class ContainerScreen extends StatefulWidget {
  final String containerName;

  const ContainerScreen({super.key, required this.containerName});

  @override
  State<ContainerScreen> createState() => _ContainerScreenState();
}

class _ContainerScreenState extends State<ContainerScreen> {
  // Reference to your Firebase Realtime Database instance.
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  double _currentWeight = 0.0;
  List<WeightData> _weightHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToWeightData();
  }

  void _listenToWeightData() {
    // Listen for currentWeight changes.
    // Based on the screenshot, currentWeight is directly under the root.
    _databaseRef.child('currentWeight').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        setState(() {
          _currentWeight = (data as num).toDouble();
        });
      }
    }, onError: (error) {
      print("Failed to load current weight: $error");
    });

    // Listen for weightHistory changes.
    // Based on the screenshot, weightHistory is directly under the root.
    _databaseRef.child('weightHistory').onValue.listen((event) {
      final data = event.snapshot.value;
      List<WeightData> loadedHistory = [];
      if (data != null && data is Map) {
        data.forEach((key, value) {
          try {
            // Timestamp format: YYYY-MM-DD_HH-MM-SS
            List<String> dateTimeParts = key.split('_');
            List<String> dateParts = dateTimeParts[0].split('-');
            List<String> timeParts = dateTimeParts[1].split('-');

            DateTime timestamp = DateTime(
              int.parse(dateParts[0]), // Year
              int.parse(dateParts[1]), // Month
              int.parse(dateParts[2]), // Day
              int.parse(timeParts[0]), // Hour
              int.parse(timeParts[1]), // Minute
              int.parse(timeParts[2]), // Second
            );
            loadedHistory.add(WeightData(timestamp, (value as num).toDouble()));
          } catch (e) {
            print('Error parsing timestamp $key: $e');
          }
        });

        // Sort the history by time to ensure the chart draws correctly
        loadedHistory.sort((a, b) => a.time.compareTo(b.time));
      }

      setState(() {
        _weightHistory = loadedHistory;
        _isLoading = false;
      });
    }, onError: (error) {
      print("Failed to load weight history: $error");
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine min/max Y values for the bar chart
    // For bar charts, minY is typically 0.
    double minY = 0;
    double maxY = _weightHistory.isNotEmpty
        ? _weightHistory.map((data) => data.weight).reduce((a, b) => a > b ? a : b) * 1.1
        : 100; // Add 10% buffer to max or default to 100

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.containerName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Current Usage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Jar cup current weight amount',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_currentWeight.toStringAsFixed(2)}kg', // Display live weight
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Produce sales',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '% Producer Sales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Live chart integration
                    AspectRatio(
                      aspectRatio: 1.5, // Adjust as needed
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _weightHistory.isEmpty
                              ? const Center(child: Text('No weight history available.'))
                              : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: maxY, // Set maximum Y value
                                      minY: minY, // Set minimum Y value to 0 for bar charts
                                      gridData: const FlGridData(
                                          show: true, drawVerticalLine: false),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border.all(
                                            color: const Color(0xff37434d)),
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false)),
                                        topTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false)),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                              // Use the index for titles, then map back to DateTime
                                              if (value.toInt() < 0 || value.toInt() >= _weightHistory.length) {
                                                return SideTitleWidget(axisSide: meta.axisSide, child: const Text(''));
                                              }
                                              final dateTime = _weightHistory[value.toInt()].time;
                                              return SideTitleWidget(
                                                axisSide: meta.axisSide,
                                                space: 8.0,
                                                child: Text(
                                                  DateFormat('HH:mm').format(dateTime),
                                                  style: const TextStyle(fontSize: 10),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                value.toStringAsFixed(1),
                                                style: const TextStyle(fontSize: 10),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      barGroups: _weightHistory.asMap().entries.map((entry) {
                                        int index = entry.key;
                                        WeightData data = entry.value;
                                        return BarChartGroupData(
                                          x: index, // Use index for X value in BarChart
                                          barRods: [
                                            BarChartRodData(
                                              toY: data.weight,
                                              color: Colors.blue,
                                              width: 15, // Adjust bar width as needed
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                      barTouchData: BarTouchData(
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                            final dateTime = _weightHistory[group.x].time;
                                            return BarTooltipItem(
                                              '${DateFormat('HH:mm').format(dateTime)}\n${rod.toY.toStringAsFixed(2)} kg',
                                              const TextStyle(color: Colors.white),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Your existing bottom navigation bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
              color: Colors.grey,
            ),
            IconButton(
              icon: const Icon(Icons.person, size: 30),
              onPressed: () {},
              color: Colors.grey,
            ),
            IconButton(
              icon: const Icon(Icons.history, size: 30),
              onPressed: () {},
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}