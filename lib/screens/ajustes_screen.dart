import 'package:flutter/material.dart';
import '../services/ajustes_controller.dart';
import '../theme/app_theme.dart';

/// Selección del modo de tema y de los colores de las fichas.
/// Los cambios se ven al momento y se guardan en shared_preferences.
class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ajustes = AjustesScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tema'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro')),
              ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
            ],
            selected: {ajustes.modoTema},
            onSelectionChanged: (s) => ajustes.cambiarModoTema(s.first),
          ),
          const SizedBox(height: 24),
          const Text('Color de las fichas'),
          SegmentedButton<PaletaFichas>(
            segments: [
              for (final p in PaletaFichas.values)
                ButtonSegment(value: p, label: Text(AppTheme.nombrePaleta(p))),
            ],
            selected: {ajustes.paleta},
            onSelectionChanged: (s) => ajustes.cambiarPaleta(s.first),
          ),
        ],
      ),
    );
  }
}
