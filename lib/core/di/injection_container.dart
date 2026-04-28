import 'package:get_it/get_it.dart';

import '../../features/ai_chat/data/datasources/chat_remote_datasource.dart';
import '../../features/ai_chat/data/repositories/chat_repository_impl.dart';
import '../../features/ai_chat/domain/repositories/chat_repository.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/gamification/data/repositories/badge_repository_impl.dart';
import '../../features/gamification/domain/repositories/badge_repository.dart';
import '../../features/vault/data/datasources/metadata_remote_datasource.dart';
import '../../features/vault/data/datasources/vault_remote_datasource.dart';
import '../../features/vault/data/repositories/share_repository_impl.dart';
import '../../features/vault/data/repositories/vault_repository_impl.dart';
import '../../features/vault/domain/repositories/share_repository.dart';
import '../../features/vault/domain/repositories/vault_repository.dart';
import '../../features/vault/domain/usecases/add_note.dart';
import '../../features/vault/domain/usecases/delete_note.dart';
import '../../features/vault/domain/usecases/get_notes.dart';
import '../../features/vault/domain/usecases/update_note.dart';
import '../network/supabase_client.dart';
import '../services/notification_service.dart';
import '../services/voice_input_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton(() => SupabaseService.instance);

  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SignUp(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

  // Vault
  sl.registerLazySingleton<VaultRemoteDataSource>(
      () => VaultRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<VaultRepository>(() => VaultRepositoryImpl(sl()));
  sl.registerLazySingleton<MetadataRemoteDataSource>(
      () => MetadataRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ShareRepository>(() => ShareRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetNotes(sl()));
  sl.registerLazySingleton(() => AddNote(sl()));
  sl.registerLazySingleton(() => DeleteNote(sl()));
  sl.registerLazySingleton(() => UpdateNote(sl()));

  // Services
  sl.registerLazySingleton(() => VoiceInputService());
  sl.registerLazySingleton(() => NotificationService.instance);

  // Chat
  sl.registerLazySingleton(() => ChatRemoteDataSource(sl()));
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));

  // Dashboard
  sl.registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(sl()));

  // Badges
  sl.registerLazySingleton<BadgeRepository>(() => BadgeRepositoryImpl(sl()));
}
