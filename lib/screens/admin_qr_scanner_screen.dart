import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/firestore_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class AdminQrScannerScreen extends StatefulWidget {
  const AdminQrScannerScreen({super.key, required this.gateway});

  final PhaseTwoGateway? gateway;

  @override
  State<AdminQrScannerScreen> createState() => _AdminQrScannerScreenState();
}

class _AdminQrScannerScreenState extends State<AdminQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  Map<String, dynamic>? _profile;
  String? _error;
  String? _scannedUid;
  bool _isReading = false;
  bool _isRegistering = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isReading || _scannedUid != null) return;
    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (rawValue == null || rawValue.isEmpty) return;
    _isReading = true;
    try {
      await _controller.stop();
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map) {
        throw const FormatException('El QR no contiene un perfil válido.');
      }
      final qr = Map<String, dynamic>.from(decoded);
      final uid = qr['uid'];
      final email = qr['email'];
      if (uid is! String || uid.trim().isEmpty || email is! String) {
        throw const FormatException('El QR debe incluir uid y correo.');
      }
      final gateway = widget.gateway;
      if (gateway == null) {
        throw StateError('El servicio de perfiles no está disponible.');
      }
      final profile = await gateway.readUserProfile(uid.trim());
      if (profile == null) {
        throw StateError('NO SE ENCONTRÓ EL PERFIL DEL PASE.');
      }
      final profileEmail = profile['email'] as String? ?? '';
      if (profileEmail.toLowerCase() != email.trim().toLowerCase()) {
        throw const FormatException(
          'EL CORREO DEL QR NO COINCIDE CON EL PERFIL.',
        );
      }
      if (profile['rol'] != 'fan') {
        throw const FormatException('EL PASE NO PERTENECE A UN FAN.');
      }
      if (!mounted) return;
      setState(() {
        _scannedUid = uid.trim();
        _profile = profile;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      _isReading = false;
    }
  }

  Future<void> _registerAttendance() async {
    final gateway = widget.gateway;
    final uid = _scannedUid;
    if (gateway == null || uid == null || _isRegistering) return;
    setState(() => _isRegistering = true);
    try {
      await gateway.registerEventAttendance(uid);
      final profile = await gateway.readUserProfile(uid);
      if (mounted) setState(() => _profile = profile);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NO SE PUDO REGISTRAR ASISTENCIA: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<void> _scanAgain() async {
    setState(() {
      _profile = null;
      _error = null;
      _scannedUid = null;
    });
    try {
      await _controller.start();
    } catch (error) {
      if (mounted) setState(() => _error = 'CÁMARA NO DISPONIBLE: $error');
    }
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: const Text(
        '[ ESCÁNER DE PASES QR ]',
        style: TextStyle(
          color: TerminalTheme.red,
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      ),
      iconTheme: const IconThemeData(color: TerminalTheme.red),
    ),
    body: widget.gateway == null
        ? const Center(
            child: Text(
              'SERVICIO DE ESCANEO NO DISPONIBLE.',
              style: TextStyle(color: TerminalTheme.red),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '> ENCUADRA EL PASE DE UN FAN',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      onDetectError: (error, stackTrace) {
                        if (mounted) {
                          setState(
                            () => _error = 'ERROR DE LECTURA QR: $error',
                          );
                        }
                      },
                      errorBuilder: (context, error) => Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'CÁMARA / PERMISO NO DISPONIBLE\n${error.errorCode.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: TerminalTheme.red,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      placeholderBuilder: (_) => const Center(
                        child: CircularProgressIndicator(
                          color: TerminalTheme.red,
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: TerminalTheme.red,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.qr_code_2,
                          color: TerminalTheme.red,
                          size: 38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TerminalTheme.red,
                    fontSize: 10,
                  ),
                ),
              ],
              if (_profile != null) ...[
                const SizedBox(height: 14),
                TerminalPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '> FICHA DE VERIFICACIÓN // FAN',
                        style: TextStyle(
                          color: TerminalTheme.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _profileField('NOMBRE', _profile!['nombre']),
                      _profileField('CORREO', _profile!['email']),
                      _profileField('ROL', _profile!['rol']),
                      _profileField(
                        'CÓDIGOS DESBLOQUEADOS',
                        _unlockedCodesText(_profile!['unlockedCodes']),
                      ),
                      _profileField(
                        'EVENTOS / RIFAS',
                        _profile!['eventsAttended'] ?? 0,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _isRegistering ? null : _registerAttendance,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: TerminalTheme.red,
                          side: const BorderSide(color: TerminalTheme.red),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: Text(
                          _isRegistering
                              ? 'REGISTRANDO...'
                              : '[ REGISTRAR ASISTENCIA / RIFA ]',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_scannedUid != null || _error != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _scanAgain,
                  child: const Text(
                    '[ ESCANEAR OTRO PASE ]',
                    style: TextStyle(color: TerminalTheme.red),
                  ),
                ),
              ],
            ],
          ),
  );

  Widget _profileField(String label, Object? value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      '$label // ${value ?? '—'}',
      style: const TextStyle(color: Colors.white70, fontSize: 10),
    ),
  );

  String _unlockedCodesText(Object? value) {
    final codes = value is List ? value.join(', ') : '';
    return codes.isEmpty ? 'NINGUNO' : codes;
  }
}
