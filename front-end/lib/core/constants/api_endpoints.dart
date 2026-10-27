class ApiEndpoints {
  static const String baseUrl = 'http://localhost:8000';
  
  // User Auth APIs
  static const String login = '$baseUrl/api/users/login/';
  static const String register = '$baseUrl/api/users/register/';

  // Case APIs
  static const String createCase = '$baseUrl/api/cases/create/';
  static const String listCases = '$baseUrl/api/cases/list/';
}
