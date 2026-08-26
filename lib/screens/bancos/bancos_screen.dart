import 'package:flutter/material.dart';

import '../../models/banco.dart';
import '../../services/banco_service.dart';
import '../../utils/storage.dart';

class BancosScreen extends StatefulWidget {
  const BancosScreen({super.key});

  @override
  State<BancosScreen> createState() => _BancosScreenState();
}

class _BancosScreenState extends State<BancosScreen> {
  bool _cargando = true;
  String? _error;
  String? _rol;

  List<Banco> _bancos = [];

  bool get _puedeCrear =>
      _rol == 'ADMIN' || _rol == 'OPERADOR' || _rol == 'CLIENTE';

  bool get _puedeEliminar => _rol == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final rol = await Storage.obtenerRol();
      final bancos = await BancoService.getBancos();

      if (!mounted) return;

      setState(() {
        _rol = rol;
        _bancos = bancos;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar los bancos';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<void> _mostrarFormularioBanco() async {
    if (!_puedeCrear) return;

    final nombreController = TextEditingController();
    final codigoController = TextEditingController();

    final creado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nuevo banco'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.account_balance),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = nombreController.text.trim();

                final codigo = codigoController.text.trim();

                if (nombre.isEmpty || codigo.isEmpty) {
                  _mostrarMensaje('Complete nombre y código.');
                  return;
                }

                try {
                  final banco = Banco(nombre: nombre, codigo: codigo);

                  await BancoService.crearBanco(banco);

                  if (!dialogContext.mounted) {
                    return;
                  }

                  Navigator.of(dialogContext).pop(true);
                } catch (e) {
                  if (!mounted) return;

                  _mostrarMensaje(e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    nombreController.dispose();
    codigoController.dispose();

    if (creado != true || !mounted) {
      return;
    }

    _mostrarMensaje('Banco creado correctamente.');

    await _cargarDatos();
  }

  Future<void> _eliminarBanco(Banco banco) async {
    if (!_puedeEliminar || banco.id == null) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar banco'),
          content: Text(
            '¿Está seguro de eliminar '
            '"${banco.nombre}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await BancoService.eliminarBanco(banco.id!);

      if (!mounted) return;

      _mostrarMensaje('Banco eliminado correctamente.');

      await _cargarDatos();
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bancos'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarDatos,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: _puedeCrear
          ? FloatingActionButton.extended(
              onPressed: _mostrarFormularioBanco,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo'),
            )
          : null,
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarDatos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_bancos.isEmpty) {
      return const Center(
        child: Text(
          'No hay bancos registrados',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bancos.length,
        itemBuilder: (context, index) {
          final banco = _bancos[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.account_balance)),
              title: Text(
                banco.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Código: ${banco.codigo}'),
              trailing: _puedeEliminar && banco.id != null
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Eliminar',
                      onPressed: () => _eliminarBanco(banco),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
