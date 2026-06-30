import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/tareas_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/tarea.dart';
import '../../widgets/tarea_card.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../auth/login_screen.dart';
import 'tarea_form_screen.dart';

class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showCalendar = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<TareasProvider>().cargarTareas();
      await NotificationService().solicitarPermisos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tareasProvider = context.watch<TareasProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    final tareasFiltradas = _selectedDay != null
        ? tareasProvider.tareasPorFecha(_selectedDay!)
        : tareasProvider.tareas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          IconButton(
            icon: Icon(_showCalendar
                ? Icons.calendar_month
                : Icons.calendar_month_outlined),
            tooltip: 'Mostrar/ocultar calendario',
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => tareasProvider.cargarTareas(),
        child: Column(
          children: [
            if (_showCalendar)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay =
                          isSameDay(_selectedDay, selected) ? null : selected;
                      _focusedDay = focused;
                    });
                  },
                  calendarFormat: CalendarFormat.week,
                  availableCalendarFormats: const {
                    CalendarFormat.week: 'Semana'
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: theme.textTheme.titleMedium!
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12),
                    weekendStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    markerDecoration: const BoxDecoration(
                        color: AppColors.secondary, shape: BoxShape.circle),
                    defaultTextStyle: theme.textTheme.bodyMedium!,
                    weekendTextStyle: theme.textTheme.bodyMedium!,
                  ),
                  eventLoader: (day) => tareasProvider.tareasPorFecha(day),
                ),
              ).animate().fadeIn().slideY(begin: -0.05),
            if (_selectedDay != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Tareas del día',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _selectedDay = null),
                      child: const Text('Ver todas'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: tareasProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : tareasProvider.error != null
                      ? _ErrorState(
                          theme: theme,
                          mensaje: tareasProvider.error!,
                          onRetry: () => tareasProvider.cargarTareas(),
                        )
                      : tareasFiltradas.isEmpty
                          ? _EmptyState(theme: theme)
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 100),
                              itemCount: tareasFiltradas.length,
                              itemBuilder: (context, index) {
                                final tarea = tareasFiltradas[index];
                                return TareaCard(
                                  tarea: tarea,
                                  onTap: () =>
                                      _abrirFormulario(context, tarea: tarea),
                                  onDelete: () =>
                                      tareasProvider.eliminarTarea(tarea.id),
                                )
                                    .animate()
                                    .fadeIn(delay: (index * 40).ms)
                                    .slideX(begin: 0.03);
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva tarea'),
      ),
    );
  }

  void _abrirFormulario(BuildContext context, {Tarea? tarea}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TareaFormScreen(tarea: tarea)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final ThemeData theme;
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorState(
      {required this.theme, required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.danger.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt_rounded,
              size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No hay tareas por aquí',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(height: 4),
          Text(
            'Crea una nueva tarea con el botón +',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
