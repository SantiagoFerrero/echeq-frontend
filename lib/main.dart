import 'package:flutter/material.dart';

import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login/login_screen.dart';
import 'utils/app_navigator.dart';
import 'utils/storage.dart';

void main() {
  runApp(const EcheqApp());
}

class EcheqApp extends StatelessWidget {
  const EcheqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      scaffoldMessengerKey: AppNavigator.messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'eCheq System',
      routes: {
        '/login': (_) => const LoginScreen(),
      },
      home: const SessionGate(),
    );
  }
}

enum _EstadoSesion {
  activa,
  sinSesion,
  expirada,
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Future<_EstadoSesion> _sesionFuture;

  bool _mensajeExpiracionMostrado = false;

  @override
  void initState() {
    super.initState();
    _sesionFuture = _resolverSesion();
  }

  Future<_EstadoSesion> _resolverSesion() async {
    final token = await Storage.obtenerToken();

    final habiaToken =
        token != null && token.isNotEmpty;

    final sesionActiva = await Storage.haySesion();

    if (sesionActiva) {
      return _EstadoSesion.activa;
    }

    if (habiaToken) {
      return _EstadoSesion.expirada;
    }

    return _EstadoSesion.sinSesion;
  }

  void _mostrarMensajeExpiracion() {
    if (_mensajeExpiracionMostrado) {
      return;
    }

    _mensajeExpiracionMostrado = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNavigator.messengerKey.currentState
          ?.hideCurrentSnackBar();

      AppNavigator.messengerKey.currentState
          ?.showSnackBar(
        const SnackBar(
          content: Text(
            'La sesión expiró. Inicie sesión nuevamente.',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EstadoSesion>(
      future: _sesionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState !=
            ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == _EstadoSesion.activa) {
          return const DashboardScreen();
        }

        if (snapshot.data == _EstadoSesion.expirada) {
          _mostrarMensajeExpiracion();
        }

        return const LoginScreen();
      },
    );
  }
}