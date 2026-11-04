class Room {
  final int id;
  final String name;
  Room({required this.id, required this.name});
  factory Room.fromJson(Map<String, dynamic> j) => Room(id: j['id'], name: j['name']);
}

class Message {
  final int id;
  final int roomId;
  final int userId;
  final String username;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: int.parse('${j['id']}'), // BIGSERIAL arrives as a string
        roomId: j['roomId'],
        userId: j['userId'],
        username: j['username'],
        content: j['content'],
        createdAt: DateTime.parse(j['createdAt']).toLocal(),
      );
}
