// lib/models/user.dart

class User {
  final String id;
  final String email;
  final String token;
  final String name;
  // Add other user fields as needed

  User({
    required this.id,
    required this.email,
    required this.token,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['id'].toString(),
      email: json['email'],
      token: token,
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'token': token,
      };
}
