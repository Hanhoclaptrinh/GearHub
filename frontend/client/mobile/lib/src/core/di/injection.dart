import 'package:get_it/get_it.dart';
import 'package:mobile/src/core/network/api_client.dart';
import 'package:mobile/src/core/notifications/push_notification_service.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';
import 'package:mobile/src/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/data/services/google_auth_service.dart';
import 'package:mobile/src/features/home/data/datasources/home_remote_datasource.dart';
import 'package:mobile/src/features/home/data/repositories/home_repository_impl.dart';
import 'package:mobile/src/features/home/domain/repositories/home_repository.dart';
import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';
import 'package:mobile/src/features/home/presentation/state/home_cubit.dart';
import 'package:mobile/src/features/home/presentation/state/brand_products_cubit.dart';
import 'package:mobile/src/features/product_detail/data/datasources/product_detail_remote_datasource.dart';
import 'package:mobile/src/features/product_detail/data/repositories/product_detail_repository_impl.dart';
import 'package:mobile/src/features/product_detail/domain/repositories/product_detail_repository.dart';
import 'package:mobile/src/features/product_detail/presentation/state/product_detail_cubit.dart';
import 'package:mobile/src/features/product_compare/data/datasources/product_compare_remote_datasource.dart';
import 'package:mobile/src/features/product_compare/data/repositories/product_compare_repository_impl.dart';
import 'package:mobile/src/features/product_compare/domain/repositories/product_compare_repository.dart';
import 'package:mobile/src/features/product_compare/presentation/state/product_compare_cubit.dart';
import 'package:mobile/src/features/cart/data/datasources/cart_remote_datasource.dart'
    as mobile_cart_remote;
import 'package:mobile/src/features/cart/data/datasources/cart_local_datasource.dart'
    as mobile_cart_local;
import 'package:mobile/src/features/cart/data/repositories/cart_repository_impl.dart'
    as mobile_cart_repo_impl;
import 'package:mobile/src/features/cart/domain/repositories/cart_repository.dart'
    as mobile_cart_repo;
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart'
    as mobile_cart_cubit;
import 'package:mobile/src/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mobile/src/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:mobile/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:mobile/src/features/chat/presentation/services/chat_socket_service.dart';
import 'package:mobile/src/features/chat/presentation/state/concierge_cubit.dart';
import 'package:mobile/src/features/checkout/presentation/state/checkout_cubit.dart'
    as mobile_checkout_cubit;
