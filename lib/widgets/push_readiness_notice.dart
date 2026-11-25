import 'package:flutter/material.dart';

class PushReadinessNotice extends StatelessWidget {
  const PushReadinessNotice({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: Colors.black,
      border: Border.all(color: const Color(0xFF222222)),
    ),
    child: const Text(
      'PUSH // deathfish_all LISTO PARA CONECTAR CON CLOUD FUNCTIONS / FIREBASE CONSOLE\n'
      'WEB // REQUIERE VAPID + SERVICE WORKER; LOS TOPICS SE GESTIONAN DESDE BACKEND',
      style: TextStyle(color: Colors.white70, fontSize: 9, height: 1.4),
    ),
  );
}
