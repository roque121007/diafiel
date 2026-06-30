class Tarea {
  final int id;
  final String titulo;
  final String? descripcion;
  final String estado;
  final int categoriaId;
  final String? categoria;
  final DateTime? fechaLimite;
  final DateTime? fechaCreacion;

  Tarea({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.estado,
    required this.categoriaId,
    this.categoria,
    this.fechaLimite,
    this.fechaCreacion,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'],
      estado: json['estado'] ?? 'Pendiente',
      categoriaId: json['categoria_id'] ?? 0,
      categoria: json['categoria'],
      fechaLimite: json['fecha_limite'] != null
          ? DateTime.tryParse(json['fecha_limite'])
          : null,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'estado': estado,
      'categoria_id': categoriaId,
      'fecha_limite': fechaLimite?.toIso8601String(),
    };
  }

  Tarea copyWith({
    String? titulo,
    String? descripcion,
    String? estado,
    int? categoriaId,
    DateTime? fechaLimite,
  }) {
    return Tarea(
      id: id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      categoriaId: categoriaId ?? this.categoriaId,
      categoria: categoria,
      fechaLimite: fechaLimite ?? this.fechaLimite,
      fechaCreacion: fechaCreacion,
    );
  }
}
