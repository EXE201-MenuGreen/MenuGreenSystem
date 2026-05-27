class ApiEndpoints {
  // 1. Dành cho Android Emulator (Máy ảo Android chạy từ Android Studio) - ĐANG KÍCH HOẠT:
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // 2. Dành cho iOS Simulator (Máy ảo iOS) hoặc chạy Flutter Web/Desktop:
  // static const String baseUrl = 'http://localhost:5000/api';

  // 3. Dành cho Thiết bị thật (Physical Device) kết nối Wi-Fi:
  // IP hiện tại của máy tính bạn: 172.16.130.121
  // static const String baseUrl = 'http://172.16.130.121:5000/api';

  static const String login = '$baseUrl/Auth/login';
  static const String register = '$baseUrl/Auth/register';
  static const String getProfile = '$baseUrl/Profile/me';
  static const String changePassword = '$baseUrl/User/change-password';
}