import 'package:mobile/src/features/profile/presentation/state/orders_cubit.dart';
import 'package:mobile/src/features/wishlist/data/datasources/wishlist_remote_datasource.dart';
import 'package:mobile/src/features/wishlist/data/repositories/wishlist_repository_impl.dart';
import 'package:mobile/src/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_cubit.dart';
import 'package:mobile/src/features/explore/data/datasources/explore_remote_datasource.dart';
import 'package:mobile/src/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:mobile/src/features/explore/domain/repositories/explore_repository.dart';
import 'package:mobile/src/features/product_review/data/datasources/review_remote_datasource.dart';
import 'package:mobile/src/features/product_review/data/repositories/review_repository_impl.dart';
import 'package:mobile/src/features/product_review/domain/repositories/review_repository.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_cubit.dart';
import 'package:mobile/src/features/promotions/data/datasources/promotions_remote_datasource.dart';
import 'package:mobile/src/features/promotions/data/repositories/promotions_repository_impl.dart';
import 'package:mobile/src/features/promotions/domain/repositories/promotions_repository.dart';
import 'package:mobile/src/features/promotions/presentation/state/promotions_cubit.dart';
import 'package:mobile/src/features/promotions/presentation/state/my_vouchers_cubit.dart';
import 'package:mobile/src/features/checkout/presentation/state/checkout_promotion_cubit.dart';
import 'package:mobile/src/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:mobile/src/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:mobile/src/features/notifications/domain/repositories/notification_repository.dart';
import 'package:mobile/src/features/notifications/presentation/state/notification_cubit.dart';
import 'package:mobile/src/features/preferences/data/datasources/preferences_local_datasource.dart';
import 'package:mobile/src/features/preferences/data/datasources/preferences_remote_datasource.dart';
import 'package:mobile/src/features/preferences/data/repositories/preferences_repository_impl.dart';
import 'package:mobile/src/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:mobile/src/features/preferences/presentation/state/preferences_cubit.dart';
import 'package:mobile/src/features/address/data/datasources/address_remote_datasource.dart';
import 'package:mobile/src/features/address/data/repositories/address_repository_impl.dart';
import 'package:mobile/src/features/address/domain/repositories/address_repository.dart';
import 'package:mobile/src/features/address/presentation/state/address_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // core
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(storageService: getIt<SecureStorageService>()),
  );

  getIt.registerLazySingleton<PushNotificationService>(
    () => PushNotificationService(
      apiClient: getIt<ApiClient>(),
      storageService: getIt<SecureStorageService>(),
    ),
  );

  // auth
  getIt.registerLazySingleton<GoogleAuthService>(() => GoogleAuthService());

  getIt.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasource(dio: getIt<ApiClient>().dio),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDatasource: getIt<AuthRemoteDatasource>(),
      storageService: getIt<SecureStorageService>(),
      pushNotificationService: getIt<PushNotificationService>(),
    ),
  );

  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      repository: getIt<AuthRepository>(),
      googleAuthService: getIt<GoogleAuthService>(),
    ),
  );

  // home
  getIt.registerLazySingleton<HomeRemoteDatasource>(
    () => HomeRemoteDatasource(dio: getIt<ApiClient>().dio),
  );

  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDatasource: getIt<HomeRemoteDatasource>()),
  );

  getIt.registerFactory<HomeCubit>(
    () => HomeCubit(repository: getIt<HomeRepository>()),
  );

  // preferences
  getIt.registerLazySingleton<PreferencesRemoteDatasource>(
    () => PreferencesRemoteDatasource(dio: getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<PreferencesLocalDatasource>(
    () => PreferencesLocalDatasource(
      sharedPreferences: getIt<SharedPreferences>(),
    ),
  );
  getIt.registerLazySingleton<PreferencesRepository>(
    () => PreferencesRepositoryImpl(
      remoteDatasource: getIt<PreferencesRemoteDatasource>(),
      localDatasource: getIt<PreferencesLocalDatasource>(),
    ),
  );
  getIt.registerFactory<PreferencesCubit>(
    () => PreferencesCubit(repository: getIt<PreferencesRepository>()),
  );

  // product detail
  getIt.registerLazySingleton<ProductDetailRemoteDatasource>(
    () => ProductDetailRemoteDatasource(dio: getIt<ApiClient>().dio),
  );

  getIt.registerLazySingleton<ProductDetailRepository>(
    () => ProductDetailRepositoryImpl(
      remoteDatasource: getIt<ProductDetailRemoteDatasource>(),
    ),
  );

  getIt.registerFactory<ProductDetailCubit>(
    () => ProductDetailCubit(repository: getIt<ProductDetailRepository>()),
  );

  // product compare
  getIt.registerLazySingleton<ProductCompareRemoteDatasource>(
    () => ProductCompareRemoteDatasource(dio: getIt<ApiClient>().dio),
  );

  getIt.registerLazySingleton<ProductCompareRepository>(
    () => ProductCompareRepositoryImpl(
      remoteDatasource: getIt<ProductCompareRemoteDatasource>(),
    ),
  );

  getIt.registerLazySingleton<ProductCompareCubit>(
    () => ProductCompareCubit(repository: getIt<ProductCompareRepository>()),
  );

  // cart
  getIt.registerLazySingleton<mobile_cart_remote.CartRemoteDataSource>(
    () => mobile_cart_remote.CartRemoteDataSourceImpl(
      apiClient: getIt<ApiClient>(),
    ),
  );

  getIt.registerLazySingleton<mobile_cart_local.CartLocalDataSource>(
    () => mobile_cart_local.CartLocalDataSourceImpl(
      sharedPreferences: getIt<SharedPreferences>(),
    ),
  );

  getIt.registerLazySingleton<mobile_cart_repo.CartRepository>(
    () => mobile_cart_repo_impl.CartRepositoryImpl(
      remoteDataSource: getIt<mobile_cart_remote.CartRemoteDataSource>(),
      localDataSource: getIt<mobile_cart_local.CartLocalDataSource>(),
      authRepository: getIt<AuthRepository>(),
    ),
  );

  getIt.registerLazySingleton<mobile_cart_cubit.CartCubit>(
    () => mobile_cart_cubit.CartCubit(
      repository: getIt<mobile_cart_repo.CartRepository>(),
    ),
  );

  getIt.registerFactory<mobile_checkout_cubit.CheckoutCubit>(
    () => mobile_checkout_cubit.CheckoutCubit(apiClient: getIt<ApiClient>()),
  );

  // chat
  getIt.registerLazySingleton<ChatRemoteDatasource>(
    () => ChatRemoteDatasource(dio: getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDatasource: getIt<ChatRemoteDatasource>()),
  );
  getIt.registerLazySingleton<ChatSocketService>(() => ChatSocketService());
  getIt.registerFactory<ConciergeCubit>(
    () => ConciergeCubit(
      repository: getIt<ChatRepository>(),
      socketService: getIt<ChatSocketService>(),
      storageService: getIt<SecureStorageService>(),
    ),
  );

  getIt.registerFactory<OrdersCubit>(
    () => OrdersCubit(apiClient: getIt<ApiClient>()),
  );

  // wishlist
  getIt.registerLazySingleton<WishlistRemoteDatasource>(
    () => WishlistRemoteDatasource(dio: getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<WishlistRepository>(
    () => WishlistRepositoryImpl(
      remoteDatasource: getIt<WishlistRemoteDatasource>(),
    ),
  );
  getIt.registerFactory<WishlistCubit>(
    () => WishlistCubit(repository: getIt<WishlistRepository>()),
  );

  // explore
  getIt.registerLazySingleton<ExploreRemoteDatasource>(
    () => ExploreRemoteDatasource(dio: getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<ExploreRepository>(
    () => ExploreRepositoryImpl(
      remoteDatasource: getIt<ExploreRemoteDatasource>(),
    ),
  );

  // reviews
  getIt.registerLazySingleton<ReviewRemoteDatasource>(
    () => ReviewRemoteDatasource(dio: getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<ReviewRepository>(
    () => ReviewRepositoryImpl(
      remoteDatasource: getIt<ReviewRemoteDatasource>(),
      authRepository: getIt<AuthRepository>(),
    ),
  );
  getIt.registerFactory<ReviewCubit>(
    () => ReviewCubit(repository: getIt<ReviewRepository>()),
  );

  getIt.registerFactoryParam<BrandProductsCubit, BrandEntity, void>(
    (brand, _) => BrandProductsCubit(getIt<ExploreRepository>(), brand),
  );

  // promotions
  getIt.registerLazySingleton<PromotionsRemoteDatasource>(
    () => PromotionsRemoteDatasource(dio: getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<PromotionsRepository>(
    () => PromotionsRepositoryImpl(
      remoteDatasource: getIt<PromotionsRemoteDatasource>(),
    ),
  );
  getIt.registerFactory<PromotionsCubit>(
    () => PromotionsCubit(repository: getIt<PromotionsRepository>()),
  );
  getIt.registerFactory<MyVouchersCubit>(
    () => MyVouchersCubit(repository: getIt<PromotionsRepository>()),
  );
  getIt.registerFactory<CheckoutPromotionCubit>(
    () => CheckoutPromotionCubit(repository: getIt<PromotionsRepository>()),
  );

  // notifications
  getIt.registerLazySingleton<NotificationRemoteDatasource>(
    () => NotificationRemoteDatasource(dio: getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDatasource: getIt<NotificationRemoteDatasource>(),
    ),
  );
  getIt.registerFactory<NotificationCubit>(
    () => NotificationCubit(repository: getIt<NotificationRepository>()),
  );

  // address
  getIt.registerLazySingleton<AddressRemoteDataSource>(
    () => AddressRemoteDataSource(dio: getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<AddressRepository>(
    () => AddressRepositoryImpl(
      remoteDataSource: getIt<AddressRemoteDataSource>(),
    ),
  );
  getIt.registerFactory<AddressCubit>(
    () => AddressCubit(repository: getIt<AddressRepository>()),
  );
}
