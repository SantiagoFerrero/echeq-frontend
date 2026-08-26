import 'package:flutter/material.dart';

import '../../models/banco.dart';
import '../../models/cuenta.dart';
import '../../models/cuenta_banco.dart';
import '../../models/usuario.dart';
import '../../services/banco_service.dart';
import '../../services/cuenta_banco_service.dart';
import '../../services/cuenta_service.dart';
import '../../services/usuario_service.dart';
import '../../utils/storage.dart';

class CuentasBancoScreen extends StatefulWidget {
  const CuentasBancoScreen({super.key});

  @override
  State<CuentasBancoScreen> createState() => _CuentasBancoScreenState();
}

class _CuentasBancoScreenState extends State<CuentasBancoScreen> {
  List<CuentaBanco> _cuentasBanco = [];
  List<Cuenta> _cuentas = [];
  List<Banco> _bancos = [];
  List<Usuario> _clientes = [];

  bool _cargando = true;
  String? _error;
  String? _rol;

  bool get _esCliente => _rol == 'CLIENTE';

  bool get _puedeGestionar =>
      _rol == 'ADMIN' || _rol == 'OPERADOR';

  bool get _puedeCrear => _esCliente || _puedeGestionar;

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

      final cuentasBanco = await CuentaBancoService.getCuentasBanco();

      List<Cuenta> cuentas = [];
      List<Banco> bancos = [];
      List<Usuario> clientes = [];

      if (rol == 'CLIENTE') {
        cuentas = await CuentaService.getCuentas();
        bancos = await BancoService.getBancos();
      }

      if (rol == 'ADMIN' || rol == 'OPERADOR') {
        cuentas = await CuentaService.getCuentas();
        bancos = await BancoService.getBancos();
        clientes = await UsuarioService.getClientesActivos();
      }

      if (!mounted) return;

