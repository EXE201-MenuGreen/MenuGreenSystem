import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../models/sepay_models.dart';
import '../models/subscription_models.dart';
import '../repositories/sepay_payment_repository.dart';
import 'sepay_payment_success_screen.dart';

enum SepayPaymentFlow { subscribe, renew }

class SepayPaymentScreen extends StatefulWidget {
  final SepayPaymentFlow flow;
  final String planTitle;
  final String? subscriptionPlanId;
  final String? userSubscriptionId;

  const SepayPaymentScreen.subscribe({
    super.key,
    required this.planTitle,
    required this.subscriptionPlanId,
  })  : flow = SepayPaymentFlow.subscribe,
        userSubscriptionId = null;

  const SepayPaymentScreen.renew({
    super.key,
    required this.planTitle,
    required this.userSubscriptionId,
  })  : flow = SepayPaymentFlow.renew,
        subscriptionPlanId = null;

  @override
  State<SepayPaymentScreen> createState() => _SepayPaymentScreenState();
}

class _SepayPaymentScreenState extends State<SepayPaymentScreen> {
  static const _pollInterval = Duration(seconds: 4);

  final _repository = SepayPaymentRepository();

  SepayOrder? _order;
  bool _loading = true;
  bool _cancelling = false;
  bool _isCancelled = false;
  int _cancelCountdown = 10;
  String? _error;
  Timer? _pollTimer;
  Timer? _cancelCountdownTimer;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    _createOrder();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _cancelCountdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _createOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final resumed = await _tryResumePendingOrder();
    if (resumed) return;

    final ({bool success, SepayOrder? data, String message}) result;
    if (widget.flow == SepayPaymentFlow.subscribe) {
      result = await _repository.createOrder(
        subscriptionPlanId: widget.subscriptionPlanId!,
      );
    } else {
      result = await _repository.createRenewOrder(
        userSubscriptionId: widget.userSubscriptionId!,
      );
    }

    if (!mounted) return;

    if (!result.success || result.data == null) {
      // Check if error is due to pending order - try to cancel it and retry
      if (_isPendingOrderError(result.message)) {
        final cancelled = await _cancelPendingOrderForDifferentPlan();
        if (!mounted) return;

        if (cancelled) {
          // Retry creating order after successful cancellation
          await _createOrderAfterCancel();
          return;
        }
        // If cancel failed, show error
        setState(() {
          _loading = false;
          _error = _localizeError(result.message);
        });
        return;
      }

      setState(() {
        _loading = false;
        _error = _localizeError(result.message);
      });
      return;
    }

