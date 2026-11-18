import 'dart:convert';

/// Fila única de partida_guardada (la partida en curso).
class PartidaGuardada {
  final List<int> tablero; // 16 valores del tablero 4x4
  final int puntuacion;
  final int movimientos;
  final int segundosTranscurridos;

  const PartidaGuardada({
    required this.tablero,
    required this.puntuacion,
    required this.movimientos,
    required this.segundosTranscurridos,
  });

  /// SQLite no guarda listas, así que el tablero se guarda como texto JSON: "[2,0,4,...]".
  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'tablero': jsonEncode(tablero),
      'puntuacion': puntuacion,
      'movimientos': movimientos,
      'segundos_transcurridos': segundosTranscurridos,
    };
  }

  factory PartidaGuardada.fromMap(Map<String, dynamic> map) {
    return PartidaGuardada(
      tablero: List<int>.from(jsonDecode(map['tablero'] as String) as List),
      puntuacion: map['puntuacion'] as int,
      movimientos: map['movimientos'] as int,
      segundosTranscurridos: map['segundos_transcurridos'] as int,
    );
  }
}
