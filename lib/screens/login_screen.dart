import 'package:flutter/material.dart';
import '../data/partida_guardada_dao.dart';
import '../data/usuario_dao.dart';
import '../models/usuario.dart';
import '../services/preferencias_service.dart';
import 'juego_screen.dart';

/// Login y registro. Tras entrar, si hay una partida guardada, ofrece continuarla.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuarioCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final _usuarioDao = UsuarioDao();
  final _guardadaDao = PartidaGuardadaDao();
  final _preferencias = const PreferenciasService();
  bool _esRegistro = false;

  @override
  void initState() {
    super.initState();
    // B.3: rellena el campo con el último jugador.
    _preferencias.leerUltimoJugador().then((nombre) {
      if (nombre != null && mounted) setState(() => _usuarioCtrl.text = nombre);
    });
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _emailCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _enviar() async {
    if (_usuarioCtrl.text.trim().isEmpty || _contrasenaCtrl.text.isEmpty) {
      _mensaje('Rellena usuario y contraseña');
      return;
    }
    try {
      final Usuario? usuario = _esRegistro
          ? await _usuarioDao.registrar(_usuarioCtrl.text, _emailCtrl.text, _contrasenaCtrl.text)
          : await _usuarioDao.login(_usuarioCtrl.text, _contrasenaCtrl.text);
      if (usuario == null) {
        _mensaje('Usuario o contraseña incorrectos');
        return;
      }
      await _preferencias.guardarUltimoJugador(usuario.usuario);

      // A.4 Continuar partida
      var continuar = false;
      if (await _guardadaDao.existe() && mounted) {
        continuar = await _preguntarContinuar() ?? false;
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => JuegoScreen(usuario: usuario, continuar: continuar)),
      );
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool?> _preguntarContinuar() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Partida guardada'),
        content: const Text('¿Quieres continuar la partida guardada o empezar una nueva?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nueva')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_esRegistro ? 'Registro' : 'Login')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _usuarioCtrl,
            decoration: InputDecoration(labelText: _esRegistro ? 'Usuario' : 'Usuario o email'),
          ),
          if (_esRegistro)
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          TextField(
            controller: _contrasenaCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contraseña'),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _enviar, child: Text(_esRegistro ? 'Registrarme' : 'Entrar')),
          TextButton(
            onPressed: () => setState(() => _esRegistro = !_esRegistro),
            child: Text(_esRegistro ? 'Ya tengo cuenta' : 'Crear cuenta nueva'),
          ),
        ],
      ),
    );
  }
}
