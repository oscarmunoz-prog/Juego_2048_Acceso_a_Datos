import 'package:sqflite/sqflite.dart';
import '../models/estadisticas.dart';
import '../models/partida.dart';
import 'database_helper.dart';

/// Historial de partidas: CRUD, ranking, estadísticas y filtros.
class PartidaDao {
  static const String _tabla = 'partidas';
  final DatabaseHelper _helper = DatabaseHelper.instance;

  // JOIN con usuarios para tener también el nombre del jugador.
  static const String _consultaBase = '''
    SELECT p.*, u.usuario
    FROM partidas p
    JOIN usuarios u ON u.id = p.usuario_id
  ''';

  /// Ejecuta una operación con la BD abierta y convierte los errores de SQLite
  /// en una Exception con un mensaje legible (evita repetir el try/catch).
  Future<T> _seguro<T>(String accion, Future<T> Function(Database db) operacion) async {
    try {
      return await operacion(await _helper.database);
    } on DatabaseException catch (e) {
      throw Exception('Error al $accion: $e');
    }
  }

  List<Partida> _aPartidas(List<Map<String, dynamic>> filas) {
    return filas.map((fila) => Partida.fromMap(fila)).toList();
  }

  // ───────────── CRUD ─────────────

  Future<int> insertar(Partida partida) {
    return _seguro('guardar la partida', (db) => db.insert(_tabla, partida.toMap()));
  }

  Future<List<Partida>> obtenerHistorial() {
    return _seguro('cargar el historial', (db) async {
      return _aPartidas(await db.rawQuery('$_consultaBase ORDER BY p.fecha DESC'));
    });
  }

  Future<Partida?> obtenerPorId(int id) {
    return _seguro('cargar la partida', (db) async {
      final filas = await db.rawQuery('$_consultaBase WHERE p.id = ?', [id]);
      return filas.isEmpty ? null : Partida.fromMap(filas.first);
    });
  }

  Future<int> eliminar(int id) {
    return _seguro('eliminar la partida',
        (db) => db.delete(_tabla, where: 'id = ?', whereArgs: [id]));
  }

  /// La confirmación del usuario se pide en la pantalla antes de llamar aquí.
  Future<int> eliminarTodo() {
    return _seguro('borrar el historial', (db) => db.delete(_tabla));
  }

  // ───────────── TRANSACCIÓN ─────────────

  /// Al terminar una partida: la guarda en el historial y borra la partida en curso.
  /// Dentro de la transacción se usa txn (no db); si un paso falla, se deshacen los dos.
  Future<int> registrarPartidaTerminada(Partida partida) {
    return _seguro('registrar la partida', (db) {
      return db.transaction<int>((Transaction txn) async {
        final id = await txn.insert(_tabla, partida.toMap());
        await txn.delete('partida_guardada', where: 'id = ?', whereArgs: [1]);
        return id;
      });
    });
  }

  // ───────────── FILTROS, ORDENACIÓN Y AGREGACIONES ─────────────

  Future<List<Partida>> ranking() {
    return _seguro('cargar el ranking', (db) async {
      return _aPartidas(
          await db.rawQuery('$_consultaBase ORDER BY p.puntuacion DESC LIMIT ?', [10]));
    });
  }

  Future<EstadisticasGlobales> estadisticasGlobales() {
    return _seguro('cargar las estadísticas', (db) async {
      // Los alias (AS) son las claves que lee EstadisticasGlobales.fromMap.
      final filas = await db.rawQuery('''
        SELECT COUNT(*) AS partidas,
               MAX(puntuacion) AS max_puntuacion,
               AVG(puntuacion) AS media_puntuacion,
               MAX(ficha_maxima) AS max_ficha,
               SUM(duracion_segundos) AS tiempo_total
        FROM partidas
      ''');
      return EstadisticasGlobales.fromMap(filas.first);
    });
  }

  /// Una fila por jugador con su mejor puntuación y su número de partidas.
  Future<List<EstadisticaJugador>> estadisticasPorJugador() {
    return _seguro('cargar las estadísticas por jugador', (db) async {
      final filas = await db.rawQuery('''
        SELECT u.usuario, MAX(p.puntuacion) AS mejor, COUNT(p.id) AS partidas
        FROM usuarios u
        JOIN partidas p ON p.usuario_id = u.id
        GROUP BY u.id, u.usuario
        ORDER BY mejor DESC
      ''');
      return filas.map((fila) => EstadisticaJugador.fromMap(fila)).toList();
    });
  }

  /// Filtra por nombre (contiene) y/o ficha máxima mínima. Sin filtros = historial completo.
  /// Solo se concatenan trozos fijos con '?'; los valores van siempre aparte.
  Future<List<Partida>> filtrar({String? nombre, int? fichaMinima}) {
    return _seguro('filtrar el historial', (db) async {
      final condiciones = <String>[];
      final argumentos = <Object>[];
      if (nombre != null && nombre.trim().isNotEmpty) {
        condiciones.add('u.usuario LIKE ?');
        argumentos.add('%${nombre.trim()}%');
      }
      if (fichaMinima != null) {
        condiciones.add('p.ficha_maxima >= ?');
        argumentos.add(fichaMinima);
      }
      final where = condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}';
      return _aPartidas(
          await db.rawQuery('$_consultaBase $where ORDER BY p.fecha DESC', argumentos));
    });
  }
}
