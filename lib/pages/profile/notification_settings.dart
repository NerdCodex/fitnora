import 'package:fitnora/services/notification_service.dart';
import 'package:fitnora/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late Box _settingsBox;
  final NotificationService _notificationService = NotificationService();

  // Individual toggles
  bool _workoutEnabled = true;
  bool _breakfastEnabled = true;
  bool _lunchEnabled = true;
  bool _dinnerEnabled = true;
  bool _snackEnabled = true;

  // Times
  TimeOfDay _workoutTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 30);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _snackTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box(UserSession().settingsBoxName);
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _workoutEnabled = _settingsBox.get('workout_enabled', defaultValue: true);
      _breakfastEnabled = _settingsBox.get('breakfast_enabled', defaultValue: true);
      _lunchEnabled = _settingsBox.get('lunch_enabled', defaultValue: true);
      _dinnerEnabled = _settingsBox.get('dinner_enabled', defaultValue: true);
      _snackEnabled = _settingsBox.get('snack_enabled', defaultValue: true);

      _workoutTime = _parseTime(_settingsBox.get('workout_time', defaultValue: '18:00'));
      _breakfastTime = _parseTime(_settingsBox.get('breakfast_time', defaultValue: '08:30'));
      _lunchTime = _parseTime(_settingsBox.get('lunch_time', defaultValue: '13:00'));
      _dinnerTime = _parseTime(_settingsBox.get('dinner_time', defaultValue: '20:00'));
      _snackTime = _parseTime(_settingsBox.get('snack_time', defaultValue: '17:00'));
    });
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return const TimeOfDay(hour: 12, minute: 0);
  }

  String _formatTimeForStorage(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveAndReschedule() async {
    // Save toggles
    await _settingsBox.put('workout_enabled', _workoutEnabled);
    await _settingsBox.put('breakfast_enabled', _breakfastEnabled);
    await _settingsBox.put('lunch_enabled', _lunchEnabled);
    await _settingsBox.put('dinner_enabled', _dinnerEnabled);
    await _settingsBox.put('snack_enabled', _snackEnabled);

    // Also keep the master flag true if any are enabled
    final anyEnabled = _workoutEnabled || _breakfastEnabled || _lunchEnabled || _dinnerEnabled || _snackEnabled;
    await _settingsBox.put('notifications_enabled', anyEnabled);

    // Save times
    await _settingsBox.put('workout_time', _formatTimeForStorage(_workoutTime));
    await _settingsBox.put('breakfast_time', _formatTimeForStorage(_breakfastTime));
    await _settingsBox.put('lunch_time', _formatTimeForStorage(_lunchTime));
    await _settingsBox.put('dinner_time', _formatTimeForStorage(_dinnerTime));
    await _settingsBox.put('snack_time', _formatTimeForStorage(_snackTime));

    // Cancel all first, then reschedule only enabled ones
    await _notificationService.cancelAllNotifications();

    if (anyEnabled) {
      await _notificationService.requestPermissions();
    }

    if (_workoutEnabled) {
      await _notificationService.scheduleDailyNotification(
        id: 1,
        title: "Workout Reminder",
        body: "Don't forget to complete your workout session today!",
        time: _workoutTime,
      );
    }

    if (_breakfastEnabled) {
      await _notificationService.scheduleDailyNotification(
        id: 2,
        title: "Breakfast Time",
        body: "Time to log your breakfast!",
        time: _breakfastTime,
      );
    }

    if (_lunchEnabled) {
      await _notificationService.scheduleDailyNotification(
        id: 3,
        title: "Lunch Time",
        body: "Time to log your lunch!",
        time: _lunchTime,
      );
    }

    if (_dinnerEnabled) {
      await _notificationService.scheduleDailyNotification(
        id: 4,
        title: "Dinner Time",
        body: "Time to log your dinner!",
        time: _dinnerTime,
      );
    }

    if (_snackEnabled) {
      await _notificationService.scheduleDailyNotification(
        id: 5,
        title: "Snack Time",
        body: "Time to log your snacks!",
        time: _snackTime,
      );
    }
  }

  Future<void> _selectTime(BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != initialTime) {
      setState(() {
        onSelected(picked);
      });
      _saveAndReschedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        children: [
          _buildNotificationCard(
            icon: Icons.fitness_center,
            title: "Workout Reminder",
            subtitle: "Remind if no workout recorded today",
            enabled: _workoutEnabled,
            time: _workoutTime,
            onToggle: (val) {
              setState(() => _workoutEnabled = val);
              _saveAndReschedule();
            },
            onTimeTap: () => _selectTime(context, _workoutTime, (t) => _workoutTime = t),
          ),
          _buildNotificationCard(
            icon: Icons.free_breakfast_outlined,
            title: "Breakfast",
            subtitle: "Remind if breakfast not logged today",
            enabled: _breakfastEnabled,
            time: _breakfastTime,
            onToggle: (val) {
              setState(() => _breakfastEnabled = val);
              _saveAndReschedule();
            },
            onTimeTap: () => _selectTime(context, _breakfastTime, (t) => _breakfastTime = t),
          ),
          _buildNotificationCard(
            icon: Icons.lunch_dining_outlined,
            title: "Lunch",
            subtitle: "Remind if lunch not logged today",
            enabled: _lunchEnabled,
            time: _lunchTime,
            onToggle: (val) {
              setState(() => _lunchEnabled = val);
              _saveAndReschedule();
            },
            onTimeTap: () => _selectTime(context, _lunchTime, (t) => _lunchTime = t),
          ),
          _buildNotificationCard(
            icon: Icons.dinner_dining_outlined,
            title: "Dinner",
            subtitle: "Remind if dinner not logged today",
            enabled: _dinnerEnabled,
            time: _dinnerTime,
            onToggle: (val) {
              setState(() => _dinnerEnabled = val);
              _saveAndReschedule();
            },
            onTimeTap: () => _selectTime(context, _dinnerTime, (t) => _dinnerTime = t),
          ),
          _buildNotificationCard(
            icon: Icons.fastfood_outlined,
            title: "Snack",
            subtitle: "Remind if snack not logged today",
            enabled: _snackEnabled,
            time: _snackTime,
            onToggle: (val) {
              setState(() => _snackEnabled = val);
              _saveAndReschedule();
            },
            onTimeTap: () => _selectTime(context, _snackTime, (t) => _snackTime = t),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required TimeOfDay time,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTimeTap,
  }) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          children: [
            SwitchListTile(
              secondary: Icon(icon, color: enabled ? Colors.blueAccent : Colors.white38),
              title: Text(title, style: TextStyle(color: enabled ? Colors.white : Colors.white38, fontSize: 16, fontWeight: FontWeight.w500)),
              subtitle: Text(subtitle, style: TextStyle(color: enabled ? Colors.white54 : Colors.white24, fontSize: 12)),
              activeColor: Colors.blueAccent,
              value: enabled,
              onChanged: onToggle,
            ),
            if (enabled)
              InkWell(
                onTap: onTimeTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.only(left: 72, right: 16, bottom: 12, top: 0),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.white54, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        time.format(context),
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, color: Colors.white38, size: 16),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
