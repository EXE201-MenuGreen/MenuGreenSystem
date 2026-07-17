import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../subscription/models/sepay_models.dart';

class PremiumProgramRepository {
  PremiumProgramRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> getPrograms() async {
    return _asList(_body(await _api.get(ApiEndpoints.premiumPrograms)));
  }

  Future<List<Map<String, dynamic>>> getMyPrograms() async {
    final response = await _api.get(ApiEndpoints.myPremiumPrograms);
    if (response.statusCode == 404) return const [];
    return _asList(_body(response));
  }

  Future<SepayOrder> checkout(String programId) async {
    final data = _asMap(
      _body(
        await _api.postJson(
          ApiEndpoints.premiumProgramCheckout(programId),
          const {},
        ),
      ),
    );
    return SepayOrder.fromJson(data);
  }

  Future<Map<String, dynamic>> activate(
    String userProgramId,
    DateTime startDate,
  ) async {
    return _asMap(
      _body(
        await _api.postJson(
          ApiEndpoints.premiumProgramActivate(userProgramId),
          {'startDate': _dateOnly(startDate)},
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> checkIn({
    required int weekNumber,
    required double weightKg,
    double? bodyFatPercent,
    double? chestCm,
    double? waistCm,
    double? hipCm,
  }) async {
    final payload = <String, dynamic>{'weightKg': weightKg};
    if (bodyFatPercent != null) {
      payload['bodyFatPercent'] = bodyFatPercent;
    }
    if (chestCm != null) payload['chestCm'] = chestCm;
    if (waistCm != null) payload['waistCm'] = waistCm;
    if (hipCm != null) payload['hipCm'] = hipCm;
    return _asMap(
      _body(
        await _api.postJson(
          ApiEndpoints.premiumProgramCheckIn(weekNumber),
          payload,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> graduate() async {
    return _asMap(
      _body(await _api.postJson(ApiEndpoints.premiumProgramGraduate, const {})),
    );
  }

  Future<Map<String, dynamic>> getReport(String userProgramId) async {
    return _asMap(
      _body(await _api.get(ApiEndpoints.premiumProgramReport(userProgramId))),
    );
  }

  dynamic _body(http.Response response) {
    final dynamic data = response.body.isEmpty
        ? null
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? data['message'] ?? data['Message'] ?? data['title']
          : null;
      throw Exception(
        message?.toString() ?? 'Yêu cầu thất bại (${response.statusCode})',
      );
    }
    return data;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return Map<String, dynamic>.from(value as Map);
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
