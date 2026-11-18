import 'package:sqflite/sqflite.dart';
import '../models/partida_guardada.dart';
import 'database_helper.dart';

/// Partida en curso (una sola fila, siempre con id = 1).
class PartidaGuardadaDao {
  static const String _tabla = 'partida_guardada';
  final DatabaseHelper _helper = DatabaseHelper.instance;

  /// replace: si ya hay una partida guardada, se sobrescribe.
  Future<void> guardar(PartidaGuardada partida) async {
    try {
      final db = await _helper.database;
      await db.insert(_tabla, partida.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } on DatabaseException catch (e) {
      throw Exception('Error al guardar la partida en curso: $e');
    }
  }

  Future<PartidaGuardada?> obtener() async {
    try {
      final db = await _helper.database;
      final filas = await db.query(_tabla, where: 'id = ?', whereArgs: [1]);
      return filas.isEmpty ? null : PartidaGuardada.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw Exception('Error al cargar la partida en curso: $e');
    }
  }

  Future<void> borrar() async {
    try {
      final db = await _helper.database;
      await db.delete(_tabla, where: 'id = ?', whereArgs: [1]);
    } on DatabaseException catch (e) {
      throw Exception('Error al borrar la partida en curso: $e');
    }
  }

  Future<bool> existe() async => await obtener() != null;
}
