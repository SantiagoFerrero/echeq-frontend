import 'package:flutter/material.dart';

import '../../models/notificacion.dart';
import '../../services/notificacion_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<Notificacion> _notificaciones = [];

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await NotificacionService.obtenerMisNotificaciones();

      if (!mounted) return;

      setState(() {
        _notificaciones = resultado;
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

  Future<void> _marcarComoLeida(Notificacion notificacion) async {
    if (notificacion.leida) {
      return;
    }

    try {
      await NotificacionService.marcarComoLeida(notificacion.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación marcada como leída.')),
      );

      await _cargarNotificaciones();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la notificación: $e')),
      );
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return '';
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
                onPressed: _cargarNotificaciones,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notificaciones.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarNotificaciones,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Icon(Icons.notifications_none, size: 64),
            SizedBox(height: 16),
            Center(child: Text('No tiene notificaciones.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarNotificaciones,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notificaciones.length,
        itemBuilder: (context, index) {
          final notificacion = _notificaciones[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                notificacion.leida
                    ? Icons.notifications_none
                    : Icons.notifications_active,
              ),
              title: Text(
                notificacion.mensaje,
                style: TextStyle(
                  fontWeight: notificacion.leida
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text('Solicitud #${notificacion.solicitudId}'),
                  if (notificacion.fechaEnvio != null)
                    Text(_formatearFecha(notificacion.fechaEnvio)),
                ],
              ),
              trailing: notificacion.leida
                  ? const Chip(label: Text('Leída'))
                  : TextButton(
                      onPressed: () {
                        _marcarComoLeida(notificacion);
                      },
                      child: const Text('Marcar como leída'),
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
        title: const Text('Mis notificaciones'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarNotificaciones,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
