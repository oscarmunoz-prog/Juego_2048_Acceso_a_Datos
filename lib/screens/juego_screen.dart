import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/partida_dao.dart';
import '../data/partida_guardada_dao.dart';
import '../logic/juego_2048.dart';
import '../models/partida.dart';
import '../models/partida_guardada.dart';
import '../models/usuario.dart';
import '../services/ajustes_controller.dart';
import '../services/preferencias_service.dart';
import '../theme/app_theme.dart';
import 'ajustes_screen.dart';
import 'historial_screen.dart';
import 'ranking_screen.dart';

/// Pantalla de juego básica para generar datos.
/// La versión visual definitiva (gestos, widgets) es de Desarrollo de Interfaces.
class JuegoScreen extends StatefulWidget {
  const JuegoScreen({super.key, required this.usuario, required this.continuar});

  final Usuario usuario;
  final bool continuar; // true = cargar la partida guardada

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

// WidgetsBindingObserver permite saber cuándo la app pasa a segundo plano.
class _JuegoScreenState extends State<JuegoScreen> with WidgetsBindingObserver {
  final _guardadaDao = PartidaGuardadaDao();
  final _partidaDao = PartidaDao();
  final _preferencias = const PreferenciasService();
  Juego2048? _juego; // null mientras se carga
  Timer? _cronometro;
  int _mejor = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciar();
  }

  // Guardado automático al salir de la pantalla de juego.
  @override
  void dispose() {
    _guardar();
    WidgetsBinding.instance.removeObserver(this);
    _cronometro?.cancel();
    super.dispose();
  }

  // Guardado automático al pasar a segundo plano.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _guardar();
  }

  Future<void> _iniciar() async {
    var juego = Juego2048.nueva();
    try {
      if (widget.continuar) {
        final guardada = await _guardadaDao.obtener();
        if (guardada != null) juego = Juego2048.desde(guardada);
      }
      _mejor = await _preferencias.leerMejorPuntuacion();
    } catch (e) {
      _mensaje('$e');
    }
    if (!mounted) return;
    setState(() => _juego = juego);
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _juego != null) setState(() => _juego!.segundos++);
    });
  }

  void _mensaje(String texto) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _guardar() async {
    final juego = _juego;
    if (juego == null) return;
    try {
      await _guardadaDao.guardar(PartidaGuardada(
        tablero: juego.tablero,
        puntuacion: juego.puntuacion,
        movimientos: juego.movimientos,
        segundosTranscurridos: juego.segundos,
      ));
    } catch (e) {
      _mensaje('$e');
    }
  }

  Future<void> _mover(Direccion direccion) async {
    final juego = _juego;
    if (juego == null || !juego.mover(direccion)) return;
    setState(() {
      if (juego.puntuacion > _mejor) _mejor = juego.puntuacion;
    });
    if (!juego.hayMovimientos()) await _terminarPartida();
  }

  /// Guarda la partida en el historial y empieza una nueva.
  /// Se usa al perder y al pulsar el botón de terminar.
  Future<void> _terminarPartida() async {
    final juego = _juego;
    if (juego == null) return;
    // Transacción: insertar en partidas + borrar partida_guardada.
    try {
      await _partidaDao.registrarPartidaTerminada(Partida(
        usuarioId: widget.usuario.id!,
        puntuacion: juego.puntuacion,
        fichaMaxima: juego.fichaMaxima,
        movimientos: juego.movimientos,
        duracionSegundos: juego.segundos,
        fecha: DateTime.now(),
      ));
      await _preferencias.guardarMejorPuntuacionSiEsMayor(juego.puntuacion);
      _mensaje('Partida terminada: ${juego.puntuacion} puntos. Guardada en el historial');
    } catch (e) {
      _mensaje('$e');
    }
    if (mounted) setState(() => _juego = Juego2048.nueva());
  }

  Future<void> _confirmarTerminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminar partida'),
        content: const Text('La partida se guardará en el historial y empezará una nueva.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Terminar')),
        ],
      ),
    );
    if (confirmar == true) await _terminarPartida();
  }

  // Ir a otra pantalla también cuenta como salir del juego, así que se guarda antes.
  Future<void> _abrir(Widget pantalla) async {
    await _guardar();
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final juego = _juego;
    final tema = Theme.of(context);
    final paleta = AjustesScope.of(context).paleta;
    // Flechas del teclado como alternativa a los botones.
    // Focus con autofocus hace que la pantalla reciba las teclas nada más abrirse.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _mover(Direccion.arriba),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _mover(Direccion.abajo),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _mover(Direccion.izquierda),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _mover(Direccion.derecha),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.usuario.usuario),
            actions: [
              IconButton(onPressed: _confirmarTerminar, icon: const Icon(Icons.flag), tooltip: 'Terminar partida'),
              IconButton(onPressed: () => _abrir(const HistorialScreen()), icon: const Icon(Icons.history)),
              IconButton(onPressed: () => _abrir(const RankingScreen()), icon: const Icon(Icons.leaderboard)),
              IconButton(onPressed: () => _abrir(const AjustesScreen()), icon: const Icon(Icons.settings)),
            ],
          ),
          body: juego == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Puntos: ${juego.puntuacion}   Mejor: $_mejor   '
                    'Movs: ${juego.movimientos}   Tiempo: ${juego.segundos}s',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: Juego2048.lado,
                shrinkWrap: true, // necesario dentro de un ListView
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (final valor in juego.tablero) _casilla(valor, paleta, tema),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: () => _mover(Direccion.izquierda), icon: const Icon(Icons.arrow_back)),
                  IconButton(onPressed: () => _mover(Direccion.arriba), icon: const Icon(Icons.arrow_upward)),
                  IconButton(onPressed: () => _mover(Direccion.abajo), icon: const Icon(Icons.arrow_downward)),
                  IconButton(onPressed: () => _mover(Direccion.derecha), icon: const Icon(Icons.arrow_forward)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Los colores salen de AppTheme según la paleta elegida y el modo claro/oscuro.
  Widget _casilla(int valor, PaletaFichas paleta, ThemeData tema) {
    if (valor == 0) return Container(color: AppTheme.colorCasillaVacia(tema));
    final fondo = AppTheme.colorFicha(valor, paleta, tema.brightness);
    return Container(
      color: fondo,
      alignment: Alignment.center,
      child: Text(
        '$valor',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.colorTextoFicha(fondo),
        ),
      ),
    );
  }
}