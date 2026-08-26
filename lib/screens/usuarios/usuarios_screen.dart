import 'package:flutter/material.dart';

import '../../models/rol.dart';
import '../../models/usuario.dart';
import '../../services/rol_service.dart';
import '../../services/usuario_service.dart';
import '../../utils/storage.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Usuario> _usuarios = [];
  List<Rol> _roles = [];

  bool _cargando = true;
  String? _error;

  String? _rolActual;
  int? _usuarioIdActual;

  bool get _esAdmin => _rolActual == 'ADMIN';

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
      final rolActual = await Storage.obtenerRol();
      final usuarioIdActual = await Storage.obtenerUsuarioId();

      if (rolActual != 'ADMIN') {
        if (!mounted) return;

        setState(() {
          _rolActual = rolActual;
          _usuarioIdActual = usuarioIdActual;
          _error = 'No tiene permisos para administrar usuarios.';
        });

        return;
      }

      final resultados = await Future.wait([
        UsuarioService.getUsuarios(),
        RolService.getRoles(),
      ]);

      if (!mounted) return;

      setState(() {
        _rolActual = rolActual;
        _usuarioIdActual = usuarioIdActual;

        _usuarios = resultados[0] as List<Usuario>;
        _roles = resultados[1] as List<Rol>;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  String _nombreRol(int rolId) {
    for (final rol in _roles) {
      if (rol.id == rolId) {
        return rol.nombre;
      }
    }

    return 'Rol $rolId';
  }

  Future<void> _cambiarRol(Usuario usuario) async {
    if (!_esAdmin || usuario.id == null) {
      return;
    }

    if (usuario.id == _usuarioIdActual) {
      _mostrarMensaje('No puede cambiar su propio rol desde esta pantalla.');
      return;
    }

    int rolSeleccionado = usuario.rolId;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cambiar rol'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nombreCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(usuario.email),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      initialValue: rolSeleccionado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: _roles
                          .map(
                            (rol) => DropdownMenuItem<int>(
                              value: rol.id,
                              child: Text(rol.nombre),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          rolSeleccionado = value;
                        });
                      },
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
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmado != true) return;

    if (rolSeleccionado == usuario.rolId) {
      _mostrarMensaje('El usuario ya tiene ese rol.');
      return;
    }

    try {
      await UsuarioService.cambiarRol(usuario.id!, rolSeleccionado);

      if (!mounted) return;

      _mostrarMensaje('Rol actualizado correctamente.');

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
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarDatos,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 60),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarDatos,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_usuarios.isEmpty) {
      return const Center(
        child: Text(
          'No hay usuarios registrados.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _usuarios.length,
        itemBuilder: (context, index) {
          final usuario = _usuarios[index];

          final esUsuarioActual = usuario.id == _usuarioIdActual;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  usuario.nombre.isNotEmpty
                      ? usuario.nombre[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      usuario.nombreCompleto,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (esUsuarioActual)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Chip(label: Text('Tu usuario')),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(usuario.email),
                    const SizedBox(height: 4),
                    Text('Rol: ${_nombreRol(usuario.rolId)}'),
                    Text(
                      usuario.activo ? 'Estado: Activo' : 'Estado: Inactivo',
                    ),
                  ],
                ),
              ),
              trailing: !esUsuarioActual
                  ? IconButton(
                      icon: const Icon(Icons.manage_accounts),
                      tooltip: 'Cambiar rol',
                      onPressed: () => _cambiarRol(usuario),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
