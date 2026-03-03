
import 'package:fitnora/animations.dart';
import 'package:fitnora/pages/profile/add_measurement.dart';
import 'package:fitnora/pages/profile/settings.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _latest;
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _nutritionHistory = [];
  String _selectedNutritionMetric = 'Calories'; // Calories | Protein | Carbs
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Public method so the parent can trigger a reload (e.g. on tab switch).
  void reload() {
    _loadData();
  }

  Future<void> _loadData() async {
    final latest = await WorkoutDatabaseService.instance.getLatestMeasurement();
    final history = await WorkoutDatabaseService.instance.getMeasurements();
    final sessions = await WorkoutDatabaseService.instance.getSessionHistory();
    final nutritionHistory = await WorkoutDatabaseService.instance.getNutritionHistory();
    if (!mounted) return;
    setState(() {
      _latest = latest;
      _history = history;
      _sessions = sessions;
      _nutritionHistory = nutritionHistory;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context, AppRoutes.slideFromRight(SettingsPage()));
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= LATEST MEASUREMENT CARD =================
                  _buildLatestCard(),

                  const SizedBox(height: 24),

                  // ================= MEASUREMENT HISTORY =================
                  _buildSectionHeader("Measurement History"),
                  const SizedBox(height: 12),

                  if (_history.isEmpty)
                    _buildEmptyState("No measurements recorded yet")
                  else
                    ..._history.map((m) => _buildHistoryTile(m)),

                  const SizedBox(height: 24),

                  // ================= PROGRESS GRAPHS =================
                  _buildSectionHeader("Progress"),
                  const SizedBox(height: 12),

                  // Graph 1: Body Weight + Body Fat
                  if (_history.isNotEmpty) ...[
                    _buildBodyGraph(),
                    const SizedBox(height: 16),
                  ],

                  // Graph 2: Volume / Sets
                  if (_sessions.isNotEmpty) ...[
                    _buildVolumeGraph(),
                    const SizedBox(height: 16),
                  ],

                  // Graph 3: Nutrition (Calories, Protein, Carbs)
                  if (_nutritionHistory.isNotEmpty) ...[
                    _buildNutritionGraph(),
                    const SizedBox(height: 16),
                  ],

                  if (_history.isEmpty && _sessions.isEmpty && _nutritionHistory.isEmpty)
                    _buildEmptyState("No data for graphs yet"),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ================= SHARED WIDGETS =================

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  // ================= LATEST CARD =================

  Widget _buildLatestCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Body Measurements",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: _addMeasurement,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.blueAccent, size: 20),
                ),
              ),
            ],
          ),
          if (_latest == null) ...[
            const SizedBox(height: 16),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.monitor_weight_outlined, size: 42, color: Colors.white24),
                  SizedBox(height: 8),
                  Text(
                    "Tap + to record your first measurement",
                    style: TextStyle(color: Colors.white30, fontSize: 13),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem("Weight", "${_latest!['weight'] ?? '-'}", "kg"),
                _buildStatItem("Height", "${_latest!['height'] ?? '-'}", "cm"),
                _buildStatItem(
                    "Body Fat", "${_latest!['body_fat'] ?? '-'}", "%"),
              ],
            ),
            if (_latest!['chest'] != null ||
                _latest!['waist'] != null ||
                _latest!['hips'] != null) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatItem(
                      "Chest", "${_latest!['chest'] ?? '-'}", "cm"),
                  _buildStatItem(
                      "Waist", "${_latest!['waist'] ?? '-'}", "cm"),
                  _buildStatItem(
                      "Hips", "${_latest!['hips'] ?? '-'}", "cm"),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value == "null" ? "-" : value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "$label ($unit)",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================= HISTORY TILE =================

  Widget _buildHistoryTile(Map<String, dynamic> m) {
    final dt = DateTime.fromMillisecondsSinceEpoch(m['measured_at'] as int);
    final dateStr =
        "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";

    return Dismissible(
      key: ValueKey('meas_${m['measurement_id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await WorkoutDatabaseService.instance
            .deleteMeasurement(m['measurement_id'] as int);
        _loadData();
      },
      child: GestureDetector(
        onTap: () => _editMeasurement(m['measurement_id'] as int),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${m['weight'] ?? '-'} kg",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildSubtitle(m),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle(Map<String, dynamic> m) {
    final parts = <String>[];
    if (m['height'] != null) parts.add("${m['height']}cm");
    if (m['body_fat'] != null) parts.add("${m['body_fat']}% BF");
    if (m['chest'] != null) parts.add("Chest ${m['chest']}");
    if (m['waist'] != null) parts.add("Waist ${m['waist']}");
    return parts.isEmpty ? "Weight only" : parts.join(" · ");
  }

  // ================= GRAPH 1: Body Weight + Body Fat =================

  Widget _buildBodyGraph() {
    final sortedHistory = List<Map<String, dynamic>>.from(_history)
      ..sort((a, b) => (a['measured_at'] as int).compareTo(b['measured_at'] as int));

    if (sortedHistory.isEmpty) return const SizedBox();

    final earliest = sortedHistory.first['measured_at'] as int;
    final weightSpots = <FlSpot>[];
    final bfSpots = <FlSpot>[];
    double maxW = 0;

    for (var m in sortedHistory) {
      final days = ((m['measured_at'] as int) - earliest) / (1000 * 60 * 60 * 24);
      final w = (m['weight'] as num?)?.toDouble() ?? 0;
      if (w > 0) {
        weightSpots.add(FlSpot(days, w));
        if (w > maxW) maxW = w;
      }
      final bf = (m['body_fat'] as num?)?.toDouble() ?? 0;
      if (bf > 0) {
        // Scale body fat to weight range for dual-axis visualization
        bfSpots.add(FlSpot(days, bf));
      }
    }

    // If we have both, normalize body fat to weight scale
    final normalizedBf = <FlSpot>[];
    if (bfSpots.isNotEmpty && maxW > 0) {
      for (var s in bfSpots) {
        normalizedBf.add(FlSpot(s.x, s.y * maxW / 50)); // assume BF max ~50%
      }
    }

    final maxY = maxW > 0 ? maxW * 1.2 : 100.0;

    return _buildChartContainer(
      title: "Body Weight & Fat",
      legends: [
        _buildLegend(Colors.blueAccent, "Weight (kg)"),
        if (normalizedBf.isNotEmpty) _buildLegend(Colors.orangeAccent, "Body Fat (%)"),
      ],
      chart: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          titlesData: _chartTitles(maxY),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            if (weightSpots.isNotEmpty)
              _lineBar(weightSpots, Colors.blueAccent),
            if (normalizedBf.isNotEmpty)
              _lineBar(normalizedBf, Colors.orangeAccent),
          ],
        ),
      ),
    );
  }

  // ================= GRAPH 2: Volume / Sets =================

  Widget _buildVolumeGraph() {
    final sortedSessions = List<Map<String, dynamic>>.from(_sessions)
      ..sort((a, b) => (a['started_at'] as int).compareTo(b['started_at'] as int));

    if (sortedSessions.isEmpty) return const SizedBox();

    final earliest = sortedSessions.first['started_at'] as int;
    final volumeSpots = <FlSpot>[];
    final setsSpots = <FlSpot>[];
    double maxVol = 0;
    double maxSets = 0;

    for (var s in sortedSessions) {
      final days = ((s['started_at'] as int) - earliest) / (1000 * 60 * 60 * 24);
      final vol = (s['total_volume'] as num?)?.toDouble() ?? 0;
      final sets = (s['total_sets'] as num?)?.toDouble() ?? 0;
      if (vol > 0) {
        volumeSpots.add(FlSpot(days, vol));
        if (vol > maxVol) maxVol = vol;
      }
      if (sets > 0) {
        setsSpots.add(FlSpot(days, sets));
        if (sets > maxSets) maxSets = sets;
      }
    }

    // Normalize sets to volume scale
    final normalizedSets = <FlSpot>[];
    if (setsSpots.isNotEmpty && maxVol > 0 && maxSets > 0) {
      final scale = maxVol / maxSets;
      for (var s in setsSpots) {
        normalizedSets.add(FlSpot(s.x, s.y * scale));
      }
    } else {
      normalizedSets.addAll(setsSpots);
    }

    final maxY = maxVol > 0 ? maxVol * 1.2 : (maxSets > 0 ? maxSets * 1.2 : 100.0);

    return _buildChartContainer(
      title: "Workout Volume & Sets",
      legends: [
        if (volumeSpots.isNotEmpty) _buildLegend(Colors.purpleAccent, "Volume"),
        if (normalizedSets.isNotEmpty) _buildLegend(Colors.tealAccent, "Sets"),
      ],
      chart: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          titlesData: _chartTitles(maxY),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            if (volumeSpots.isNotEmpty)
              _lineBar(volumeSpots, Colors.purpleAccent),
            if (normalizedSets.isNotEmpty)
              _lineBar(normalizedSets, Colors.tealAccent),
          ],
        ),
      ),
    );
  }

  // ================= GRAPH 3: Nutrition =================

  Widget _buildNutritionGraph() {
    if (_nutritionHistory.isEmpty) return const SizedBox();

    // Determine which metric key and color to use
    String dataKey;
    Color lineColor;
    String unit;
    switch (_selectedNutritionMetric) {
      case 'Protein':
        dataKey = 'total_protein';
        lineColor = Colors.redAccent;
        unit = 'g';
        break;
      case 'Carbs':
        dataKey = 'total_carbs';
        lineColor = Colors.lightBlueAccent;
        unit = 'g';
        break;
      default: // Calories
        dataKey = 'total_calories';
        lineColor = Colors.amber;
        unit = 'cal';
    }

    final spots = <FlSpot>[];
    final dateLabels = <double, String>{};
    double maxY = 0;

    for (int i = 0; i < _nutritionHistory.length; i++) {
      final n = _nutritionHistory[i];
      final ts = (n['logged_at'] as num).toInt();
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      final x = i.toDouble();
      final y = (n[dataKey] as num?)?.toDouble() ?? 0;

      spots.add(FlSpot(x, y));
      dateLabels[x] = '${dt.day}/${dt.month}';
      if (y > maxY) maxY = y;
    }

    if (maxY == 0) maxY = 100;
    final chartMaxY = maxY * 1.2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Nutrition",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Metric toggle chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['Calories', 'Protein', 'Carbs'].map((metric) {
              final isActive = _selectedNutritionMetric == metric;
              Color chipColor;
              switch (metric) {
                case 'Protein': chipColor = Colors.redAccent; break;
                case 'Carbs': chipColor = Colors.lightBlueAccent; break;
                default: chipColor = Colors.amber;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(metric, style: TextStyle(
                    color: Colors.black,
                    // color: isActive ? Colors.black : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
                  selected: isActive,
                  selectedColor: chipColor,
                  backgroundColor: Colors.white10,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (_) {
                    setState(() => _selectedNutritionMetric = metric);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: chartMaxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value >= chartMaxY) return const SizedBox();
                        return Text(
                          '${value.toInt()}$unit',
                          style: const TextStyle(color: Colors.white38, fontSize: 9),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: _nutritionHistory.length > 7 ? (_nutritionHistory.length / 5).ceilToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        final label = dateLabels[value];
                        if (label == null) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label,
                            style: const TextStyle(color: Colors.white38, fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  _lineBar(spots, lineColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CHART HELPERS =================

  Widget _buildChartContainer({
    required String title,
    required List<Widget> legends,
    required Widget chart,
  }) {
    return Container(
      width: double.infinity,
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: legends,
          ),
          const SizedBox(height: 12),
          Expanded(child: chart),
        ],
      ),
    );
  }

  LineChartBarData _lineBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: spots.length > 2,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: spots.length < 15,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }

  FlTitlesData _chartTitles(double maxY) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            if (value == 0 || value == maxY) return const SizedBox();
            return Text(
              value.toInt().toString(),
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            );
          },
        ),
      ),
      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  // ================= NAVIGATION =================

  Future<void> _addMeasurement() async {
    final result = await Navigator.push(
      context,
      AppRoutes.slideFromRight(const AddMeasurementPage()),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _editMeasurement(int measurementId) async {
    final result = await Navigator.push(
      context,
      AppRoutes.slideFromRight(AddMeasurementPage(measurementId: measurementId)),
    );
    if (result == true) {
      _loadData();
    }
  }
}