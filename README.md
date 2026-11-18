# 2048 en Flutter: Acceso a Datos

Práctica final de Acceso a Datos: el juego 2048 hecho con Flutter y Dart. Lo que se evalúa en este módulo es la capa de datos, es decir, cómo la app guarda, recupera y consulta información de forma persistente.

Se usan dos mecanismos de persistencia:

| Mecanismo            | Para qué se usa 
| sqflite (SQLite) | Usuarios, historial de partidas, partida en curso y estadísticas |
| shared_preferences | Tema (claro / oscuro / sistema), color de las fichas, último jugador y mejor puntuación |

> La parte visual (widgets reutilizables, gestos, rutas, animaciones) corresponde a Desarrollo de Interfaces y la hace mi compañero de grupo. La pantalla de juego que hay aquí es una versión sencilla, solo para poder generar y probar los datos.

---

## Cómo ejecutarlo

1. Instalar las dependencias:
   
   flutter pub add sqflite path shared_preferences crypto
 
2. En Windows, activar el Modo de desarrollador, porque lo necesitan los plugins.
3. Ejecutar en un emulador o móvil Android. sqflite no funciona en web.


## Estructura de carpetas

lib/
├── main.dart                     → Carga las preferencias antes de runApp y aplica el tema
├── data/                         → Capa de acceso a datos (el ÚNICO sitio con SQL)
│   ├── database_helper.dart      → Singleton: abre game2048.db, crea tablas y migra
│   ├── usuario_dao.dart          → Registro y login (contraseña encriptada)
│   ├── partida_dao.dart          → CRUD, ranking, estadísticas, filtros y transacción
│   └── partida_guardada_dao.dart → Guardar / recuperar / borrar la partida en curso
├── models/                       → Clases con toMap() y fromMap()
│   ├── usuario.dart
│   ├── partida.dart
│   ├── partida_guardada.dart
│   └── estadisticas.dart         → Resultados de COUNT/MAX/AVG/SUM y GROUP BY
├── services/
│   ├── preferencias_service.dart → Única clase que toca SharedPreferences
│   └── ajustes_controller.dart   → ChangeNotifier: cambio de tema en tiempo real
├── theme/
│   └── app_theme.dart            → Temas claro/oscuro y colores de las fichas
├── logic/
│   └── juego_2048.dart           → Reglas del juego (mover, fusionar, fin de partida)
└── screens/
    ├── login_screen.dart         → Login, registro y "¿continuar partida?"
    ├── juego_screen.dart         → Partida + guardado automático
    ├── historial_screen.dart     → Lista, filtros y borrado
    ├── ranking_screen.dart       → Top 10 y estadísticas
    └── ajustes_screen.dart       → Tema y color de fichas


## Modelo de datos (game2048.db)

┌──────────────────────┐          ┌───────────────────────────┐
│ usuarios             │          │ partidas                  │
├──────────────────────┤          ├───────────────────────────┤
│ id  PK AUTOINCREMENT │◄────┐    │ id  PK AUTOINCREMENT      │
│ usuario  TEXT UNIQUE │     └────│ usuario_id  FK            │
│ email    TEXT UNIQUE │          │ puntuacion        INTEGER │
│ contrasena  TEXT     │          │ ficha_maxima      INTEGER │
│ fecha_registro TEXT  │          │ movimientos       INTEGER │
└──────────────────────┘          │ duracion_segundos INTEGER │
                                  │ fecha             TEXT    │
┌──────────────────────────────┐  │ tamano_tablero (v2) INT   │
│ partida_guardada             │  └───────────────────────────┘
├──────────────────────────────┤
│ id  PK  CHECK (id = 1)       │   ← solo puede existir una fila
│ tablero  TEXT (JSON)         │   ← [2,0,4,0,...] 16 valores
│ puntuacion  INTEGER          │
│ movimientos INTEGER          │
│ segundos_transcurridos INT   │
└──────────────────────────────┘

### Cambios respecto al enunciado

- Normalización: `partidas` guarda `usuario_id` (clave foránea a `usuarios.id`) en vez del nombre como texto. Así el nombre está en un solo sitio. Las claves foráneas se activan con `PRAGMA foreign_keys = ON` en `onConfigure`. Con `ON DELETE CASCADE`, si se borra un usuario se borran sus partidas.
- `contrasena` sin ñ: se evitan problemas de codificación en los nombres de columna.
- `UNIQUE` en usuario y email: no puede haber dos cuentas iguales, y el login por nombre o email nunca es ambiguo.
- `CHECK (id = 1)`: garantiza desde la propia BD que solo hay una partida en curso.
- Las fechas se guardan como texto ISO 8601 (`2026-11-18T16:30:00.000`).


