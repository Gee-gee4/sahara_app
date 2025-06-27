class DummyUsers {
  static final Map<String, String> _users = {
    'Janet': '1234',
    'Mark': '5678',
    'Alice': '0000',
  };

  static List<String> getUsernames() => _users.keys.toList();

  static bool login(String username, String password) {
    return _users[username] == password;
  }
}
