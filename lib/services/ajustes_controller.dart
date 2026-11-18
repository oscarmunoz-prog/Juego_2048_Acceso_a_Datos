import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'preferencias_service.dart';

/// Guarda el tema y la paleta actuales. Al cambiar, avisa con notifyListeners()
/// y la app se redibuja al momento, sin reiniciar.
class AjustesController extends ChangeNotifier {
  AjustesController({required ThemeMode modoInicial, required PaletaFichas paletaInicial})
      : _modoTema = modoInicial,
        _paleta = paletaInicial;

  final PreferenciasService _servicio = const PreferenciasService();
  ThemeMode _modoTema;
  PaletaFichas _paleta;

  ThemeMode get modoTema => _modoTema;
  PaletaFichas get paleta => _paleta;

  /// Se llama en main() antes de runApp para no ver el tema equivocado al arrancar.
  static Future<AjustesController> cargar() async {
    const servicio = PreferenciasService();
    return AjustesController(
      modoInicial: await servicio.leerModoTema(),
      paletaInicial: await servicio.leerPaletaFichas(),
    );
  }

  Future<void> cambiarModoTema(ThemeMode nuevo) async {
    if (nuevo == _modoTema) return;
    _modoTema = nuevo;
    notifyListeners();
    await _servicio.guardarModoTema(nuevo);
  }

  Future<void> cambiarPaleta(PaletaFichas nueva) async {
    if (nueva == _paleta) return;
    _paleta = nueva;
    notifyListeners();
    await _servicio.guardarPaletaFichas(nueva);
  }
}

/// Hace accesible el controlador desde cualquier pantalla con AjustesScope.of(context).
/// Los widgets que lo usan se redibujan cuando el controlador cambia.
class AjustesScope extends InheritedNotifier<AjustesController> {
  const AjustesScope({super.key, required AjustesController controller, required super.child})
      : super(notifier: controller);

  static AjustesController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AjustesScope>()!.notifier!;
  }
}
