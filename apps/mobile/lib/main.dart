import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Services
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/sync_service.dart';
import 'services/connectivity_service.dart';
import 'services/background_sync_service.dart';

// BLoCs
import 'blocs/auth/auth_bloc.dart';
import 'blocs/sync/sync_bloc.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Services
  getIt.registerLazySingleton(() => ApiService());
  getIt.registerLazySingleton(() => AuthService(getIt()));
  getIt.registerLazySingleton(() => DatabaseService());
  getIt.registerLazySingleton(() => SyncService(getIt(), getIt()));
  getIt.registerLazySingleton(() => ConnectivityService());
  getIt.registerLazySingleton(() => BackgroundSyncService());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup DI
  setupDependencies();
  
  // Initialize services
  await getIt<DatabaseService>().init();
  await getIt<ConnectivityService>().initialize();
  await getIt<BackgroundSyncService>().initialize();
  await getIt<BackgroundSyncService>().registerPeriodicSync();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(getIt())..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => SyncBloc(
            getIt(),
            getIt(),
            Connectivity(),
          )..add(SyncStarted()),
        ),
      ],
      child: MaterialApp(
        title: 'DeliveryMaker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AppNavigator(),
      ),
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is AuthAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
