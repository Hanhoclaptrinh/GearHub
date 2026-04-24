import 'package:get_it/get_it.dart';
import 'package:mobile/src/core/network/api_client.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';
import 'package:mobile/src/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // core
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(storageService: getIt<SecureStorageService>()),
  );

  // auth
  getIt.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasource(dio: getIt<ApiClient>().dio),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDatasource: getIt<AuthRemoteDatasource>(),
      storageService: getIt<SecureStorageService>(),
    ),
  );

  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(repository: getIt<AuthRepository>()),
  );
}
