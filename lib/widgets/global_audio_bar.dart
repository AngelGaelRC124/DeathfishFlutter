import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/audio_provider.dart';
import '../theme/terminal_theme.dart';

class GlobalAudioBar extends StatelessWidget {
  const GlobalAudioBar({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final track = audio.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final durationMs = audio.duration.inMilliseconds;
    final positionMs = audio.position.inMilliseconds
        .clamp(0, durationMs > 0 ? durationMs : 0)
        .toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 0),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: TerminalTheme.red, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${track.title} // ${track.album}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              _AudioEqualizer(isPlaying: audio.isPlaying),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: audio.isPlaying ? 'Pausar' : 'Reproducir',
                onPressed: audio.isLoading
                    ? null
                    : () => _run(context, audio.togglePlayback),
                icon: Icon(
                  audio.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: TerminalTheme.red,
                  size: 20,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Cerrar reproductor',
                onPressed: () => _run(context, audio.close),
                icon: const Icon(
                  Icons.close,
                  color: TerminalTheme.red,
                  size: 18,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 15,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: TerminalTheme.red,
                inactiveTrackColor: Colors.white24,
                thumbColor: TerminalTheme.red,
              ),
              child: Slider(
                min: 0,
                max: durationMs > 0 ? durationMs.toDouble() : 1,
                value: durationMs > 0 ? positionMs : 0,
                onChanged: durationMs <= 0
                    ? null
                    : (value) => unawaited(
                        audio.seek(Duration(milliseconds: value.round())),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERROR DEL REPRODUCTOR: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    }
  }
}

class _AudioEqualizer extends StatefulWidget {
  const _AudioEqualizer({required this.isPlaying});

  final bool isPlaying;

  @override
  State<_AudioEqualizer> createState() => _AudioEqualizerState();
}

class _AudioEqualizerState extends State<_AudioEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _AudioEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying == oldWidget.isPlaying) return;
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => SizedBox(
      width: 42,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(8, (index) {
          final phase = (_controller.value * 2 * 3.14159) + index * 0.9;
          final height = widget.isPlaying
              ? 4.0 + ((math.sin(phase) + 1) * 8)
              : 3.0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 3,
            height: height,
            color: TerminalTheme.red,
          );
        }),
      ),
    ),
  );
}
