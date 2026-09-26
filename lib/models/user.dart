class User {
  final int id;
  final String username;
  final String phone;
  final bool isAdmin;
  final String fullName;

  User({
    required this.id,
    required this.username,
    required this.phone,
    this.isAdmin = false,
    this.fullName = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isAdmin: json['is_admin'] == true,
      fullName: json['full_name']?.toString() ?? '',
    );
  }
}
