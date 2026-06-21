import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/tokens.dart';
import '../providers/rcon_provider.dart';
import '../services/rcon_service.dart';
import '../widgets/command_button.dart';
import '../widgets/log_output.dart';
import '../widgets/player_card.dart';
import 'connect_screen.dart';

/// Main control panel shown after successful RCON connection.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _customCmdController = TextEditingController();
  final _mapController = TextEditingController(text: 'de_mirage');
  final _mapFocusNode = FocusNode();
  final _workshopController = TextEditingController();
  bool _botsFrozen = false;
  String _selectedMap = 'de_mirage';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customCmdController.dispose();
    _mapController.dispose();
    _mapFocusNode.dispose();
    _workshopController.dispose();
    super.dispose();
  }

  // ═════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Consumer<RconProvider>(
      builder: (context, provider, _) {
        // If disconnected, go back to connect screen
        if (provider.connectionState == RconConnectionState.disconnected &&
            !provider.isConnecting) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ConnectScreen()),
              );
            }
          });
        }

        return Scaffold(
          backgroundColor: CS2Colors.surface,
          appBar: _buildAppBar(provider),
          body: Column(
            children: [
              // Server info bar
              _buildServerInfoBar(provider),

              // Tab bar
              Container(
                decoration: const BoxDecoration(
                  color: CS2Colors.surfaceAlt,
                  border: Border(
                    bottom: BorderSide(color: CS2Colors.cardBorder),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelStyle: CS2TextStyles.label.copyWith(fontSize: 12),
                  unselectedLabelStyle: CS2TextStyles.label.copyWith(fontSize: 12),
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(icon: Icon(Icons.people_rounded, size: 18), text: '玩家'),
                    Tab(icon: Icon(Icons.bolt_rounded, size: 18), text: '指令'),
                    Tab(icon: Icon(Icons.terminal_rounded, size: 18), text: '日志'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPlayersTab(provider),
                    _buildCommandsTab(provider),
                    _buildLogTab(provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════
  //  APP BAR
  // ═════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(RconProvider provider) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: provider.isConnected
                  ? CS2Colors.emerald500
                  : CS2Colors.amber400,
              boxShadow: provider.isConnected
                  ? [
                      BoxShadow(
                        color: CS2Colors.emerald500.withAlpha(100),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(width: CS2Spacing.sm),
          Text(
            provider.serverName.isNotEmpty
                ? provider.serverName
                : 'CS2 RCON',
            style: CS2TextStyles.title.copyWith(fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        // Refresh
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: '刷新服务器信息',
          onPressed: () => provider.fetchServerInfo(),
          style: IconButton.styleFrom(
            foregroundColor: CS2Colors.textSecondary,
          ),
        ),
        // Disconnect
        IconButton(
          icon: const Icon(Icons.power_settings_new_rounded, size: 20),
          tooltip: '断开连接',
          onPressed: () => _confirmDisconnect(context, provider),
          style: IconButton.styleFrom(
            foregroundColor: CS2Colors.red400,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════
  //  SERVER INFO BAR
  // ═════════════════════════════════════════════════

  Widget _buildServerInfoBar(RconProvider provider) {
    return Container(
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
          // Map
          _InfoChip(
            icon: Icons.map_rounded,
            label: provider.currentMap.isNotEmpty
                ? provider.currentMap
                : '—',
          ),
          const SizedBox(width: CS2Spacing.lg),
          // Players
          _InfoChip(
            icon: Icons.people_rounded,
            label: '${provider.playerCount + provider.botCount}/${provider.maxPlayers}',
          ),
          if (provider.botCount > 0) ...[
            const SizedBox(width: CS2Spacing.sm),
            Text(
              '+${provider.botCount} BOT',
              style: CS2TextStyles.code.copyWith(
                color: CS2Colors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
          const Spacer(),
          // Refresh btn
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 14),
              tooltip: '刷新服务器信息',
              onPressed: () => provider.fetchServerInfo(),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                foregroundColor: CS2Colors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: CS2Spacing.sm),
          // Connection info
          Text(
            '${provider.host}:${provider.port}',
            style: CS2TextStyles.code.copyWith(
              color: CS2Colors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════
  //  PLAYERS TAB
  // ═════════════════════════════════════════════════

  Widget _buildPlayersTab(RconProvider provider) {
    if (provider.players.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: CS2Colors.textMuted.withAlpha(80),
            ),
            const SizedBox(height: CS2Spacing.md),
            Text(
              '没有在线玩家',
              style: CS2TextStyles.bodySmall.copyWith(
                color: CS2Colors.textMuted,
              ),
            ),
            const SizedBox(height: CS2Spacing.sm),
            CommandButton(
              label: '刷新',
              icon: Icons.refresh_rounded,
              style: CommandButtonStyle.default_,
              onPressed: () => provider.fetchServerInfo(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Player count header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CS2Spacing.lg,
            vertical: CS2Spacing.sm,
          ),
          child: Row(
            children: [
              Text(
                '玩家 (${provider.playerCount})',
                style: CS2TextStyles.subtitle.copyWith(fontSize: 13),
              ),
              if (provider.botCount > 0)
                Text(
                  '  + ${provider.botCount} BOT',
                  style: CS2TextStyles.bodySmall.copyWith(
                    color: CS2Colors.textMuted,
                  ),
                ),
              const Spacer(),
              CommandButton(
                label: '刷新',
                icon: Icons.refresh_rounded,
                style: CommandButtonStyle.default_,
                onPressed: () => provider.fetchServerInfo(),
                width: 90,
                fontSize: 11,
              ),
            ],
          ),
        ),
        // Player list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: CS2Spacing.lg),
            itemCount: provider.players.length,
            itemBuilder: (context, index) {
              final player = provider.players[index];
              return PlayerCard(
                player: player,
                disabled: !provider.isConnected,
                onKick: (userId, name) => provider.kickPlayer(userId, name),
                onBan: (userId, name, minutes) =>
                    provider.banPlayer(userId, name, minutes),
                onSlay: (userId, name) => provider.slayPlayer(userId, name),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════
  //  COMMANDS TAB
  // ═════════════════════════════════════════════════

  Widget _buildCommandsTab(RconProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CS2Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section: Cheats ────────────────────
          _sectionHeader('作弊 & 无限弹药'),
          const SizedBox(height: CS2Spacing.sm),
          Row(
            children: [
              Expanded(
                child: CommandButton(
                  label: provider.cheatsEnabled ? '作弊：开' : '作弊：关',
                  icon: provider.cheatsEnabled
                      ? Icons.check_circle_rounded
                      : Icons.block_rounded,
                  style: provider.cheatsEnabled
                      ? CommandButtonStyle.accent
                      : CommandButtonStyle.default_,
                  isActive: provider.cheatsEnabled,
                  enabled: provider.isConnected,
                  onPressed: () => provider.toggleCheats(),
                ),
              ),
              const SizedBox(width: CS2Spacing.sm),
              Expanded(
                child: CommandButton(
                  label: provider.infiniteAmmoEnabled ? '无限弹药：开' : '无限弹药：关',
                  icon: provider.infiniteAmmoEnabled
                      ? Icons.unpublished_rounded
                      : Icons.inventory_2_rounded,
                  style: provider.infiniteAmmoEnabled
                      ? CommandButtonStyle.accent
                      : CommandButtonStyle.default_,
                  isActive: provider.infiniteAmmoEnabled,
                  enabled: provider.isConnected,
                  onPressed: () => provider.toggleInfiniteAmmo(),
                ),
              ),
            ],
          ),
          const SizedBox(height: CS2Spacing.lg),

          // ── Section: Restart Game ───────────────
          _sectionHeader('重启游戏'),
          const SizedBox(height: CS2Spacing.sm),
          Row(
            children: [
              Expanded(
                child: CommandButton(
                  label: '5 秒',
                  icon: Icons.timer_outlined,
                  style: CommandButtonStyle.default_,
                  enabled: provider.isConnected,
                  onPressed: () => provider.restartGame(5),
                ),
              ),
              const SizedBox(width: CS2Spacing.sm),
              Expanded(
                child: CommandButton(
                  label: '10 秒',
                  icon: Icons.timer_outlined,
                  style: CommandButtonStyle.default_,
                  enabled: provider.isConnected,
                  onPressed: () => provider.restartGame(10),
                ),
              ),
              const SizedBox(width: CS2Spacing.sm),
              Expanded(
                child: CommandButton(
                  label: '30 秒',
                  icon: Icons.timer_outlined,
                  style: CommandButtonStyle.default_,
                  enabled: provider.isConnected,
                  onPressed: () => provider.restartGame(30),
                ),
              ),
              const SizedBox(width: CS2Spacing.sm),
              Expanded(
                child: CommandButton(
                  label: '自定义',
                  icon: Icons.timer_off_outlined,
                  style: CommandButtonStyle.warning,
                  enabled: provider.isConnected,
                  onPressed: () => _showRestartDialog(context, provider),
                ),
              ),
            ],
          ),
          const SizedBox(height: CS2Spacing.lg),

          // ── Section: Game Control ──────────────
          _sectionHeader('游戏控制'),
          const SizedBox(height: CS2Spacing.sm),
          Row(
            children: [
              Expanded(
                child: CommandButton(
                  label: '结束热身',
                  icon: Icons.skip_next_rounded,
                  style: CommandButtonStyle.warning,
                  enabled: provider.isConnected,
                  onPressed: () => provider.endWarmup(),
                ),
              ),
            ],
          ),
          const SizedBox(height: CS2Spacing.lg),

          // ── Section: Bot Control ───────────────
          _sectionHeader('Bot 控制'),
          const SizedBox(height: CS2Spacing.sm),
          Row(
            children: [
              Expanded(
                child: CommandButton(
                  label: '添加 Bot (CT)',
                  icon: Icons.person_add_rounded,
                  style: CommandButtonStyle.default_,
                  enabled: provider.isConnected,
                  onPressed: () => provider.addBot('CT'),
                ),
              ),
              const SizedBox(width: CS2Spacing.sm),
              Expanded(
                child: CommandButton(
                  label: '添加 Bot (T)',
                  icon: Icons.person_add_rounded,
                  style: CommandButtonStyle.default_,
                  enabled: provider.isConnected,
                  onPressed: () => provider.addBot('T'),
                ),
              ),
            ],
          ),
          const SizedBox(height: CS2Spacing.sm),
          Row(
            children: [
              Expanded(
                child: CommandButton(
                  label: '踢出所有 Bot',
                  icon: Icons.person_remove_rounded,
                  style: CommandButtonStyle.warning,
                  enabled: provider.isConnected,
                  onPressed: () => provider.kickAllBots(),
                ),
              ),
              const SizedBox(width: CS2Spacing.sm),
              Expanded(
                child: CommandButton(
                  label: _botsFrozen ? '解冻 Bot' : '冻结 Bot',
                  icon: _botsFrozen
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  style: _botsFrozen
                      ? CommandButtonStyle.accent
                      : CommandButtonStyle.default_,
                  isActive: _botsFrozen,
                  enabled: provider.isConnected,
                  onPressed: () async {
                    if (_botsFrozen) {
                      await provider.unfreezeBots();
                    } else {
                      await provider.freezeBots();
                    }
                    setState(() => _botsFrozen = !_botsFrozen);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: CS2Spacing.xxl),

          // ── Map Switching ───────────────────────
          _sectionHeader('切换地图'),
          const SizedBox(height: CS2Spacing.sm),
          // Dropdown row
          SizedBox(
            height: 40,
            child: DropdownButtonFormField<String>(
              value: _selectedMap,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.map_rounded, size: 18),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8,
                ),
              ),
              dropdownColor: CS2Colors.card,
              style: CS2TextStyles.body.copyWith(fontSize: 13),
              items: RconProvider.commonMaps.map((m) {
                return DropdownMenuItem(
                  value: m['id'],
                  child: Text('${m['name']}  (${m['id']})', style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedMap = val);
                  _mapController.text = val;
                }
              },
            ),
          ),
          const SizedBox(height: CS2Spacing.sm),
          // Custom map name + action row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _mapController,
                  focusNode: _mapFocusNode,
                  decoration: const InputDecoration(
                    hintText: '或手动输入地图名 …',
                    prefixIcon: Icon(Icons.edit_rounded, size: 18),
                    isDense: true,
                  ),
                  style: CS2TextStyles.code.copyWith(fontSize: 13),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty && provider.isConnected) {
                      provider.changeMap(val.trim());
                    }
                  },
                ),
              ),
              const SizedBox(width: CS2Spacing.sm),
              CommandButton(
                label: '切换',
                icon: Icons.swap_horiz_rounded,
                style: CommandButtonStyle.accent,
                enabled: provider.isConnected && _mapController.text.trim().isNotEmpty,
                onPressed: () => provider.changeMap(_mapController.text.trim()),
                width: 72,
              ),
            ],
          ),
          const SizedBox(height: CS2Spacing.xl),

          // ── Workshop Map ────────────────────────
          _sectionHeader('创意工坊地图'),
          const SizedBox(height: CS2Spacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _workshopController,
                  decoration: const InputDecoration(
                    hintText: 'Workshop ID 或 Steam 链接 …',
                    prefixIcon: Icon(Icons.link_rounded, size: 18),
                    isDense: true,
                  ),
                  style: CS2TextStyles.code.copyWith(fontSize: 12),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty && provider.isConnected) {
                      provider.changeWorkshopMap(val.trim());
                    }
                  },
                ),
              ),
              const SizedBox(width: CS2Spacing.sm),
              CommandButton(
                label: '加载',
                icon: Icons.download_rounded,
                style: CommandButtonStyle.accent,
                enabled: provider.isConnected && _workshopController.text.trim().isNotEmpty,
                onPressed: () {
                  final val = _workshopController.text.trim();
                  if (val.isNotEmpty) provider.changeWorkshopMap(val);
                },
                width: 64,
                fontSize: 11,
              ),
            ],
          ),
          const SizedBox(height: CS2Spacing.xxl),

          // ── Custom Command ─────────────────────
          _sectionHeader('自定义 RCON 指令'),
          const SizedBox(height: CS2Spacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customCmdController,
                  decoration: const InputDecoration(
                    hintText: '输入任意 RCON 指令 …',
                    prefixIcon: Icon(Icons.terminal_rounded, size: 18),
                    isDense: true,
                  ),
                  style: CS2TextStyles.code.copyWith(fontSize: 13),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty && provider.isConnected) {
                      _sendCustomCommand(provider);
                    }
                  },
                ),
              ),
              const SizedBox(width: CS2Spacing.sm),
              CommandButton(
                label: '发送',
                icon: Icons.send_rounded,
                style: CommandButtonStyle.accent,
                enabled: provider.isConnected,
                onPressed: () => _sendCustomCommand(provider),
                width: 80,
              ),
            ],
          ),
          const SizedBox(height: CS2Spacing.xxl),

          // ── Quick Response Preview ─────────────
          _sectionHeader('最新响应'),
          const SizedBox(height: CS2Spacing.sm),
          Consumer<RconProvider>(
            builder: (context, prov, _) {
              final recentLogs = prov.logs.reversed
                  .where((l) => l.type == LogType.response)
                  .take(3)
                  .toList();
              if (recentLogs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(CS2Spacing.md),
                  decoration: BoxDecoration(
                    color: CS2Colors.slate900,
                    borderRadius: BorderRadius.circular(CS2Radius.md),
                    border: Border.all(color: CS2Colors.cardBorder),
                  ),
                  child: Text(
                    '暂无响应 — 发送一条指令',
                    style: CS2TextStyles.code.copyWith(
                      color: CS2Colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return Container(
                padding: const EdgeInsets.all(CS2Spacing.md),
                decoration: BoxDecoration(
                  color: CS2Colors.slate900,
                  borderRadius: BorderRadius.circular(CS2Radius.md),
                  border: Border.all(color: CS2Colors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: recentLogs.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        entry.message,
                        style: CS2TextStyles.code.copyWith(
                          color: CS2Colors.slate300,
                          fontSize: 12,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: CS2Spacing.xxxl),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════
  //  LOG TAB
  // ═════════════════════════════════════════════════

  Widget _buildLogTab(RconProvider provider) {
    return LogOutput(
      entries: provider.logs,
      onClear: () => provider.clearLogs(),
    );
  }

  // ═════════════════════════════════════════════════
  //  HELPERS
  // ═════════════════════════════════════════════════

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CS2Spacing.xs),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: CS2Colors.emerald500,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: CS2Spacing.sm),
          Text(
            title,
            style: CS2TextStyles.label.copyWith(
              color: CS2Colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _sendCustomCommand(RconProvider provider) {
    final cmd = _customCmdController.text.trim();
    if (cmd.isEmpty) return;
    _customCmdController.clear();
    provider.sendCommand(cmd).catchError((e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('指令执行失败: $e')),
        );
      }
    });
  }

  void _showRestartDialog(BuildContext context, RconProvider provider) {
    final controller = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重启游戏'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('输入倒计时秒数：'),
            const SizedBox(height: CS2Spacing.lg),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '秒数',
                hintText: '1–60',
                prefixIcon: Icon(Icons.timer_rounded, size: 18),
              ),
              autofocus: true,
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
              final seconds = int.tryParse(controller.text) ?? 5;
              final clamped = seconds.clamp(1, 60);
              Navigator.pop(ctx);
              provider.restartGame(clamped);
            },
            style: TextButton.styleFrom(foregroundColor: CS2Colors.emerald400),
            child: const Text('重启'),
          ),
        ],
      ),
    );
  }

  void _confirmDisconnect(BuildContext context, RconProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('断开连接'),
        content: const Text('确定断开与服务器的连接？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.disconnect();
            },
            style: TextButton.styleFrom(foregroundColor: CS2Colors.red400),
            child: const Text('断开'),
          ),
        ],
      ),
    );
  }
}

// ── Info chip widget ──────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: CS2Colors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: CS2TextStyles.bodySmall.copyWith(
            color: CS2Colors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
