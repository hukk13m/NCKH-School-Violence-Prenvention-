class User {
  final int id;
  final String username;
  final String? fullName;
  final String firstName;
  final String lastName;
  final String email;
  final String? roleName;
  final String status;
  final bool isActive;
  final bool isStaff;
  final bool isSuperuser;
  final DateTime? dateJoined;

  User({
    required this.id,
    required this.username,
    this.fullName,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.roleName,
    required this.status,
    required this.isActive,
    this.isStaff = false,
    this.isSuperuser = false,
    this.dateJoined,
  });

  bool get isAdmin =>
      isSuperuser || isStaff || (roleName?.toLowerCase().contains('admin') ?? false);

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id']
          : int.parse(json['id'].toString()),

      username: json['username']?.toString() ?? '',

      fullName: json['full_name']?.toString(),

      firstName: json['first_name']?.toString() ?? '',

      lastName: json['last_name']?.toString() ?? '',

      email: json['email']?.toString() ?? '',

      roleName: json['role_name']?.toString(),

      status: json['status']?.toString() ?? '',

      isActive: json['is_active'] == true,

      isStaff: json['is_staff'] == true,

      isSuperuser: json['is_superuser'] == true,

      dateJoined: json['date_joined'] != null
          ? DateTime.tryParse(json['date_joined'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'full_name': fullName,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'role_name': roleName,
    'status': status,
    'is_active': isActive,
    'is_staff': isStaff,
    'is_superuser': isSuperuser,
  };
}

