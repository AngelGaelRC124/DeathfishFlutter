import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/timed_comment.dart';
import '../models/track.dart';
import '../models/user_session.dart';
import '../providers/audio_provider.dart';
import '../services/firestore_service.dart';
import '../theme/terminal_theme.dart';

class TimedCommentsPanel extends StatefulWidget {
  const TimedCommentsPanel({
    super.key,
    required this.track,
    required this.gateway,
    required this.session,
  });

  final Track track;
  final PhaseThreeGateway gateway;
  final UserSession session;

  @override
  State<TimedCommentsPanel> createState() => _TimedCommentsPanelState();
}

class _TimedCommentsPanelState extends State<TimedCommentsPanel> {
  bool _sending = false;

  Future<void> _addNote(AudioProvider audio) async {
    if (widget.session.isGuest) {
      _notify('INICIA SESIÓN COMO FAN PARA ANCLAR UNA NOTA.');
      return;
    }
    if (audio.currentTrack?.id != widget.track.id) {
      _notify('REPRODUCE ESTA PISTA PARA ANCLARLA AL SEGUNDO ACTUAL.');
      return;
    }
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(
          '> NOTA EN ESTE SEGUNDO',
          style: TextStyle(color: TerminalTheme.red, fontSize: 12),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'ESCRIBE UNA NOTA...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text(
              '[ ANCLAR ]',
              style: TextStyle(color: TerminalTheme.red),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty || !mounted) return;
    setState(() => _sending = true);
    try {
      final author = widget.session.name?.trim().isNotEmpty == true
          ? widget.session.name!.trim()
          : widget.session.email.split('@').first;
      await widget.gateway.addTimedComment(
        trackId: widget.track.id,
        uid: widget.session.uid,
        userName: author,
        second: audio.position.inSeconds,
        text: text,
      );
    } catch (error) {
      _notify('NO SE PUDO ANCLAR LA NOTA: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: TerminalTheme.red),
    );
  }

  String _clock(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<TimedComment>>(
    stream: widget.gateway.watchTimedComments(widget.track.id),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Text(
          'ERROR AL CARGAR NOTAS: ${snapshot.error}',
          style: const TextStyle(color: TerminalTheme.red, fontSize: 9),
        );
      }
      final comments = snapshot.data ?? const <TimedComment>[];
      return Consumer<AudioProvider>(
        builder: (context, audio, _) {
          final isTrackActive = audio.currentTrack?.id == widget.track.id;
          final position = audio.position.inSeconds;
          final current = isTrackActive
              ? comments.where((item) => (item.second - position).abs() <= 1)
              : const <TimedComment>[];
          final duration = audio.duration.inSeconds;
          final progress = isTrackActive && duration > 0
              ? (position / duration).clamp(0.0, 1.0)
              : 0.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '> NOTAS ANCLADAS // TIMED LOG',
                style: TextStyle(color: TerminalTheme.red, fontSize: 9),
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: 18,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 3,
                        color: Colors.white24,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(height: 3, color: TerminalTheme.red),
                        ),
                      ),
                      for (final comment in comments)
                        if (duration > 0)
                          Positioned(
                            left: (constraints.maxWidth *
                                        (comment.second / duration))
                                    .clamp(0.0, constraints.maxWidth - 5)
                                .toDouble(),
                            child: const Text(
                              '•',
                              style: TextStyle(
                                color: TerminalTheme.red,
                                fontSize: 17,
                                height: 1,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              if (current.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(7),
                  color: const Color(0xFF171717),
                  child: Text(
                    '[${_clock(current.first.second)}] '
                    '@${current.first.userName} > ${current.first.text}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      height: 1.4,
                    ),
                  ),
                ),
              if (!widget.session.isGuest)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _sending ? null : () => _addNote(audio),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _sending
                          ? '[ ANCLANDO... ]'
                          : '[ + NOTA EN ESTE SEGUNDO ]',
                      style: const TextStyle(
                        color: TerminalTheme.red,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                )
              else
                const Text(
                  'INICIA SESIÓN PARA DEJAR NOTAS.',
                  style: TextStyle(color: Colors.white54, fontSize: 9),
                ),
              if (comments.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 88),
                  margin: const EdgeInsets.only(top: 5),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              '[${_clock(comment.second)}] '
                              '@${comment.userName} > ${comment.text}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          if (widget.session.isAdmin)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () async {
                                try {
                                  await widget.gateway.deleteTimedComment(
                                    widget.track.id,
                                    comment.id,
                                  );
                                } catch (error) {
                                  _notify('NO SE PUDO BORRAR LA NOTA: $error');
                                }
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: TerminalTheme.red,
                                size: 15,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}
