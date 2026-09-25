class User {
  final int id;
  final String username;
  final String phone;

  User({
    required this.id,
    required this.username,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}