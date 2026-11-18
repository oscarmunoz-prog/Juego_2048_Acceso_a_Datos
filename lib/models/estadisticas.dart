/// Resultado de la consulta con COUNT, MAX, AVG y SUM.
class EstadisticasGlobales {
  final int partidasJugadas;
  final int puntuacionMaxima;
  final double puntuacionMedia;
  final int fichaMaxima;
  final int tiempoTotalSegundos;

  const EstadisticasGlobales({
    required this.partidasJugadas,
    required this.puntuacionMaxima,
    required this.puntuacionMedia,
    required this.fichaMaxima,
    required this.tiempoTotalSegundos,
  });

  /// Si no hay partidas, MAX, AVG y SUM devuelven null; en ese caso se usa 0.
  factory EstadisticasGlobales.fromMap(Map<String, dynamic> map) {
    return EstadisticasGlobales(
      partidasJugadas: (map['partidas'] as int?) ?? 0,
      puntuacionMaxima: (map['max_puntuacion'] as int?) ?? 0,
      puntuacionMedia: ((map['media_puntuacion'] as num?) ?? 0).toDouble(),
      fichaMaxima: (map['max_ficha'] as int?) ?? 0,
      tiempoTotalSegundos: (map['tiempo_total'] as int?) ?? 0,
    );
  }
}

/// Una fila del GROUP BY por jugador.
class EstadisticaJugador {
  final String usuario;
  final int mejorPuntuacion;
  final int partidas;

  const EstadisticaJugador({
    required this.usuario,
    required this.mejorPuntuacion,
    required this.partidas,
  });

  factory EstadisticaJugador.fromMap(Map<String, dynamic> map) {
    return EstadisticaJugador(
      usuario: map['usuario'] as String,
      mejorPuntuacion: map['mejor'] as int,
      partidas: map['partidas'] as int,
    );
  }
}
