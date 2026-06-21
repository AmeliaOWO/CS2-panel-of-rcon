import 'package:flutter/material.dart';
import '../design/tokens.dart';
import '../providers/rcon_provider.dart';
import 'command_button.dart';

/// Renders a single player row with Kick / Ban / Slay controls.
class PlayerCard extends StatelessWidget {
  final Player player;
  final Future<String?> Function(int userId, String name) onKick;
  final Future<String?> Function(int userId, String name, int minutes) onBan;
  final Future<String?> Function(int userId, String name) onSlay;
  final bool disabled;

  const PlayerCard({
    super.key,
    required this.player,
    required this.onKick,
    required this.onBan,
    required this.onSlay,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isBot = player.steamId == 'BOT';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: CS2Spacing.lg,
        vertical: CS2Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: CS2Colors.card,
        borderRadius: BorderRadius.circular(CS2Radius.md),
        border: Border.all(color: CS2Colors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CS2Spacing.md),
        child: Row(
          children: [
            // Ping indicator
            _PingBadge(ping: player.ping),
            const SizedBox(width: CS2Spacing.md),

            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    player.name,
                    style: CS2TextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isBot ? CS2Colors.textSecondary : CS2Colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isBot ? 'BOT' : player.steamId,
                    style: CS2TextStyles.code.copyWith(
                      color: CS2Colors.textMuted,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'User #${player.userId}  ·  ${player.connected}',
                    style: CS2TextStyles.code.copyWith(
                      color: CS2Colors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            if (!isBot)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CommandButton(
                    label: '踢出',
                    icon: Icons.exit_to_app_rounded,
                    style: CommandButtonStyle.warning,
                    onPressed: disabled
                        ? null
                        : () => _confirmKick(context),
                    width: 56,
                    fontSize: 11,
                  ),
                  const SizedBox(width: 4),
                  CommandButton(
                    label: '封禁',
                    icon: Icons.gavel_rounded,
                    style: CommandButtonStyle.danger,
                    onPressed: disabled
                        ? null
                        : () => _showBanDialog(context),
                    width: 56,
                    fontSize: 11,
                  ),
                  const SizedBox(width: 4),
                  CommandButton(
                    label: '处决',
                    icon: Icons.dangerous_rounded,
                    style: CommandButtonStyle.accent,
                    onPressed: disabled
                        ? null
                        : () => _confirmSlay(context),
                    width: 64,
                    fontSize: 11,
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CS2Spacing.sm,
                  vertical: CS2Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: CS2Colors.slate600.withAlpha(40),
                  borderRadius: BorderRadius.circular(CS2Radius.sm),
                ),
                child: Text(
                  'BOT',
                  style: CS2TextStyles.label.copyWith(
                    color: CS2Colors.slate400,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmKick(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('踢出玩家'),
        content: Text('踢出 "${player.name}" (#${player.userId})？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: CS2Colors.amber400),
            child: const Text('踢出'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final err = await onKick(player.userId, player.name);
      if (err != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    }
  }

  Future<void> _confirmSlay(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('处决玩家'),
        content: Text('立即杀死 "${player.name}" (#${player.userId})？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: CS2Colors.emerald400),
            child: const Text('处决'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final err = await onSlay(player.userId, player.name);
      if (err != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    }
  }

  Future<void> _showBanDialog(BuildContext context) async {
    final controller = TextEditingController(text: '0');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('封禁玩家'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('封禁 "${player.name}" (#${player.userId})'),
            const SizedBox(height: CS2Spacing.lg),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '时长（分钟）',
                hintText: '0 = 永久',
                helperText: '输入 0 为永久封禁',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text) ?? 0;
              Navigator.pop(ctx, minutes);
            },
            style: TextButton.styleFrom(foregroundColor: CS2Colors.red400),
            child: const Text('封禁'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      final err = await onBan(player.userId, player.name, result);
      if (err != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    }
  }
}

class _PingBadge extends StatelessWidget {
  final int ping;
  const _PingBadge({required this.ping});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (ping < 30) {
      color = CS2Colors.emerald500;
    } else if (ping < 60) {
      color = CS2Colors.amber400;
    } else {
      color = CS2Colors.red400;
    }

    return Container(
      width: 40,
      height: 28,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(CS2Radius.sm),
        border: Border.all(color: color.withAlpha(80)),
      ),
      alignment: Alignment.center,
      child: Text(
        '$ping',
        style: CS2TextStyles.code.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
