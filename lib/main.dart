import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/ajustes_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Necesario para usar plugins (shared_preferences, sqflite) antes de runApp.
  WidgetsFlutterBinding.ensureInitialized();
  // Las preferencias se cargan antes de pintar nada para evitar el parpadeo del tema.
  final ajustes = await AjustesController.cargar();
  runApp(App2048(ajustes: ajustes));
}

class App2048 extends StatelessWidget {
  const App2048({super.key, required this.ajustes});

  final AjustesController ajustes;

  @override
  Widget build(BuildContext context) {
    return AjustesScope(
      controller: ajustes,
      // ListenableBuilder reconstruye MaterialApp cada vez que cambia el tema.
      child: ListenableBuilder(
        listenable: ajustes,
        builder: (context, _) => MaterialApp(
          title: '2048',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro,
          darkTheme: AppTheme.oscuro,
          themeMode: ajustes.modoTema,
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
