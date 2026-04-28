import 'package:flutter/material.dart';

class UserSensorsScreen extends StatefulWidget {
  const UserSensorsScreen({super.key});

  @override
  State<UserSensorsScreen> createState() => _UserSensorsScreenState();
}

class _UserSensorsScreenState extends State<UserSensorsScreen> {
  // Local, fixed sensor data (no fetching)
  Map<String, dynamic> m = {
    'sensorId': 12345667,
    'type': 'soil',
    'humidity': 55,
    'isUsed': true,
    'relay_state': false,
    'soil_moisture': 48,
    'temperature': 24.6,
    'water_level': 67,
    'AI_DETECT': 72,
  }; // Simple local state; no streams or network [web:98][web:96]

  // Helpers
  double numToDouble(dynamic v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  } // Conversion helpers for resilience [web:99][web:101]

  bool toBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is num) return v != 0;
    return fallback;
  } // Conversion helpers for resilience [web:99][web:101]

  // Colors
  Color _humidityColor(double v) {
    if (v < 30) return Colors.orange;
    if (v > 70) return Colors.blue;
    return Colors.green;
  } // Simple UI mapping [web:95][web:55]

  Color _moistureColor(double v) {
    if (v < 30) return Colors.red;
    if (v < 60) return Colors.orange;
    return Colors.green;
  } // Simple UI mapping [web:95][web:55]

  Color _temperatureColor(double v) {
    if (v < 10) return Colors.blue;
    if (v > 30) return Colors.red;
    return Colors.orange;
  } // Simple UI mapping [web:95][web:55]

  Color _waterLevelColor(double v) {
    if (v < 20) return Colors.red;
    if (v < 50) return Colors.orange;
    return Colors.green;
  } // Simple UI mapping [web:95][web:55]

  Color aiColor(double v) {
    if (v < 34) return Colors.red;
    if (v < 67) return Colors.orange;
    return Colors.green;
  } // Simple UI mapping [web:95][web:55]

  String aiLabel(double v) {
    if (v < 34) return 'Needs water';
    if (v < 67) return 'Borderline';
    return 'OK';
  } // Friendly label [web:95][web:55]

  void toggleRelay() {
    setState(() {
      m['relay_state'] = !toBool(m['relay_state']);
    }); // Local update via setState (no streams) [web:98][web:101]
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness ==
        Brightness.dark; // Theming awareness [web:98][web:106]

    // Read current values
    final humidity = numToDouble(m['humidity']);
    final isUsed = toBool(m['isUsed']);
    final relayOn = toBool(m['relay_state']);
    final soil = numToDouble(m['soil_moisture']);
    final temp = numToDouble(m['temperature']);
    final water = numToDouble(m['water_level']);
    final sensorId = (m['sensorId']).toString();
    final type = (m['type'] ?? 'soil').toString();
    final aiDetect =
        numToDouble(m['AI_DETECT']); // Direct local reads [web:98][web:96]

    final surface = isDark
        ? Colors.grey[900]!
        : Colors.white; // Surface colors [web:98][web:106]
    final divider = isDark
        ? Colors.grey[800]!
        : Colors.grey[200]!; // Divider colors [web:98][web:106]

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Details'),
        centerTitle: true,
      ), // Simple top app bar [web:98][web:106]
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                color: surface,
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isDark
                                  ? Colors.blue[900]
                                  : Colors.blue[50])!,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.sensors,
                                color: Colors.blueAccent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Sensor $sensorId",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.grey[200]
                                        : Colors.blueGrey[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.blueGrey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  isUsed ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isUsed
                                      ? Colors.green[300]!
                                      : Colors.red[300]!),
                            ),
                            child: Text(
                              isUsed ? 'active' : 'inactive',
                              style: TextStyle(
                                color: isUsed
                                    ? Colors.green[900]
                                    : Colors.red[900],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ), // Overflow-safe header [web:111][web:113]

                      const SizedBox(height: 16),
                      Divider(height: 1, color: divider),
                      const SizedBox(height: 12),

                      // Metrics grid-like list
                      _buildDataRow(
                        context,
                        icon: Icons.opacity,
                        label: 'Humidity',
                        value: '${humidity.toStringAsFixed(0)}%',
                        color: _humidityColor(humidity),
                      ), // Row uses constraints and ellipsis [web:111][web:113]
                      _buildDataRow(
                        context,
                        icon: relayOn ? Icons.power : Icons.power_off,
                        label: 'Relay State',
                        value: relayOn ? 'ON' : 'OFF',
                        color: relayOn ? Colors.green : Colors.red,
                      ), // Controlled chip width [web:111][web:113]
                      _buildDataRow(
                        context,
                        icon: Icons.grass,
                        label: 'Soil Moisture',
                        value: '${soil.toStringAsFixed(0)}%',
                        color: _moistureColor(soil),
                      ), // Prevents right overflow [web:111][web:119]
                      _buildDataRow(
                        context,
                        icon: Icons.thermostat,
                        label: 'Temperature',
                        value: '${temp.toStringAsFixed(1)}°C',
                        color: _temperatureColor(temp),
                      ), // Text ellipsis for small devices [web:112][web:113]
                      _buildDataRow(
                        context,
                        icon: Icons.water_drop,
                        label: 'Water Level',
                        value: '${water.toStringAsFixed(0)}%',
                        color: _waterLevelColor(water),
                      ), // Uses Expanded for label [web:111][web:113]

                      const SizedBox(height: 10),
                      Divider(height: 1, color: divider),
                      const SizedBox(height: 12),

                      _buildDataRow(
                        context,
                        icon: Icons.insights,
                        label: 'AI Detect',
                        value:
                            '${aiDetect.toStringAsFixed(0)} • ${aiLabel(aiDetect)}',
                        color: aiColor(aiDetect),
                      ), // AI row with ellipsis [web:111][web:113]

                      const SizedBox(height: 16),

                      // AI badge
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: aiColor(aiDetect).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: aiColor(aiDetect).withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: aiColor(aiDetect), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'AI Prediction',
                                style: TextStyle(
                                  color: aiColor(aiDetect),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ), // Visual status badge [web:95][web:55]

                      const SizedBox(height: 20),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                relayOn ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          icon: Icon(relayOn ? Icons.power_off : Icons.power),
                          label: Text(
                              relayOn ? 'Turn OFF Relay' : 'Turn ON Relay'),
                          onPressed: toggleRelay,
                        ),
                      ), // Local state toggle via setState [web:98][web:101],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // Constrain value chip width to avoid pushing out of screen
    final maxChipWidth = MediaQuery.of(context).size.width *
        0.40; // responsive cap [web:111][web:115]
    final clampedChipWidth =
        maxChipWidth.clamp(120.0, 180.0); // guard rails [web:111][web:115]

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          // Label expands and can ellipsize to avoid overflow
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ), // Expanded prevents pushing beyond width [web:111][web:113]
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: clampedChipWidth.toDouble()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(
                value,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: color),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ), // Chip constrained to avoid right overflow [web:111][web:119]
        ],
      ),
    );
  }
}
