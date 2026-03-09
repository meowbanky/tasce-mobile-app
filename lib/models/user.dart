// lib/models/user.dart

class User {
  final String id;
  final String email;
  final String token;
  final String name;
  final String? employeeId;
  // Add other user fields as needed

  User({
    required this.id,
    required this.email,
    required this.token,
    required this.name,
    this.employeeId,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['id'].toString(),
      email: json['email'],
      token: token,
      name: json['name'],
      employeeId: json['employee_id'] ?? json['employeeId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'token': token,
        'name': name,
        'employee_id': employeeId,
      };
}
