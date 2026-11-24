import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/band_info.dart';
import '../services/auth_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    required this.bandInfo,
  });

  final AuthGateway authService;
  final BandInfo bandInfo;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool asGuest}) async {
    if (!asGuest && !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (asGuest) {
        final session = await widget.authService.signInAsGuest();
        if (!session.isGuest) {
          throw StateError('El acceso invitado debe ser de solo lectura.');
        }
      } else if (_isRegistering) {
        await widget.authService.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await widget.authService.signIn(
          _emailController.text,
          _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authError(error));
    } catch (error) {
      if (mounted) setState(() => _error = 'ERROR DE AUTENTICACIÓN: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _authError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'CORREO O CONTRASEÑA INCORRECTOS.';
      case 'email-already-in-use':
        return 'ESE CORREO YA TIENE UNA CUENTA.';
      case 'invalid-email':
        return 'EL CORREO NO ES VÁLIDO.';
      case 'weak-password':
        return 'LA CONTRASEÑA DEBE TENER AL MENOS 6 CARACTERES.';
      case 'operation-not-allowed':
        return 'HABILITA ESTE MÉTODO DE ACCESO EN FIREBASE AUTHENTICATION.';
      default:
        return 'FIREBASE AUTH ${error.code}: ${error.message ?? 'ERROR'}';
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
                          widget.bandInfo.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.bandInfo.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: TerminalTheme.red,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _isRegistering
                              ? '> REGISTRO DE NUEVA CUENTA'
                              : '> TERMINAL DE ACCESO',
                          style: const TextStyle(color: TerminalTheme.red),
                        ),
                        const SizedBox(height: 16),
                        if (_isRegistering) ...[
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'NOMBRE',
                            ),
                            validator: (value) =>
                                (value?.trim().isNotEmpty ?? false)
                                ? null
                                : 'Ingresa tu nombre.',
                          ),
                          const SizedBox(height: 14),
                        ],
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
                          onFieldSubmitted: (_) => _submit(asGuest: false),
                          decoration: const InputDecoration(
                            labelText: 'CONTRASEÑA',
                          ),
                          validator: (value) => (value?.length ?? 0) >= 6
                              ? null
                              : 'Mínimo 6 caracteres.',
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
                              : _isRegistering
                              ? 'CREAR CUENTA'
                              : 'INICIAR SESIÓN',
                          onPressed: _isLoading
                              ? null
                              : () => _submit(asGuest: false),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => setState(() {
                                  _isRegistering = !_isRegistering;
                                  _error = null;
                                }),
                          child: Text(
                            _isRegistering
                                ? 'YA TENGO UNA CUENTA // INICIAR SESIÓN'
                                : 'CREAR CUENTA DE FAN',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'monospace',
                              fontSize: 10,
                            ),
                          ),
                        ),
                        TerminalButton(
                          label: 'ENTRAR COMO INVITADO',
                          icon: Icons.login,
                          isPrimary: false,
                          onPressed: _isLoading
                              ? null
                              : () => _submit(asGuest: true),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '© ${widget.bandInfo.year} ${widget.bandInfo.name} - ${widget.bandInfo.label}',
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
