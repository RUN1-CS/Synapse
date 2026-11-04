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

  Future<List<User>> searchUsers(String search) async => (await api.get(
              '/conversations/users?search=${Uri.encodeQueryComponent(search)}')
          as List)
      .map((e) => User.fromJson(e))
      .toList();

  Future<User> profile(int userId) async =>
      User.fromJson(Map<String, dynamic>.from(
          await api.get('/conversations/users/$userId') as Map));

  Future<List<NotificationItem>> notifications() async =>
      (await api.get('/notifications') as List)
          .map((e) => NotificationItem.fromJson(e))
          .toList();

  Future<void> markNotificationRead(int id) async =>
      api.patch('/notifications/$id/read', {});

  Future<Conversation> conversationFor(User user) async {
    final data = Map<String, dynamic>.from(
        await api.post('/conversations', {'userId': user.id}) as Map);
    data['userId'] = user.id;
    data['username'] = user.username;
    data['displayName'] = user.displayName;
    data['avatarUrl'] = user.avatarUrl;
    return Conversation.fromJson(data);
  }

  Future<void> requestFriend(int userId) async {
    await api.post('/conversations/friends/requests', {'userId': userId});
  }

  Future<void> respondFriend(int userId, bool accept) async {
    await api
        .patch('/conversations/friends/requests/$userId', {'accept': accept});
  }

  Future<void> setMuted(int userId, bool muted) async {
    await api.patch('/conversations/friends/$userId/mute', {'muted': muted});
  }

  Future<void> setBlocked(int userId, bool blocked) async {
    await api
        .patch('/conversations/friends/$userId/block', {'blocked': blocked});
  }

  Future<List<Message>> messages(int conversationId,
          {int? before, int? after}) async =>
      (await api.get('/conversations/$conversationId/messages?'
              '${before == null ? '' : 'before=$before&'}'
              '${after == null ? '' : 'after=$after'}') as List)
          .map((e) => Message.fromJson(e))
          .toList();
}
