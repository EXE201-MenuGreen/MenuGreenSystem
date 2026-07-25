import 'dart:async';
import 'package:flutter/material.dart';
import '../network/network_connectivity_service.dart';

/// Banner hiển thị trạng thái tự động thử kết nối lại khi mất kết nối server.
class ConnectionStatusBanner extends StatefulWidget {
  const ConnectionStatusBanner({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ConnectionStatusBanner> createState() => _ConnectionStatusBannerState();
}

class _ConnectionStatusBannerState extends State<ConnectionStatusBanner> {
  final _service = NetworkConnectivityService.instance;
  bool _showReconnectedSuccess = false;
  Timer? _hideSuccessTimer;
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onStatusChanged);
    _sub = _service.onReconnected.listen((_) {
      if (mounted) {
        setState(() => _showReconnectedSuccess = true);
        _hideSuccessTimer?.cancel();
        _hideSuccessTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showReconnectedSuccess = false);
        });
      }
    });
  }

  void _onStatusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onStatusChanged);
    _sub?.cancel();
    _hideSuccessTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReconnecting = _service.isReconnecting || _service.isDisconnected;
    final showSuccess = _showReconnectedSuccess && !isReconnecting;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: (isReconnecting || showSuccess) ? 36.0 : 0.0,
          color: showSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
          child: (isReconnecting || showSuccess)
              ? SafeArea(
                  bottom: false,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isReconnecting) ...[
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Đang mất kết nối với máy chủ. Đang thử kết nối lại...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Đã kết nối lại với máy chủ!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
