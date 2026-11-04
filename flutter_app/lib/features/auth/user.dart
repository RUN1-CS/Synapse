class User {
  final int id;
  final String username;
  User({required this.id, required this.username});

  factory User.fromJson(Map<String, dynamic> j) => User(id: j['id'], username: j['username']);
  Map<String, dynamic> toJson() => {'id': id, 'username': username};
}
