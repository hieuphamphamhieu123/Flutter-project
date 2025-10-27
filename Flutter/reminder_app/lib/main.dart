import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _NotificationService().init();
  runApp(const ReminderApp());
}

class Reminder {
  final int id;
  final String title;
  final int scheduledMillis;

  Reminder({required this.id, required this.title, required this.scheduledMillis});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'scheduledMillis': scheduledMillis};
  static Reminder fromJson(Map<String, dynamic> j) => Reminder(id: j['id'], title: j['title'], scheduledMillis: j['scheduledMillis']);
}

class _NotificationService {
  static final _instance = _NotificationService._internal();
  factory _NotificationService() => _instance;
  _NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // timezone
    tz.initializeTimeZones();
    final String tzName = await FlutterNativeTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSInit = DarwinInitializationSettings(requestSoundPermission: true, requestAlertPermission: true, requestBadgePermission: true);
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iOSInit);

    await flutterLocalNotificationsPlugin.initialize(initSettings, onDidReceiveNotificationResponse: (details) {
      // handle notification tapped logic here if needed
    });
  }

  Future<void> scheduleNotification(int id, String title, DateTime scheduledDateTime) async {
    final tz.TZDateTime tzScheduled = tz.TZDateTime.from(scheduledDateTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Channel for reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      'Reminder: $title',
      tzScheduled,
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminders',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const RemindersHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RemindersHomePage extends StatefulWidget {
  const RemindersHomePage({super.key});

  @override
  State<RemindersHomePage> createState() => _RemindersHomePageState();
}

class _RemindersHomePageState extends State<RemindersHomePage> {
  final _service = _NotificationService();
  final List<Reminder> _reminders = [];
  bool _loading = true;

  static const _storageKey = 'reminders_v1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    _reminders.clear();
    for (final s in raw) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        _reminders.add(Reminder.fromJson(map));
      } catch (_) {}
    }
    _reminders.sort((a, b) => a.scheduledMillis.compareTo(b.scheduledMillis));
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _reminders.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_storageKey, list);
  }

  Future<void> _addReminder() async {
    final result = await showDialog<Reminder?>(context: context, builder: (c) => const AddReminderDialog());
    if (result == null) return;
    // schedule
    await _service.scheduleNotification(result.id, result.title, DateTime.fromMillisecondsSinceEpoch(result.scheduledMillis));
    _reminders.add(result);
    _reminders.sort((a, b) => a.scheduledMillis.compareTo(b.scheduledMillis));
    await _save();
    setState(() {});
  }

  Future<void> _cancelReminder(Reminder r) async {
    await _service.cancelNotification(r.id);
    _reminders.removeWhere((e) => e.id == r.id);
    await _save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? const Center(child: Text('No reminders. Tap + to add.'))
              : ListView.builder(
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    final r = _reminders[index];
                    final dt = DateTime.fromMillisecondsSinceEpoch(r.scheduledMillis);
                    return ListTile(
                      title: Text(r.title),
                      subtitle: Text(dt.toLocal().toString()),
                      trailing: IconButton(icon: const Icon(Icons.cancel), onPressed: () => _cancelReminder(r)),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add_alert),
      ),
    );
  }
}

class AddReminderDialog extends StatefulWidget {
  const AddReminderDialog({super.key});

  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final _titleCtrl = TextEditingController();
  DateTime? _pickedDateTime;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: DateTime(now.year + 5));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _pickedDateTime = dt);
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _pickedDateTime == null) return;
    if (_pickedDateTime!.isBefore(DateTime.now())) return;
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final r = Reminder(id: id, title: title, scheduledMillis: _pickedDateTime!.millisecondsSinceEpoch);
    Navigator.of(context).pop(r);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(_pickedDateTime == null ? 'No time chosen' : _pickedDateTime!.toLocal().toString())),
              TextButton(onPressed: _pickDateTime, child: const Text('Pick')),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Schedule')),
      ],
    );
  }
}
