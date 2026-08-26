import 'package:flutter/material.dart';

import '../../models/aprobacion.dart';
import '../../services/aprobacion_service.dart';

class AprobacionesScreen extends StatefulWidget {
  const AprobacionesScreen({super.key});

  @override
  State<AprobacionesScreen> createState() => _AprobacionesScreenState();
}

class _AprobacionesScreenState extends State<AprobacionesScreen> {
  List<Aprobacion> _aprobaciones = [];

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarAprobaciones();
  }

  Future<void> _cargarAprobaciones() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await AprobacionService.obtenerTodas();

      if (!mounted) return;

      setState(() {
        _aprobaciones = resultado;
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

  Color _colorDecision(String decision) {
    switch (decision.toUpperCase()) {
      case 'APROBADO':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      default:
        return Colors.grey;
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

    return '$dia/$mes/$anio $hora:$minuto';
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
                onPressed: _cargarAprobaciones,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_aprobaciones.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarAprobaciones,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Icon(Icons.verified_outlined, size: 64),
            SizedBox(height: 16),
            Center(child: Text('No hay aprobaciones registradas.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarAprobaciones,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _aprobaciones.length,
        itemBuilder: (context, index) {
          final aprobacion = _aprobaciones[index];

          final color = _colorDecision(aprobacion.decision);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        aprobacion.decision == 'APROBADO'
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: color,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Solicitud #${aprobacion.solicitudId}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Chip(label: Text(aprobacion.decision)),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    'Decidido por',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    aprobacion.usuarioNombre,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fecha de decisión',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(_formatearFecha(aprobacion.fechaDecision)),
                  if (aprobacion.observacion != null &&
                      aprobacion.observacion!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Observación',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(aprobacion.observacion!),
                  ],
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
        title: const Text('Aprobaciones'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarAprobaciones,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
