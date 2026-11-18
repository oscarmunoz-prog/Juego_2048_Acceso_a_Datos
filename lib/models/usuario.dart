/// Fila de la tabla usuarios.
class Usuario {
  final int? id; // null hasta que SQLite lo asigna al insertar
  final String usuario;
  final String email;
  final String contrasena; // hash SHA-256, nunca la contraseña real
  final DateTime fechaRegistro;

  const Usuario({
    this.id,
    required this.usuario,
    required this.email,
    required this.contrasena,
    required this.fechaRegistro,
  });

  /// Las claves coinciden con los nombres de las columnas.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'usuario': usuario,
      'email': email,
      'contrasena': contrasena,
      'fecha_registro': fechaRegistro.toIso8601String(),
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as int,
      usuario: map['usuario'] as String,
      email: map['email'] as String,
      contrasena: map['contrasena'] as String,
      fechaRegistro: DateTime.parse(map['fecha_registro'] as String),
    );
  }
}
