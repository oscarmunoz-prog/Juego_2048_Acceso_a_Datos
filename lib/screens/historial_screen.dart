import 'package:flutter/material.dart';
import '../data/partida_dao.dart';
import '../models/partida.dart';

/// Historial de partidas con filtros y borrado.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _dao = PartidaDao();
  final _nombreCtrl = TextEditingController();
  int? _fichaMinima; // null = sin filtro
  late Future<List<Partida>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _dao.obtenerHistorial();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  // Asignar un Future nuevo hace que el FutureBuilder vuelva a consultar.
  void _recargar() {
    setState(() => _futuro = _dao.filtrar(nombre: _nombreCtrl.text, fichaMinima: _fichaMinima));
  }

  void _mensaje(String texto) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _eliminar(Partida partida) async {
    try {
      await _dao.eliminar(partida.id!);
      _mensaje('Partida eliminada');
    } catch (e) {
      _mensaje('$e');
    }
    _recargar();
  }

  Future<void> _eliminarTodo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar todo el historial'),
        content: const Text('¿Seguro? Se eliminarán todas las partidas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _dao.eliminarTodo();
      _mensaje('Historial borrado');
    } catch (e) {
      _mensaje('$e');
    }
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [IconButton(onPressed: _eliminarTodo, icon: const Icon(Icons.delete_sweep))],
      ),
      body: Column(
        children: [
          _filtros(),
          Expanded(
            child: FutureBuilder<List<Partida>>(
              future: _futuro,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
                final partidas = snapshot.data ?? [];
                if (partidas.isEmpty) return const Center(child: Text('No hay partidas'));
                return ListView.builder(
                  itemCount: partidas.length,
                  itemBuilder: (context, i) {
                    final p = partidas[i];
                    return ListTile(
                      title: Text('${p.nombreUsuario} · ${p.puntuacion} puntos · ficha ${p.fichaMaxima}'),
                      subtitle: Text(
                          '${p.fecha.toString().substring(0, 16)} · ${p.movimientos} movs · ${p.duracionSegundos}s'),
                      trailing: IconButton(onPressed: () => _eliminar(p), icon: const Icon(Icons.delete)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Jugador'),
              onSubmitted: (_) => _recargar(),
            ),
          ),
          DropdownButton<int?>(
            value: _fichaMinima,
            items: const [
              DropdownMenuItem(value: null, child: Text('Todas')),
              DropdownMenuItem(value: 512, child: Text('≥ 512')),
              DropdownMenuItem(value: 1024, child: Text('≥ 1024')),
              DropdownMenuItem(value: 2048, child: Text('≥ 2048')),
            ],
            onChanged: (valor) {
              _fichaMinima = valor;
              _recargar();
            },
          ),
        ],
      ),
    );
  }
}
