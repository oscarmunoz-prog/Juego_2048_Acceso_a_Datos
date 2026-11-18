import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paletas de color de las fichas que puede elegir el usuario.
enum PaletaFichas { clasica, azul, verde, morada }

class AppTheme {
  AppTheme._();

  static const Color _semilla = Color(0xFFEDC22E);

  static final ThemeData claro = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _semilla, brightness: Brightness.light),
  );

  static final ThemeData oscuro = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _semilla, brightness: Brightness.dark),
  );

  static String nombrePaleta(PaletaFichas paleta) {
    return switch (paleta) {
      PaletaFichas.clasica => 'Clásica',
      PaletaFichas.azul => 'Azul',
      PaletaFichas.verde => 'Verde',
      PaletaFichas.morada => 'Morada',
    };
  }

  // Tono de cada paleta en grados del círculo cromático (0-360).
  static double _tono(PaletaFichas paleta) {
    return switch (paleta) {
      PaletaFichas.clasica => 35,
      PaletaFichas.azul => 210,
      PaletaFichas.verde => 130,
      PaletaFichas.morada => 280,
    };
  }

  /// El color depende del valor de la ficha: 2 → nivel 1, 4 → 2, ..., 2048 → 11.
  /// En modo claro las fichas se oscurecen al subir de nivel y en modo oscuro se aclaran,
  /// para que siempre contrasten con el fondo.
  static Color colorFicha(int valor, PaletaFichas paleta, Brightness brillo) {
    final nivel = math.min((math.log(valor) / math.ln2).round(), 11);
    final luz = brillo == Brightness.light ? 0.85 - nivel * 0.05 : 0.22 + nivel * 0.04;
    return HSLColor.fromAHSL(1, _tono(paleta), 0.65, luz).toColor();
  }

  /// Texto negro sobre fondos claros y blanco sobre fondos oscuros.
  static Color colorTextoFicha(Color fondo) {
    return fondo.computeLuminance() > 0.45 ? Colors.black87 : Colors.white;
  }

  static Color colorCasillaVacia(ThemeData tema) => tema.colorScheme.surfaceContainerHighest;
}
