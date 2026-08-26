import 'package:flutter/material.dart';

import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login/login_screen.dart';
import 'utils/storage.dart';

void main() {
  runApp(const EcheqApp());
}

class EcheqApp extends StatelessWidget {
  const EcheqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eCheq System',
      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Future<bool> _sesionFuture;

  @override
  void initState() {
    super.initState();
    _sesionFuture = Storage.haySesion();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sesionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
