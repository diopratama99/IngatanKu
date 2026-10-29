import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/ai_chat/data/chat_session_store.dart';
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
import '../../features/quiz/data/datasources/quiz_remote_datasource.dart';
import '../../features/quiz/data/repositories/quiz_repository_impl.dart';
import '../../features/quiz/domain/repositories/quiz_repository.dart';
import '../../features/notes/data/datasources/personal_note_image_store.dart';
import '../../features/notes/data/datasources/personal_note_local_datasource.dart';
import '../../features/notes/data/datasources/personal_note_remote_datasource.dart';
import '../../features/notes/data/repositories/personal_note_repository_impl.dart';
import '../../features/notes/domain/repositories/personal_note_repository.dart';
import '../../features/companion/data/pet_inbox.dart';
import '../../features/companion/data/pet_remote.dart';
import '../../features/companion/data/pet_store.dart';
import '../../features/companion/data/pet_sync.dart';
import '../../features/vault/data/datasources/auto_summarize_remote_datasource.dart';
import '../../features/vault/data/datasources/metadata_remote_datasource.dart';
import '../../features/vault/data/datasources/vault_local_datasource.dart';
import '../../features/vault/data/datasources/vault_remote_datasource.dart';
import '../../features/vault/data/repositories/auto_summarize_repository_impl.dart';
import '../../features/vault/data/repositories/vault_repository_impl.dart';
import '../../features/vault/domain/repositories/auto_summarize_repository.dart';
import '../../features/vault/domain/repositories/vault_repository.dart';
import '../../features/vault/domain/usecases/add_note.dart';
import '../../features/vault/domain/usecases/auto_summarize.dart';
import '../../features/vault/domain/usecases/delete_note.dart';
import '../../features/vault/domain/usecases/get_notes.dart';
import '../../features/vault/domain/usecases/update_note.dart';
import '../database/app_database.dart';
import '../database/local_sync.dart';
import '../network/supabase_client.dart';
import '../services/app_settings_service.dart';
import '../services/media_download_service.dart';
import '../services/notification_service.dart';
import '../services/voice_input_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton(() => SupabaseService.instance);
  // The app's own database: the user's notes on the phone.
  sl.registerLazySingleton(() => AppDatabase());
  String? currentUser() => sl<SupabaseService>().currentUserId;

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
  sl.registerLazySingleton(() => VaultLocalDataSource(sl()));
  sl.registerLazySingleton<VaultRepository>(() =>
      VaultRepositoryImpl(remote: sl(), local: sl(), currentUser: currentUser));
  sl.registerLazySingleton<MetadataRemoteDataSource>(
      () => MetadataRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton(() => GetNotes(sl()));
  sl.registerLazySingleton(() => AddNote(sl()));
  sl.registerLazySingleton(() => DeleteNote(sl()));
  sl.registerLazySingleton(() => UpdateNote(sl()));

  // Auto-summarize (write-aid for AddNote/EditNote)
  sl.registerLazySingleton(() => AutoSummarizeRemoteDataSource(sl()));
  sl.registerLazySingleton<AutoSummarizeRepository>(
      () => AutoSummarizeRepositoryImpl(sl()));
  sl.registerLazySingleton(() => AutoSummarize(sl()));

  // Services
  sl.registerLazySingleton(() => VoiceInputService());
  sl.registerLazySingleton(() => NotificationService.instance);
  sl.registerLazySingleton(() => MediaDownloadService(sl()));
  // AppSettingsService is initialized in main() before runApp because
  // its values are read on first paint by MaterialApp. We just expose
  // the already-initialized singleton here for everyone else to use.
  sl.registerLazySingleton(() => AppSettingsService.instance);

  // Chat
  sl.registerLazySingleton(() => ChatRemoteDataSource(sl()));
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));

  // Dashboard
  sl.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl(
      notes: sl(), pet: sl(), currentUser: currentUser));

  // The virtual pet — on the device first, kept in the account too.
  final prefs = await SharedPreferences.getInstance();
  // The Assistant's last conversation, for when the app is opened again.
  sl.registerLazySingleton(() => ChatSessionStore(prefs));
  sl.registerLazySingleton(() => PetStore(prefs));
  // Its inbox (the bell on Beranda) watches it from the start, so no
  // moment worth keeping slips by.
  sl.registerSingleton(PetInbox(prefs, sl<PetStore>()));
  sl.registerLazySingleton<PetRemote>(() => SupabasePetRemote(sl()));
  // Follows whoever is signed in: their pet comes down, changes go up.
  final auth = sl<SupabaseService>().auth;
  sl.registerSingleton(
    PetSync(prefs, sl<PetStore>(), sl<PetInbox>(), sl<PetRemote>())
      ..start(
        auth.currentUser?.id,
        auth.onAuthStateChange.map((e) => e.session?.user.id),
      ),
  );

  // Weekly Quiz
  sl.registerLazySingleton(() => QuizRemoteDataSource(sl()));
  sl.registerLazySingleton<QuizRepository>(() => QuizRepositoryImpl(sl()));

  // Personal Notes (Catatan / Google-Keep-style)
  sl.registerLazySingleton<PersonalNoteImageStore>(
      () => PersonalNoteImageStore());
  sl.registerLazySingleton<PersonalNoteRemoteDataSource>(
      () => PersonalNoteRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton(() => PersonalNoteLocalDataSource(sl()));
  sl.registerLazySingleton<PersonalNoteRepository>(() =>
      PersonalNoteRepositoryImpl(
          remote: sl(), local: sl(), images: sl(), currentUser: currentUser));

  // Notes on the phone, kept in step with the account.
  sl.registerSingleton(
    LocalSync([sl<VaultRepository>(), sl<PersonalNoteRepository>()])
      ..start(
        auth.currentUser?.id,
        auth.onAuthStateChange.map((e) => e.session?.user.id),
      ),
  );
}
