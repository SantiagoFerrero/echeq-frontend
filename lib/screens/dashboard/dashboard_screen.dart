import 'package:flutter/material.dart';

import '../../utils/storage.dart';
import '../aprobaciones/aprobaciones_screen.dart';
import '../auditorias/auditorias_screen.dart';
import '../bancos/bancos_screen.dart';
import '../cuentas/cuentas_screen.dart';
import '../cuentas_banco/cuentas_banco_screen.dart';
import '../cuentas_corrientes/cuentas_corrientes_screen.dart';
import '../login/login_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import '../solicitudes/solicitudes_screen.dart';
import '../usuarios/usuarios_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _rol;
  bool _cargando = true;

  bool get _puedeVerAprobaciones =>
      _rol == 'ADMIN' || _rol == 'OPERADOR' || _rol == 'AUDITOR';

  bool get _puedeVerAuditoria => _rol == 'ADMIN' || _rol == 'AUDITOR';

  bool get _puedeAdministrarUsuarios => _rol == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _cargarRol();
  }

  Future<void> _cargarRol() async {
    final rol = await Storage.obtenerRol();

    if (!mounted) return;

    setState(() {
      _rol = rol;
      _cargando = false;
    });
  }

  Future<void> _cerrarSesion() async {
    await Storage.limpiarSesion();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmarCerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Desea cerrar la sesión actual?'),
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
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await _cerrarSesion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eCheq System'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _confirmarCerrarSesion,
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : GridView.count(
              padding: const EdgeInsets.all(24),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _opcion(
                  context,
                  icon: Icons.account_balance,
                  titulo: 'Bancos',
                  pantalla: const BancosScreen(),
                ),
                _opcion(
                  context,
                  icon: Icons.account_balance_wallet,
                  titulo: 'Cuentas',
                  pantalla: const CuentasScreen(),
                ),
                _opcion(
                  context,
                  icon: Icons.link,
                  titulo: 'Cuentas Banco',
                  pantalla: const CuentasBancoScreen(),
                ),
                _opcion(
                  context,
                  icon: Icons.credit_card,
                  titulo: 'Cuentas corrientes',
                  pantalla: const CuentasCorrientesScreen(),
                ),
                _opcion(
                  context,
                  icon: Icons.notifications,
                  titulo: 'Mis notificaciones',
                  pantalla: const NotificacionesScreen(),
                ),
                _opcion(
                  context,
                  icon: Icons.receipt_long,
                  titulo: 'Solicitudes eCheq',
                  pantalla: const SolicitudesScreen(),
                ),
                if (_puedeVerAprobaciones)
                  _opcion(
                    context,
                    icon: Icons.verified,
                    titulo: 'Aprobaciones',
                    pantalla: const AprobacionesScreen(),
                  ),
                if (_puedeVerAuditoria)
                  _opcion(
                    context,
                    icon: Icons.history,
                    titulo: 'Auditoría',
                    pantalla: const AuditoriasScreen(),
                  ),
                if (_puedeAdministrarUsuarios)
                  _opcion(
                    context,
                    icon: Icons.manage_accounts,
                    titulo: 'Usuarios',
                    pantalla: const UsuariosScreen(),
                  ),
              ],
            ),
    );
  }

  Widget _opcion(
    BuildContext context, {
    required IconData icon,
    required String titulo,
    required Widget pantalla,
  }) {
    return Card(
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => pantalla));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
