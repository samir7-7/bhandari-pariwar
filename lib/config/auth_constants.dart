class AuthConstants {
  static const userCollection = 'app_users';

  static const adminEmails = <String>{
    'admin1@bhandaripariwar.app',
    'admin2@bhandaripariwar.app',
    'admin3@bhandaripariwar.app',
    'admin4@bhandaripariwar.app',
  };

  static bool isAdminEmail(String? email) {
    if (email == null) return false;
    return adminEmails.contains(email.trim().toLowerCase());
  }
}
