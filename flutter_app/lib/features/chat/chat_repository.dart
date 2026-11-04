import '../../core/api_client.dart';
import '../auth/user.dart';
import 'models.dart';

class ChatRepository {
  final ApiClient api;
  ChatRepository(this.api);

  Future<List<User>> users() async =>
      (await api.get('/conversations/users') as List)
          .map((e) => User.fromJson(e))
          .toList();

  Future<Conversation> conversationFor(User user) async =>
      Conversation.fromJson(
          await api.post('/conversations', {'userId': user.id}));

  Future<List<Message>> messages(int conversationId) async =>
      (await api.get('/conversations/$conversationId/messages') as List)
          .map((e) => Message.fromJson(e))
          .toList();
}
