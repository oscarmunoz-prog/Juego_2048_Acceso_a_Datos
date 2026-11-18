import 'dart:math';
import '../models/partida_guardada.dart';

enum Direccion { arriba, abajo, izquierda, derecha }

/// Reglas del 2048. No sabe nada de pantallas ni de base de datos.
class Juego2048 {
  static const int lado = 4;
  final Random _azar = Random();

  List<int> tablero; // 16 casillas, 0 = vacía
  int puntuacion;
  int movimientos;
  int segundos; // lo incrementa el cronómetro de la pantalla

  Juego2048.nueva()
      : tablero = List<int>.filled(lado * lado, 0),
        puntuacion = 0,
        movimientos = 0,
        segundos = 0 {
    _ponerFichaNueva();
    _ponerFichaNueva();
  }

  /// Reconstruye el juego a partir de la partida guardada en la BD.
  Juego2048.desde(PartidaGuardada guardada)
      : tablero = List<int>.from(guardada.tablero),
        puntuacion = guardada.puntuacion,
        movimientos = guardada.movimientos,
        segundos = guardada.segundosTranscurridos;

  int get fichaMaxima => tablero.reduce(max);

  /// Devuelve true si el movimiento ha cambiado algo (solo entonces cuenta y sale ficha nueva).
  bool mover(Direccion direccion) {
    var cambiado = false;
    for (var i = 0; i < lado; i++) {
      final indices = _indicesLinea(direccion, i);
      final nueva = _comprimir([for (final idx in indices) tablero[idx]]);
      for (var j = 0; j < lado; j++) {
        if (tablero[indices[j]] != nueva[j]) {
          tablero[indices[j]] = nueva[j];
          cambiado = true;
        }
      }
    }
    if (cambiado) {
      movimientos++;
      _ponerFichaNueva();
    }
    return cambiado;
  }

  /// Hay movimientos si queda un hueco o dos fichas iguales están juntas.
  bool hayMovimientos() {
    if (tablero.contains(0)) return true;
    for (var fila = 0; fila < lado; fila++) {
      for (var col = 0; col < lado; col++) {
        final valor = tablero[fila * lado + col];
        if (col + 1 < lado && valor == tablero[fila * lado + col + 1]) return true;
        if (fila + 1 < lado && valor == tablero[(fila + 1) * lado + col]) return true;
      }
    }
    return false;
  }

  /// Posiciones de la fila/columna i, empezando por el lado hacia el que se mueven las fichas.
  /// Así las cuatro direcciones se resuelven con la misma función _comprimir.
  List<int> _indicesLinea(Direccion direccion, int i) {
    return switch (direccion) {
      Direccion.izquierda => [for (var j = 0; j < lado; j++) i * lado + j],
      Direccion.derecha => [for (var j = lado - 1; j >= 0; j--) i * lado + j],
      Direccion.arriba => [for (var j = 0; j < lado; j++) j * lado + i],
      Direccion.abajo => [for (var j = lado - 1; j >= 0; j--) j * lado + i],
    };
  }

  /// Junta las fichas y fusiona las iguales: [2,0,2,4] → [4,4,0,0].
  List<int> _comprimir(List<int> linea) {
    final numeros = linea.where((v) => v != 0).toList();
    final resultado = <int>[];
    var k = 0;
    while (k < numeros.length) {
      if (k + 1 < numeros.length && numeros[k] == numeros[k + 1]) {
        final suma = numeros[k] * 2;
        resultado.add(suma);
        puntuacion += suma;
        k += 2; // las dos fichas ya se han usado
      } else {
        resultado.add(numeros[k]);
        k++;
      }
    }
    while (resultado.length < lado) {
      resultado.add(0);
    }
    return resultado;
  }

  /// Pone un 2 (90 %) o un 4 (10 %) en un hueco aleatorio.
  void _ponerFichaNueva() {
    final huecos = [for (var i = 0; i < tablero.length; i++) if (tablero[i] == 0) i];
    if (huecos.isEmpty) return;
    tablero[huecos[_azar.nextInt(huecos.length)]] = _azar.nextDouble() < 0.9 ? 2 : 4;
  }
}
