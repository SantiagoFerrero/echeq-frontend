import 'package:flutter/material.dart';

import '../../models/cuenta_banco.dart';
import '../../models/cuenta_corriente.dart';
import '../../models/usuario.dart';
import '../../services/cuenta_banco_service.dart';
import '../../services/cuenta_corriente_service.dart';
import '../../services/usuario_service.dart';
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
  List<Usuario> _clientes = [];

  bool _cargando = true;
  String? _error;
  String? _rol;

  bool get _esCliente => _rol == 'CLIENTE';

  bool get _puedeGestionar =>
      _rol == 'ADMIN' || _rol == 'OPERADOR';

  bool get _puedeCrear =>
      _esCliente || _puedeGestionar;

  bool get _puedeEliminar => _puedeGestionar;

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

      final cuentas =
          await CuentaCorrienteService.getCuentasCorrientes();

      List<CuentaBanco> cuentasBanco = [];
      List<Usuario> clientes = [];

      if (rol == 'CLIENTE') {
        cuentasBanco =
            await CuentaBancoService.getCuentasBanco();
      }

      if (rol == 'ADMIN' || rol == 'OPERADOR') {
        cuentasBanco =
            await CuentaBancoService.getCuentasBanco();

        clientes =
            await UsuarioService.getClientesActivos();
      }

      if (!mounted) return;

      setState(() {
        _rol = rol;
        _cuentas = cuentas;
        _cuentasBanco = cuentasBanco;
        _clientes = clientes;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            e.toString().replaceFirst('Exception: ', '');
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
      _mostrarMensaje(
        'Primero debe registrar una Cuenta Banco.',
      );
      return;
    }

    final cbuController = TextEditingController();
    final aliasController = TextEditingController();
    final numeroController = TextEditingController();
    final limiteController =
        TextEditingController(text: '0');

    int? cuentaBancoSeleccionada;

    final creada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Nueva cuenta corriente',
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 460,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue:
                            cuentaBancoSeleccionada,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(
                          labelText: 'Cuenta Banco',
                          prefixIcon: Icon(
                            Icons.account_balance,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: _cuentasBanco
                            .map(
                              (cb) =>
                                  DropdownMenuItem<int>(
                                value: cb.id,
                                child: Text(
                                  '${cb.numeroCuenta} - ${cb.nombreBanco}',
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            cuentaBancoSeleccionada =
                                value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: cbuController,
                        keyboardType:
                            TextInputType.number,
                        maxLength: 22,
                        decoration:
                            const InputDecoration(
                          labelText: 'CBU',
                          hintText: '22 dígitos',
                          prefixIcon:
                              Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: aliasController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Alias',
                          prefixIcon:
                              Icon(Icons.label_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: numeroController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Número de cuenta corriente',
                          prefixIcon: Icon(
                            Icons.account_balance_wallet,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: limiteController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Límite de descubierto',
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
                    Navigator.of(dialogContext)
                        .pop(false);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final datos =
                        _validarDatosCuentaCorriente(
                      cuentaBancoId:
                          cuentaBancoSeleccionada,
                      cbuController: cbuController,
                      aliasController:
                          aliasController,
                      numeroController:
                          numeroController,
                      limiteController:
                          limiteController,
                    );

                    if (datos == null) return;

                    try {
                      final cuenta =
                          CuentaCorriente(
                        cuentaBancoId:
                            cuentaBancoSeleccionada!,
                        cbu: datos.cbu,
                        alias: datos.alias,
                        numeroCuentaCorriente:
                            datos.numero,
                        limiteDescubierto:
                            datos.limite,
                      );

                      await CuentaCorrienteService
                          .crearMiCuentaCorriente(
                        cuenta,
                      );

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

    if (creada != true || !mounted) return;

    _mostrarMensaje(
      'Cuenta corriente creada correctamente.',
    );

    await _cargarDatos();
  }

  Future<void> _crearCuentaCorrienteGestion() async {
    if (!_puedeGestionar) return;

    if (_clientes.isEmpty) {
      _mostrarMensaje(
        'No hay clientes activos disponibles.',
      );
      return;
    }

    if (_cuentasBanco.isEmpty) {
      _mostrarMensaje(
        'No hay Cuentas Banco disponibles.',
      );
      return;
    }

    final cbuController = TextEditingController();
    final aliasController = TextEditingController();
    final numeroController = TextEditingController();
    final limiteController =
        TextEditingController(text: '0');

    int? clienteSeleccionado;
    int? cuentaSeleccionada;
    int? cuentaBancoSeleccionada;

    final creada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cuentasPorId =
                <int, CuentaBanco>{};

            if (clienteSeleccionado != null) {
              for (final cb in _cuentasBanco) {
                if (cb.usuarioId ==
                    clienteSeleccionado) {
                  cuentasPorId.putIfAbsent(
                    cb.cuentaId,
                    () => cb,
                  );
                }
              }
            }

            final cuentasCliente =
                cuentasPorId.values.toList();

            final relacionesCuenta =
                cuentaSeleccionada == null
                    ? <CuentaBanco>[]
                    : _cuentasBanco
                        .where(
                          (cb) =>
                              cb.usuarioId ==
                                  clienteSeleccionado &&
                              cb.cuentaId ==
                                  cuentaSeleccionada,
                        )
                        .toList();

            return AlertDialog(
              title: const Text(
                'Nueva cuenta corriente para cliente',
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue:
                            clienteSeleccionado,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(
                          labelText: 'Cliente',
                          prefixIcon:
                              Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        items: _clientes
                            .where(
                              (cliente) =>
                                  cliente.id != null,
                            )
                            .map(
                              (cliente) =>
                                  DropdownMenuItem<int>(
                                value: cliente.id!,
                                child: Text(
                                  '${cliente.nombreCompleto} - ${cliente.email}',
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            clienteSeleccionado =
                                value;
                            cuentaSeleccionada = null;
                            cuentaBancoSeleccionada =
                                null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue:
                            cuentaSeleccionada,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Cuenta',
                          prefixIcon: const Icon(
                            Icons
                                .account_balance_wallet,
                          ),
                          border:
                              const OutlineInputBorder(),
                          helperText:
                              clienteSeleccionado ==
                                      null
                                  ? 'Primero seleccione un cliente'
                                  : cuentasCliente
                                          .isEmpty
                                      ? 'El cliente no tiene Cuentas Banco'
                                      : null,
                        ),
                        items: cuentasCliente
                            .map(
                              (cb) =>
                                  DropdownMenuItem<int>(
                                value: cb.cuentaId,
                                child: Text(
                                  cb.numeroCuenta,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged:
                            clienteSeleccionado ==
                                        null ||
                                    cuentasCliente
                                        .isEmpty
                                ? null
                                : (value) {
                                    setDialogState(
                                      () {
                                        cuentaSeleccionada =
                                            value;
                                        cuentaBancoSeleccionada =
                                            null;
                                      },
                                    );
                                  },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue:
                            cuentaBancoSeleccionada,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Cuenta Banco',
                          prefixIcon: const Icon(
                            Icons.account_balance,
                          ),
                          border:
                              const OutlineInputBorder(),
                          helperText:
                              cuentaSeleccionada ==
                                      null
                                  ? 'Primero seleccione una cuenta'
                                  : relacionesCuenta
                                          .isEmpty
                                      ? 'La cuenta no tiene relaciones bancarias'
                                      : null,
                        ),
                        items: relacionesCuenta
                            .map(
                              (cb) =>
                                  DropdownMenuItem<int>(
                                value: cb.id,
                                child: Text(
                                  '${cb.nombreBanco} - ${cb.estado}',
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged:
                            cuentaSeleccionada == null ||
                                    relacionesCuenta
                                        .isEmpty
                                ? null
                                : (value) {
                                    setDialogState(
                                      () {
                                        cuentaBancoSeleccionada =
                                            value;
                                      },
                                    );
                                  },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: cbuController,
                        keyboardType:
                            TextInputType.number,
                        maxLength: 22,
                        decoration:
                            const InputDecoration(
                          labelText: 'CBU',
                          hintText: '22 dígitos',
                          prefixIcon:
                              Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: aliasController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Alias',
                          prefixIcon: Icon(
                            Icons.label_outline,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: numeroController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Número de cuenta corriente',
                          prefixIcon: Icon(
                            Icons.account_balance_wallet,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: limiteController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Límite de descubierto',
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
                    Navigator.of(dialogContext)
                        .pop(false);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (clienteSeleccionado == null ||
                        cuentaSeleccionada == null ||
                        cuentaBancoSeleccionada ==
                            null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Seleccione cliente, cuenta y Cuenta Banco.',
                          ),
                        ),
                      );
                      return;
                    }

                    final datos =
                        _validarDatosCuentaCorriente(
                      cuentaBancoId:
                          cuentaBancoSeleccionada,
                      cbuController: cbuController,
                      aliasController:
                          aliasController,
                      numeroController:
                          numeroController,
                      limiteController:
                          limiteController,
                    );

                    if (datos == null) return;

                    try {
                      final cuenta =
                          CuentaCorriente(
                        cuentaBancoId:
                            cuentaBancoSeleccionada!,
                        cbu: datos.cbu,
                        alias: datos.alias,
                        numeroCuentaCorriente:
                            datos.numero,
                        limiteDescubierto:
                            datos.limite,
                      );

                      await CuentaCorrienteService
                          .crearCuentaCorriente(
                        cuenta,
                      );

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

    if (creada != true || !mounted) return;

    _mostrarMensaje(
      'Cuenta corriente creada correctamente.',
    );

    await _cargarDatos();
  }

  _DatosCuentaCorriente? _validarDatosCuentaCorriente({
    required int? cuentaBancoId,
    required TextEditingController cbuController,
    required TextEditingController aliasController,
    required TextEditingController numeroController,
    required TextEditingController limiteController,
  }) {
    final cbu = cbuController.text.trim();
    final alias = aliasController.text.trim();
    final numero = numeroController.text.trim();

    final limiteTexto = limiteController.text
        .trim()
        .replaceAll(',', '.');

    if (cuentaBancoId == null ||
        cbu.isEmpty ||
        alias.isEmpty ||
        numero.isEmpty ||
        limiteTexto.isEmpty) {
      _mostrarMensaje(
        'Complete todos los campos.',
      );
      return null;
    }

    if (!RegExp(r'^\d{22}$').hasMatch(cbu)) {
      _mostrarMensaje(
        'El CBU debe contener exactamente 22 dígitos.',
      );
      return null;
    }

    final limite = double.tryParse(limiteTexto);

    if (limite == null || limite < 0) {
      _mostrarMensaje(
        'El límite de descubierto no puede ser negativo.',
      );
      return null;
    }

    return _DatosCuentaCorriente(
      cbu: cbu,
      alias: alias,
      numero: numero,
      limite: limite,
    );
  }

  Future<void> _crearCuentaCorriente() async {
    if (_esCliente) {
      await _crearMiCuentaCorriente();
      return;
    }

    if (_puedeGestionar) {
      await _crearCuentaCorrienteGestion();
    }
  }

  Future<void> _eliminarCuenta(
    CuentaCorriente cuenta,
  ) async {
    if (!_puedeEliminar || cuenta.id == null) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Eliminar cuenta corriente',
          ),
          content: Text(
            '¿Está seguro de eliminar ${cuenta.alias}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await CuentaCorrienteService
          .eliminarCuentaCorriente(
        cuenta.id!,
      );

      _mostrarMensaje(
        'Cuenta corriente eliminada correctamente.',
      );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Cuentas Corrientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed:
                _cargando ? null : _cargarDatos,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _puedeCrear
          ? FloatingActionButton.extended(
              onPressed: _crearCuentaCorriente,
              icon: const Icon(Icons.add),
              label: const Text('Nueva'),
            )
          : null,
    );
  }

  Widget _buildBody() {
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
              const Icon(
                Icons.error_outline,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
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
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay cuentas corrientes registradas',
              style: TextStyle(fontSize: 18),
            ),
            if (_puedeCrear) ...[
              const SizedBox(height: 8),
              const Text(
                'Puede crear una con el botón "Nueva".',
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
        itemCount: _cuentas.length,
        itemBuilder: (context, index) {
          final cuenta = _cuentas[index];

          return Card(
            margin:
                const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(
                  Icons.account_balance,
                ),
              ),
              title: Text(
                cuenta.alias.isEmpty
                    ? 'Sin alias'
                    : cuenta.alias,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding:
                    const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text('CBU: ${cuenta.cbu}'),
                    if (cuenta
                        .numeroCuentaCorriente
                        .isNotEmpty)
                      Text(
                        'Cuenta corriente: ${cuenta.numeroCuentaCorriente}',
                      ),
                    if (cuenta.numeroCuenta.isNotEmpty)
                      Text(
                        'Cuenta: ${cuenta.numeroCuenta}',
                      ),
                    if (cuenta.nombreBanco.isNotEmpty)
                      Text(
                        'Banco: ${cuenta.nombreBanco}',
                      ),
                    Text(
                      'Límite descubierto: \$${cuenta.limiteDescubierto.toStringAsFixed(2)}',
                    ),
                    if (!_esCliente &&
                        cuenta.usuarioNombre
                            .isNotEmpty)
                      Text(
                        'Usuario: ${cuenta.usuarioNombre}',
                      ),
                    if (cuenta.fechaApertura
                        .isNotEmpty)
                      Text(
                        'Fecha de apertura: ${cuenta.fechaApertura}',
                      ),
                  ],
                ),
              ),
              trailing: _puedeEliminar &&
                      cuenta.id != null
                  ? IconButton(
                      icon:
                          const Icon(Icons.delete),
                      tooltip: 'Eliminar',
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

class _DatosCuentaCorriente {
  final String cbu;
  final String alias;
  final String numero;
  final double limite;

  const _DatosCuentaCorriente({
    required this.cbu,
    required this.alias,
    required this.numero,
    required this.limite,
  });
}