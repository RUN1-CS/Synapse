class User {
  final int id;
  final String username;
  User({required this.id, required this.username});

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] is int
            ? j['id']
            : int.tryParse(j['id']?.toString() ?? '') ?? 0,
        username: j['username']?.toString() ?? '',
      );
  Map<String, dynamic> toJson() => {'id': id, 'username': username};
}
