class ApiEndpoints {
  // Use 10.0.2.2 for Android emulator to access local IIS/Kestrel.
  // Port 5000 is typically HTTP for .NET. Change if you are using HTTPS (5001).
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  static const String login = '$baseUrl/Auth/login';
  static const String register = '$baseUrl/Auth/register';
  static const String getProfile = '$baseUrl/Profile/me';
  static const String changePassword = '$baseUrl/User/change-password';
}
