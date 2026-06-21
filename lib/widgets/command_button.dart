import 'package:flutter/material.dart';
import '../design/tokens.dart';

/// Pre-defined button style variants for the panel.
enum CommandButtonStyle {
  accent,    // Emerald — primary action
  danger,    // Red — destructive action
  warning,   // Amber — caution
  default_,  // Slate — neutral
}

/// A styled action button used across the command panel.
///
/// Wraps [ElevatedButton] in the CS2 dark-theme aesthetic.
class CommandButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final CommandButtonStyle style;
  final bool isLoading;
  final bool isActive;
  final bool enabled;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final double fontSize;

  const CommandButton({
    super.key,
    required this.label,
    this.icon,
    this.style = CommandButtonStyle.default_,
    this.isLoading = false,
    this.isActive = false,
    this.enabled = true,
    this.onPressed,
    this.width,
    this.height,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();

    return SizedBox(
      width: width,
      height: height ?? 40,
      child: ElevatedButton(
        onPressed: (enabled && !isLoading) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? colors.activeBg : colors.bg,
          foregroundColor: isActive ? colors.activeFg : colors.fg,
          disabledBackgroundColor: CS2Colors.slate800,
          disabledForegroundColor: CS2Colors.slate600,
          padding: const EdgeInsets.symmetric(
            horizontal: CS2Spacing.sm,
            vertical: CS2Spacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CS2Radius.sm),
            side: BorderSide(
              color: isActive ? colors.activeBorder : colors.border,
              width: isActive ? 1.2 : 0.8,
            ),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CS2Colors.slate200,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  _ButtonColors _resolveColors() {
    switch (style) {
      case CommandButtonStyle.accent:
        return _ButtonColors(
          bg: isActive ? CS2Colors.emerald600 : CS2Colors.emerald500.withAlpha(30),
          fg: isActive ? Colors.white : CS2Colors.emerald400,
          activeBg: CS2Colors.emerald600,
          activeFg: Colors.white,
          activeBorder: CS2Colors.emerald400,
          border: CS2Colors.emerald500.withAlpha(60),
        );
      case CommandButtonStyle.danger:
        return _ButtonColors(
          bg: isActive ? CS2Colors.red700 : CS2Colors.red500.withAlpha(30),
          fg: isActive ? Colors.white : CS2Colors.red400,
          activeBg: CS2Colors.red700,
          activeFg: Colors.white,
          activeBorder: CS2Colors.red400,
          border: CS2Colors.red500.withAlpha(60),
        );
      case CommandButtonStyle.warning:
        return _ButtonColors(
          bg: isActive ? CS2Colors.amber500.withAlpha(80) : CS2Colors.amber500.withAlpha(25),
          fg: CS2Colors.amber400,
          activeBg: CS2Colors.amber500.withAlpha(80),
          activeFg: Colors.white,
          activeBorder: CS2Colors.amber400,
          border: CS2Colors.amber500.withAlpha(50),
        );
      case CommandButtonStyle.default_:
        return _ButtonColors(
          bg: isActive ? CS2Colors.slate700 : CS2Colors.slate600.withAlpha(40),
          fg: isActive ? Colors.white : CS2Colors.slate200,
          activeBg: CS2Colors.slate700,
          activeFg: Colors.white,
          activeBorder: CS2Colors.slate500,
          border: CS2Colors.slate600.withAlpha(60),
        );
    }
  }
}

class _ButtonColors {
  final Color bg;
  final Color fg;
  final Color activeBg;
  final Color activeFg;
  final Color activeBorder;
  final Color border;

  const _ButtonColors({
    required this.bg,
    required this.fg,
    required this.activeBg,
    required this.activeFg,
    required this.activeBorder,
    required this.border,
  });
}
