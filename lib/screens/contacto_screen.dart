import 'dart:async';

import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class ContactoScreen extends StatefulWidget {
  const ContactoScreen({super.key, required this.dataService});

  final DataService dataService;

  @override
  State<ContactoScreen> createState() => _ContactoScreenState();
}

class _ContactoScreenState extends State<ContactoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _honeypotController = TextEditingController();
  bool _isSending = false;
  bool _sent = false;
  String? _error;
  Timer? _successTimer;

  @override
  void dispose() {
    _successTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _honeypotController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate() || _isSending) return;
    if (_honeypotController.text.trim().isNotEmpty) return;
    setState(() {
      _isSending = true;
      _sent = false;
      _error = null;
    });
    try {
      await widget.dataService.sendContactMessage(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );
      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();
      if (!mounted) return;
      setState(() => _sent = true);
      _successTimer?.cancel();
      _successTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _sent = false);
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'NO SE PUDO ENVIAR EL MENSAJE: $error');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '> CONTACTO // MENSAJE A LA PECERA',
          style: TextStyle(
            color: TerminalTheme.red,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        TerminalPanel(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Abre una línea directa con DEATHFISH.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'NOMBRE / ORGANIZACIÓN',
                  ),
                  validator: (value) => (value?.trim().isNotEmpty ?? false)
                      ? null
                      : 'Este campo es obligatorio.',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'CORREO ELECTRÓNICO',
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                        ? null
                        : 'Ingresa un correo válido.';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'ASUNTO'),
                  validator: (value) => (value?.trim().isNotEmpty ?? false)
                      ? null
                      : 'Este campo es obligatorio.',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  minLines: 5,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: 'MENSAJE'),
                  validator: (value) => (value?.trim().isNotEmpty ?? false)
                      ? null
                      : 'Escribe tu mensaje.',
                ),
                Offstage(
                  child: TextFormField(
                    controller: _honeypotController,
                    keyboardType: TextInputType.url,
                    autofillHints: const [],
                    decoration: const InputDecoration(
                      labelText: 'No completar',
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: const TextStyle(color: TerminalTheme.red),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSending || _sent ? null : _send,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _sent
                          ? TerminalTheme.red
                          : Colors.transparent,
                      disabledForegroundColor: Colors.white,
                      disabledBackgroundColor: _sent
                          ? TerminalTheme.red
                          : Colors.white12,
                      side: const BorderSide(color: TerminalTheme.red),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    child: Text(
                      _sent
                          ? '¡MENSAJE ENVIADO A LA PECERA!'
                          : _isSending
                          ? 'ENVIANDO TRANSMISIÓN...'
                          : 'ENVIAR MENSAJE',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'EL MENSAJE SE TRANSMITE DE FORMA SEGURA A LA PECERA.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 9),
        ),
      ],
    );
  }
}
