import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remote;
  ChatRepositoryImpl(this.remote);

  @override
  Stream<ChatStreamEvent> ask({
    required String question,
    required String sessionId,
  }) =>
      remote.ask(question: question, sessionId: sessionId);
}
