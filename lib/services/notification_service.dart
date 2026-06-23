import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:ui';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Initialisation sécurisée ──────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Casablanca'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  // ─── Demande de permission séparée (À appeler dans le SplashScreen) ───
  
  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ─── Le reste de votre code ne change pas ──────────────────────────────

  Future<void> scheduleDailyTournamentNotification() async {
    await init();
    await _plugin.cancel(_kDailyTournamentId);
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, 8, 0,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _kDailyTournamentId,
      '🏆 Tournoi du jour disponible !',
      'Une nouvelle grille vous attend. Prêt à grimper dans le classement ?',
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showInstantTournamentNotification() async {
    await init();
    await _plugin.show(
      _kInstantTestId,
      '🏆 Tournois prêts !',
      'Les tournois quotidiens sont maintenant disponibles.',
      _notificationDetails(),
    );
  }

  Future<void> cancelDailyTournamentNotification() async {
    await _plugin.cancel(_kDailyTournamentId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static const int _kDailyTournamentId = 1001;
  static const int _kInstantTestId = 1002;

  NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      'daily_tournament_channel',
      'Tournois Quotidiens',
      channelDescription: 'Rappel quotidien pour les tournois Sudoku Kingdom',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFFD700),
      playSound: true,
      enableVibration: true,
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(android: android, iOS: ios);
  }
}
