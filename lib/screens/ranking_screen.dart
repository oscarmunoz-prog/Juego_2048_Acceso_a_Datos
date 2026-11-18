import 'package:flutter/material.dart';
import '../data/partida_dao.dart';
import '../models/estadisticas.dart';
import '../models/partida.dart';

/// Top 10, estadísticas globales y estadísticas por jugador.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _dao = PartidaDao();
  late final Future<(List<Partida>, EstadisticasGlobales, List<EstadisticaJugador>)> _futuro = _cargar();

  // Devuelve las tres consultas juntas en un record para usar un solo FutureBuilder.
  Future<(List<Partida>, EstadisticasGlobales, List<EstadisticaJugador>)> _cargar() async {
    final top = await _dao.ranking();
    final globales = await _dao.estadisticasGlobales();
    final jugadores = await _dao.estadisticasPorJugador();
    return (top, globales, jugadores);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking y estadísticas')),
      body: FutureBuilder(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
          final (top, g, jugadores) = snapshot.data!;
          return ListView(
            children: [
              const ListTile(title: Text('ESTADÍSTICAS GLOBALES')),
              Text('  Partidas jugadas: ${g.partidasJugadas}'),
              Text('  Puntuación máxima: ${g.puntuacionMaxima}'),
              Text('  Puntuación media: ${g.puntuacionMedia.toStringAsFixed(1)}'),
              Text('  Ficha máxima: ${g.fichaMaxima}'),
              Text('  Tiempo total: ${g.tiempoTotalSegundos ~/ 60} min ${g.tiempoTotalSegundos % 60} s'),
              const ListTile(title: Text('TOP 10')),
              for (var i = 0; i < top.length; i++)
                Text('  ${i + 1}. ${top[i].nombreUsuario} · ${top[i].puntuacion} puntos'),
              const ListTile(title: Text('POR JUGADOR')),
              for (final j in jugadores)
                Text('  ${j.usuario}: mejor ${j.mejorPuntuacion} · ${j.partidas} partidas'),
            ],
          );
        },
      ),
    );
  }
}
