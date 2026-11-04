import '../../core/api_client.dart';
import 'models.dart';

class ChatRepository {
  final ApiClient api;
  ChatRepository(this.api);

  Future<List<Room>> rooms() async =>
      (await api.get('/rooms') as List).map((e) => Room.fromJson(e)).toList();

  Future<Room> createRoom(String name) async => Room.fromJson(await api.post('/rooms', {'name': name}));

  Future<List<Message>> messages(int roomId) async =>
      (await api.get('/rooms/$roomId/messages') as List).map((e) => Message.fromJson(e)).toList();
}
