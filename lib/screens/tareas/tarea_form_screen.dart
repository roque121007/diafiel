import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/tarea.dart';
import '../../models/categoria.dart';
import '../../providers/tareas_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_snackbar.dart';
import '../../theme/app_theme.dart';

class TareaFormScreen extends StatefulWidget {
  final Tarea? tarea;
  const TareaFormScreen({super.key, this.tarea});

  @override
  State<TareaFormScreen> createState() => _TareaFormScreenState();
}

class _TareaFormScreenState extends State<TareaFormScreen> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _api = ApiService();
  String _estado = 'Pendiente';
  DateTime? _fechaLimite;
  int? _categoriaId;
  List<Categoria> _categorias = [];
  bool _cargandoCategorias = true;
  bool _guardando = false;

  final List<String> _estados = ['Pendiente', 'En proceso', 'Completada'];

  @override
  void initState() {
    super.initState();
    if (widget.tarea != null) {
      _tituloCtrl.text = widget.tarea!.titulo;
      _descCtrl.text = widget.tarea!.descripcion ?? '';
      _estado = widget.tarea!.estado;
      _fechaLimite = widget.tarea!.fechaLimite;
      _categoriaId = widget.tarea!.categoriaId;
    }
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final data = await _api.getCategorias();
      setState(() {
        _categorias = data.map((j) => Categoria.fromJson(j)).toList();
        _categoriaId ??= _categorias.isNotEmpty ? _categorias.first.id : null;
        _cargandoCategorias = false;
      });
    } catch (e) {
      setState(() => _cargandoCategorias = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaLimite ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (fecha == null) return;

    if (!mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: _fechaLimite != null
          ? TimeOfDay.fromDateTime(_fechaLimite!)
          : TimeOfDay.now(),
    );

    setState(() {
      _fechaLimite = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora?.hour ?? 23,
        hora?.minute ?? 59,
      );
    });
  }

  Future<void> _guardar() async {
    if (_tituloCtrl.text.trim().isEmpty) {
      showAppSnackBar(context, mensaje: 'El título es obligatorio');
      return;
    }
    if (_categoriaId == null) {
      showAppSnackBar(context, mensaje: 'Selecciona una categoría');
      return;
    }

    setState(() => _guardando = true);
    final provider = context.read<TareasProvider>();

    try {
      if (widget.tarea == null) {
        final nueva = Tarea(
          id: 0,
          titulo: _tituloCtrl.text.trim(),
          descripcion: _descCtrl.text.trim(),
          estado: _estado,
          categoriaId: _categoriaId!,
          fechaLimite: _fechaLimite,
        );
        await provider.crearTarea(nueva);
      } else {
        final actualizada = widget.tarea!.copyWith(
          titulo: _tituloCtrl.text.trim(),
          descripcion: _descCtrl.text.trim(),
          estado: _estado,
          categoriaId: _categoriaId,
          fechaLimite: _fechaLimite,
        );
        await provider.actualizarTarea(actualizada);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, mensaje: e.toString());
      }
    }
    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esEdicion = widget.tarea != null;

    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar tarea' : 'Nueva tarea')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                      controller: _tituloCtrl,
                      label: 'Título',
                      icon: Icons.title_rounded)
                  .animate()
                  .fadeIn()
                  .slideY(begin: 0.1),
              const SizedBox(height: 16),
              AppTextField(
                controller: _descCtrl,
                label: 'Descripción (opcional)',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),
              const SizedBox(height: 20),
              Text('Estado',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _estados.map((e) {
                  final selected = _estado == e;
                  return ChoiceChip(
                    label: Text(e),
                    selected: selected,
                    onSelected: (_) => setState(() => _estado = e),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color:
                          selected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: theme.cardTheme.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 24),
              Text('Categoría',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _cargandoCategorias
                  ? const Center(
                      child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                  : _categorias.isEmpty
                      ? Text(
                          'No hay categorías disponibles',
                          style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5)),
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _categorias.map((cat) {
                            final selected = _categoriaId == cat.id;
                            return ChoiceChip(
                              label: Text(cat.nombre),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _categoriaId = cat.id),
                              selectedColor: AppColors.secondary,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: theme.cardTheme.color,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: theme.dividerColor),
                              ),
                            );
                          }).toList(),
                        ).animate().fadeIn(delay: 120.ms),
              const SizedBox(height: 24),
              Text('Fecha límite',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _seleccionarFecha,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 14),
                      Text(
                        _fechaLimite == null
                            ? 'Seleccionar fecha y hora'
                            : DateFormat("d 'de' MMMM, yyyy · HH:mm", 'es')
                                .format(_fechaLimite!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _fechaLimite == null
                              ? theme.colorScheme.onSurface.withOpacity(0.5)
                              : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (_fechaLimite != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => _fechaLimite = null),
                        ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(esEdicion ? 'Guardar cambios' : 'Crear tarea'),
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }
}
