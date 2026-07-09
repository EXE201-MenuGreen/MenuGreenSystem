import 'dart:async';

import 'package:flutter/foundation.dart';

import 'connectivity_probe.dart';

class NetworkStatusProvider extends ChangeNotifier {
  NetworkStatusProvider({
    Duration checkInterval = const Duration(seconds: 8),
  }) : _checkInterval = checkInterval;

  final Duration _checkInterval;
  final _reconnectedController = StreamController<void>.broadcast();

  Timer? _timer;
  bool _isOnline = true;
  bool _hasChecked = false;
  bool _checking = false;

  bool get isOnline => _isOnline;
  bool get hasChecked => _hasChecked;
  Stream<void> get onReconnected => _reconnectedController.stream;

  void start() {
    if (_timer != null) return;
    unawaited(checkNow());
    _timer = Timer.periodic(_checkInterval, (_) => unawaited(checkNow()));
  }

  Future<void> checkNow() async {
    if (_checking) return;
    _checking = true;
    final wasOnline = _isOnline;

    try {
      final online = await hasNetworkConnection();
      _hasChecked = true;
      _isOnline = online;

      if (wasOnline != online) {
        notifyListeners();
        if (online) _reconnectedController.add(null);
      }
    } finally {
      _checking = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reconnectedController.close();
    super.dispose();
  }
}
