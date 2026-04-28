class UsersTable {
  static const String tableName = 'users';
  static const String id = 'id';
  static const String name = 'name';
  static const String email = 'email';
  static const String password = 'password';
  static const String role = 'role';
  static const String createdAt = 'created_at';
  static const String contactNumber = 'contact_number';

  static const String createSql =
      '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $name TEXT NOT NULL,
      $email TEXT NOT NULL UNIQUE,
      $password TEXT NOT NULL,
      $role TEXT NOT NULL DEFAULT 'user',
      $createdAt TEXT NOT NULL,
      $contactNumber TEXT
    )
  ''';
}
