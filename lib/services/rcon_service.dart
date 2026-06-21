import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

/// Log severity for the console panel.
enum LogType { command, response, info, error, success }

/// Immutable log entry for the output panel.
class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogType type;

  const LogEntry({
    required this.timestamp,
    required this.message,
    required this.type,
  });

  factory LogEntry.command(String msg) =>
      LogEntry(timestamp: DateTime.now(), message: msg, type: LogType.command);
  factory LogEntry.response(String msg) =>
      LogEntry(timestamp: DateTime.now(), message: msg, type: LogType.response);
  factory LogEntry.info(String msg) =>
      LogEntry(timestamp: DateTime.now(), message: msg, type: LogType.info);
  factory LogEntry.error(String msg) =>
      LogEntry(timestamp: DateTime.now(), message: msg, type: LogType.error);
  factory LogEntry.success(String msg) =>
      LogEntry(timestamp: DateTime.now(), message: msg, type: LogType.success);
  factory LogEntry.timestamp(String msg, {LogType type = LogType.info}) =>
      LogEntry(timestamp: DateTime.now(), message: msg, type: type);
}

/// Connection state enum.
enum RconConnectionState { disconnected, connecting, connected, error }

/// Result from the worker isolate.
class _WorkerResult {
  final bool success;
  final String? error;
  final String? response;
  _WorkerResult({required this.success, this.error, this.response});
}

// ─────────────────────────────────────────────────────────
//  RCON Service  (singleton, isolate-based)
// ─────────────────────────────────────────────────────────

class RconService {
  RconService._();
  static final RconService _instance = RconService._();
  factory RconService() => _instance;

  Isolate? _isolate;
  SendPort? _workerSendPort;
  bool _isConnected = false;

  final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();
  final StreamController<RconConnectionState> _stateController =
      StreamController<RconConnectionState>.broadcast();

  Stream<LogEntry> get logStream => _logController.stream;
  Stream<RconConnectionState> get stateStream => _stateController.stream;
  bool get isConnected => _isConnected;

  /// Connect to a CS2 server via Source RCON protocol.
  /// Runs all socket I/O in a background isolate.
  Future<bool> connect(String host, int port, String password) async {
    _setState(RconConnectionState.connecting);
    _addLog(LogEntry.info('正在连接 $host:$port …'));

    try {
      // Spawn worker isolate
      final mainReceivePort = ReceivePort();
      try {
        _isolate = await Isolate.spawn(
          _rconWorkerEntry,
          mainReceivePort.sendPort,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        _disposeWorker();
        _setState(RconConnectionState.disconnected);
        _addLog(LogEntry.error('创建工作线程失败: $e'));
        return false;
      }

      // Receive worker's command SendPort
      SendPort workerSendPort;
      try {
        workerSendPort = await mainReceivePort.first.timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('工作线程未响应'),
        ) as SendPort;
      } catch (e) {
        _isolate?.kill(priority: Isolate.immediate);
        _isolate = null;
        _setState(RconConnectionState.disconnected);
        _addLog(LogEntry.error('工作线程启动超时: $e'));
        return false;
      }
      _workerSendPort = workerSendPort;

      // Request connection
      final result = await _sendToWorker({
        'action': 'connect',
        'host': host,
        'port': port,
        'password': password,
      });

      if (result.success) {
        _isConnected = true;
        _setState(RconConnectionState.connected);
        _addLog(LogEntry.success('已连接到 $host:$port'));
        return true;
      } else {
        _isConnected = false;
        _setState(RconConnectionState.disconnected);
        _addLog(LogEntry.error('连接失败: ${result.error}'));
        _disposeWorker();
        return false;
      }
    } catch (e) {
      _isConnected = false;
      _setState(RconConnectionState.disconnected);
      _addLog(LogEntry.error('连接错误: $e'));
      _disposeWorker();
      return false;
    }
  }

  /// Send an arbitrary RCON command and return the response string.
  Future<String> sendCommand(String command) async {
    if (_workerSendPort == null || !_isConnected) {
      throw Exception('未连接到服务器');
    }

    _addLog(LogEntry.command('> $command'));

    try {
      final result = await _sendToWorker({
        'action': 'command',
        'command': command,
      });

      if (result.error != null) {
        _addLog(LogEntry.error('命令错误: ${result.error}'));
        throw Exception(result.error);
      }

      final response = result.response ?? '';
      if (response.isNotEmpty) {
        _addLog(LogEntry.response(response));
      }
      return response;
    } catch (e) {
      _addLog(LogEntry.error('命令执行失败: $e'));
      rethrow;
    }
  }

