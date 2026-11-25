import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/radio_station.dart';
import '../models/user_session.dart';
import '../providers/audio_provider.dart';
import '../services/firestore_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({
    super.key,
    required this.gateway,
    required this.session,
    required this.isActive,
  });

  final RadioGateway? gateway;
  final UserSession session;
  final bool isActive;

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  bool _presenceRegistered = false;

  @override
  void didUpdateWidget(covariant RadioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive && !widget.isActive) {
      unawaited(_setPresence(false));
    }
  }

  Future<void> _setPresence(bool shouldRegister) async {
    final gateway = widget.gateway;
    if (gateway == null || widget.session.isGuest || !mounted) return;
    if (_presenceRegistered == shouldRegister) return;
    _presenceRegistered = shouldRegister;
    try {
      await gateway.adjustRadioListeners(shouldRegister ? 1 : -1);
    } catch (error, stackTrace) {
      _presenceRegistered = !shouldRegister;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NO SE PUDO ACTUALIZAR LA AUDIENCIA: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      } else {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'radio',
            context: ErrorDescription('al actualizar el contador de oyentes'),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final gateway = widget.gateway;
    if (gateway == null || widget.session.isGuest || _isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await gateway.sendRadioMessage(
        uid: widget.session.uid,
        author: widget.session.name?.trim().isNotEmpty == true
            ? widget.session.name!.trim()
            : widget.session.email.split('@').first,
        message: text,
      );
      _messageController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NO SE PUDO TRANSMITIR EL SALUDO: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _toggleRadio(RadioStation station) async {
    final audio = context.read<AudioProvider>();
    try {
      if (audio.currentTrack?.id == 'radio_live') {
        await audio.close();
      } else {
        await audio.playStream(
          title: station.programTitle.trim().isEmpty
              ? 'RADIO LA PECERA'
              : station.programTitle,
          url: station.streamUrl,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NO SE PUDO CONECTAR A RADIO FM: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_presenceRegistered) {
      unawaited(widget.gateway?.adjustRadioListeners(-1));
    }
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gateway = widget.gateway;
    if (gateway == null) {
      return const Center(
        child: TerminalPanel(
          child: Text(
            'RADIO // SERVICIO FIRESTORE NO DISPONIBLE',
            textAlign: TextAlign.center,
            style: TextStyle(color: TerminalTheme.red),
          ),
        ),
      );
    }
    return StreamBuilder<RadioStation>(
      stream: gateway.watchRadioStation(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'ERROR DE SEÑAL: ${snapshot.error}',
              style: const TextStyle(color: TerminalTheme.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: TerminalTheme.red),
          );
        }
        final station = snapshot.data!;
        unawaited(_setPresence(widget.isActive && station.isLive));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TerminalPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    station.isLive ? '[ 🔴 ON_AIR ]' : '88.5 // LA PECERA FM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: station.isLive ? TerminalTheme.red : Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    station.isLive
                        ? '> SIGNAL_STATUS: ON_AIR'
                        : '> SIGNAL_STATUS: OFFLINE // FRECUENCIA EN SILENCIO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: station.isLive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                  if (station.programTitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      station.isLive
                          ? '> PROGRAMA ACTUAL // ${station.programTitle}'
                          : '> ÚLTIMO PROGRAMA // ${station.programTitle}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: TerminalTheme.red,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  if (station.isLive) ...[
                    const SizedBox(height: 8),
                    Text(
                      'OYENTES CONECTADOS // ${station.listenersCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<AudioProvider>(
                      builder: (context, audio, _) => OutlinedButton(
                        onPressed: () => _toggleRadio(station),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              audio.currentTrack?.id == 'radio_live'
                              ? TerminalTheme.red
                              : Colors.black,
                          side: const BorderSide(color: TerminalTheme.red),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: Text(
                          audio.currentTrack?.id == 'radio_live'
                              ? '[ DESCONECTAR RADIO ]'
                              : '[ CONECTAR A LA SEÑAL ]',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (station.isLive) ...[
              const SizedBox(height: 16),
              _LiveChat(
                gateway: gateway,
                session: widget.session,
                controller: _messageController,
                isSending: _isSending,
                onSend: _sendMessage,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LiveChat extends StatelessWidget {
  const _LiveChat({
    required this.gateway,
    required this.session,
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final RadioGateway gateway;
  final UserSession session;
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => TerminalPanel(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '> LIVE SHOUTBOX // CABINA',
          style: TextStyle(
            color: TerminalTheme.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
          child: StreamBuilder<List<RadioChatMessage>>(
            stream: gateway.watchRadioChat(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'ERROR AL CARGAR CHAT: ${snapshot.error}',
                  style: const TextStyle(color: TerminalTheme.red),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: TerminalTheme.red),
                );
              }
              final messages = snapshot.data!;
              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    'SIN MENSAJES // ABRE LA TRANSMISIÓN',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                );
              }
              return ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${message.author} > ${message.message}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (!session.isGuest) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLength: 240,
                  decoration: const InputDecoration(
                    hintText: 'ESCRIBE UN SALUDO...',
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: isSending ? null : onSend,
                tooltip: 'Transmitir saludo',
                icon: const Icon(Icons.send, color: TerminalTheme.red),
              ),
            ],
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'INICIA SESIÓN COMO FAN PARA ENVIAR SALUDOS.',
              style: TextStyle(color: Colors.white54, fontSize: 9),
            ),
          ),
      ],
    ),
  );
}
