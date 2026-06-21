import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/rcon_service.dart';

/// 连接历史条目
class ConnectionHistoryEntry {
  final String host;
  final int port;
  final DateTime lastConnected;

  const ConnectionHistoryEntry({
    required this.host,
    required this.port,
    required this.lastConnected,
  });

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'lastConnected': lastConnected.toIso8601String(),
      };

  factory ConnectionHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ConnectionHistoryEntry(
        host: json['host'] as String,
        port: json['port'] as int,
        lastConnected: DateTime.parse(json['lastConnected'] as String),
      );

  String get displayName => '$host:$port';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionHistoryEntry &&
          host == other.host &&
          port == other.port;

  @override
  int get hashCode => host.hashCode ^ port.hashCode;
}

/// Parsed player data from `status` output.
class Player {
  final int userId;
  final String name;
  final String steamId;
  final String connected;
  final int ping;
  final int loss;
  final String state;

  const Player({
    required this.userId,
    required this.name,
    required this.steamId,
    required this.connected,
    required this.ping,
    required this.loss,
    required this.state,
  });

  static const empty = Player(
    userId: 0, name: '', steamId: '',
    connected: '', ping: 0, loss: 0, state: '',
  );
}

/// Application-wide RCON state & logic.
class RconProvider extends ChangeNotifier {
  final RconService _rcon = RconService();

  // ── Connection ──────────────────────────────────
  RconConnectionState _connectionState = RconConnectionState.disconnected;
  RconConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == RconConnectionState.connected;
  bool get isConnecting => _connectionState == RconConnectionState.connecting;

  String _host = '';
  int _port = 27015;
  String get host => _host;
  int get port => _port;

  // ── Server info ─────────────────────────────────
  String _serverName = '';
  String _currentMap = '';
  int _playerCount = 0;
  int _maxPlayers = 0;
  int _botCount = 0;
  String get serverName => _serverName;
  String get currentMap => _currentMap;
  int get playerCount => _playerCount;
  int get maxPlayers => _maxPlayers;
  int get botCount => _botCount;

  // ── Players ─────────────────────────────────────
  List<Player> _players = [];
  List<Player> get players => _players;

  // ── Logs ────────────────────────────────────────
  List<LogEntry> _logs = [];
  List<LogEntry> get logs => _logs;

  // ── Cheats state ────────────────────────────────
  bool _cheatsEnabled = false;
  bool _infiniteAmmoEnabled = false;
  bool get cheatsEnabled => _cheatsEnabled;
  bool get infiniteAmmoEnabled => _infiniteAmmoEnabled;

  // ── Auto-reconnect ──────────────────────────────
  StreamSubscription? _connectivitySub;
  Timer? _keepaliveTimer;
  bool _autoReconnectEnabled = false;
  String _lastPassword = '';

  // ── Connection history ──────────────────────────
  List<ConnectionHistoryEntry> _history = [];
  List<ConnectionHistoryEntry> get history => List.unmodifiable(_history);

  // ── Internal ────────────────────────────────────
  StreamSubscription? _stateSub;
  StreamSubscription? _logSub;
  bool _logStreamInitialized = false;

  // ── Constructor ─────────────────────────────────
  RconProvider() {
    _initStreams();
    _loadHistory();
  }