  /// Disconnect from the server.
  void disconnect() {
    if (_workerSendPort != null) {
      try {
        _workerSendPort!.send({'action': 'disconnect'});
      } catch (_) {}
    }
    _disposeWorker();
    _isConnected = false;
    _setState(RconConnectionState.disconnected);
    _addLog(LogEntry.info('已断开连接'));
  }

  void dispose() {
    disconnect();
    _logController.close();
    _stateController.close();
  }

  // ── Internal helpers ──────────────────────────────

  Future<_WorkerResult> _sendToWorker(Map<dynamic, dynamic> message) async {
    final responsePort = ReceivePort();
    message['responsePort'] = responsePort.sendPort;
    _workerSendPort!.send(message);
    final raw = await responsePort.first.timeout(
      const Duration(seconds: 10),
      onTimeout: () => <dynamic, dynamic>{'success': false, 'error': '请求超时'},
    );
    responsePort.close();
    final result = raw as Map<dynamic, dynamic>;
    return _WorkerResult(
      success: result['success'] as bool? ?? false,
      error: result['error'] as String?,
      response: result['response'] as String?,
    );
  }

  void _disposeWorker() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _workerSendPort = null;
  }

  void _setState(RconConnectionState state) {
    _stateController.add(state);
  }

  void _addLog(LogEntry entry) {
    _logController.add(entry);
  }

  // ═══════════════════════════════════════════════════════
  //  WORKER ISOLATE  —  all socket I/O lives here
  // ═══════════════════════════════════════════════════════

  static Future<void> _rconWorkerEntry(SendPort mainSendPort) async {
    final commandPort = ReceivePort();
    mainSendPort.send(commandPort.sendPort);

    Socket? socket;
    _PacketReader? reader;
    int requestId = 0;

    await for (final raw in commandPort) {
      final msg = raw as Map<dynamic, dynamic>;
      final action = msg['action'] as String?;
      final responsePort = msg['responsePort'] as SendPort?;

      try {
        switch (action) {
          case 'connect':
            final host = msg['host'] as String;
            final port = msg['port'] as int;
            final password = msg['password'] as String;

            socket = await Socket.connect(
              host,
              port,
              timeout: const Duration(seconds: 6),
            );
            socket.setOption(SocketOption.tcpNoDelay, true);
            reader = _PacketReader(socket);

            final authOk = await _authenticate(socket, reader, password);
            // 清空 reader 缓冲区，防止认证阶段残留数据干扰后续命令
            reader.clearBuffer();
            if (authOk) {
              responsePort?.send({'success': true});
            } else {
              socket.close();
              socket = null;
              reader = null;
              responsePort?.send({
                'success': false,
                'error': 'RCON 认证被拒 — 请检查密码',
              });
            }
            break;

          case 'command':
            if (socket == null || reader == null) {
              responsePort?.send({
                'error': '未连接',
                'success': false,
              });
              break;
            }
            final cmd = msg['command'] as String;
            final id = ++requestId;
            final resp = await _executeCommand(socket, reader, cmd, id);
            responsePort?.send({
              'response': resp,
              'success': true,
            });
            break;

          case 'disconnect':
            try {
              socket?.close();
            } catch (_) {}
            socket = null;
            reader = null;
            responsePort?.send({'success': true});
            break;
        }
      } catch (e) {
        responsePort?.send({
          'success': false,
          'error': e.toString(),
        });
        // On fatal error, close the socket
        try {
          socket?.close();
        } catch (_) {}
        socket = null;
        reader = null;
      }
    }
  }

  /// Authenticate with the server.
  ///
  /// Some servers send:  [empty type=0] + [auth type=2]
  /// Others send only:   [auth type=2]
  /// We loop reading packets until we find the type=2 auth response.
  static Future<bool> _authenticate(
      Socket socket, _PacketReader reader, String password) async {
    final authPacket = _encodePacket(0, 3, password);
    socket.add(authPacket);
    await socket.flush();

    // Read up to 10 packets, looking for SERVERDATA_AUTH_RESPONSE (type=2)
    for (int i = 0; i < 10; i++) {
      Uint8List pkt;
      try {
        pkt = await reader.readPacket();
      } catch (_) {
        return false;
      }

      if (pkt.length < 8) continue;

      final view = ByteData.view(pkt.buffer, 0);
      final type = view.getInt32(4, Endian.little);

      // SERVERDATA_AUTH_RESPONSE
      if (type == 2) {
        final id = view.getInt32(0, Endian.little);
        // id == -1  →  auth failure
        // id != -1  →  auth success
        return id != -1;
      }
      // type == 0 (SERVERDATA_RESPONSE_VALUE) → empty ack, keep reading
    }

    return false;
  }

  /// Send a command and read all response packets until the terminator.
  static Future<String> _executeCommand(
      Socket socket, _PacketReader reader, String command, int requestId) async {
    final packet = _encodePacket(requestId, 2, command);
    socket.add(packet);
    await socket.flush();

    final buffer = StringBuffer();
    int safety = 0;

    while (safety < 200) {
      safety++;
      Uint8List raw;
      try {
        raw = await reader.readPacket();
      } catch (_) {
        break; // Connection closed
      }

      if (raw.length < 10) break;

      // 提取 body：跳过 [id:4][type:4]，找 null 终止符
      int bodyEnd = raw.length - 2;
      for (int i = 8; i < raw.length - 2; i++) {
        if (raw[i] == 0) {
          bodyEnd = i;
          break;
        }
      }

      final bodyLen = bodyEnd - 8;
      if (bodyLen > 0) {
        final body = utf8.decode(raw.sublist(8, 8 + bodyLen));
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(body);
        continue;
      }

      // Empty body → terminator
      break;
    }

    return buffer.toString();
  }

  /// Encode a Source RCON protocol packet.
  ///
  /// Format:
  ///   [size: int32 LE]  =  total remaining bytes (id + type + body + 2)
  ///   [id:   int32 LE]
  ///   [type: int32 LE]
  ///   [body: UTF-8 string + 0x00]
  ///   [0x00]
  static Uint8List _encodePacket(int id, int type, String body) {
    final bodyBytes = utf8.encode(body);
    final size = 4 + 4 + bodyBytes.length + 2; // id + type + body + two nulls
    final packet = ByteData(4 + size);

    packet.setInt32(0, size, Endian.little);
    packet.setInt32(4, id, Endian.little);
    packet.setInt32(8, type, Endian.little);

    for (int i = 0; i < bodyBytes.length; i++) {
      packet.setUint8(12 + i, bodyBytes[i]);
    }
    packet.setUint8(12 + bodyBytes.length, 0); // null-terminator
    packet.setUint8(12 + bodyBytes.length + 1, 0); // empty string

    return packet.buffer.asUint8List();
  }
}

