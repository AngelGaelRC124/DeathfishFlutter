import 'package:flutter/material.dart';

import '../theme/terminal_theme.dart';

class TerminalBackground extends StatelessWidget {
  const TerminalBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/fondo1.JPG', fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.75)),
        child,
      ],
    );
  }
}

class TerminalPanel extends StatelessWidget {
  const TerminalPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        border: Border.all(color: TerminalTheme.red.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: child,
    );
  }
}

class TerminalButton extends StatelessWidget {
  const TerminalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = isPrimary ? Colors.white : TerminalTheme.red;
    final background = isPrimary ? TerminalTheme.red : Colors.transparent;
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
        side: BorderSide(
          color: isPrimary
              ? TerminalTheme.red
              : TerminalTheme.red.withValues(alpha: 0.6),
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 8)],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
    return SizedBox(width: double.infinity, child: button);
  }
}

class TerminalMessageScreen extends StatelessWidget {
  const TerminalMessageScreen({
    super.key,
    required this.message,
    this.detail,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TerminalBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: TerminalPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: TerminalTheme.red,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (showProgress) ...[
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(color: TerminalTheme.red),
                    ],
                    if (detail != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        detail!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 20),
                      TerminalButton(
                        label: actionLabel!,
                        onPressed: onAction,
                        isPrimary: false,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
