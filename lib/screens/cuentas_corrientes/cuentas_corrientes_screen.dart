import 'package:flutter/material.dart';

import '../../models/cuenta_banco.dart';
import '../../models/cuenta_corriente.dart';
import '../../services/cuenta_banco_service.dart';
import '../../services/cuenta_corriente_service.dart';
import '../../utils/storage.dart';

class CuentasCorrientesScreen extends StatefulWidget {
  const CuentasCorrientesScreen({super.key});

  @override
  State<CuentasCorrientesScreen> createState() =>
      _CuentasCorrientesScreenState();
}

class _CuentasCorrientesScreenState extends State<CuentasCorrientesScreen> {
  List<CuentaCorriente> _cuentas = [];
  List<CuentaBanco> _cuentasBanco = [];

  bool _cargando = true;
  String? _error;
  String? _rol;

  bool get _esCliente => _rol == 'CLIENTE';

  bool get _puedeEliminar => _rol == 'ADMIN' || _rol == 'OPERADOR';

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

      final cuentas = await CuentaCorrienteService.getCuentasCorrientes();

      List<CuentaBanco> cuentasBanco = [];

      if (rol == 'CLIENTE') {
        cuentasBanco = await CuentaBancoService.getCuentasBanco();
      }

      if (!mounted) return;

      setState(() {
        _rol = rol;
        _cuentas = cuentas;
        _cuentasBanco = cuentasBanco;
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

  Future<void> _crearMiCuentaCorriente() async {
    if (!_esCliente) return;

    if (_cuentasBanco.isEmpty) {
      _mostrarMensaje('Primero debe registrar una Cuenta Banco.');
      return;
    }

    final cbuController = TextEditingController();

    final aliasController = TextEditingController();

    final numeroController = TextEditingController();

    final limiteController = TextEditingController(text: '0');

    int? cuentaBancoSeleccionada;

    final creada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva cuenta corriente'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: cuentaBancoSeleccionada,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Cuenta Banco',
                          prefixIcon: Icon(Icons.account_balance),
                          border: OutlineInputBorder(),
                        ),
                        items: _cuentasBanco
                            .map(
                              (cb) => DropdownMenuItem<int>(
                                value: cb.id,
                                child: Text(
                                  '${cb.numeroCuenta} - ${cb.nombreBanco}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            cuentaBancoSeleccionada = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: cbuController,
                        keyboardType: TextInputType.number,
                        maxLength: 22,
                        decoration: const InputDecoration(
                          labelText: 'CBU',
                          hintText: '22 dígitos',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: aliasController,
                        decoration: const InputDecoration(
                          labelText: 'Alias',
                          prefixIcon: Icon(Icons.label_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: numeroController,
                        decoration: const InputDecoration(
                          labelText: 'Número de cuenta corriente',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: limiteController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Límite de descubierto',
                          prefixIcon: Icon(Icons.attach_money),
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
                    final cbu = cbuController.text.trim();

                    final alias = aliasController.text.trim();

                    final numero = numeroController.text.trim();

                    final limiteTexto = limiteController.text.trim().replaceAll(
                      ',',
                      '.',
                    );

                    if (cuentaBancoSeleccionada == null ||
                        cbu.isEmpty ||
                        alias.isEmpty ||
                        numero.isEmpty ||
                        limiteTexto.isEmpty) {
                      _mostrarMensaje('Complete todos los campos.');
                      return;
                    }

                    if (!RegExp(r'^\d{22}$').hasMatch(cbu)) {
                      _mostrarMensaje(
                        'El CBU debe contener exactamente 22 dígitos.',
                      );
                      return;
                    }

                    final limite = double.tryParse(limiteTexto);

                    if (limite == null || limite < 0) {
                      _mostrarMensaje(
                        'El límite de descubierto no puede ser negativo.',
                      );
                      return;
                    }

                    try {
                      final cuenta = CuentaCorriente(
                        cuentaBancoId: cuentaBancoSeleccionada!,
                        cbu: cbu,
                        alias: alias,
                        numeroCuentaCorriente: numero,
                        limiteDescubierto: limite,
                      );

                      await CuentaCorrienteService.crearMiCuentaCorriente(
                        cuenta,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      Navigator.of(dialogContext).pop(true);
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }

                      _mostrarMensaje(
                        e.toString().replaceFirst('Exception: ', ''),
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

    cbuController.dispose();
    aliasController.dispose();
    numeroController.dispose();
    limiteController.dispose();

    if (creada != true || !mounted) {
      return;
    }

    _mostrarMensaje('Cuenta corriente creada correctamente.');

    await _cargarDatos();
  }

  Future<void> _eliminarCuenta(CuentaCorriente cuenta) async {
    if (!_puedeEliminar || cuenta.id == null) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar cuenta corriente'),
          content: Text(
            '¿Está seguro de eliminar '
            '${cuenta.alias}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await CuentaCorrienteService.eliminarCuentaCorriente(cuenta.id!);

      _mostrarMensaje('Cuenta corriente eliminada correctamente.');

      await _cargarDatos();
    } catch (e) {
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
        title: const Text('Cuentas Corrientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargarDatos,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _esCliente
          ? FloatingActionButton.extended(
              onPressed: _crearMiCuentaCorriente,
              icon: const Icon(Icons.add),
              label: const Text('Nueva'),
            )
          : null,
    );
  }

  Widget _buildBody() {
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
              const Icon(Icons.error_outline, size: 60),
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

    if (_cuentas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 60),
            const SizedBox(height: 16),
            const Text(
              'No hay cuentas corrientes registradas',
              style: TextStyle(fontSize: 18),
            ),
            if (_esCliente) ...[
              const SizedBox(height: 8),
              const Text('Puede crear una con el botón "Nueva".'),
            ],
          ],
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
              leading: const CircleAvatar(child: Icon(Icons.account_balance)),
              title: Text(
                cuenta.alias.isEmpty ? 'Sin alias' : cuenta.alias,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CBU: ${cuenta.cbu}'),
                    if (cuenta.numeroCuentaCorriente.isNotEmpty)
                      Text('Cuenta corriente: ${cuenta.numeroCuentaCorriente}'),
                    if (cuenta.numeroCuenta.isNotEmpty)
                      Text('Cuenta: ${cuenta.numeroCuenta}'),
                    if (cuenta.nombreBanco.isNotEmpty)
                      Text('Banco: ${cuenta.nombreBanco}'),
                    Text(
                      'Límite descubierto: \$${cuenta.limiteDescubierto.toStringAsFixed(2)}',
                    ),
                    if (!_esCliente && cuenta.usuarioNombre.isNotEmpty)
                      Text('Usuario: ${cuenta.usuarioNombre}'),
                    if (cuenta.fechaApertura.isNotEmpty)
                      Text('Fecha de apertura: ${cuenta.fechaApertura}'),
                  ],
                ),
              ),
              trailing: _puedeEliminar && cuenta.id != null
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Eliminar',
                      onPressed: () => _eliminarCuenta(cuenta),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
