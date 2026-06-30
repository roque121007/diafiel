import 'package:flutter/material.dart';
import '../models/tarea.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class TareasProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final NotificationService _notifications = NotificationService();
  List<Tarea> _tareas = [];
  bool isLoading = false;
  String? error;

  List<Tarea> get tareas => _tareas;

  List<Tarea> tareasPorFecha(DateTime day) {
    return _tareas.where((t) {
      if (t.fechaLimite == null) return false;
      return t.fechaLimite!.year == day.year &&
          t.fechaLimite!.month == day.month &&
          t.fechaLimite!.day == day.day;
    }).toList();
  }

  Set<DateTime> get diasConTareas {
    return _tareas
        .where((t) => t.fechaLimite != null)
        .map((t) => DateTime(
            t.fechaLimite!.year, t.fechaLimite!.month, t.fechaLimite!.day))
        .toSet();
  }

  Future<void> cargarTareas() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.getTareas();
      _tareas = data.map((j) => Tarea.fromJson(j)).toList();
      _tareas.sort((a, b) {
        if (a.fechaLimite == null) return 1;
        if (b.fechaLimite == null) return -1;
        return a.fechaLimite!.compareTo(b.fechaLimite!);
      });
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> crearTarea(Tarea tarea) async {
    final data = await _api.createTarea(tarea.toJson());
    await cargarTareas();
    final nuevaTarea =
        _tareas.firstWhere((t) => t.id == data['id'], orElse: () => tarea);
    await _notifications.programarRecordatorio(nuevaTarea);
  }

  Future<void> actualizarTarea(Tarea tarea) async {
    await _api.updateTarea(tarea.id, tarea.toJson());
    await _notifications.cancelarRecordatorio(tarea.id);
    if (tarea.estado != 'Completada') {
      await _notifications.programarRecordatorio(tarea);
    }
    await cargarTareas();
  }

  Future<void> eliminarTarea(int id) async {
    await _api.deleteTarea(id);
    await _notifications.cancelarRecordatorio(id);
    _tareas.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
