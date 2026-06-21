import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/tokens.dart';
import '../services/rcon_service.dart';

/// Read-only log output panel showing all RCON commands and responses.
class LogOutput extends StatefulWidget {
  final List<LogEntry> entries;
  final VoidCallback? onClear;

  const LogOutput({super.key, required this.entries, this.onClear});

  @override
  State<LogOutput> createState() => _LogOutputState();
}

class _LogOutputState extends State<LogOutput> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Disable auto-scroll when user scrolls up
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      _autoScroll = (currentScroll >= maxScroll - 10);
    }
  }

  @override
  void didUpdateWidget(LogOutput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_autoScroll && widget.entries.length > oldWidget.entries.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CS2Spacing.lg,
            vertical: CS2Spacing.sm,
          ),
          decoration: const BoxDecoration(
            color: CS2Colors.surfaceAlt,
            border: Border(
              bottom: BorderSide(color: CS2Colors.cardBorder),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.terminal_rounded, size: 14, color: CS2Colors.textSecondary),
              const SizedBox(width: CS2Spacing.sm),
              Text(
                'RCON 日志',
                style: CS2TextStyles.label.copyWith(color: CS2Colors.textSecondary),
              ),
              const SizedBox(width: CS2Spacing.sm),
              Text(
                '${widget.entries.length} 条记录',
                style: CS2TextStyles.code.copyWith(
                  color: CS2Colors.textMuted,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              // Copy all
              _HeaderButton(
                icon: Icons.copy_rounded,
                tooltip: '复制全部',
                onPressed: _copyAll,
              ),
              const SizedBox(width: 4),
              // Clear
              if (widget.onClear != null)
                _HeaderButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: '清空日志',
                  onPressed: widget.onClear,
                ),
            ],
          ),
        ),

        // Log entries
        Expanded(
          child: widget.entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.terminal_rounded,
                        size: 32,
                        color: CS2Colors.textMuted.withAlpha(80),
                      ),
                      const SizedBox(height: CS2Spacing.sm),
                      Text(
                        '暂无指令',
                        style: CS2TextStyles.bodySmall.copyWith(
                          color: CS2Colors.textMuted,
                        ),
                      ),
                      Text(
                        '发送指令后将在此显示',
                        style: CS2TextStyles.code.copyWith(
                          color: CS2Colors.textMuted.withAlpha(120),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(CS2Spacing.sm),
                  itemCount: widget.entries.length,
                  itemBuilder: (context, index) {
                    return _LogEntryWidget(entry: widget.entries[index]);
                  },
                ),
        ),
      ],
    );
  }

  void _copyAll() {
    final text = widget.entries
        .map((e) =>
            '[${_formatTime(e.timestamp)}] ${e.message}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('日志已复制到剪贴板'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        icon: Icon(icon, size: 14),
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: CS2Colors.textSecondary,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CS2Radius.sm),
          ),
          backgroundColor: CS2Colors.slate800.withAlpha(80),
        ),
      ),
    );
  }
}

class _LogEntryWidget extends StatelessWidget {
  final LogEntry entry;

  const _LogEntryWidget({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            _formatTime(entry.timestamp),
            style: CS2TextStyles.logTimestamp,
          ),
          const SizedBox(width: CS2Spacing.sm),

          // Icon
          Icon(_iconForType(entry.type), size: 12, color: _colorForType(entry.type)),
          const SizedBox(width: CS2Spacing.xs),

          // Message
          Expanded(
            child: SelectableText(
              entry.message,
              style: _styleForType(entry.type),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  IconData _iconForType(LogType type) {
    switch (type) {
      case LogType.command:
        return Icons.arrow_forward_rounded;
      case LogType.response:
        return Icons.subdirectory_arrow_left_rounded;
      case LogType.info:
        return Icons.info_outline_rounded;
      case LogType.error:
        return Icons.error_outline_rounded;
      case LogType.success:
        return Icons.check_circle_outline_rounded;
    }
  }

  Color _colorForType(LogType type) {
    switch (type) {
      case LogType.command:
        return CS2Colors.emerald400;
      case LogType.response:
        return CS2Colors.slate300;
      case LogType.info:
        return CS2Colors.blue400;
      case LogType.error:
        return CS2Colors.red400;
      case LogType.success:
        return CS2Colors.emerald400;
    }
  }

  TextStyle _styleForType(LogType type) {
    switch (type) {
      case LogType.command:
        return CS2TextStyles.logCommand;
      case LogType.response:
        return CS2TextStyles.logResponse;
      case LogType.info:
        return CS2TextStyles.code.copyWith(color: CS2Colors.blue400);
      case LogType.error:
        return CS2TextStyles.logError;
      case LogType.success:
        return CS2TextStyles.code.copyWith(color: CS2Colors.emerald400);
    }
  }
}

/// Helper to format timestamps.
String _formatTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}
