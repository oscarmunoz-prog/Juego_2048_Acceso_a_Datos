import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Abre la base de datos game2048.db, crea las tablas y aplica las migraciones.
/// Es un singleton: toda la app comparte una única conexión.
class DatabaseHelper {
  static const String _nombreBD = 'game2048.db';

  // Migración: cambiar a 2 al final del desarrollo para añadir tamano_tablero.
  static const int _version = 1;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  /// Devuelve la conexión, abriéndola solo la primera vez.
  Future<Database> get database async {
    _db ??= await _abrir();
    return _db!;
  }

  Future<Database> _abrir() async {
    final ruta = join(await getDatabasesPath(), _nombreBD);
    return openDatabase(
      ruta,
      version: _version,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // SQLite trae las claves foráneas desactivadas por defecto.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Instalación nueva: se crean las tablas de la v1 y se aplican las migraciones
  // pendientes, para acabar con el mismo esquema que quien actualiza.
  Future<void> _onCreate(Database db, int version) async {
    await _crearTablasVersion1(db);
    await _onUpgrade(db, 1, version);
  }

  Future<void> _crearTablasVersion1(Database db) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        contrasena TEXT NOT NULL,
        fecha_registro TEXT NOT NULL
      )
    ''');

    // usuario_id → usuarios.id (modelo normalizado)
    await db.execute('''
      CREATE TABLE partidas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        puntuacion INTEGER NOT NULL,
        ficha_maxima INTEGER NOT NULL,
        movimientos INTEGER NOT NULL,
        duracion_segundos INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
      )
    ''');

    // CHECK (id = 1): solo puede existir una partida en curso.
    await db.execute('''
      CREATE TABLE partida_guardada (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        tablero TEXT NOT NULL,
        puntuacion INTEGER NOT NULL,
        movimientos INTEGER NOT NULL,
        segundos_transcurridos INTEGER NOT NULL
      )
    ''');
  }

  /// Cada migración va en su propio if, así se pueden encadenar (1→2→3...).
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      // ADD COLUMN no borra filas: las partidas existentes reciben el valor 4.
      await db.execute(
        'ALTER TABLE partidas ADD COLUMN tamano_tablero INTEGER NOT NULL DEFAULT 4',
      );
    }
  }
}
