enum SepayPaymentStatus {
  pending,
  paid,
  expired,
  failed,
  refunded,
  unknown;

  static SepayPaymentStatus fromString(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'PENDING':
        return SepayPaymentStatus.pending;
      case 'PAID':
        return SepayPaymentStatus.paid;
      case 'EXPIRED':
        return SepayPaymentStatus.expired;
      case 'FAILED':
        return SepayPaymentStatus.failed;
      case 'REFUNDED':
        return SepayPaymentStatus.refunded;
      default:
        return SepayPaymentStatus.unknown;
    }
  }

  bool get isTerminal =>
      this == SepayPaymentStatus.paid ||
      this == SepayPaymentStatus.expired ||
      this == SepayPaymentStatus.failed ||
      this == SepayPaymentStatus.refunded;
}

class SepayReceiver {
  final String bankName;
  final String accountNumber;
  final String accountHolderName;

  const SepayReceiver({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
  });

  factory SepayReceiver.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SepayReceiver(
        bankName: '',
        accountNumber: '',
        accountHolderName: '',
      );
    }
    return SepayReceiver(
      bankName: _pickString(json, 'bankName', 'BankName'),
      accountNumber: _pickString(json, 'accountNumber', 'AccountNumber'),
      accountHolderName: _pickString(json, 'accountHolderName', 'AccountHolderName'),
    );
  }
}

class SepayOrder {
  final String paymentId;
  final String userSubscriptionId;
  final int amountVnd;
  final String status;
  final String providerOrderCode;
  final String transferContent;
  final String transferMemo;
  final String qrImageUrl;
  final SepayReceiver receiver;
  final DateTime? expiredAt;
  final String orderType;
  final String subscriptionPlanId;
  final String subscriptionPlanName;
  final DateTime? createdAt;

  const SepayOrder({
    required this.paymentId,
    required this.userSubscriptionId,
    required this.amountVnd,
    required this.status,
    required this.providerOrderCode,
    required this.transferContent,
    required this.transferMemo,
    required this.qrImageUrl,
    required this.receiver,
    this.expiredAt,
    this.orderType = '',
    this.subscriptionPlanId = '',
    this.subscriptionPlanName = '',
    this.createdAt,
  });

  factory SepayOrder.fromJson(Map<String, dynamic> json) {
    final receiverRaw = json['receiver'] ?? json['Receiver'];
    return SepayOrder(
      paymentId: _pickString(json, 'paymentId', 'PaymentId'),
      userSubscriptionId: _pickString(json, 'userSubscriptionId', 'UserSubscriptionId'),
      amountVnd: _pickInt(json, 'amountVnd', 'AmountVnd'),
      status: _pickString(json, 'status', 'Status'),
      providerOrderCode: _pickString(json, 'providerOrderCode', 'ProviderOrderCode'),
      transferContent: _pickString(json, 'transferContent', 'TransferContent'),
      transferMemo: _pickString(json, 'transferMemo', 'TransferMemo'),
      qrImageUrl: _pickString(json, 'qrImageUrl', 'QrImageUrl'),
      receiver: receiverRaw is Map<String, dynamic>
          ? SepayReceiver.fromJson(receiverRaw)
          : SepayReceiver.fromJson(null),
      expiredAt: _pickDate(json, 'expiredAt', 'ExpiredAt'),
      orderType: _pickString(json, 'orderType', 'OrderType'),
      subscriptionPlanId: _pickString(json, 'subscriptionPlanId', 'SubscriptionPlanId'),
      subscriptionPlanName: _pickString(json, 'subscriptionPlanName', 'SubscriptionPlanName'),
      createdAt: _pickDate(json, 'createdAt', 'CreatedAt'),
    );
  }

  bool get isSubscribeOrder =>
      orderType.toLowerCase() == 'subscribe' || orderType.isEmpty;

  bool get isRenewOrder => orderType.toLowerCase() == 'renew';

  SepayPaymentStatus get paymentStatus => SepayPaymentStatus.fromString(status);

  String get copyTransferText {
    if (transferMemo.isNotEmpty) return transferMemo;
    if (transferContent.isNotEmpty) return transferContent;
    return providerOrderCode;
  }
}

String _pickString(Map<String, dynamic> json, String camel, String pascal) {
  return (json[camel] ?? json[pascal])?.toString() ?? '';
}

int _pickInt(Map<String, dynamic> json, String camel, String pascal) {
  final value = json[camel] ?? json[pascal];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

DateTime? _pickDate(Map<String, dynamic> json, String camel, String pascal) {
  final value = json[camel] ?? json[pascal];
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String formatSepayDateTime(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

String formatCountdown(Duration remaining) {
  if (remaining.isNegative) return '00:00';
  final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = remaining.inHours;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}