## Arquitectura de la capa de datos


Pantallas (screens/)  ──llaman a──►  DAOs (data/)  ──usan──►  DatabaseHelper  ──►  game2048.db
        │                                 │
        └── nunca contienen SQL           └── convierten filas ↔ objetos con los modelos


- DatabaseHelper: constructor privado + `static final instance`. Toda la app comparte una única conexión. El getter `database` la abre solo la primera vez.
- Modelos: `toMap()` convierte el objeto en un Map para `insert`, y `fromMap()` convierte una fila del `SELECT` en objeto.
- DAOs: encapsulan TODO el SQL. Las pantallas solo llaman a métodos como `obtenerHistorial()` o `ranking()`.
- Consultas parametrizadas: todos los valores van con `?` y `whereArgs` / argumentos de `rawQuery`. Nunca se concatenan datos del usuario dentro del SQL (evita la inyección SQL). En `filtrar()` solo se concatenan trozos fijos como `'u.usuario LIKE ?'`, y los valores van aparte.
- Asincronía y errores: todos los métodos devuelven `Future` y usan `async/await`. Las `DatabaseException` se capturan con `try/catch` y se relanzan con un mensaje claro, que la pantalla muestra en un `SnackBar`.
- Seguridad: la contraseña se guarda como hash **SHA-256** (paquete `crypto`) y el email se valida con una expresión regular (tiene que tener `@` y dominio) antes de insertarlo.

### Transacción

`PartidaDao.registrarPartidaTerminada()` usa `db.transaction`. Al terminar una partida, inserta la fila en `partidas` y borra la de `partida_guardada`. Si un paso falla, SQLite deshace los dos, así que nunca queda la partida en el historial y a la vez guardada como "en curso".

### Operaciones

| Operación        | Método                | SQL clave |

| Insertar partida | `PartidaDao.insertar` | `INSERT` |
| Historial completo | `obtenerHistorial` | `ORDER BY fecha DESC` |
| Detalle por id | `obtenerPorId` | `WHERE p.id = ?` |
| Eliminar una | `eliminar` | `DELETE ... WHERE id = ?` |
| Eliminar todo (con confirmación) | `eliminarTodo` | `DELETE FROM partidas` |
| Partida en curso | `PartidaGuardadaDao.guardar / obtener / borrar` | `INSERT OR REPLACE` |
| Ranking | `ranking` | `ORDER BY puntuacion DESC LIMIT 10` |
| Estadísticas globales | `estadisticasGlobales` | `COUNT, MAX, AVG, SUM` |
| Por jugador | `estadisticasPorJugador` | `JOIN + GROUP BY` |
| Filtro | `filtrar` | `LIKE ?` y `ficha_maxima >= ?` |


## Preferencias con shared_preferences

- `PreferenciasService`: las claves son constantes privadas (`_claveModoTema`, `_claveColorFichas`...), nunca cadenas repetidas. Tiene los métodos `guardarModoTema(ThemeMode)` y `leerModoTema()`, que devuelve `ThemeMode.system` si no hay nada guardado.
- Sin parpadeo: en `main()` se llama a `WidgetsFlutterBinding.ensureInitialized()` y se hace `await AjustesController.cargar()` antes de `runApp`.
- Tiempo real: `AjustesController` es un `ChangeNotifier`. `MaterialApp` está dentro de un `ListenableBuilder`, así que al cambiar el tema hace `notifyListeners()` y toda la app se redibuja sin reiniciarse.
- Tema: `MaterialApp(theme: AppTheme.claro, darkTheme: AppTheme.oscuro, themeMode: ...)`.
- Colores de las fichas: 4 paletas (clásica, azul, verde, morada). En modo claro las fichas se oscurecen según su valor, y en modo oscuro se aclaran. El número sale en blanco o negro según el fondo, así que se lee en ambos modos.
- Ampliación: se guardan el último jugador (rellena el login) y la mejor puntuación (se muestra en el juego).

## Interfaz relacionada con los datos

- Login / registro: entrar con usuario o email, o darse de alta.
- Continuar partida: al entrar, si existe una fila en `partida_guardada`, un diálogo pregunta si continuar o empezar una nueva.
- Guardado automático: la pantalla de juego guarda la partida al pasar a segundo plano (`WidgetsBindingObserver`, estado `paused`), al ir a otra pantalla y al cerrarse (`dispose`).
- Historial: lista con filtros por jugador y ficha mínima, botón para borrar cada partida y botón para borrar todo (con confirmación).
- Ranking y estadísticas: top 10, estadísticas globales y estadísticas por jugador.
