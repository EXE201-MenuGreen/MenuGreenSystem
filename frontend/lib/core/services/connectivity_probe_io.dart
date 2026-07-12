import 'dart:io';

Future<bool> hasNetworkConnection() async {
  try {
    final result = await InternetAddress.lookup(
      'api.menugreen.food',
    ).timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
