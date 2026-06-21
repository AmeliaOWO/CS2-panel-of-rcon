import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/tokens.dart';
import '../providers/rcon_provider.dart';
import '../services/rcon_service.dart';
import 'dashboard_screen.dart';

/// Initial connection screen where users enter server details.
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '27015');
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Try to restore from previous session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RconProvider>();
      if (provider.host.isNotEmpty) {
        _hostController.text = provider.host;
        _portController.text = provider.port.toString();
      }
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 27015;
    final password = _passwordController.text;

    final provider = context.read<RconProvider>();

    // Show loading state
    final snackBar = ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CS2Colors.emerald400,
              ),
            ),
            SizedBox(width: 12),
            Text('连接中 …'),
          ],
        ),
        duration: Duration(seconds: 20),
      ),
    );

    final error = await provider.connect(host, port, password);

    snackBar.close();

    if (!mounted) return;

    if (error == null) {
      // Navigate to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: CS2Colors.red400, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: CS2Colors.red900.withAlpha(200),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CS2Colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CS2Spacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo / Title
                    _buildHeader(),
                    const SizedBox(height: CS2Spacing.xxxl),

                    // Connection form card
                    _buildFormCard(),
                    const SizedBox(height: CS2Spacing.xxl),

                    // Connection history
                    _buildHistory(),
                    const SizedBox(height: CS2Spacing.lg),

                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: CS2Colors.emerald500.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CS2Colors.emerald500.withAlpha(60),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.shield_rounded,
            size: 36,
            color: CS2Colors.emerald500,
          ),
        ),
        const SizedBox(height: CS2Spacing.lg),
        Text(
          'CS2 RCON 控制面板',
          style: CS2TextStyles.headline.copyWith(
            color: CS2Colors.textPrimary,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: CS2Spacing.sm),
        Text(
          '服务器远程管理工具',
          style: CS2TextStyles.subtitle.copyWith(
            color: CS2Colors.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(CS2Spacing.xxl),
      decoration: BoxDecoration(
        color: CS2Colors.card,
        borderRadius: BorderRadius.circular(CS2Radius.lg),
        border: Border.all(color: CS2Colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Server address
          TextFormField(
            controller: _hostController,
            decoration: const InputDecoration(
              labelText: '服务器地址',
              hintText: '192.168.1.100 或 域名',
              prefixIcon: Icon(Icons.dns_rounded, size: 18),
            ),
            style: CS2TextStyles.body,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return '请输入服务器地址';
              return null;
            },
          ),
          const SizedBox(height: CS2Spacing.lg),

          // Port
          TextFormField(
            controller: _portController,
            decoration: const InputDecoration(
              labelText: '端口',
              hintText: '27015',
              prefixIcon: Icon(Icons.settings_ethernet_rounded, size: 18),
            ),
            style: CS2TextStyles.body,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return '请输入端口';
              final port = int.tryParse(v.trim());
              if (port == null || port < 1 || port > 65535) return '无效端口 (1–65535)';
              return null;
            },
          ),
          const SizedBox(height: CS2Spacing.lg),

          // RCON Password
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'RCON 密码',
              hintText: '输入服务器 RCON 密码',
              prefixIcon: const Icon(Icons.lock_rounded, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            style: CS2TextStyles.body,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _connect(),
            validator: (v) {
              if (v == null || v.isEmpty) return '密码不能为空';
              return null;
            },
          ),
          const SizedBox(height: CS2Spacing.xxl),

          // Connect button
          Consumer<RconProvider>(
            builder: (context, provider, _) {
              final connecting = provider.isConnecting;
              return SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: connecting ? null : _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CS2Colors.emerald500,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: CS2Colors.slate700,
                  ),
                  child: connecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CS2Colors.slate200,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.power_settings_new_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('连接'),
                          ],
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Consumer<RconProvider>(
      builder: (context, provider, _) {
        final history = provider.history;
        if (history.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(CS2Spacing.md),
          decoration: BoxDecoration(
            color: CS2Colors.card,
            borderRadius: BorderRadius.circular(CS2Radius.lg),
            border: Border.all(color: CS2Colors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded, size: 14, color: CS2Colors.textSecondary),
                  const SizedBox(width: CS2Spacing.sm),
                  Text('最近连接', style: CS2TextStyles.label.copyWith(color: CS2Colors.textSecondary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => provider.clearHistory(),
                    child: Text('清除', style: CS2TextStyles.bodySmall.copyWith(
                      color: CS2Colors.textMuted,
                      fontSize: 10,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: CS2Spacing.sm),
              ...history.take(5).map((entry) {
                final timeStr = _formatHistoryTime(entry.lastConnected);
                return InkWell(
                  onTap: () {
                    _hostController.text = entry.host;
                    _portController.text = entry.port.toString();
                    _passwordController.clear();
                    _passwordFocusNode.requestFocus();
                  },
                  borderRadius: BorderRadius.circular(CS2Radius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CS2Spacing.sm,
                      vertical: CS2Spacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.dns_rounded, size: 12, color: CS2Colors.textMuted),
                        const SizedBox(width: CS2Spacing.sm),
                        Expanded(
                          child: Text(
                            '${entry.host}:${entry.port}',
                            style: CS2TextStyles.code.copyWith(
                              fontSize: 12,
                              color: CS2Colors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          timeStr,
                          style: CS2TextStyles.code.copyWith(
                            fontSize: 10,
                            color: CS2Colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _formatHistoryTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.month}/${dt.day}';
  }

  Widget _buildFooter() {
    return Consumer<RconProvider>(
      builder: (context, provider, _) {
        final state = provider.connectionState;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CS2Spacing.lg,
            vertical: CS2Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: CS2Colors.slate900.withAlpha(150),
            borderRadius: BorderRadius.circular(CS2Radius.lg),
            border: Border.all(
              color: _stateColor(state).withAlpha(60),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle_rounded,
                size: 8,
                color: _stateColor(state),
              ),
              const SizedBox(width: CS2Spacing.sm),
              Text(
                _stateLabel(state),
                style: CS2TextStyles.bodySmall.copyWith(
                  color: _stateColor(state),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _stateColor(RconConnectionState state) {
    switch (state) {
      case RconConnectionState.disconnected:
        return CS2Colors.slate500;
      case RconConnectionState.connecting:
        return CS2Colors.amber400;
      case RconConnectionState.connected:
        return CS2Colors.emerald500;
      case RconConnectionState.error:
        return CS2Colors.red400;
    }
  }

  String _stateLabel(RconConnectionState state) {
    switch (state) {
      case RconConnectionState.disconnected:
        return '未连接';
      case RconConnectionState.connecting:
        return '连接中 …';
      case RconConnectionState.connected:
        return '已连接';
      case RconConnectionState.error:
        return '连接错误';
    }
  }
}
