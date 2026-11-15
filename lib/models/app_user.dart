class AppUser {
  final int id;
  final String name, email, role;
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
  bool get isAdmin => role == 'admin';
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
  };
}
