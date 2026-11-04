import '../../core/api_client.dart';
import '../auth/user.dart';
import 'models.dart';

class ChatRepository {
  final ApiClient api;
  ChatRepository(this.api);

  Future<List<Conversation>> conversations() async =>
      (await api.get('/conversations') as List)
          .map((e) => Conversation.fromJson(e))
          .toList();

  Future<List<User>> users() async =>
      (await api.get('/conversations/users') as List)
          .map((e) => User.fromJson(e))
          .toList();

  Future<Conversation> conversationFor(User user) async {
    final data = Map<String, dynamic>.from(
        await api.post('/conversations', {'userId': user.id}) as Map);
    data['userId'] = user.id;
    data['username'] = user.username;
    data['displayName'] = user.displayName;
    data['avatarUrl'] = user.avatarUrl;
    return Conversation.fromJson(data);
  }

  Future<List<Message>> messages(int conversationId) async =>
      (await api.get('/conversations/$conversationId/messages') as List)
          .map((e) => Message.fromJson(e))
          .toList();
}
