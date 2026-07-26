import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';

enum ConnectionStateStatus {
  connected,
  reconnecting,
  disconnected,
}

/// Service theo dõi trạng thái kết nối mạng & tự động kết nối lại với máy chủ.
class NetworkConnectivityService extends ChangeNotifier {
  NetworkConnectivityService._() {
    _startPeriodicCheck();
  }

  static final NetworkConnectivityService instance = NetworkConnectivityService._();

  ConnectionStateStatus _status = ConnectionStateStatus.connected;
  ConnectionStateStatus get status => _status;
  bool get isConnected => _status == ConnectionStateStatus.connected;
  bool get isReconnecting => _status == ConnectionStateStatus.reconnecting;
  bool get isDisconnected => _status == ConnectionStateStatus.disconnected;

  Timer? _checkTimer;
  final StreamController<void> _reconnectedStreamController = StreamController<void>.broadcast();
  Stream<void> get onReconnected => _reconnectedStreamController.stream;

  void reportConnectionFailure() {
    if (_status == ConnectionStateStatus.connected) {
      _status = ConnectionStateStatus.reconnecting;
      notifyListeners();
      _triggerFastCheck();
    }
  }

  void reportConnectionSuccess() {
    if (_status != ConnectionStateStatus.connected) {
      _status = ConnectionStateStatus.connected;
      notifyListeners();
      _reconnectedStreamController.add(null);
    }
  }

  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pingServer());
  }

  void _triggerFastCheck() {
    _pingServer();
  }

  Future<void> _pingServer() async {
    if (_status == ConnectionStateStatus.connected) return;

    try {
      final response = await http
          .get(Uri.parse(ApiEndpoints.health))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode >= 200 && response.statusCode < 500) {
        reportConnectionSuccess();
      } else {
        if (_status != ConnectionStateStatus.reconnecting) {
          _status = ConnectionStateStatus.reconnecting;
          notifyListeners();
        }
      }
    } catch (_) {
      if (_status != ConnectionStateStatus.reconnecting) {
        _status = ConnectionStateStatus.reconnecting;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _reconnectedStreamController.close();
    super.dispose();
  }
}
