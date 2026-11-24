import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/terminal_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _bootLines = [
    '> INICIALIZANDO SISTEMA...',
    '> CONECTANDO A LA PECERA...',
    '> ACCESO CONCEDIDO_',
  ];

  Timer? _timer;
  int _visibleLines = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 480), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _visibleLines++);
      if (_visibleLines >= _bootLines.length) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: TerminalTheme.red, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DEATHFISH // LA PECERA RECORDS',
                    style: TextStyle(
                      color: TerminalTheme.red,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final line in _bootLines.take(_visibleLines))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