  void _initStreams() {
    _stateSub?.cancel();
    _stateSub = _rcon.stateStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });

    _logSub?.cancel();
    _logSub = _rcon.logStream.listen((entry) {
      _logs = [..._logs, entry];
      if (_logs.length > 500) {
        _logs = _logs.sublist(_logs.length - 500);
      }
      notifyListeners();
    });

    _logStreamInitialized = true;
  }

  // ═══════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════

  /// Connect to a server.
  Future<String?> connect(String host, int port, String password) async {
    if (password.isEmpty) return '密码不能为空';
    if (host.isEmpty) return '服务器地址不能为空';

    _host = host;
    _port = port;
    _lastPassword = password;

    _addLog(LogEntry.info('正在连接 $host:$port …'));

    try {
      final ok = await _rcon.connect(host, port, password);
      if (!ok) return '连接失败 — 请检查地址、端口和密码';
    } catch (e) {
      return '连接异常: $e';
    }

    _addLog(LogEntry.success('已连接到 $host:$port'));
    await _saveHistoryEntry(host, port);
    _startKeepalive();
    try {
      await fetchServerInfo();
    } catch (e) {
      _addLog(LogEntry.error('获取服务器信息失败: $e'));
    }
    _startConnectivityMonitor();
    return null;
  }

  /// Disconnect from the server.
  void disconnect() {
    _stopKeepalive();
    _stopConnectivityMonitor();
    _rcon.disconnect();
    _players = [];
    _serverName = '';
    _currentMap = '';
    _playerCount = 0;
    _maxPlayers = 0;
    _botCount = 0;
    _cheatsEnabled = false;
    _infiniteAmmoEnabled = false;
    notifyListeners();
  }

  /// Fetch server info & player list via the `status` command.
  Future<void> fetchServerInfo() async {
    try {
      final response = await _rcon.sendCommand('status');
      _addLog(LogEntry.info('status 返回 ${response.length} 字符'));
      if (response.length > 500) {
        _addLog(LogEntry.response(response.substring(0, 500)));
      } else {
        _addLog(LogEntry.response(response));
      }
      _parseStatus(response);
      _addLog(LogEntry.info('解析结果: ${_playerCount} 玩家, ${_botCount} BOT'));
      notifyListeners();
    } catch (e) {
      _addLog(LogEntry.error('获取服务器信息失败: $e'));
    }
  }

  /// Send an arbitrary RCON command.
  Future<String> sendCommand(String command) async {
    try {
      final response = await _rcon.sendCommand(command);
      return response;
    } catch (e) {
      _addLog(LogEntry.error('命令执行失败: $e'));
      rethrow;
    }
  }

  // ── Player actions ──────────────────────────────

  Future<String?> kickPlayer(int userId, String name) async {
    _addLog(LogEntry.info('正在踢出玩家 #$userId "$name" …'));
    try {
      await _rcon.sendCommand('kick #$userId');
      await fetchServerInfo();
      return null;
    } catch (e) {
      _addLog(LogEntry.error('踢出失败: $e'));
      return '踢出失败: $e';
    }
  }

  Future<String?> banPlayer(int userId, String name, int minutes) async {
    _addLog(LogEntry.info('正在封禁玩家 #$userId "$name" ${minutes > 0 ? "$minutes 分钟" : "永久"} …'));
    try {
      if (minutes > 0) {
        await _rcon.sendCommand('banid $minutes #$userId');
      } else {
        await _rcon.sendCommand('banid 0 #$userId');
      }
      await _rcon.sendCommand('kick #$userId');
      await fetchServerInfo();
      return null;
    } catch (e) {
      _addLog(LogEntry.error('封禁失败: $e'));
      return '封禁失败: $e';
    }
  }

  Future<String?> slayPlayer(int userId, String name) async {
    _addLog(LogEntry.info('正在处决玩家 #$userId "$name" …'));
    try {
      await _rcon.sendCommand('slay #$userId');
      return null;
    } catch (e) {
      _addLog(LogEntry.error('处决失败: $e'));
      return '处决失败: $e';
    }
  }

  // ── Quick commands ──────────────────────────────

  Future<void> toggleCheats() async {
    if (_cheatsEnabled) {
      await _rcon.sendCommand('sv_cheats 0');
      _cheatsEnabled = false;
      _addLog(LogEntry.info('作弊: 关'));
    } else {
      await _rcon.sendCommand('sv_cheats 1');
      _cheatsEnabled = true;
      _addLog(LogEntry.info('作弊: 开'));
    }
    notifyListeners();
  }

  Future<void> toggleInfiniteAmmo() async {
    if (_infiniteAmmoEnabled) {
      await _rcon.sendCommand('sv_infinite_ammo 0');
      _infiniteAmmoEnabled = false;
      _addLog(LogEntry.info('无限弹药: 关'));
    } else {
      await _rcon.sendCommand('sv_infinite_ammo 1');
      _infiniteAmmoEnabled = true;
      _addLog(LogEntry.info('无限弹药: 开'));
    }
    notifyListeners();
  }

  Future<void> setCheatsState(bool enabled) async {
    if (enabled == _cheatsEnabled) return;
    await toggleCheats();
  }

  Future<void> restartGame(int seconds) async {
    _addLog(LogEntry.info('游戏将在 $seconds 秒后重启 …'));
    await _rcon.sendCommand('mp_restartgame $seconds');
  }

  Future<void> endWarmup() async {
    _addLog(LogEntry.info('正在结束热身 …'));
    await _rcon.sendCommand('mp_warmup_end');
  }

  Future<void> addBot(String team) async {
    final cmd = team == 'CT' ? 'bot_add_ct' : 'bot_add_t';
    _addLog(LogEntry.info('正在添加 Bot 到 $team …'));
    await _rcon.sendCommand(cmd);
    await fetchServerInfo();
  }

  Future<void> kickAllBots() async {
    _addLog(LogEntry.info('正在踢出所有 Bot …'));
    await _rcon.sendCommand('bot_kick all');
    await fetchServerInfo();
  }

  Future<void> freezeBots() async {
    _addLog(LogEntry.info('正在冻结 Bot …'));
    await _rcon.sendCommand('bot_stop 1');
  }

  Future<void> unfreezeBots() async {
    _addLog(LogEntry.info('正在解冻 Bot …'));
    await _rcon.sendCommand('bot_stop 0');
  }

  // ── Map switching ───────────────────────────────

  Future<void> changeMap(String mapName) async {
    if (mapName.trim().isEmpty) return;
    _addLog(LogEntry.info('正在切换地图到 $mapName …'));
    await _rcon.sendCommand('changelevel ${mapName.trim()}');
    await Future.delayed(const Duration(seconds: 3));
    await fetchServerInfo();
  }

  // ── Workshop map ───────────────────────────────

  static String extractWorkshopId(String input) {
    final trimmed = input.trim();
    final urlMatch = RegExp(r'[?&]id=(\d+)').firstMatch(trimmed);
    if (urlMatch != null) return urlMatch.group(1)!;
    final digitsMatch = RegExp(r'^(\d{5,})$').firstMatch(trimmed);
    if (digitsMatch != null) return digitsMatch.group(1)!;
    return trimmed;
  }

  Future<void> changeWorkshopMap(String input) async {
    final id = extractWorkshopId(input);
    if (id.isEmpty) return;
    _addLog(LogEntry.info('正在切换创意工坊地图 ID: $id …'));
    await _rcon.sendCommand('host_workshop_map $id');
    await Future.delayed(const Duration(seconds: 5));
    await fetchServerInfo();
  }

  static const List<Map<String, String>> commonMaps = [
    {'name': '荒漠迷城', 'id': 'de_mirage'},
    {'name': '炼狱小镇', 'id': 'de_inferno'},
    {'name': '死亡游乐园', 'id': 'de_overpass'},
    {'name': '核子危机', 'id': 'de_nuke'},
    {'name': '炙热沙城 II', 'id': 'de_dust2'},
    {'name': '远古遗迹', 'id': 'de_ancient'},
    {'name': '阿努比斯', 'id': 'de_anubis'},
    {'name': '殒命大厦', 'id': 'de_vertigo'},
    {'name': '办公大楼', 'id': 'cs_office'},
    {'name': '意大利小镇', 'id': 'cs_italy'},
  ];

  // ── Log management ──────────────────────────────

  void clearLogs() {
    _logs = [];
    notifyListeners();
  }

  void addLog(LogEntry entry) {
    _logs = [..._logs, entry];
    if (_logs.length > 500) {
      _logs = _logs.sublist(_logs.length - 500);
    }
    notifyListeners();
  }

  // ── Refresh ─────────────────────────────────────

  Future<void> refreshAll() async {
    await fetchServerInfo();
  }

  // ═══════════════════════════════════════════════════
  //  INTERNALS
  // ═══════════════════════════════════════════════════

  /// 解析 CS2 `status` 输出（CS2 格式与 CS:GO 完全不同）
  void _parseStatus(String output) {
    if (output.isEmpty) return;

    final lines = output.split('\n');

    // ── 基本信息 ──
    for (final line in lines) {
      final t = line.trim();

      if (t.startsWith('hostname')) {
        final idx = t.indexOf(':');
        if (idx > 0) _serverName = t.substring(idx + 1).trim();
        continue;
      }

      if (t.startsWith('players')) {
        final h = RegExp(r'(\d+)\s*humans?').firstMatch(t);
        final b = RegExp(r'(\d+)\s*bots?').firstMatch(t);
        final m = RegExp(r'\((\d+)\s*max').firstMatch(t);
        _playerCount = int.tryParse(h?.group(1) ?? '') ?? 0;
        _botCount = int.tryParse(b?.group(1) ?? '') ?? 0;
        _maxPlayers = int.tryParse(m?.group(1) ?? '') ?? 0;
        continue;
      }

      if (t.startsWith('loaded spawngroup')) {
        final mapM = RegExp(r'\[\d+:\s*([a-zA-Z0-9_]+)').firstMatch(t);
        if (mapM != null && _currentMap.isEmpty) _currentMap = mapM.group(1)!;
        continue;
      }
    }

    // ── 玩家列表 ──
    _players = [];
    bool inP = false;

    for (final line in lines) {
      final tr = line.trimLeft();

      if (tr == '---------players--------') { inP = true; continue; }
      if (tr == '#end' || tr.startsWith('---------')) { inP = false; continue; }
      if (!inP) continue;
      if (tr.contains('id') && tr.contains('time') && tr.contains('ping')) continue;
      if (tr.startsWith('65535') || tr.isEmpty) continue;

      final matches = RegExp(r"'([^']*)'").allMatches(tr);
      if (matches.isEmpty) continue;
      final nm = matches.last;
      final name = nm.group(1) ?? '';
      if (name.isEmpty) continue;

      final pre = tr.substring(0, nm.start).trim();
      final pts = pre.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (pts.isEmpty) continue;
      final uid = int.tryParse(pts[0]) ?? -1;
      if (uid < 0) continue;

      final isBot = pts.length > 1 && pts[1] == 'BOT';
      String conn = '';
      int ping = 0, loss = 0;
      if (isBot) {
        ping = int.tryParse(pts.length > 2 ? pts[2] : '0') ?? 0;
        loss = int.tryParse(pts.length > 3 ? pts[3] : '0') ?? 0;
      } else {
        conn = pts.length > 1 ? pts[1] : '';
        ping = int.tryParse(pts.length > 2 ? pts[2] : '0') ?? 0;
        loss = int.tryParse(pts.length > 3 ? pts[3] : '0') ?? 0;
      }

      _players = [..._players, Player(
        userId: uid, name: name,
        steamId: isBot ? 'BOT' : 'CS2-$uid',
        connected: conn, ping: ping, loss: loss, state: '',
      )];
    }
  }

  void _addLog(LogEntry entry) {
    if (!_logStreamInitialized) {
      _logs = [..._logs, entry];
      if (_logs.length > 500) {
        _logs = _logs.sublist(_logs.length - 500);
      }
      notifyListeners();
    }
  }

  // ── Connection History ──────────────────────────

  static File get _historyFile =>
      File('${Directory.systemTemp.path}/cs2_rcon_history.json');
  static const int _maxHistoryEntries = 10;

  Future<void> _loadHistory() async {
    try {
      final file = _historyFile;
      if (await file.exists()) {
        final raw = await file.readAsString();
        if (raw.isNotEmpty) {
          final list = jsonDecode(raw) as List<dynamic>;
          _history = list
              .map((e) => ConnectionHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveHistoryEntry(String host, int port) async {
    final entry = ConnectionHistoryEntry(
      host: host, port: port, lastConnected: DateTime.now(),
    );
    _history.remove(entry);
    _history.insert(0, entry);
    if (_history.length > _maxHistoryEntries) {
      _history = _history.sublist(0, _maxHistoryEntries);
    }
    notifyListeners();
    try {
      await _historyFile.writeAsString(
        jsonEncode(_history.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    _history = [];
    notifyListeners();
    try {
      if (await _historyFile.exists()) await _historyFile.delete();
    } catch (_) {}
  }

  // ── Keepalive ───────────────────────────────────

  void _startKeepalive() {
    _stopKeepalive();
    _keepaliveTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!isConnected) { _stopKeepalive(); return; }
      _rcon.sendCommand('echo ping').catchError((_) {
        _addLog(LogEntry.error('心跳检测失败 — 连接可能已断开'));
        disconnect();
      });
    });
  }

  void _stopKeepalive() {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
  }

  // ── Connectivity Monitor ────────────────────────

  void _startConnectivityMonitor() {
    _stopConnectivityMonitor();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && !isConnected) {
        _addLog(LogEntry.info('网络已恢复 — 正在尝试重新连接 …'));
        _autoReconnectEnabled = true;
        _attemptReconnect();
      } else if (!hasConnection && isConnected) {
        _addLog(LogEntry.info('网络已断开 — 恢复后自动重连'));
      }
    });
  }

  void _stopConnectivityMonitor() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _autoReconnectEnabled = false;
  }

  Future<void> _attemptReconnect() async {
    if (!_autoReconnectEnabled || _host.isEmpty) return;
    _addLog(LogEntry.info('正在尝试重新连接 …'));
    final ok = await _rcon.connect(_host, _port, _lastPassword);
    if (ok) {
      _addLog(LogEntry.success('已重新连接'));
      await fetchServerInfo();
    } else {
      _addLog(LogEntry.error('重连失败 — 将重试'));
      Future.delayed(const Duration(seconds: 10), _attemptReconnect);
    }
  }

  @override
  void dispose() {
    _stopConnectivityMonitor();
    _stopKeepalive();
    _stateSub?.cancel();
    _logSub?.cancel();
    _rcon.dispose();
    super.dispose();
  }
}
