import 'dart:convert';

class AuthorizedUser {
  final String username;
  final String passwordHash;
  final String salt;
  final bool isAdmin;
  final DateTime createdAt;

  const AuthorizedUser({
    required this.username,
    required this.passwordHash,
    required this.salt,
    this.isAdmin = false,
    required this.createdAt,
  });

  AuthorizedUser copyWith({
    String? username,
    String? passwordHash,
    String? salt,
    bool? isAdmin,
    DateTime? createdAt,
  }) {
    return AuthorizedUser(
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'passwordHash': passwordHash,
      'salt': salt,
      'isAdmin': isAdmin,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AuthorizedUser.fromJson(Map<String, dynamic> json) {
    return AuthorizedUser(
      username: json['username'] as String,
      passwordHash: json['passwordHash'] as String,
      salt: json['salt'] as String,
      isAdmin: json['isAdmin'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory AuthorizedUser.fromJsonString(String jsonString) {
    return AuthorizedUser.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthorizedUser && other.username == username;
  }

  @override
  int get hashCode => username.hashCode;
}