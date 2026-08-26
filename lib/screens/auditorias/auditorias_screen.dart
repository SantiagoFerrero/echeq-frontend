import 'package:flutter/material.dart';

import '../../models/auditoria.dart';
import '../../services/auditoria_service.dart';

class AuditoriasScreen extends StatefulWidget {
  const AuditoriasScreen({super.key});

  @override
  State<AuditoriasScreen> createState() => _AuditoriasScreenState();
}

class _AuditoriasScreenState extends State<AuditoriasScreen> {
  List<Auditoria> _auditorias = [];

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarAuditorias();
  }

  Future<void> _cargarAuditorias() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await AuditoriaService.obtenerTodas();

      if (!mounted) return;

      setState(() {
        _auditorias = resultado;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  IconData _iconoAccion(String accion) {
    switch (accion.toUpperCase()) {
      case 'CREAR':
        return Icons.add_circle_outline;

      case 'MODIFICAR':
        return Icons.edit_outlined;

      case 'ELIMINAR':
        return Icons.delete_outline;

      case 'APROBAR':
        return Icons.check_circle_outline;

      case 'RECHAZAR':
        return Icons.cancel_outlined;

      case 'LOGIN':
        return Icons.login;

      case 'LOGOUT':
        return Icons.logout;

      default:
        return Icons.history;
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return '-';
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;

    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    final segundo = fecha.second.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto:$segundo';
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
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarAuditorias,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_auditorias.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarAuditorias,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Icon(Icons.history, size: 64),
            SizedBox(height: 16),
            Center(child: Text('No hay registros de auditoría.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarAuditorias,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _auditorias.length,
        itemBuilder: (context, index) {
          final auditoria = _auditorias[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(child: Icon(_iconoAccion(auditoria.accion))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                auditoria.accion,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text('#${auditoria.id}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          auditoria.detalle,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Text('Usuario: ${auditoria.usuarioNombre}'),
                        const SizedBox(height: 4),
                        Text('Fecha: ${_formatearFecha(auditoria.fechaHora)}'),
                      ],
                    ),
                  ),
                ],
              ),
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
        title: const Text('Auditoría'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarAuditorias,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
