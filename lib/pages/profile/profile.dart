import 'dart:io';

import 'package:fitnora/animations.dart';
import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/custom_image_picker.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/pages/profile/add_measurement.dart';
import 'package:fitnora/pages/profile/settings.dart';
import 'package:fitnora/services/user_session.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:video_player/video_player.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _nutritionHistory = [];
  String _selectedNutritionMetric = 'Calories'; // Calories | Protein | Carbs
  String _selectedWorkoutMetric = 'Volume'; // Volume | Reps | Seconds
  String _selectedWorkoutRange = 'Last 3 months';
  String _selectedBodyRange = 'Last 3 months';

  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
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
    final history = await WorkoutDatabaseService.instance.getMeasurements();
    final sessions = await WorkoutDatabaseService.instance.getSessionHistory();
    final nutritionHistory = await WorkoutDatabaseService.instance
        .getNutritionHistory();
    if (!mounted) return;
    setState(() {
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
              Navigator.push(context, AppRoutes.slideFromRight(SettingsPage()));
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
                  // ================= MEASUREMENT CALENDAR =================
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDate,
                      calendarFormat: CalendarFormat.week,
                      availableCalendarFormats: const {
                        CalendarFormat.week: 'Week',
                      },
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDate, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDate = selectedDay;
                          _focusedDate = focusedDay;
                        });
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: Colors.white70),
                        weekendStyle: TextStyle(color: Colors.white70),
                      ),
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: TextStyle(color: Colors.white),
                        weekendTextStyle: TextStyle(color: Colors.white),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) =>
                            _buildCalendarCell(day, isSelected: false),
                        todayBuilder: (context, day, focusedDay) =>
                            _buildCalendarCell(
                              day,
                              isSelected: false,
                              isToday: true,
                            ),
                        selectedBuilder: (context, day, focusedDay) =>
                            _buildCalendarCell(day, isSelected: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ================= SELECTED DAY MEASUREMENT =================
                  _buildDailyMeasurementCard(),

                  const SizedBox(height: 24),

                  // ================= PROGRESS GRAPHS =================
                  _buildSectionHeader("Progress"),
                  const SizedBox(height: 12),

                  // Graph 1: Workout Session (bar chart)
                  if (_sessions.isNotEmpty) ...[
                    _buildWorkoutSessionGraph(),
                    const SizedBox(height: 16),
                  ],

                  // Graph 2: Nutrition (Calories, Protein, Carbs)
                  if (_nutritionHistory.isNotEmpty) ...[
                    _buildNutritionGraph(),
                    const SizedBox(height: 16),
                  ],

                  // Graph 3: Body Weight + Body Fat
                  if (_history.isNotEmpty) ...[
                    _buildBodyGraph(),
                    const SizedBox(height: 16),
                  ],

                  if (_history.isEmpty &&
                      _sessions.isEmpty &&
                      _nutritionHistory.isEmpty)
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
        child: Text(message, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  // ================= DAILY CARD =================

  Widget _buildDailyMeasurementCard() {
    final measurements = _getMeasurementsForDay(_selectedDate);
    final hasEntry = measurements.isNotEmpty;
    final m = hasEntry ? measurements.first : null;

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasEntry)
                    GestureDetector(
                      onTap: () =>
                          _deleteMeasurement(m!['measurement_id'] as int),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: hasEntry
                        ? () => _editMeasurement(m!['measurement_id'] as int)
                        : _addMeasurement,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        hasEntry ? "Edit" : "Create",
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!hasEntry) ...[
            const SizedBox(height: 16),
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.monitor_weight_outlined,
                    size: 42,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "No measurements recorded today\nTap Create to log your progress",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white30, fontSize: 13),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            if (m!['progress_image'] != null &&
                m['progress_image'].toString().isNotEmpty) ...[
              Center(
                child: FutureBuilder<File?>(
                  future: resolveProgressImage(m['progress_image']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 150,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final file = snapshot.data;
                    if (file == null) return const SizedBox.shrink();

                    final fileName = m['progress_image'].toString();
                    if (isVideoFile(fileName)) {
                      return _ProgressVideoPlayer(file: file);
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        file,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                _buildStatItem("Weight", "${m['weight'] ?? '-'}", "kg"),
                _buildStatItem("Height", "${m['height'] ?? '-'}", "cm"),
                _buildStatItem("Body Fat", "${m['body_fat'] ?? '-'}", "%"),
              ],
            ),
            if (m['chest'] != null ||
                m['waist'] != null ||
                m['hips'] != null) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatItem("Chest", "${m['chest'] ?? '-'}", "cm"),
                  _buildStatItem("Waist", "${m['waist'] ?? '-'}", "cm"),
                  _buildStatItem("Hips", "${m['hips'] ?? '-'}", "cm"),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<File?> resolveProgressImage(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return null;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${UserSession().imagesPath}/$fileName');
    return await file.exists() ? file : null;
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

  // ================= MEASUREMENT CALENDAR HELPERS =================

  List<Map<String, dynamic>> _getMeasurementsForDay(DateTime day) {
    return _history.where((m) {
      final dt = DateTime.fromMillisecondsSinceEpoch(m['measured_at'] as int);
      return isSameDay(dt, day);
    }).toList();
  }

  Widget _buildCalendarCell(
    DateTime day, {
    required bool isSelected,
    bool isToday = false,
  }) {
    final hasMeasurement = _getMeasurementsForDay(day).isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.transparent,
        shape: BoxShape.circle,
        border: isToday && !isSelected ? Border.all(color: Colors.blue) : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isToday ? Colors.blue : Colors.white),
              fontWeight: isSelected || isToday
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          if (hasMeasurement) ...[
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= GRAPH 1: Body Weight + Body Fat =================

  List<Map<String, dynamic>> _filterMeasurementsByRange(
    List<Map<String, dynamic>> measurements,
  ) {
    final now = DateTime.now();
    DateTime cutoff;
    switch (_selectedBodyRange) {
      case 'Last 7 days':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case 'Last month':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case 'Last 6 months':
        cutoff = now.subtract(const Duration(days: 180));
        break;
      case 'All time':
        return List<Map<String, dynamic>>.from(measurements);
      default: // Last 3 months
        cutoff = now.subtract(const Duration(days: 90));
    }
    final cutoffMs = cutoff.millisecondsSinceEpoch;
    return measurements.where((m) => (m['measured_at'] as int) >= cutoffMs).toList();
  }

  Widget _buildBodyGraph() {
    final filteredHistory = _filterMeasurementsByRange(_history)
      ..sort((a, b) => (a['measured_at'] as int).compareTo(b['measured_at'] as int));

    if (filteredHistory.isEmpty) return const SizedBox();

    final earliest = filteredHistory.first['measured_at'] as int;
    final weightSpots = <FlSpot>[];
    final bfSpots = <FlSpot>[];
    final dateLabels = <double, String>{};
    final Set<double> visibleKeys = {};
    double sumW = 0;
    int countW = 0;
    double maxW = 0;

    int N = filteredHistory.length;
    if (N <= 7) {
      for (int i = 0; i < N; i++) visibleKeys.add(i.toDouble());
    } else {
      for (int i = 0; i < 7; i++) {
        visibleKeys.add((i * (N - 1) / 6).roundToDouble());
      }
    }

    for (int i = 0; i < filteredHistory.length; i++) {
      var m = filteredHistory[i];
      final xIdx = i.toDouble();
      final dt = DateTime.fromMillisecondsSinceEpoch(m['measured_at'] as int);
      dateLabels[xIdx] = '${dt.day}/${dt.month}';

      final w = (m['weight'] as num?)?.toDouble() ?? 0;
      if (w > 0) {
        weightSpots.add(FlSpot(xIdx, w));
        sumW += w;
        countW++;
        if (w > maxW) maxW = w;
      }
      final bf = (m['body_fat'] as num?)?.toDouble() ?? 0;
      if (bf > 0) {
        bfSpots.add(FlSpot(xIdx, bf));
      }
    }

    final normalizedBf = <FlSpot>[];
    if (bfSpots.isNotEmpty && maxW > 0) {
      for (var s in bfSpots) {
        normalizedBf.add(FlSpot(s.x, s.y * maxW / 50));
      }
    }

    final maxY = maxW > 0 ? maxW * 1.2 : 100.0;
    if (weightSpots.isEmpty && normalizedBf.isEmpty) return const SizedBox();

    String avgText = countW > 0 ? "${(sumW / countW).toStringAsFixed(1)} kg avg" : "No weight logs";

    return _buildChartContainer(
      title: "Body Weight & Fat",
      customHeader: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: "Weight Progress",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: "\n$avgText",
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 13),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _selectedBodyRange,
            dropdownColor: Colors.grey.shade800,
            style: const TextStyle(color: Colors.blueAccent, fontSize: 14),
            underline: const SizedBox(),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Colors.blueAccent,
            ),
            items: [
              'Last 7 days',
              'Last month',
              'Last 3 months',
              'Last 6 months',
              'All time',
            ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedBodyRange = val);
            },
          ),
        ],
      ),
      legends: [
        _buildLegend(Colors.blueAccent, "Weight (kg)"),
        if (normalizedBf.isNotEmpty) _buildLegend(Colors.orangeAccent, "Body Fat (%)"),
      ],
      chart: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          titlesData: _chartTitles(maxY, dateLabels, visibleKeys),
          borderData: FlBorderData(show: false),
          lineTouchData: _tooltipData(dateLabels, "kg"),
          lineBarsData: [
            if (weightSpots.isNotEmpty) _lineBar(weightSpots, Colors.blueAccent),
            if (normalizedBf.isNotEmpty) _lineBar(normalizedBf, Colors.orangeAccent),
          ],
        ),
      ),
    );
  }

  // ================= GRAPH: Workout Session (Bar Chart) =================

  /// Filter sessions by the selected time range.
  List<Map<String, dynamic>> _filterSessionsByRange(
    List<Map<String, dynamic>> sessions,
  ) {
    final now = DateTime.now();
    DateTime cutoff;
    switch (_selectedWorkoutRange) {
      case 'Last 7 days':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case 'Last month':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case 'Last 6 months':
        cutoff = now.subtract(const Duration(days: 180));
        break;
      case 'All time':
        return sessions;
      default: // Last 3 months
        cutoff = now.subtract(const Duration(days: 90));
    }
    final cutoffMs = cutoff.millisecondsSinceEpoch;
    return sessions.where((s) => (s['started_at'] as int) >= cutoffMs).toList();
  }

  Widget _buildWorkoutSessionGraph() {
    final sortedSessions = List<Map<String, dynamic>>.from(_sessions)
      ..sort(
        (a, b) => (a['started_at'] as int).compareTo(b['started_at'] as int),
      );

    final filtered = _filterSessionsByRange(sortedSessions);
    if (filtered.isEmpty) return const SizedBox();

    // ── Compute summary for the header based on the selected range ──
    double rangeTotal = 0;
    for (var s in filtered) {
      switch (_selectedWorkoutMetric) {
        case 'Reps':
          rangeTotal += (s['total_reps'] as num?)?.toDouble() ?? 0;
          break;
        case 'Seconds':
          rangeTotal += (s['total_seconds'] as num?)?.toDouble() ?? 0;
          break;
        default: // Volume
          rangeTotal += (s['total_volume'] as num?)?.toDouble() ?? 0;
      }
    }

    String headerValue = rangeTotal.toStringAsFixed(0);
    String headerUnit;
    switch (_selectedWorkoutMetric) {
      case 'Reps':
        headerUnit = 'reps';
        break;
      case 'Seconds':
        headerUnit = 'secs';
        break;
      default: // Volume
        headerUnit = 'kg';
    }

    // ── Build bar data ──
    final List<_BarEntry> entries = [];
    double maxY = 0;

    for (var s in filtered) {
      final dt = DateTime.fromMillisecondsSinceEpoch(s['started_at'] as int);
      double value;
      switch (_selectedWorkoutMetric) {
        case 'Reps':
          value = (s['total_reps'] as num?)?.toDouble() ?? 0;
          break;
        case 'Seconds':
          value = (s['total_seconds'] as num?)?.toDouble() ?? 0;
          break;
        default: // Volume
          value = (s['total_volume'] as num?)?.toDouble() ?? 0;
      }
      entries.add(_BarEntry(dt: dt, value: value));
      if (value > maxY) maxY = value;
    }

    if (maxY == 0) maxY = 1;
    final chartMaxY = maxY * 1.2;

    String yUnit;
    switch (_selectedWorkoutMetric) {
      case 'Reps':
        yUnit = '';
        break;
      case 'Seconds':
        yUnit = 's';
        break;
      default: // Volume
        yUnit = 'kg';
    }

    // Build date label map
    final dateLabels = <int, String>{};
    final Set<int> visibleLabelIndices = {};
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    int N = entries.length;
    if (N <= 7) {
      for (int i = 0; i < N; i++) visibleLabelIndices.add(i);
    } else {
      for (int i = 0; i < 7; i++) {
        visibleLabelIndices.add((i * (N - 1) / 6).round());
      }
    }

    for (int i = 0; i < entries.length; i++) {
      final dt = entries[i].dt;
      dateLabels[i] = '${months[dt.month - 1]} ${dt.day}';
    }

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
          // ── Header row: summary + dropdown ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$headerValue $headerUnit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: ' ',
                    ),
                    TextSpan(
                      text: _selectedWorkoutRange.toLowerCase(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: _selectedWorkoutRange,
                dropdownColor: Colors.grey.shade800,
                style: const TextStyle(color: Colors.blueAccent, fontSize: 14),
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.blueAccent,
                ),
                items:
                    ['Last 7 days', 'Last month', 'Last 3 months', 'Last 6 months', 'All time']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedWorkoutRange = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Bar chart ──
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: chartMaxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY / 4,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: chartMaxY / 4,
                      getTitlesWidget: (value, meta) {
                        if (value <= 0 || value >= chartMaxY) {
                          return const SizedBox();
                        }
                        return Text(
                          '${value.toStringAsFixed(value < 10 ? 1 : 0)} $yUnit',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dateLabels.length) return const SizedBox();
                        if (!visibleLabelIndices.contains(idx)) return const SizedBox();
                        
                        final label = dateLabels[idx];
                        if (label == null) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = dateLabels[group.x] ?? '';
                      final val = rod.toY.toStringAsFixed(rod.toY < 10 ? 1 : 0);
                      return BarTooltipItem(
                        '$val $yUnit\n',
                        const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: label,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                barGroups: List.generate(entries.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: entries[i].value,
                        color: Colors.blueAccent,
                        width: entries.length > 20
                            ? 4
                            : (entries.length > 10 ? 8 : 14),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Metric toggle chips ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['Volume', 'Reps', 'Seconds'].map((metric) {
              final isActive = _selectedWorkoutMetric == metric;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    metric,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: isActive,
                  selectedColor: Colors.blueAccent,
                  backgroundColor: Colors.grey.shade800,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) {
                    setState(() => _selectedWorkoutMetric = metric);
                  },
                ),
              );
            }).toList(),
          ),
        ],
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
                case 'Protein':
                  chipColor = Colors.redAccent;
                  break;
                case 'Carbs':
                  chipColor = Colors.lightBlueAccent;
                  break;
                default:
                  chipColor = Colors.amber;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    metric,
                    style: TextStyle(
                      color: Colors.black,
                      // color: isActive ? Colors.black : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: isActive,
                  selectedColor: chipColor,
                  backgroundColor: Colors.white10,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                        if (value == 0 || value >= chartMaxY) {
                          return const SizedBox();
                        }
                        return Text(
                          '${value.toInt()}$unit',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: _nutritionHistory.length > 7
                          ? (_nutritionHistory.length / 5).ceilToDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        final label = dateLabels[value];
                        if (label == null) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineTouchData: _tooltipData(dateLabels, unit),
                lineBarsData: [_lineBar(spots, lineColor)],
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
    Widget? customHeader,
  }) {
    return Container(
      width: double.infinity,
      height: 290,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          customHeader ??
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
          const SizedBox(height: 12),
          Wrap(spacing: 16, children: legends),
          const SizedBox(height: 16),
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
        getDotPainter: (spot, percent, bar, index) =>
            FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }

  FlTitlesData _chartTitles(double maxY, Map<double, String> dateLabels, [Set<double>? visibleKeys]) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30, // changed slightly for better spacing
          getTitlesWidget: (value, meta) {
            if (value == 0 || value >= maxY) return const SizedBox();
            return Text(
              value.toInt().toString(),
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1, // Evaluate aggressively
          getTitlesWidget: (value, meta) {
            String? label;
            double minDiff = double.infinity;
            double? matchedKey;
            
            for (final k in dateLabels.keys) {
              final diff = (k - value).abs();
              if (diff < 0.5 && diff < minDiff) {
                minDiff = diff;
                label = dateLabels[k];
                matchedKey = k;
              }
            }
            if (label == null || matchedKey == null) return const SizedBox();
            if (visibleKeys != null && !visibleKeys.contains(matchedKey)) return const SizedBox();
            
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Transform.rotate(
                angle: -0.5,
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 9),
                ),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  LineTouchData _tooltipData(Map<double, String> dateLabels, String unit) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => Colors.white,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            String? dateStr;
            double minDiff = double.infinity;
            for (final k in dateLabels.keys) {
              final diff = (k - spot.x).abs();
              if (diff <= 1.5 && diff < minDiff) {
                // Widen search radius slightly for touch
                minDiff = diff;
                dateStr = dateLabels[k];
              }
            }
            final valueStr = spot.y
                .toStringAsFixed(1)
                .replaceAll(RegExp(r'\.0$'), '');
            return LineTooltipItem(
              "$valueStr $unit\n",
              const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              children: [
                if (dateStr != null)
                  TextSpan(
                    text: dateStr,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
              ],
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  // ================= NAVIGATION / ACTIONS =================

  Future<void> _addMeasurement() async {
    final hasEntry = _getMeasurementsForDay(_selectedDate).isNotEmpty;
    if (hasEntry) {
      showMessageDialog(
        context,
        "You already have a measurement for this date. Please edit the existing entry instead.",
      );
      return;
    }

    final result = await Navigator.push(
      context,
      AppRoutes.slideFromRight(AddMeasurementPage(measuredDate: _selectedDate)),
    );
    if (result == true) _loadData();
  }

  Future<void> _editMeasurement(int id) async {
    final result = await Navigator.push(
      context,
      AppRoutes.slideFromRight(AddMeasurementPage(measurementId: id)),
    );
    if (result == true) _loadData();
  }

  Future<void> _deleteMeasurement(int id) async {
    final confirm = await showConfirmDialog(
      context,
      title: "Delete Measurement?",
      content: "Are you sure you want to delete this measurement entry?",
      trueText: "DELETE",
      falseText: "CANCEL",
    );

    if (confirm != true) return;

    await WorkoutDatabaseService.instance.deleteMeasurement(id);
    _loadData();
  }
}

/// Simple data holder for workout session bar chart entries.
class _BarEntry {
  final DateTime dt;
  final double value;
  const _BarEntry({required this.dt, required this.value});
}

/// Inline video player for progress videos in the daily measurement card.
class _ProgressVideoPlayer extends StatefulWidget {
  final File file;
  const _ProgressVideoPlayer({required this.file});

  @override
  State<_ProgressVideoPlayer> createState() => _ProgressVideoPlayerState();
}

class _ProgressVideoPlayerState extends State<_ProgressVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
              if (!_controller.value.isPlaying)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              // Duration badge
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam,
                        color: Colors.orangeAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_controller.value.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
