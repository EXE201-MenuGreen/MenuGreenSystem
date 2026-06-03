import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/sepay_models.dart';

class SepayPaymentRepository {
  SepayPaymentRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<({bool success, SepayOrder? data, String message})> createOrder({
    required String subscriptionPlanId,
    String? note,
  }) async {
    final response = await _api.postJson(ApiEndpoints.sepayCreateOrder, {
      'subscriptionPlanId': subscriptionPlanId,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return _parseOrderResponse(response);
  }

  Future<({bool success, SepayOrder? data, String message})> createRenewOrder({
    required String userSubscriptionId,
    String? note,
  }) async {
    final response = await _api.postJson(ApiEndpoints.sepayCreateRenewOrder, {
      'userSubscriptionId': userSubscriptionId,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return _parseOrderResponse(response);
  }

  Future<({bool success, SepayOrder? data, String message})> getPaymentStatus(
    String paymentId,
  ) async {
    final response = await _api.get(ApiEndpoints.sepayPaymentStatus(paymentId));
    return _parseOrderResponse(response);
  }

  Future<({bool success, List<SepayOrder> data, String message})> getPendingOrders() async {
    final response = await _api.get(ApiEndpoints.sepayPendingOrders);
    if (response.statusCode != 200) {
      return (
        success: false,
        data: <SepayOrder>[],
        message: _extractErrorMessage(response.body),
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return (success: false, data: <SepayOrder>[], message: 'Phản hồi không hợp lệ');
      }

      final items = decoded['items'] ?? decoded['Items'];
      if (items is! List) {
        return (success: true, data: <SepayOrder>[], message: 'Thành công');
      }

      final orders = items
          .whereType<Map<String, dynamic>>()
          .map(SepayOrder.fromJson)
          .where((o) => o.paymentStatus == SepayPaymentStatus.pending)
          .toList();

      return (success: true, data: orders, message: 'Thành công');
    } catch (_) {
      return (success: false, data: <SepayOrder>[], message: 'Phản hồi không hợp lệ');
    }
  }

  Future<({bool success, SepayOrder? data, String message})> _parseOrderResponse(
    dynamic response,
  ) async {
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return (
          success: true,
          data: SepayOrder.fromJson(decoded),
          message: 'Thành công',
        );
      }
      return (success: false, data: null, message: 'Phản hồi không hợp lệ');
    }

    return (
      success: false,
      data: null,
      message: _extractErrorMessage(response.body),
    );
  }

  String _extractErrorMessage(String body) {
    if (body.isEmpty) return 'Yêu cầu thất bại';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['Message'];
        if (message != null) return message.toString();
      }
    } catch (_) {}
    return 'Yêu cầu thất bại';
  }
}
