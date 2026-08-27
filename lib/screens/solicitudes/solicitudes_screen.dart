import 'package:flutter/material.dart';

import '../../models/cuenta_corriente.dart';
import '../../models/solicitud_echeq.dart';
import '../../models/usuario.dart';
import '../../services/cuenta_corriente_service.dart';
import '../../services/solicitud_echeq_service.dart';
import '../../services/usuario_service.dart';
import '../../utils/storage.dart';
import '../../utils/web_download.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  final SolicitudECheqService _service = SolicitudECheqService();

  List<SolicitudECheq> solicitudes = [];
  List<Usuario> _clientes = [];

  final TextEditingController _conceptoFiltroController =
      TextEditingController();

  int? _usuarioFiltroId;
  DateTime? _fechaDesdeFiltro;
  DateTime? _fechaHastaFiltro;
  String _estadoFiltro = 'TODOS';

  bool cargando = true;
  bool _exportando = false;
  String? error;
  String? rol;

  bool get puedeGestionar => rol == 'ADMIN' || rol == 'OPERADOR';

  bool get esCliente => rol == 'CLIENTE';

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final rolActual = await Storage.obtenerRol();

      List<Usuario> clientesActuales = _clientes;

      if ((rolActual == 'ADMIN' || rolActual == 'OPERADOR') &&
          clientesActuales.isEmpty) {
        clientesActuales = await UsuarioService.getClientesActivos();
      }

      final resultado = await _service.obtenerTodas(
        usuarioId: _usuarioFiltroId,
        fechaDesde: _fechaDesdeFiltro,
        fechaHasta: _fechaHastaFiltro,
        estado: _estadoFiltro,
        concepto: _conceptoFiltroController.text,
      );

      if (!mounted) return;

      setState(() {
        rol = rolActual;
        solicitudes = resultado;
        _clientes = clientesActuales;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  // ============================================================
  // CREAR SOLICITUD - CLIENTE
  // ============================================================

  Future<void> _crearSolicitudCliente() async {
    try {
      final usuarioId = await Storage.obtenerUsuarioId();

      if (usuarioId == null) {
        _mostrarMensaje('No se pudo obtener el usuario de la sesión.');
        return;
      }

      final cuentasCorrientes =
          await CuentaCorrienteService.getCuentasCorrientes();

      if (!mounted) return;

      final cuentasValidas = cuentasCorrientes
          .where((cuenta) => cuenta.id != null)
          .toList();

      if (cuentasValidas.isEmpty) {
        _mostrarMensaje('No tiene cuentas corrientes disponibles.');
        return;
      }

      final montoController = TextEditingController();
      final conceptoController = TextEditingController();

      int? cuentaCorrienteId;

      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Nueva solicitud eCheq'),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Cuenta corriente',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Seleccione una cuenta'),
                    items: cuentasValidas.map((CuentaCorriente cuenta) {
                      return DropdownMenuItem<int>(
                        value: cuenta.id!,
                        child: Text(
                          cuenta.alias.isNotEmpty
                              ? '${cuenta.alias} - ${cuenta.cbu}'
                              : cuenta.cbu,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      cuentaCorrienteId = value;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: montoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: conceptoController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Concepto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
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
                child: const Text('Crear solicitud'),
              ),
            ],
          );
        },
      );

      if (confirmar != true) {
        montoController.dispose();
        conceptoController.dispose();
        return;
      }

      final montoTexto = montoController.text.trim().replaceAll(',', '.');

      final monto = double.tryParse(montoTexto);

      final concepto = conceptoController.text.trim();

      montoController.dispose();
      conceptoController.dispose();

      if (cuentaCorrienteId == null) {
        _mostrarMensaje('Debe seleccionar una cuenta corriente.');
        return;
      }

      if (monto == null || monto <= 0) {
        _mostrarMensaje('Ingrese un monto válido mayor a cero.');
        return;
      }

      if (concepto.isEmpty) {
        _mostrarMensaje('Debe ingresar un concepto.');
        return;
      }

      final nuevaSolicitud = SolicitudECheq(
        monto: monto,
        concepto: concepto,
        usuarioId: usuarioId,
        usuarioNombre: '',
        cuentaCorrienteId: cuentaCorrienteId!,
        estado: 'PENDIENTE',
      );

      final creada = await _service.crear(nuevaSolicitud);

      if (!mounted) return;

      _mostrarMensaje('Solicitud #${creada.id} creada correctamente.');

      await _cargarSolicitudes();
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('No se pudo crear la solicitud: $e');
    }
  }

  // ============================================================
  // EDITAR SOLICITUD PENDIENTE - CLIENTE
  // ============================================================

  Future<void> _editarSolicitudCliente(SolicitudECheq solicitud) async {
    if (solicitud.id == null) {
      return;
    }

    try {
      final cuentasCorrientes =
          await CuentaCorrienteService.getCuentasCorrientes();

      if (!mounted) return;

      final cuentasValidas = cuentasCorrientes
          .where((cuenta) => cuenta.id != null)
          .toList();

      if (cuentasValidas.isEmpty) {
        _mostrarMensaje('No tiene cuentas corrientes disponibles.');
        return;
      }

      int cuentaCorrienteId = solicitud.cuentaCorrienteId;

      final existeCuentaActual = cuentasValidas.any(
        (cuenta) => cuenta.id == cuentaCorrienteId,
      );

      if (!existeCuentaActual) {
        _mostrarMensaje('La cuenta corriente actual no está disponible.');
        return;
      }

      final montoController = TextEditingController(
        text: solicitud.monto.toStringAsFixed(2),
      );

      final conceptoController = TextEditingController(
        text: solicitud.concepto,
      );

      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Editar solicitud #${solicitud.id}'),
                content: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: cuentaCorrienteId,
                        decoration: const InputDecoration(
                          labelText: 'Cuenta corriente',
                          border: OutlineInputBorder(),
                        ),
                        items: cuentasValidas.map((CuentaCorriente cuenta) {
                          return DropdownMenuItem<int>(
                            value: cuenta.id!,
                            child: Text(
                              cuenta.alias.isNotEmpty
                                  ? '${cuenta.alias} - ${cuenta.cbu}'
                                  : cuenta.cbu,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              cuentaCorrienteId = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: montoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: conceptoController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Concepto',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
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
                    child: const Text('Guardar cambios'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmar != true) {
        montoController.dispose();
        conceptoController.dispose();
        return;
      }

      final montoTexto = montoController.text.trim().replaceAll(',', '.');

      final monto = double.tryParse(montoTexto);
      final concepto = conceptoController.text.trim();

      montoController.dispose();
      conceptoController.dispose();

      if (monto == null || monto <= 0) {
        _mostrarMensaje('Ingrese un monto válido mayor a cero.');
        return;
      }

      if (concepto.isEmpty) {
        _mostrarMensaje('Debe ingresar un concepto.');
        return;
      }

      final solicitudEditada = SolicitudECheq(
        id: solicitud.id,
        monto: monto,
        concepto: concepto,
        fechaSolicitud: solicitud.fechaSolicitud,
        usuarioId: solicitud.usuarioId,
        usuarioNombre: solicitud.usuarioNombre,
        cuentaCorrienteId: cuentaCorrienteId,
        cuentaCorrienteAlias: solicitud.cuentaCorrienteAlias,
        estado: solicitud.estado,
      );

      final actualizada = await _service.actualizar(
        solicitud.id!,
        solicitudEditada,
      );

      if (!mounted) return;

      _mostrarMensaje(
        'Solicitud #${actualizada.id} actualizada correctamente.',
      );

      await _cargarSolicitudes();
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('No se pudo editar la solicitud: $e');
    }
  }
  // ============================================================
  // APROBAR / RECHAZAR - ADMIN / OPERADOR
  // ============================================================

  Future<void> _actualizarEstado(
    SolicitudECheq solicitud,
    String estado,
  ) async {
    if (solicitud.id == null) return;

    final observacionController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final esAprobacion = estado == 'APROBADA';

        return AlertDialog(
          title: Text(
            esAprobacion ? 'Aprobar solicitud' : 'Rechazar solicitud',
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  esAprobacion
                      ? '¿Desea aprobar la solicitud #${solicitud.id}?'
                      : '¿Desea rechazar la solicitud #${solicitud.id}?',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: observacionController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Observación',
                    hintText: 'Opcional',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
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
              child: Text(esAprobacion ? 'Aprobar' : 'Rechazar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      observacionController.dispose();
      return;
    }

    final observacion = observacionController.text.trim();

    observacionController.dispose();

    try {
      await _service.actualizarEstado(
        solicitud.id!,
        estado,
        observacion: observacion.isEmpty ? null : observacion,
      );

      if (!mounted) return;

      _mostrarMensaje(
        estado == 'APROBADA'
            ? 'Solicitud aprobada correctamente'
            : 'Solicitud rechazada correctamente',
      );

      await _cargarSolicitudes();
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('No se pudo actualizar la solicitud: $e');
    }
  }

  // ============================================================
  // ELIMINAR - ADMIN / OPERADOR
  // ============================================================

  Future<void> _eliminarSolicitud(SolicitudECheq solicitud) async {
    if (solicitud.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar solicitud'),
          content: Text(
            '¿Está seguro de que desea eliminar '
            'la solicitud #${solicitud.id}?',
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
      await _service.eliminar(solicitud.id!);

      if (!mounted) return;

      _mostrarMensaje('Solicitud eliminada correctamente');

      await _cargarSolicitudes();
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('No se pudo eliminar la solicitud: $e');
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Color _colorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'APROBADA':
        return Colors.green;
      case 'RECHAZADA':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _estadoWidget(String estado) {
    final color = _colorEstado(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _accionesSolicitud(SolicitudECheq solicitud) {
    final pendiente = solicitud.estado.toUpperCase() == 'PENDIENTE';

    if (!pendiente) {
      return const SizedBox.shrink();
    }

    // CLIENTE:
    // La edicion se muestra en el encabezado de la tarjeta.
    if (esCliente) {
      return const SizedBox.shrink();
    }

    // ADMIN / OPERADOR:
    // pueden aprobar, rechazar o eliminar pendientes.
    if (puedeGestionar) {
      return Column(
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _actualizarEstado(solicitud, 'APROBADA');
                  },
                  icon: const Icon(Icons.check, color: Colors.green),
                  label: const Text(
                    'Aprobar',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _actualizarEstado(solicitud, 'RECHAZADA');
                  },
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text(
                    'Rechazar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {
                _eliminarSolicitud(solicitud);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Eliminar solicitud',
            ),
          ),
        ],
      );
    }

    // AUDITOR:
    // solo lectura.
    return const SizedBox.shrink();
  }

  Future<DateTime?> _seleccionarFecha(DateTime? fechaActual) async {
    return showDatePicker(
      context: context,
      initialDate: fechaActual ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _aplicarFiltros() async {
    if (_fechaDesdeFiltro != null &&
        _fechaHastaFiltro != null &&
        _fechaHastaFiltro!.isBefore(_fechaDesdeFiltro!)) {
      _mostrarMensaje(
        'La fecha hasta no puede ser anterior a la fecha desde.',
      );
      return;
    }

    await _cargarSolicitudes();
  }

  Future<void> _limpiarFiltros() async {
    setState(() {
      _usuarioFiltroId = null;
      _fechaDesdeFiltro = null;
      _fechaHastaFiltro = null;
      _estadoFiltro = 'TODOS';
      _conceptoFiltroController.clear();
    });

    await _cargarSolicitudes();
  }

  @override
  void dispose() {
    _conceptoFiltroController.dispose();
    super.dispose();
  }

  Future<void> _exportarExcel() async {
    if (!puedeGestionar || _exportando) {
      return;
    }

    if (_fechaDesdeFiltro != null &&
        _fechaHastaFiltro != null &&
        _fechaHastaFiltro!.isBefore(_fechaDesdeFiltro!)) {
      _mostrarMensaje(
        'La fecha hasta no puede ser anterior a la fecha desde.',
      );
      return;
    }

    setState(() {
      _exportando = true;
    });

    try {
      final bytes = await _service.exportar(
        usuarioId: _usuarioFiltroId,
        fechaDesde: _fechaDesdeFiltro,
        fechaHasta: _fechaHastaFiltro,
        estado: _estadoFiltro,
        concepto: _conceptoFiltroController.text,
      );

      final fechaArchivo =
          _formatearFecha(DateTime.now()).replaceAll('/', '-');

      WebDownload.descargarBytes(
        bytes: bytes,
        nombreArchivo: 'solicitudes_echeq_$fechaArchivo.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (!mounted) return;

      _mostrarMensaje('Archivo Excel generado correctamente.');
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('No se pudo exportar el archivo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _exportando = false;
        });
      }
    }
  }

  Widget _buildFiltros() {
    final muestraCliente = rol == 'ADMIN' || rol == 'OPERADOR';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (muestraCliente)
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey(_usuarioFiltroId ?? -1),
                      initialValue: _usuarioFiltroId ?? -1,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Cliente',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: -1,
                          child: Text('Todos los clientes'),
                        ),
                        ..._clientes
                            .where((usuario) => usuario.id != null)
                            .map(
                              (usuario) => DropdownMenuItem<int>(
                                value: usuario.id!,
                                child: Text(
                                  usuario.nombreCompleto.isNotEmpty
                                      ? usuario.nombreCompleto
                                      : usuario.email,
                                ),
                              ),
                            ),
                      ],
                      onChanged: cargando
                          ? null
                          : (value) {
                              setState(() {
                                _usuarioFiltroId =
                                    value == -1 ? null : value;
                              });
                            },
                    ),
                  ),

                SizedBox(
                  width: 190,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: cargando
                        ? null
                        : () async {
                            final fecha = await _seleccionarFecha(
                              _fechaDesdeFiltro,
                            );

                            if (fecha != null && mounted) {
                              setState(() {
                                _fechaDesdeFiltro = fecha;
                              });
                            }
                          },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _fechaDesdeFiltro == null
                          ? 'Fecha desde'
                          : 'Desde: ${_formatearFecha(_fechaDesdeFiltro!)}',
                    ),
                  ),
                ),

                SizedBox(
                  width: 190,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: cargando
                        ? null
                        : () async {
                            final fecha = await _seleccionarFecha(
                              _fechaHastaFiltro,
                            );

                            if (fecha != null && mounted) {
                              setState(() {
                                _fechaHastaFiltro = fecha;
                              });
                            }
                          },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _fechaHastaFiltro == null
                          ? 'Fecha hasta'
                          : 'Hasta: ${_formatearFecha(_fechaHastaFiltro!)}',
                    ),
                  ),
                ),

                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_estadoFiltro),
                    initialValue: _estadoFiltro,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'TODOS',
                        child: Text('Todos'),
                      ),
                      DropdownMenuItem(
                        value: 'PENDIENTE',
                        child: Text('Pendiente'),
                      ),
                      DropdownMenuItem(
                        value: 'APROBADA',
                        child: Text('Aprobada'),
                      ),
                      DropdownMenuItem(
                        value: 'RECHAZADA',
                        child: Text('Rechazada'),
                      ),
                    ],
                    onChanged: cargando
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _estadoFiltro = value;
                              });
                            }
                          },
                  ),
                ),

                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _conceptoFiltroController,
                    enabled: !cargando,
                    decoration: const InputDecoration(
                      labelText: 'Concepto',
                      hintText: 'Buscar por concepto',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: cargando ? null : _aplicarFiltros,
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text('Buscar'),
                  ),
                ),

                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: cargando ? null : _limpiarFiltros,
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar'),
                  ),
                ),

                if (puedeGestionar)
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: cargando || _exportando
                          ? null
                          : _exportarExcel,
                      icon: _exportando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.download_outlined),
                      label: const Text('Exportar Excel'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarSolicitudes,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (solicitudes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarSolicitudes,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'No hay solicitudes eCheq registradas',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarSolicitudes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: solicitudes.length,
        itemBuilder: (context, index) {
          final solicitud = solicitudes[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Solicitud #${solicitud.id ?? '-'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (esCliente &&
                          solicitud.estado.toUpperCase() == 'PENDIENTE')
                        IconButton(
                          onPressed: () {
                            _editarSolicitudCliente(solicitud);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar solicitud',
                        ),
                      _estadoWidget(solicitud.estado),
                    ],
                  ),
                  const Divider(height: 24),
                  Text('Monto', style: TextStyle(color: Colors.grey.shade600)),
                  Text(
                    '\$ ${solicitud.monto.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Concepto',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(solicitud.concepto),
                  const SizedBox(height: 12),
                  Text(
                    'Solicitante',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(solicitud.usuarioNombre),
                  const SizedBox(height: 12),
                  Text(
                    'Cuenta corriente',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    solicitud.cuentaCorrienteAlias ??
                        'Cuenta #${solicitud.cuentaCorrienteId}',
                  ),
                  if (solicitud.fechaSolicitud != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Fecha de solicitud',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(_formatearFecha(solicitud.fechaSolicitud!)),
                  ],
                  _accionesSolicitud(solicitud),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes eCheq'),
        actions: [
          IconButton(
            onPressed: cargando ? null : _cargarSolicitudes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: esCliente
          ? FloatingActionButton.extended(
              onPressed: _crearSolicitudCliente,
              icon: const Icon(Icons.add),
              label: const Text('Nueva solicitud'),
            )
          : null,
    );
  }
}
