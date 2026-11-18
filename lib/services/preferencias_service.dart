import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Única clase que accede a SharedPreferences.
/// Los enums se guardan por su nombre (texto) y se recuperan buscándolo.
class PreferenciasService {
  const PreferenciasService();

  static const String _claveModoTema = 'modo_tema';
  static const String _claveColorFichas = 'color_fichas';
  static const String _claveUltimoJugador = 'ultimo_jugador'; // B.3
  static const String _claveMejorPuntuacion = 'mejor_puntuacion'; // B.3

  // ───────────── Tema ─────────────

  Future<void> guardarModoTema(ThemeMode modo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveModoTema, modo.name);
  }

  /// Si no hay nada guardado, se usa el tema del sistema.
  Future<ThemeMode> leerModoTema() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_claveModoTema);
    return ThemeMode.values.firstWhere((m) => m.name == texto, orElse: () => ThemeMode.system);
  }

  // ───────────── Color de las fichas ─────────────

  Future<void> guardarPaletaFichas(PaletaFichas paleta) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveColorFichas, paleta.name);
  }

  Future<PaletaFichas> leerPaletaFichas() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_claveColorFichas);
    return PaletaFichas.values.firstWhere((p) => p.name == texto, orElse: () => PaletaFichas.clasica);
  }

  // ───────────── B.3 (opcional) ─────────────

  Future<void> guardarUltimoJugador(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveUltimoJugador, nombre);
  }

  Future<String?> leerUltimoJugador() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_claveUltimoJugador);
  }

  Future<int> leerMejorPuntuacion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_claveMejorPuntuacion) ?? 0;
  }

  /// Solo guarda si supera el récord actual.
  Future<void> guardarMejorPuntuacionSiEsMayor(int puntuacion) async {
    if (puntuacion <= await leerMejorPuntuacion()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_claveMejorPuntuacion, puntuacion);
  }
}
