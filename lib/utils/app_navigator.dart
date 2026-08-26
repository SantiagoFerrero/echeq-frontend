import 'package:flutter/material.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static bool _redirigiendo = false;

  static void irALoginPorSesionExpirada() {
    if (_redirigiendo) {
      return;
    }

    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    _redirigiendo = true;

    navigator.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      messengerKey.currentState?.hideCurrentSnackBar();

      messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'La sesión expiró. Inicie sesión nuevamente.',
          ),
        ),
      );
    });

    Future<void>.delayed(
      const Duration(milliseconds: 500),
      () {
        _redirigiendo = false;
      },
    );
  }
}