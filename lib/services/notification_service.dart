import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import '../models/tarea.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);

    // Canal de alta prioridad para que suene y aparezca como heads-up.
    // Usamos un ID nuevo (v2) porque Android bloquea cambios de sonido/importancia
    // en canales que ya existían en el dispositivo con otra configuración.
    const channel = AndroidNotificationChannel(
      'tareas_recordatorios_v2',
      'Recordatorios de tareas',
      description: 'Notificaciones de fecha límite de tus tareas',
      importance: Importance.max,
      playSound: true, // usa el sonido de notificación por defecto del sistema
      enableVibration: true,
      enableLights: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<void> solicitarPermisos() async {
    await Permission.notification.request();
    // Permiso para alarmas exactas (Android 12+) - necesario para que la notificación
    // dispare exactamente a la hora programada, incluso con restricciones de batería.
    await Permission.scheduleExactAlarm.request();
  }

  Future<void> programarRecordatorio(Tarea tarea) async {
    if (tarea.fechaLimite == null) return;

    // Recordatorio 30 minutos antes de la fecha límite
    final fechaRecordatorio =
        tarea.fechaLimite!.subtract(const Duration(minutes: 30));
    if (fechaRecordatorio.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      tarea.id, // usamos el id de la tarea como id de notificación
      'Tarea por vencer ⏰',
      tarea.titulo,
      tz.TZDateTime.from(fechaRecordatorio, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tareas_recordatorios_v2',
          'Recordatorios de tareas',
          channelDescription: 'Notificaciones de fecha límite de tus tareas',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: false,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelarRecordatorio(int tareaId) async {
    await _plugin.cancel(tareaId);
  }

  Future<void> cancelarTodos() async {
    await _plugin.cancelAll();
  }
}