    _applyOrder(result.data!);
  }

  bool _isPendingOrderError(String message) {
    return message.toLowerCase().contains('pending');
  }

  Future<void> _createOrderAfterCancel() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final ({bool success, SepayOrder? data, String message}) result;
    if (widget.flow == SepayPaymentFlow.subscribe) {
      result = await _repository.createOrder(
        subscriptionPlanId: widget.subscriptionPlanId!,
      );
    } else {
      result = await _repository.createRenewOrder(
        userSubscriptionId: widget.userSubscriptionId!,
      );
    }

    if (!mounted) return;

    if (!result.success || result.data == null) {
      setState(() {
        _loading = false;
        _error = _localizeError(result.message);
      });
      return;
    }

    _applyOrder(result.data!);
  }

  Future<bool> _tryResumePendingOrder() async {
    final pending = await _repository.getPendingOrders();
    if (!mounted) return false;
    if (!pending.success || pending.data.isEmpty) return false;

    final order = _pickPendingOrder(pending.data);
    if (order == null) return false;

    _applyOrder(order, resumed: true);
    return true;
  }

  /// Cancel pending order for a different plan when user wants to switch plans.
  Future<bool> _cancelPendingOrderForDifferentPlan() async {
    final pending = await _repository.getPendingOrders();
    if (!mounted) return false;
    if (!pending.success || pending.data.isEmpty) return false;

    // Find any pending order that is NOT for the current plan
    for (final order in pending.data) {
      final isCurrentPlan = widget.flow == SepayPaymentFlow.subscribe
          ? order.subscriptionPlanId == widget.subscriptionPlanId
          : order.userSubscriptionId == widget.userSubscriptionId;

      if (!isCurrentPlan) {
        // Found pending order for different plan - cancel it
        final result = await _repository.cancelOrder(order.paymentId);
        if (!mounted) return false;

        if (result.success) {
          return true;
        }
        // If cancel fails, return false and let the API error handling show the message
        return false;
      }
    }

    return false;
  }

  SepayOrder? _pickPendingOrder(List<SepayOrder> orders) {
    if (widget.flow == SepayPaymentFlow.subscribe) {
      final planId = widget.subscriptionPlanId;
      // Tìm order khớp chính xác với plan đang đăng ký
      if (planId != null) {
        for (final o in orders) {
          if (o.isSubscribeOrder && o.subscriptionPlanId == planId) return o;
        }
      }
      // Nếu không tìm thấy order đúng plan, KHÔNG resume order khác
      // → Sẽ tạo order mới cho plan đang chọn
      return null;
    } else {
      final subId = widget.userSubscriptionId;
      if (subId != null) {
        for (final o in orders) {
          if (o.isRenewOrder && o.userSubscriptionId == subId) return o;
        }
      }
      // Nếu không tìm thấy order renew đúng subscription, KHÔNG resume order khác
      return null;
    }
  }

  void _applyOrder(SepayOrder order, {bool resumed = false}) {
    if (!mounted) return;
    setState(() {
      _order = order;
      _loading = false;
      _error = null;
      _isCancelled = false;
      _cancelCountdown = 10;
    });

    if (resumed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tải đơn thanh toán đang chờ. Vui lòng hoàn tất chuyển khoản.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }

    _startCountdown();
    _startCancelCountdown();
    _startPolling();
  }

  String _localizeError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('pending sepay payment')) {
      return 'Bạn có đơn thanh toán chưa hoàn tất. Nhấn "Thử lại" để tải QR đơn đang chờ.';
    }
    return message;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _tickCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickCountdown());
  }

  void _tickCountdown() {
    final expiredAt = _order?.expiredAt;
    if (expiredAt == null || !mounted) return;

    final remaining = expiredAt.difference(DateTime.now());
    setState(() => _remaining = remaining);

    if (remaining.isNegative && _order?.paymentStatus == SepayPaymentStatus.pending) {
      _handleTerminalStatus(SepayPaymentStatus.expired);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollStatus());
  }

  void _startCancelCountdown() {
    _cancelCountdownTimer?.cancel();
    _cancelCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_cancelCountdown > 0) {
          _cancelCountdown--;
        }
      });
      if (_cancelCountdown <= 0) {
        _cancelCountdownTimer?.cancel();
      }
    });
  }

  Future<void> _pollStatus() async {
    final order = _order;
    if (order == null || _polling || order.paymentStatus.isTerminal) return;

    _polling = true;
    final result = await _repository.getPaymentStatus(order.paymentId);
    _polling = false;

    if (!mounted || !result.success || result.data == null) return;

    setState(() => _order = result.data);
    final status = result.data!.paymentStatus;
    if (status.isTerminal) {
      _handleTerminalStatus(status);
    }
  }

  void _handleTerminalStatus(SepayPaymentStatus status) {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();

    if (status == SepayPaymentStatus.paid) {
      final isRenew = widget.flow == SepayPaymentFlow.renew;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SepayPaymentSuccessScreen(
            title: isRenew ? 'Gia hạn thành công!' : 'Thanh toán thành công!',
            subtitle: isRenew
                ? 'Gói "${widget.planTitle}" đã được gia hạn. Bạn có thể tiếp tục sử dụng MenuGreen Pro.'
                : 'Gói "${widget.planTitle}" đã được kích hoạt. Cảm ơn bạn đã tin tưởng MenuGreen!',
          ),
        ),
      );
      return;
    }

    if (status == SepayPaymentStatus.expired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đơn thanh toán đã hết hạn. Vui lòng tạo đơn mới.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _copyText(String label, String value) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label thành công'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.flow == SepayPaymentFlow.subscribe
              ? 'Thanh toán đăng ký'
              : 'Thanh toán gia hạn',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    final isPaid = order.paymentStatus == SepayPaymentStatus.paid;
    final isExpired = order.paymentStatus == SepayPaymentStatus.expired;
    final isCancelled = _isCancelled;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: isCancelled ? _createNewOrder : _pollStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusBanner(order),
            if (!isCancelled && !isPaid && !isExpired) ...[
              const SizedBox(height: 16),
              _buildQrCard(order),
              const SizedBox(height: 16),
              _buildAmountCard(order),
              const SizedBox(height: 12),
              _buildTransferDetails(order),
              const SizedBox(height: 12),
              _buildReceiverCard(order),
              const SizedBox(height: 20),
              _buildInstructions(),
            ],
            if (isCancelled) ...[
              const SizedBox(height: 20),
              _buildCancelledInfo(),
              const SizedBox(height: 16),
              _buildNewOrderButton(),
            ],
            if (!isCancelled && !isPaid && !isExpired) ...[
              const SizedBox(height: 20),
              _buildPollingIndicator(),
              const SizedBox(height: 16),
              _buildCancelButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(SepayOrder order) {
    final status = order.paymentStatus;
    Color bg;
    Color fg;
    IconData icon;
    String text;

    switch (status) {
      case SepayPaymentStatus.paid:
        bg = AppColors.primary.withValues(alpha: 0.12);
        fg = AppColors.primary;
        icon = Icons.check_circle_outline;
        text = 'Đã nhận thanh toán';
        break;
      case SepayPaymentStatus.expired:
        bg = Colors.orange.withValues(alpha: 0.12);
        fg = Colors.orange.shade800;
        icon = Icons.schedule;
        text = 'Đơn đã hết hạn';
        break;
      default:
        bg = Colors.blue.withValues(alpha: 0.1);
        fg = Colors.blue.shade800;
        icon = Icons.hourglass_top_rounded;
        text = 'Đang chờ chuyển khoản';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(fontWeight: FontWeight.bold, color: fg),
                ),
                Text(
                  widget.planTitle,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (status == SepayPaymentStatus.pending && order.expiredAt != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Còn lại',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  formatCountdown(_remaining),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _remaining.inMinutes < 5 ? Colors.red : fg,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQrCard(SepayOrder order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Quét mã VietQR',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mở app ngân hàng và quét mã bên dưới',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (order.qrImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: order.qrImageUrl,
                width: 240,
                height: 240,
                memCacheWidth: 240,
                memCacheHeight: 240,
                fit: BoxFit.contain,
                placeholder: (_, _) => const SizedBox(
                  width: 240,
                  height: 240,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                errorWidget: (context, error, stackTrace) => Container(
                  width: 240,
                  height: 240,
                  alignment: Alignment.center,
                  color: AppColors.progressBackground,
                  child: const Text(
                    'Không tải được QR.\nDùng thông tin CK bên dưới.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 240,
              height: 240,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.progressBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'QR chưa sẵn sàng',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(SepayOrder order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: Colors.white70),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Số tiền cần chuyển',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            formatVnd(order.amountVnd),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferDetails(SepayOrder order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.progressBackground),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nội dung chuyển khoản',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ghi đúng nội dung để hệ thống tự nhận diện (mã DH...)',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          _CopyableRow(
            label: 'Mã thanh toán',
            value: order.providerOrderCode,
            emphasized: true,
            onCopy: () => _copyText('mã thanh toán', order.providerOrderCode),
          ),
          const Divider(height: 20),
          _CopyableRow(
            label: 'Nội dung CK (QR)',
            value: order.copyTransferText,
            onCopy: () => _copyText('nội dung CK', order.copyTransferText),
          ),
          if (order.expiredAt != null) ...[
            const Divider(height: 20),
            _InfoRow(
              label: 'Hết hạn đơn',
              value: formatSepayDateTime(order.expiredAt),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiverCard(SepayOrder order) {
    final r = order.receiver;
    if (r.accountNumber.isEmpty && r.bankName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.progressBackground),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin nhận tiền',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          if (r.bankName.isNotEmpty)
            _InfoRow(label: 'Ngân hàng', value: r.bankName),
          if (r.accountNumber.isNotEmpty) ...[
            const SizedBox(height: 8),
            _CopyableRow(
              label: 'Số tài khoản',
              value: r.accountNumber,
              onCopy: () => _copyText('số tài khoản', r.accountNumber),
            ),
          ],
          if (r.accountHolderName.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(label: 'Chủ tài khoản', value: r.accountHolderName),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lưu ý quan trọng',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          SizedBox(height: 8),
          _Bullet('Chuyển đúng số tiền và nội dung như trên.'),
          _Bullet('Sau khi chuyển, app tự kiểm tra mỗi vài giây — không cần bấm xác nhận.'),
          _Bullet('Giao dịch trên SePay có thể mất 1–2 phút mới cập nhật gói.'),
          _Bullet('Đơn hết hạn sau ~30 phút nếu chưa thanh toán.'),
        ],
      ),
    );
  }

  Widget _buildPollingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Đang chờ xác nhận từ ngân hàng...',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Future<void> _cancelOrder() async {
    final order = _order;
    if (order == null || _cancelling || _cancelCountdown > 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy đăng ký'),
        content: const Text(
          'Bạn có chắc muốn hủy đăng ký này không? Sau khi hủy, bạn có thể tạo đăng ký mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hủy đăng ký'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);

    final result = await _repository.cancelOrder(order.paymentId);

    if (!mounted) return;

    setState(() => _cancelling = false);

    if (result.success) {
      setState(() => _isCancelled = true);
      _pollTimer?.cancel();
      _countdownTimer?.cancel();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCancelButton() {
    final countdownText = _cancelCountdown > 0 ? ' ($_cancelCountdown s)' : '';
    final isDisabled = _cancelling || _cancelCountdown > 0;

    return OutlinedButton(
      onPressed: isDisabled ? null : _cancelOrder,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: _cancelling
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
            )
          : Text('Hủy đăng ký$countdownText'),
    );
  }

  Widget _buildCancelledInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cancel_outlined, color: Colors.orange, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Đã hủy đăng ký',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn có thể tạo đăng ký mới hoặc quay về trang gói dịch vụ.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNewOrderButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _createNewOrder,
          icon: const Icon(Icons.refresh),
          label: const Text('Tạo đăng ký mới', style: TextStyle(fontSize: 16)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Quay về trang gói', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Future<void> _createNewOrder() async {
    await _createOrder();
  }
}

class _CopyableRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;
  final VoidCallback onCopy;

  const _CopyableRow({
    required this.label,
    required this.value,
    required this.onCopy,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : '—',
                style: TextStyle(
                  fontSize: emphasized ? 18 : 15,
                  fontWeight: emphasized ? FontWeight.bold : FontWeight.w600,
                  color: AppColors.textDark,
                  letterSpacing: emphasized ? 1.2 : 0,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: value.isEmpty ? null : onCopy,
          icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
          tooltip: 'Sao chép',
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
