import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import '../models/usuario.dart';
import 'database_helper.dart';

/// Registro y login de usuarios.
class UsuarioDao {
  static const String _tabla = 'usuarios';
  final DatabaseHelper _helper = DatabaseHelper.instance;

  /// Hash SHA-256: la contraseña real nunca se guarda en la base de datos.
  static String encriptar(String contrasena) {
    return sha256.convert(utf8.encode(contrasena)).toString();
  }

  /// Formato texto@dominio.ext, sin espacios.
  static bool emailValido(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  Future<Usuario> registrar(String usuario, String email, String contrasena) async {
    if (!emailValido(email)) throw Exception('El email no es válido');
    try {
      final db = await _helper.database;
      final nuevo = Usuario(
        usuario: usuario.trim(),
        email: email.trim().toLowerCase(),
        contrasena: encriptar(contrasena),
        fechaRegistro: DateTime.now(),
      );
      final id = await db.insert(_tabla, nuevo.toMap());
      return Usuario.fromMap({...nuevo.toMap(), 'id': id});
    } on DatabaseException catch (e) {
      // Salta por las restricciones UNIQUE de usuario y email.
      if (e.isUniqueConstraintError()) throw Exception('Ese usuario o email ya existe');
      throw Exception('Error al registrar: $e');
    }
  }

  /// Devuelve el usuario si las credenciales son correctas, o null si no.
  /// Se puede entrar con el nombre de usuario o con el email.
  Future<Usuario?> login(String usuarioOEmail, String contrasena) async {
    try {
      final db = await _helper.database;
      final texto = usuarioOEmail.trim();
      final filas = await db.query(
        _tabla,
        where: '(usuario = ? OR email = ?) AND contrasena = ?',
        whereArgs: [texto, texto.toLowerCase(), encriptar(contrasena)],
        limit: 1,
      );
      return filas.isEmpty ? null : Usuario.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }
}
