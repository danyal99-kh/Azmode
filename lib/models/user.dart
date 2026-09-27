class User {
  final int id;
  final String username;
  final String phone;
  final bool isStaff;
  final bool isSuperuser;
  final String fullName;

  bool get isAdmin => isStaff || isSuperuser;

  User({
    required this.id,
    required this.username,
    required this.phone,
    this.isStaff = false,
    this.isSuperuser = false,
    this.fullName = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isStaff: json['is_staff'] == true,
      isSuperuser: json['is_superuser'] == true,
      fullName: json['full_name']?.toString() ?? '',
    );
  }
}