      setState(() {
        _rol = rol;
        _cuentasBanco = cuentasBanco;
        _cuentas = cuentas;
        _bancos = bancos;
        _clientes = clientes;
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

  Future<void> _crearMiCuentaBanco() async {
    if (!_esCliente) return;

    if (_cuentas.isEmpty) {
      _mostrarMensaje('Primero debe registrar una cuenta.');
      return;
    }

    if (_bancos.isEmpty) {
      _mostrarMensaje('No hay bancos registrados.');
      return;
    }

    int? cuentaSeleccionada;
    int? bancoSeleccionado;

    final creada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva Cuenta Banco'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 430,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: cuentaSeleccionada,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Mi cuenta',
                          prefixIcon:
                              Icon(Icons.account_balance_wallet),
                          border: OutlineInputBorder(),
                        ),
                        items: _cuentas
                            .where((cuenta) => cuenta.id != null)
                            .map(
                              (cuenta) => DropdownMenuItem<int>(
                                value: cuenta.id!,
                                child: Text(
                                  '${cuenta.numero} - \$${cuenta.saldo.toStringAsFixed(2)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            cuentaSeleccionada = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _dropdownBanco(
                        bancoSeleccionado,
                        (value) {
                          setDialogState(() {
                            bancoSeleccionado = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (cuentaSeleccionada == null ||
                        bancoSeleccionado == null) {
                      _mostrarMensaje(
                        'Seleccione una cuenta y un banco.',
                      );
                      return;
                    }

                    try {
                      await CuentaBancoService.crearMiCuentaBanco(
                        cuentaId: cuentaSeleccionada!,
                        bancoId: bancoSeleccionado!,
                      );

                      if (!context.mounted) return;

                      Navigator.of(dialogContext).pop(true);
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e
                                .toString()
                                .replaceFirst('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    if (creada != true || !mounted) return;

    _mostrarMensaje('Cuenta Banco creada correctamente.');
    await _cargarDatos();
  }

  Future<void> _crearCuentaBancoGestion() async {
    if (!_puedeGestionar) return;

    if (_clientes.isEmpty) {
      _mostrarMensaje('No hay clientes activos disponibles.');
      return;
    }

    if (_bancos.isEmpty) {
      _mostrarMensaje('No hay bancos registrados.');
      return;
    }

    int? clienteSeleccionado;
    int? cuentaSeleccionada;
    int? bancoSeleccionado;

    final creada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cuentasCliente = clienteSeleccionado == null
                ? <Cuenta>[]
                : _cuentas
                    .where(
                      (cuenta) =>
                          cuenta.usuarioId == clienteSeleccionado,
                    )
                    .toList();

            return AlertDialog(
              title: const Text('Nueva Cuenta Banco'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 460,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: clienteSeleccionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Cliente',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        items: _clientes
                            .where((cliente) => cliente.id != null)
                            .map(
                              (cliente) => DropdownMenuItem<int>(
                                value: cliente.id!,
                                child: Text(
                                  '${cliente.nombreCompleto} - ${cliente.email}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            clienteSeleccionado = value;
                            cuentaSeleccionada = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: cuentaSeleccionada,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Cuenta',
                          prefixIcon: const Icon(
                            Icons.account_balance_wallet,
                          ),
                          border: const OutlineInputBorder(),
                          helperText: clienteSeleccionado == null
                              ? 'Primero seleccione un cliente'
                              : cuentasCliente.isEmpty
                                  ? 'El cliente no tiene cuentas'
                                  : null,
                        ),
                        items: cuentasCliente
                            .where((cuenta) => cuenta.id != null)
                            .map(
                              (cuenta) => DropdownMenuItem<int>(
                                value: cuenta.id!,
                                child: Text(
                                  '${cuenta.numero} - \$${cuenta.saldo.toStringAsFixed(2)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: clienteSeleccionado == null ||
                                cuentasCliente.isEmpty
                            ? null
                            : (value) {
                                setDialogState(() {
                                  cuentaSeleccionada = value;
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      _dropdownBanco(
                        bancoSeleccionado,
                        (value) {
                          setDialogState(() {
                            bancoSeleccionado = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (clienteSeleccionado == null ||
                        cuentaSeleccionada == null ||
                        bancoSeleccionado == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Seleccione cliente, cuenta y banco.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await CuentaBancoService.crear(
                        cuentaId: cuentaSeleccionada!,
                        bancoId: bancoSeleccionado!,
                      );

                      if (!context.mounted) return;

                      Navigator.of(dialogContext).pop(true);
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e
                                .toString()
                                .replaceFirst('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    if (creada != true || !mounted) return;

    _mostrarMensaje('Cuenta Banco creada correctamente.');
    await _cargarDatos();
  }

  Widget _dropdownBanco(
    int? valor,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: valor,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Banco',
        prefixIcon: Icon(Icons.account_balance),
        border: OutlineInputBorder(),
      ),
      items: _bancos
          .where((banco) => banco.id != null)
          .map(
            (banco) => DropdownMenuItem<int>(
              value: banco.id!,
              child: Text(
                '${banco.nombre} (${banco.codigo})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _crearCuentaBanco() async {
    if (_esCliente) {
      await _crearMiCuentaBanco();
      return;
    }

    if (_puedeGestionar) {
      await _crearCuentaBancoGestion();
    }
  }

  Future<void> _cambiarEstado(CuentaBanco cuentaBanco) async {
    if (!_puedeGestionar) return;

    String estadoSeleccionado = cuentaBanco.estado;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cambiar estado'),
              content: DropdownButtonFormField<String>(
                initialValue: estadoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ACTIVA',
                    child: Text('ACTIVA'),
                  ),
                  DropdownMenuItem(
                    value: 'INACTIVA',
                    child: Text('INACTIVA'),
                  ),
                  DropdownMenuItem(
                    value: 'BLOQUEADA',
                    child: Text('BLOQUEADA'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setDialogState(() {
                    estadoSeleccionado = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado != true) return;

    try {
      await CuentaBancoService.actualizarEstado(
        id: cuentaBanco.id,
        estado: estadoSeleccionado,
      );

      _mostrarMensaje('Estado actualizado correctamente.');
      await _cargarDatos();
    } catch (e) {
      _mostrarMensaje(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _eliminar(CuentaBanco cuentaBanco) async {
    if (!_puedeGestionar) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Cuenta Banco'),
          content: Text(
            '¿Desea eliminar la relación de la cuenta '
            '${cuentaBanco.numeroCuenta} con '
            '${cuentaBanco.nombreBanco}?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await CuentaBancoService.eliminar(cuentaBanco.id);

      _mostrarMensaje('Cuenta Banco eliminada.');
      await _cargarDatos();
    } catch (e) {
      _mostrarMensaje(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarDatos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cuentasBanco.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarDatos,
        child: ListView(
          children: [
            const SizedBox(height: 160),
            const Icon(
              Icons.account_balance_outlined,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No hay cuentas banco para mostrar.',
              ),
            ),
            if (_puedeCrear) ...[
              const SizedBox(height: 8),
              const Center(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Puede crear una con el botón "Nueva".',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cuentasBanco.length,
        itemBuilder: (context, index) {
          final cuentaBanco = _cuentasBanco[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.account_balance),
              ),
              title: Text(
                cuentaBanco.numeroCuenta,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (!_esCliente)
                      Text(
                        'Usuario: ${cuentaBanco.usuarioNombre}',
                      ),
                    Text(
                      'Banco: ${cuentaBanco.nombreBanco}',
                    ),
                    Text(
                      'Estado: ${cuentaBanco.estado}',
                    ),
                    Text(
                      'Fecha de alta: ${cuentaBanco.fechaAlta}',
                    ),
                  ],
                ),
              ),
              trailing: _puedeGestionar
                  ? PopupMenuButton<String>(
                      onSelected: (opcion) {
                        if (opcion == 'estado') {
                          _cambiarEstado(cuentaBanco);
                        }

                        if (opcion == 'eliminar') {
                          _eliminar(cuentaBanco);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'estado',
                          child: Text('Cambiar estado'),
                        ),
                        PopupMenuItem(
                          value: 'eliminar',
                          child: Text('Eliminar'),
                        ),
                      ],
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas Banco'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarDatos,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _construirContenido(),
      floatingActionButton: _puedeCrear
          ? FloatingActionButton.extended(
              onPressed: _crearCuentaBanco,
              icon: const Icon(Icons.add),
              label: const Text('Nueva'),
            )
          : null,
    );
  }
}