// ── Buffered packet reader ──────────────────────────
//  Reads exact byte counts from a TCP stream, buffering
//  any excess so partial chunks don't corrupt parsing.
//
//  Uses socket.listen() with Completer-based signaling.
class _PacketReader {
  final List<int> _buffer = [];
  late final StreamSubscription<Uint8List> _subscription;
  Completer<void>? _dataCompleter;
  bool _done = false;
  Object? _error;

  _PacketReader(Socket socket) {
    final timed = socket.timeout(const Duration(seconds: 6));
    _subscription = timed.listen(
      (Uint8List data) {
        _buffer.addAll(data);
        _dataCompleter?.complete();
        _dataCompleter = null;
      },
      onDone: () {
        _done = true;
        _dataCompleter?.complete();
        _dataCompleter = null;
      },
      onError: (err) {
        _error = err;
        _done = true;
        _dataCompleter?.complete();
        _dataCompleter = null;
      },
      cancelOnError: false,
    );
  }

  /// Wait for more data to arrive in the buffer.
  Future<void> _waitForData() async {
    if (_done && _buffer.isEmpty) {
      throw Exception('读取时连接已关闭: ${_error ?? "EOF"}');
    }
    if (_buffer.isNotEmpty) return;

    _dataCompleter = Completer<void>();
    await _dataCompleter!.future;
    if (_done && _buffer.isEmpty) {
      throw Exception('读取时连接已关闭: ${_error ?? "EOF"}');
    }
  }

  /// Read exactly [count] bytes from the stream.
  Future<Uint8List> read(int count) async {
    while (_buffer.length < count) {
      await _waitForData();
    }

    final result = Uint8List(count);
    result.setAll(0, _buffer.sublist(0, count));
    _buffer.removeRange(0, count);
    return result;
  }

  /// Read one complete RCON packet (4-byte size header + payload).
  Future<Uint8List> readPacket() async {
    final sizeBytes = await read(4);
    final size =
        ByteData.view(sizeBytes.buffer, 0).getInt32(0, Endian.little);
    return read(size);
  }

  /// Clear any buffered data (call after auth to discard leftovers).
  void clearBuffer() {
    _buffer.clear();
  }

  void dispose() {
    _subscription.cancel();
    _buffer.clear();
    _dataCompleter = null;
  }
}
