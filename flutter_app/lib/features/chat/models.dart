class Conversation {
  final int id;
  Conversation({required this.id});
  factory Conversation.fromJson(Map<String, dynamic> j) =>
      Conversation(id: int.parse('${j['id']}'));
}

class Message {
  final int id;
  final int conversationId;
  final int userId;
  final String username;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: int.parse('${j['id']}'), // BIGSERIAL arrives as a string
        conversationId: int.parse('${j['conversationId']}'),
        userId: j['userId'],
        username: j['username'],
        content: j['content'],
        createdAt: DateTime.parse(j['createdAt']).toLocal(),
      );
}
