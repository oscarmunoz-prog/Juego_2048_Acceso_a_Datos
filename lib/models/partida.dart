/// Fila de la tabla partidas (una partida terminada).
class Partida {
  final int? id; // null hasta que SQLite lo asigna al insertar
  final int usuarioId; // clave foránea a usuarios.id
  final int puntuacion;
  final int fichaMaxima;
  final int movimientos;
  final int duracionSegundos;
  final DateTime fecha;
  final String? nombreUsuario; // no es columna: llega del JOIN con usuarios

  const Partida({
    this.id,
    required this.usuarioId,
    required this.puntuacion,
    required this.fichaMaxima,
    required this.movimientos,
    required this.duracionSegundos,
    required this.fecha,
    this.nombreUsuario,
  });

  /// nombreUsuario no se incluye porque no existe en la tabla.
  /// tamano_tablero (v2) tampoco: su DEFAULT 4 la rellena.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'usuario_id': usuarioId,
      'puntuacion': puntuacion,
      'ficha_maxima': fichaMaxima,
      'movimientos': movimientos,
      'duracion_segundos': duracionSegundos,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Partida.fromMap(Map<String, dynamic> map) {
    return Partida(
      id: map['id'] as int,
      usuarioId: map['usuario_id'] as int,
      puntuacion: map['puntuacion'] as int,
      fichaMaxima: map['ficha_maxima'] as int,
      movimientos: map['movimientos'] as int,
      duracionSegundos: map['duracion_segundos'] as int,
      fecha: DateTime.parse(map['fecha'] as String),
      nombreUsuario: map['usuario'] as String?,
    );
  }
}
