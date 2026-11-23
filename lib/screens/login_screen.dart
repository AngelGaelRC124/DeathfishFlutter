import 'package:flutter/material.dart';

import '../models/user_session.dart';
import '../services/data_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.dataService,
    required this.onAuthenticated,
  });

  final DataService dataService;
  final ValueChanged<UserSession> onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login({required bool asGuest}) async {
    if (!asGuest && !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final session = asGuest
          ? await widget.dataService.loginAsGuest()
          : await widget.dataService.login(
              _emailController.text,
              _passwordController.text,
            );
      if (mounted) widget.onAuthenticated(session);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'NO SE PUDO GUARDAR LA SESIÓN: $error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TerminalBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: TerminalPanel(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.dataService.bandInfo.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.dataService.bandInfo.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: TerminalTheme.red,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          '> TERMINAL DE ACCESO',
                          style: TextStyle(color: TerminalTheme.red),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'CORREO ELECTRÓNICO',
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(email)
                                ? null
                                : 'Ingresa un correo válido.';
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          onFieldSubmitted: (_) => _login(asGuest: false),
                          decoration: const InputDecoration(
                            labelText: 'CONTRASEÑA',
                          ),
                          validator: (value) {
                            return (value?.length ?? 0) >= 6
                                ? null
                                : 'Mínimo 6 caracteres.';
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            style: const TextStyle(color: TerminalTheme.red),
                          ),
                        ],
                        const SizedBox(height: 20),
                        TerminalButton(
                          label: _isLoading
                              ? 'CONECTANDO...'
                              : 'INICIAR SESIÓN',
                          onPressed: _isLoading
                              ? null
                              : () => _login(asGuest: false),
                        ),
                        const SizedBox(height: 10),
                        TerminalButton(
                          label: 'ENTRAR COMO INVITADO',
                          icon: Icons.login,
                          isPrimary: false,
                          onPressed: _isLoading
                              ? null
                              : () => _login(asGuest: true),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '© ${widget.dataService.bandInfo.year} ${widget.dataService.bandInfo.name} - ${widget.dataService.bandInfo.label}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
