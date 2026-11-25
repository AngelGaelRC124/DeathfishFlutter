import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/guestbook_entry.dart';
import '../models/secret_code.dart';
import '../models/user_session.dart';
import '../services/data_service.dart';
import '../services/firestore_service.dart';
import '../theme/terminal_theme.dart';
import 'stream_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({
    super.key,
    required this.dataService,
    required this.firestoreService,
    required this.session,
  });

  final DataService dataService;
  final FirestoreGateway firestoreService;
  final UserSession session;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _codeController = TextEditingController();
  int _selectedTab = 0;
  bool _isRedeeming = false;

  PhaseTwoGateway? get _gateway => widget.firestoreService is PhaseTwoGateway
      ? widget.firestoreService as PhaseTwoGateway
      : null;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeemCode() async {
    final gateway = _gateway;
    if (gateway == null || widget.session.isGuest || _isRedeeming) return;
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _isRedeeming = true);
    try {
      final reward = await gateway.redeemSecretCode(widget.session.uid, code);
      _codeController.clear();
      if (mounted) await _showReward(reward);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CÓDIGO NO DESBLOQUEADO: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
    }
  }

  Future<void> _showReward(SecretCode reward) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          '> RECOMPENSA // ${reward.rewardTitle}',
          style: const TextStyle(
            color: TerminalTheme.red,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
        content: Text(
          reward.rewardDescription,
          style: const TextStyle(color: Colors.white, height: 1.5),
        ),
        actions: [
          if (reward.secretUrl?.isNotEmpty ?? false)
            TextButton(
              onPressed: () async {
                final uri = Uri.tryParse(reward.secretUrl!);
                if (uri == null ||
                    !uri.hasAuthority ||
                    !{'http', 'https'}.contains(uri.scheme)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('EL ENLACE DE LA RECOMPENSA NO ES VÁLIDO.'),
                    ),
                  );
                  return;
                }
                try {
                  final opened = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('NO SE PUDO ABRIR EL ENLACE SECRETO.'),
                      ),
                    );
                  }
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('ERROR AL ABRIR RECOMPENSA: $error')),
                    );
                  }
                }
              },
              child: const Text(
                '[ ABRIR RECOMPENSA ]',
                style: TextStyle(color: TerminalTheme.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'CERRAR',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gateway = _gateway;
    final pages = [
      gateway == null
          ? const Center(
              child: Text(
                'LOG // SERVICIO FIRESTORE NO DISPONIBLE',
                style: TextStyle(color: TerminalTheme.red),
              ),
            )
          : _GuestbookScreen(
              gateway: gateway,
              session: widget.session,
            ),
      StreamScreen(
        dataService: widget.dataService,
        firestoreService: widget.firestoreService,
        session: widget.session,
      ),
    ];
    return Column(
      children: [
        Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '> INGRESAR CÓDIGO DE ACCESO:_',
                style: TextStyle(
                  color: TerminalTheme.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      enabled: !widget.session.isGuest && gateway != null,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        hintText: 'PECERA2026',
                        counterText: '',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _redeemCode(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _isRedeeming ||
                            widget.session.isGuest ||
                            gateway == null
                        ? null
                        : _redeemCode,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TerminalTheme.red,
                      side: const BorderSide(color: TerminalTheme.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(_isRedeeming ? '[ ... ]' : '[ ABRIR ]'),
                  ),
                ],
              ),
              if (widget.session.isGuest)
                const Text(
                  'INICIA SESIÓN COMO FAN PARA CANJEAR CÓDIGOS.',
                  style: TextStyle(color: Colors.white54, fontSize: 9),
                ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: _CommunityTab(
                      label: '[ LOG DEL SISTEMA (MURO) ]',
                      selected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _CommunityTab(
                      label: '[ ARCHIVO // STREAM + CLIPS ]',
                      selected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: IndexedStack(index: _selectedTab, children: pages)),
      ],
    );
  }
}

class _GuestbookScreen extends StatefulWidget {
  const _GuestbookScreen({required this.gateway, required this.session});

  final PhaseTwoGateway gateway;
  final UserSession session;

  @override
  State<_GuestbookScreen> createState() => _GuestbookScreenState();
}

class _GuestbookScreenState extends State<_GuestbookScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_isSending || widget.session.isGuest) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await widget.gateway.addGuestbookMessage(
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
            content: Text('NO SE PUDO ESCRIBIR EN EL LOG: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _timestamp(GuestbookEntry entry) {
    final createdAt = entry.createdAt?.toLocal();
    if (createdAt == null) return '[--:--]';
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '[$hour:$minute]';
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: StreamBuilder<List<GuestbookEntry>>(
          stream: widget.gateway.watchGuestbook(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'ERROR AL LEER EL MURO: ${snapshot.error}',
                  style: const TextStyle(color: TerminalTheme.red),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: TerminalTheme.red),
              );
            }
            final entries = snapshot.data!;
            if (entries.isEmpty) {
              return const Center(
                child: Text(
                  'LOG VACÍO // DEJA LA PRIMERA FIRMA',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final author = entry.author.trim().replaceAll(
                  RegExp(r'\s+'),
                  '_',
                );
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF222222)),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SelectableText(
                          '${_timestamp(entry)} @$author > ${entry.message}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            height: 1.45,
                          ),
                        ),
                      ),
                      if (widget.session.isAdmin)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Eliminar firma',
                          onPressed: () async {
                            try {
                              await widget.gateway.deleteGuestbookEntry(
                                entry.id,
                              );
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'NO SE PUDO MODERAR EL MURO: $error',
                                    ),
                                    backgroundColor: TerminalTheme.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: TerminalTheme.red,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      if (!widget.session.isGuest)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLength: 200,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'FIRMA EL LOG...',
                      counterText: '',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSending ? null : _send,
                  tooltip: 'Publicar firma',
                  icon: const Icon(Icons.send, color: TerminalTheme.red),
                ),
              ],
            ),
          ),
        )
      else
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 5, 12, 12),
          child: Text(
            'INICIA SESIÓN COMO FAN PARA FIRMAR EL LOG.',
            style: TextStyle(color: Colors.white54, fontSize: 9),
          ),
        ),
    ],
  );
}

class _CommunityTab extends StatelessWidget {
  const _CommunityTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: selected ? Colors.black : TerminalTheme.red,
      backgroundColor: selected ? TerminalTheme.red : Colors.black,
      side: const BorderSide(color: TerminalTheme.red),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      textStyle: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 9,
        fontWeight: FontWeight.bold,
      ),
    ),
    child: Text(label, textAlign: TextAlign.center),
  );
}
