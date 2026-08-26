import 'package:flutter/material.dart';

import '../../models/banco.dart';
import '../../models/cuenta.dart';
import '../../models/usuario.dart';
import '../../services/banco_service.dart';
import '../../services/cuenta_service.dart';
import '../../services/usuario_service.dart';
import '../../utils/storage.dart';

class CuentasScreen extends StatefulWidget {
  const CuentasScreen({super.key});

  @override
  State<CuentasScreen> createState() => _CuentasScreenState();
}

class _CuentasScreenState extends State<CuentasScreen> {
  bool _cargando = true;
  String? _error;
  String? _rol;

  List<Cuenta> _cuentas = [];
  List<Banco> _bancos = [];
  List<Usuario> _clientes = [];

  bool get _esCliente => _rol == 'CLIENTE';

  bool get _esAdminOperador =>
      _rol == 'ADMIN' || _rol == 'OPERADOR';

  bool get _puedeEliminar => _esAdminOperador;

  bool get _puedeCrear =>
      _esCliente || _esAdminOperador;

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

      final cuentas = await CuentaService.getCuentas();
      final bancos = await BancoService.getBancos();

      List<Usuario> clientes = [];

      if (rol == 'ADMIN' || rol == 'OPERADOR') {
        clientes = await UsuarioService.getClientesActivos();
      }

      if (!mounted) return;

      setState(() {
        _rol = rol;
        _cuentas = cuentas;
        _bancos = bancos;
        _clientes = clientes;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar las cuentas';
        _cargando = false;
      });
    }
  }

  String _nombreBanco(int bancoId) {
    for (final banco in _bancos) {
      if (banco.id == bancoId) {
        return banco.nombre;
      }
    }

    return 'Banco #$bancoId';
  }

  Future<void> _eliminarCuenta(Cuenta cuenta) async {
    if (!_puedeEliminar || cuenta.id == null) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar cuenta'),
          content: Text(
            '¿Está seguro de eliminar la cuenta ${cuenta.numero}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await CuentaService.eliminarCuenta(cuenta.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta eliminada correctamente'),
        ),
      );

      await _cargarDatos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _mostrarFormularioCuenta() async {
    if (!_puedeCrear) return;

    if (_bancos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay bancos registrados.'),
        ),
      );
      return;
    }

    if (_esAdminOperador && _clientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay clientes activos disponibles.',
          ),
        ),
      );
      return;
    }

    final numeroController = TextEditingController();
    final saldoController = TextEditingController();

    int? bancoSeleccionado;
    int? clienteSeleccionado;

    final creada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                _esCliente
                    ? 'Nueva cuenta'
                    : 'Nueva cuenta para cliente',
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_esAdminOperador) ...[
                        DropdownButtonFormField<int>(
                          initialValue: clienteSeleccionado,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Cliente',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          items: _clientes
                              .where(
                                (cliente) => cliente.id != null,
                              )
                              .map(
                                (cliente) =>
                                    DropdownMenuItem<int>(
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
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      DropdownButtonFormField<int>(
                        initialValue: bancoSeleccionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Banco',
                          prefixIcon: Icon(
                            Icons.account_balance,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: _bancos
                            .where((banco) => banco.id != null)
                            .map(
                              (banco) =>
                                  DropdownMenuItem<int>(
                                value: banco.id!,
                                child: Text(
                                  '${banco.nombre} (${banco.codigo})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            bancoSeleccionado = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: numeroController,
                        decoration: const InputDecoration(
                          labelText: 'Número de cuenta',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: saldoController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Saldo actual',
                          prefixIcon:
                              Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
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
                    final numero =
                        numeroController.text.trim();

                    final saldoTexto = saldoController.text
                        .trim()
                        .replaceAll(',', '.');

                    if (numero.isEmpty ||
                        saldoTexto.isEmpty ||
                        bancoSeleccionado == null ||
                        (_esAdminOperador &&
                            clienteSeleccionado == null)) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Complete todos los campos.',
                          ),
                        ),
                      );
                      return;
                    }

                    final saldo =
                        double.tryParse(saldoTexto);

                    if (saldo == null || saldo <= 0) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'El saldo debe ser mayor a cero.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final cuenta = Cuenta(
                        numero: numero,
                        tipo: 'CUENTA',
                        saldo: saldo,
                        bancoId: bancoSeleccionado!,
                      );

                      if (_esCliente) {
                        await CuentaService.crearMiCuenta(
                          cuenta,
                        );
                      } else {
                        await CuentaService.crearCuenta(
                          cuenta,
                          clienteSeleccionado!,
                        );
                      }

                      if (!context.mounted) return;

                      Navigator.of(dialogContext)
                          .pop(true);
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            e
                                .toString()
                                .replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    numeroController.dispose();
    saldoController.dispose();

    if (creada != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cuenta creada correctamente'),
      ),
    );

    await _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas'),
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
              onPressed: _mostrarFormularioCuenta,
              icon: const Icon(Icons.add),
              label: const Text('Nueva cuenta'),
            )
          : null,
      body: _construirContenido(),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
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

    if (_cuentas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay cuentas registradas',
                style: TextStyle(fontSize: 18),
              ),
              if (_puedeCrear) ...[
                const SizedBox(height: 8),
                const Text(
                  'Puede registrar una cuenta con el botón "Nueva cuenta".',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cuentas.length,
        itemBuilder: (context, index) {
          final cuenta = _cuentas[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(
                  Icons.account_balance_wallet,
                ),
              ),
              title: Text(
                cuenta.numero,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Banco: ${_nombreBanco(cuenta.bancoId)}\n'
                'Saldo: \$${cuenta.saldo.toStringAsFixed(2)}',
              ),
              trailing: _puedeEliminar
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Eliminar cuenta',
                      onPressed: () =>
                          _eliminarCuenta(cuenta),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}