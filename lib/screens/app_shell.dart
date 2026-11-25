import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/radio_station.dart';
import '../models/user_session.dart';
import '../providers/audio_provider.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';
import '../widgets/global_audio_bar.dart';
import 'admin_screen.dart';
import 'audio_hub_screen.dart';
import 'contacto_screen.dart';
import 'admin_qr_scanner_screen.dart';
import 'community_screen.dart';
import 'inicio_screen.dart';
import 'merch_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.authService,
    required this.firestoreService,
    required this.dataService,
    required this.session,
    this.notificationService,
  });

  final AuthGateway authService;
  final FirestoreGateway firestoreService;
  final DataService dataService;
  final UserSession session;
  final NotificationService? notificationService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _showAdmin = false;
  bool _showContact = false;
  final GlobalKey<AudioHubScreenState> _audioHubKey =
      GlobalKey<AudioHubScreenState>();
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<Object>? _notificationErrorSubscription;

  @override
  void initState() {
    super.initState();
    _attachNotifications();
  }

  void _attachNotifications() {
    final service = widget.notificationService;
    if (service == null || widget.session.isGuest) return;
    _foregroundSubscription = service.foregroundMessages.listen(
      _showForegroundNotification,
      onError: (Object error) => _showNotificationError(error),
    );
    _notificationErrorSubscription = service.errors.listen(
      _showNotificationError,
    );
    unawaited(_initializeNotifications(service, widget.session.uid));
  }

  Future<void> _initializeNotifications(
    NotificationService service,
    String uid,
  ) async {
    try {
      final warnings = await service.initializeForUser(uid);
      for (final warning in warnings) {
        _showNotificationError(warning);
      }
    } catch (error) {
      _showNotificationError(error);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'NUEVA TRANSMISIÓN';
    final body = message.notification?.body ?? message.data['body']?.toString();
    _showNotificationError(
      body == null || body.isEmpty ? 'PUSH // $title' : 'PUSH // $title\n$body',
    );
  }

  void _showNotificationError(Object error) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            error.toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  Future<void> _openQrScanner() async {
    final service = widget.firestoreService;
    final gateway = service is PhaseTwoGateway
        ? service as PhaseTwoGateway
        : null;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdminQrScannerScreen(gateway: gateway),
      ),
    );
  }

  Future<void> _showFanPass() async {
    final session = widget.session;
    final passData = jsonEncode({'uid': session.uid, 'email': session.email});
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(
          '> CREDENCIAL / PASE TERMINAL',
          style: TextStyle(
            color: TerminalTheme.red,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: TerminalTheme.red, width: 1),
                ),
                child: QrImageView(
                  data: passData,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.black,
                  eyeStyle: const QrEyeStyle(color: Colors.white),
                  dataModuleStyle: const QrDataModuleStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                (session.name?.trim().isNotEmpty ?? false)
                    ? session.name!
                    : session.email.split('@').first,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                session.isAdmin ? 'ROL // ADMIN' : 'ROL // FAN',
                style: const TextStyle(color: TerminalTheme.red, fontSize: 11),
              ),
              const SizedBox(height: 5),
              SelectableText(
                session.email,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),
        actions: [
          if (session.isAdmin)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                unawaited(_openQrScanner());
              },
              icon: const Icon(
                Icons.qr_code_scanner,
                color: TerminalTheme.red,
              ),
              label: const Text(
                '[ ESCÁNER DE PASES QR ]',
                style: TextStyle(color: TerminalTheme.red, fontSize: 9),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'CERRAR',
              style: TextStyle(color: TerminalTheme.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.uid != widget.session.uid ||
        oldWidget.notificationService != widget.notificationService) {
      unawaited(
        oldWidget.notificationService?.stopForUser(oldWidget.session.uid),
      );
      unawaited(_foregroundSubscription?.cancel());
      unawaited(_notificationErrorSubscription?.cancel());
      _foregroundSubscription = null;
      _notificationErrorSubscription = null;
      _attachNotifications();
    }
    if (oldWidget.session.isAdmin && !widget.session.isAdmin) {
      _showAdmin = false;
    }
  }

  @override
  void dispose() {
    unawaited(_foregroundSubscription?.cancel());
    unawaited(_notificationErrorSubscription?.cancel());
    if (!widget.session.isGuest) {
      unawaited(
        widget.notificationService?.stopForUser(widget.session.uid),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.dataService;
    final pages = [
      InicioScreen(
        dataService: data,
        firestoreService: widget.firestoreService,
        session: widget.session,
      ),
      AudioHubScreen(
        key: _audioHubKey,
        dataService: data,
        firestoreService: widget.firestoreService,
        session: widget.session,
      ),
      CommunityScreen(
        dataService: data,
        firestoreService: widget.firestoreService,
        session: widget.session,
      ),
      MerchScreen(dataService: data, firestoreService: widget.firestoreService),
    ];

    return Scaffold(
      body: TerminalBackground(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  border: Border(
                    bottom: BorderSide(color: const Color(0xFF222222)),
                  ),
                ),
                child: Row(
                  children: [
                    if (_showAdmin || _showContact)
                      IconButton(
                        tooltip: 'Volver a la app',
                        onPressed: () => setState(() {
                          _showAdmin = false;
                          _showContact = false;
                        }),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: TerminalTheme.red,
                        ),
                      )
                    else
                      const SizedBox(width: 28),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            data.bandInfo.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _showAdmin
                                ? 'MODO ADMINISTRADOR // ${data.bandInfo.label}'
                                : widget.session.isAdmin
                                ? 'ADMINISTRADOR // ${data.bandInfo.label}'
                                : widget.session.isGuest
                                ? 'ACCESO INVITADO // ${data.bandInfo.label}'
                                : data.bandInfo.label,
                            style: const TextStyle(
                              color: TerminalTheme.red,
                              fontSize: 9,
                              letterSpacing: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (!_showAdmin && !_showContact)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Contacto',
                        onPressed: () => setState(() => _showContact = true),
                        icon: const Icon(
                          Icons.mail_outline,
                          color: TerminalTheme.red,
                        ),
                      ),
                    if (widget.session.isAdmin && !_showAdmin && !_showContact)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Panel de administrador',
                        onPressed: () => setState(() {
                          _showAdmin = true;
                          _showContact = false;
                        }),
                        icon: const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: TerminalTheme.red,
                        ),
                      ),
                    if (!widget.session.isGuest && !_showAdmin && !_showContact)
                      TextButton.icon(
                        onPressed: _showFanPass,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(
                          Icons.qr_code_2,
                          color: TerminalTheme.red,
                          size: 18,
                        ),
                        label: const Text(
                          '[ ID ]',
                          style: TextStyle(
                            color: TerminalTheme.red,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    if (!_showAdmin && !_showContact)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Cerrar sesión',
                        onPressed: () async {
                          try {
                            await widget.authService.signOut();
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'ERROR AL CERRAR SESIÓN: $error',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: TerminalTheme.red,
                        ),
                      ),
                  ],
                ),
              ),
              _radioBanner(),
              Expanded(
                child: _showAdmin
                    ? AdminScreen(
                        dataService: data,
                        firestoreService: widget.firestoreService,
                        session: widget.session,
                      )
                    : _showContact
                    ? ContactoScreen(
                        dataService: data,
                        firestoreService: widget.firestoreService,
                        session: widget.session,
                      )
                    : IndexedStack(index: _selectedIndex, children: pages),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text(
                  '© ${data.bandInfo.year} ${data.bandInfo.name} - ${data.bandInfo.label}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    letterSpacing: 0.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Consumer<AudioProvider>(
        builder: (context, audio, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (audio.currentTrack != null) const GlobalAudioBar(),
            if (_showAdmin || _showContact)
              BottomAppBar(
                color: Colors.black,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _showAdmin = false;
                    _showContact = false;
                  }),
                  icon: const Icon(Icons.arrow_back, color: TerminalTheme.red),
                  label: Text(
                    _showAdmin ? 'VOLVER A LA PECERA' : 'VOLVER A INICIO',
                    style: TextStyle(color: TerminalTheme.red),
                  ),
                ),
              )
            else
              BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                selectedFontSize: 9,
                unselectedFontSize: 8,
                iconSize: 18,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    label: 'INICIO',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.graphic_eq),
                    label: 'SONIDO',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_outline),
                    label: 'COMUNIDAD',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_bag_outlined),
                    label: 'TIENDA',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _radioBanner() {
    final service = widget.firestoreService;
    if (service is! RadioGateway) return const SizedBox.shrink();
    final radioGateway = service as RadioGateway;
    return StreamBuilder<RadioStation>(
      stream: radioGateway.watchRadioStation(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'RADIO // ERROR DE SEÑAL: ${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TerminalTheme.red,
                fontSize: 9,
                fontFamily: 'monospace',
              ),
            ),
          );
        }
        if (snapshot.data?.isLive != true) return const SizedBox.shrink();
        return _BlinkingOnAirBanner(
          onTap: () {
            setState(() {
              _showAdmin = false;
              _showContact = false;
              _selectedIndex = 1;
            });
            _audioHubKey.currentState?.selectRadio();
          },
        );
      },
    );
  }
}

class _BlinkingOnAirBanner extends StatefulWidget {
  const _BlinkingOnAirBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BlinkingOnAirBanner> createState() => _BlinkingOnAirBannerState();
}

class _BlinkingOnAirBannerState extends State<_BlinkingOnAirBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    lowerBound: 0.45,
    upperBound: 1,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) =>
        Opacity(opacity: _controller.value, child: child),
    child: Material(
      color: TerminalTheme.red,
      child: InkWell(
        onTap: widget.onTap,
        child: const SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(
              '[ 🔴 RADIO LA PECERA AL AIRE // TOCA PARA SINTONIZAR ]',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
