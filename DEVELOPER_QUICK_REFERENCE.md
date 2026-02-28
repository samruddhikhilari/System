# N-SCRRA Developer Quick Reference

## 🗺️ Architecture Map

### Project Structure Overview
```
lib/
├── core/                          # Configuration, errors, constants
│   ├── app_config.dart           # Environment-based configuration
│   ├── app_router.dart           # Navigation routes (16 screens)
│   ├── app_theme.dart            # Material Design 3 theme
│   ├── constants/app_constants.dart  # API endpoints, keys, values
│   └── errors/
│       ├── exceptions.dart       # 8 exception types (sealed)
│       └── failure.dart          # Reserved for Result pattern
│
├── data/                         # API, cache, models
│   ├── models/
│   │   ├── user_model.dart       # User + Organization models
│   │   ├── auth_model.dart       # Login + Auth response models
│   │   └── dashboard_model.dart  # Dashboard data models
│   ├── repositories/             # Data access layer (IMPLEMENT)
│   │   ├── auth_repository.dart
│   │   ├── dashboard_repository.dart
│   │   ├── supplier_repository.dart
│   │   └── ... (6+ more)
│   └── sources/
│       ├── remote/
│       │   ├── dio_provider.dart           # HTTP client config
│       │   ├── auth_interceptor.dart       # Token attachment
│       │   ├── error_interceptor.dart      # Exception mapping
│       │   └── logging_interceptor.dart    # Debug logging
│       └── local/                          # Hive, SharedPreferences (IMPLEMENT)
│
├── domain/                       # Business logic
│   ├── entities/
│   └── usecases/                 # Business logic (IMPLEMENT)
│       ├── login_usecase.dart
│       ├── dashboard_usecase.dart
│       └── ... (12+ more)
│
├── presentation/                 # UI layer
│   ├── viewmodels/               # State management (Riverpod)
│   │   ├── splash/
│   │   │   ├── splash_viewmodel.dart       # ✅ EXISTS
│   │   │   └── splash_state.dart           # ✅ EXISTS
│   │   ├── auth/                           # IMPLEMENT
│   │   ├── dashboard/                      # IMPLEMENT
│   │   └── ... (8+ more needed)
│   ├── views/                    # Screen implementations
│   │   ├── splash/splash_screen.dart              # ✅ EXISTS
│   │   ├── onboarding/onboarding_screen.dart      # ✅ EXISTS
│   │   ├── login/login_screen.dart                # ✅ EXISTS
│   │   ├── dashboard/dashboard_screen.dart        # ✅ EXISTS
│   │   ├── alerts/alert_center_screen.dart        # ✅ EXISTS
│   │   ├── settings/settings_screen.dart          # ✅ EXISTS
│   │   ├── profile/profile_screen.dart            # ✅ EXISTS
│   │   ├── network/network_map_screen.dart        # Placeholder
│   │   ├── supplier/supplier_detail_screen.dart   # Placeholder
│   │   ├── risk/risk_intelligence_screen.dart     # Placeholder
│   │   ├── admin/admin_panel_screen.dart          # ✅ EXISTS
│   │   ├── prediction/prediction_screen.dart      # Placeholder
│   │   ├── simulation/simulation_screen.dart      # Placeholder
│   │   ├── recommendations/recommendations_screen.dart  # Placeholder
│   │   ├── route_optimization/route_optimization_screen.dart  # Placeholder
│   │   ├── vulnerability/vulnerability_scanner_screen.dart  # Placeholder
│   │   └── reports/reports_screen.dart            # Placeholder
│   └── widgets/                  # Reusable UI components
│       ├── charts/               # (IMPLEMENT)
│       │   ├── nri_gauge.dart
│       │   ├── risk_trend_chart.dart
│       │   └── probability_curve_chart.dart
│       ├── cards/                # (IMPLEMENT)
│       │   ├── sector_risk_card.dart
│       │   ├── alert_card.dart
│       │   └── supplier_card.dart
│       └── common/               # (IMPLEMENT)
│           ├── loading_overlay.dart
│           ├── error_banner.dart
│           └── empty_state.dart
│
└── services/                     # Background & external services
    ├── notification_service.dart   # FCM + local notifications (IMPLEMENT)
    ├── websocket_service.dart      # Real-time alerts (IMPLEMENT)
    ├── background_sync_service.dart # Periodic sync (IMPLEMENT)
    └── analytics_service.dart       # Event tracking (IMPLEMENT)
```

## 🔄 Data Flow Patterns

### Pattern 1: Simple Data Fetch (e.g., Dashboard)
```
DashboardScreen
    ↓ (consumes)
DashboardViewModel (StateNotifier<DashboardState>)
    ↓ (calls)
GetDashboardSummaryUseCase
    ↓ (calls)
DashboardRepository
    ↓ (uses)
dioProvider + Hive cache
    ↓ (HTTP)
Backend API: GET /dashboard/summary
```

### Pattern 2: User Action (e.g., Login)
```
User taps Login button
    ↓
LoginScreen._onLoginPressed()
    ↓
authViewModelProvider.notifier.login(email, password, orgId)
    ↓ (state = AuthState.copyWith(isLoading: true))
AuthViewModel.login()
    ↓
LoginUseCase(params)
    ↓ (validation)
AuthRepository.login()
    ↓ (POST request with interceptors)
dio → AuthInterceptor (attach headers) → ErrorInterceptor → Backend
    ↓ (on success)
Save tokens to FlutterSecureStorage
    ↓
authViewModelProvider.state = AuthState(..., authResponse: response)
    ↓
NavigationProvider.goNamed('/dashboard')
```

### Pattern 3: Real-Time Alert (WebSocket)
```
Backend sends alert via WebSocket
    ↓
WebSocketService._onAlert(data)
    ↓
NotificationService.showNotification()
    ↓ (foreground + background)
AlertRepository.addAlert() [local cache]
    ↓
AlertViewModel notified (listener pattern)
    ↓
AlertCenterScreen rebuilds with new alert
```

## 🛠️ How to Implement New Features

### Add a New Repository
1. Create `lib/data/repositories/{name}_repository.dart`
2. Define abstract interface with methods needed
3. Implement using `dioProvider` for HTTP
4. Create Riverpod provider below class
5. Use in UseCase

**Template**:
```dart
// lib/data/repositories/example_repository.dart
abstract class ExampleRepository {
  Future<ExampleModel> getData();
}

class ExampleRepositoryImpl implements ExampleRepository {
  final Dio dio;
  final ExampleLocalStorage storage;
  
  ExampleRepositoryImpl({required this.dio, required this.storage});
  
  @override
  Future<ExampleModel> getData() async {
    try {
      final cached = await storage.getExample();
      if (cached != null) return cached;
      
      final response = await dio.get('/endpoint');
      final model = ExampleModel.fromJson(response.data);
      await storage.saveExample(model);
      return model;
    } on AppException {
      rethrow;
    }
  }
}

final exampleRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(exampleStorageProvider);
  return ExampleRepositoryImpl(dio: dio, storage: storage);
});
```

### Add a New UseCase
1. Create `lib/domain/usecases/{name}_usecase.dart`
2. Extend `UseCase<Params, ReturnType>`
3. Implement `call()` method with validation
4. Create Riverpod provider
5. Inject repository via constructor

**Template**:
```dart
// lib/domain/usecases/example_usecase.dart
class ExampleParams {
  final String id;
  ExampleParams({required this.id});
}

class ExampleUseCase extends UseCase<ExampleParams, ExampleModel> {
  final ExampleRepository _repository;
  
  ExampleUseCase(this._repository);
  
  @override
  Future<ExampleModel> call(ExampleParams params) async {
    if (params.id.isEmpty) {
      throw ValidationException(fieldErrors: {'id': 'ID cannot be empty'});
    }
    return await _repository.getData(params.id);
  }
}

final exampleUseCaseProvider = Provider((ref) {
  final repository = ref.watch(exampleRepositoryProvider);
  return ExampleUseCase(repository);
});
```

### Add a New ViewModel
1. Create `lib/presentation/viewmodels/{feature}/{name}_viewmodel.dart`
2. Define `@freezed` State class
3. Create StateNotifier extending class
4. Create StateNotifierProvider
5. Implement methods calling UseCases

**Template**:
```dart
// lib/presentation/viewmodels/example/example_viewmodel.dart
@freezed
class ExampleState with _$ExampleState {
  const factory ExampleState({
    @Default(false) bool isLoading,
    ExampleModel? data,
    String? error,
  }) = _ExampleState;
}

class ExampleViewModel extends StateNotifier<ExampleState> {
  final ExampleUseCase _exampleUseCase;
  
  ExampleViewModel(this._exampleUseCase) : super(const ExampleState());
  
  Future<void> loadData(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _exampleUseCase(ExampleParams(id: id));
      state = state.copyWith(data: result, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    }
  }
}

final exampleViewModelProvider = StateNotifierProvider<ExampleViewModel, ExampleState>((ref) {
  final useCase = ref.watch(exampleUseCaseProvider);
  return ExampleViewModel(useCase);
});
```

### Add a New Screen
1. Create `lib/presentation/views/{feature}/{name}_screen.dart`
2. Make it `StatelessWidget` consuming ViewModel with `watch`
3. Add route to `app_router.dart`
4. Import screen in router file

**Template**:
```dart
// lib/presentation/views/example/example_screen.dart
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exampleViewModelProvider);
    final viewModel = ref.read(exampleViewModelProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Example')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!))
              : ListView(
                  children: [
                    // Display state.data
                  ],
                ),
    );
  }
}

// Then in app_router.dart:
GoRoute(
  path: '/example/:id',
  builder: (context, state) => ExampleScreen(
    id: state.pathParameters['id']!,
  ),
)
```

## 🔐 Authentication Setup Checklist

Request implementation in this order:
1. [ ] **Implement AuthRepository**
   - `login(email, password, orgId)` → POST /auth/login
   - `refreshToken()` → POST /auth/refresh
   - `logout()` → POST /auth/logout
   - `getOrganizations()` → GET /auth/organizations
   - `saveTokens()` → Store in FlutterSecureStorage
   - `getAccessToken()` → Read from FlutterSecureStorage

2. [ ] **Implement LoginUseCase**
   - Validate email format
   - Validate password (min 8 chars)
   - Call `AuthRepository.login()`

3. [ ] **Implement AuthViewModel**
   - State: email, password, isPasswordVisible, isLoading, error
   - Methods: `setEmail()`, `setPassword()`, `togglePasswordVisibility()`, `login()`
   - Side effects: Navigate to dashboard on success

4. [ ] **Update LoginScreen**
   - Connect form fields to ViewModel
   - Handle login response
   - Show loading, error states
   - Hide password toggle

5. [ ] **Update SplashScreen**
   - Check `AuthRepository.getAccessToken()`
   - If exists, go to `/dashboard`
   - If not, go to `/onboarding`

6. [ ] **Update AuthInterceptor**
   - Verify token attachment to all requests
   - Verify org ID header present

7. [ ] **Update ErrorInterceptor**
   - Handle 401 responses → Clear token, go to login
   - Handle 403 org access denied

## 📱 Navigation Patterns

### Push to Screen (keep previous)
```dart
context.push('/dashboard');
```

### Go to Screen (replace stack)
```dart
context.go('/login');
```

### Pop to Previous
```dart
context.pop();
```

### Navigate with Parameters
```dart
context.push('/supplier/${supplierId}');
// In SupplierDetailScreen:
final supplierId = GoRouterState.of(context).pathParameters['id']!;
```

### Reset Navigation (logout)
```dart
ref.read(routerProvider).go('/splash');
```

## 🧪 Testing Patterns

### Mock Repository
```dart
final mockRepo = MockExampleRepository();
when(mockRepo.getData()).thenAnswer((_) async => ExampleModel(...));

// Use in test
final useCase = ExampleUseCase(mockRepo);
final result = await useCase(ExampleParams(...));
```

### Test ViewModel
```dart
test('ViewModel loads data', () async {
  final mockUseCase = MockExampleUseCase();
  when(mockUseCase(...)).thenAnswer((_) async => ExampleModel(...));
  
  final viewModel = ExampleViewModel(mockUseCase);
  await viewModel.loadData('id');
  
  expect(viewModel.state.data, isNotNull);
  expect(viewModel.state.isLoading, false);
});
```

### Test Screen (with ProviderContainer)
```dart
testWidgets('ExampleScreen shows loading', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exampleViewModelProvider.overrideWith((ref) => MockViewModel()),
      ],
      child: const MyApp(),
    ),
  );
  
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

## 🐛 Debugging Checklist

### "No errors found" but screen shows blank
- [ ] Check if ViewModel is being watched correctly
- [ ] Verify repository returns non-null data
- [ ] Check error state in ViewModel
- [ ] Look at console logs for exceptions

### API request returns 401
- [ ] Verify token in FlutterSecureStorage
- [ ] Check AuthInterceptor is attached
- [ ] Ensure token isn't expired
- [ ] Check OAuth token format (Bearer token)

### Screen not navigating
- [ ] Verify route exists in `app_router.dart`
- [ ] Check path parameters match
- [ ] Ensure BuildContext is from navigator
- [ ] Look for errors in GoRouter config

### ListView showing empty but data exists
- [ ] Check data access `viewModel.state.data`
- [ ] Verify list is not empty
- [ ] Confirm ListView.builder itemCount matches list length
- [ ] Check if FutureBuilder/StreamBuilder waiting

### Image not loading
- [ ] Verify URL is correct and accessible
- [ ] Check Image.network errorBuilder
- [ ] Ensure network permission in AndroidManifest.xml
- [ ] Try with placeholder (CachedNetworkImage)

## 📊 Riverpod Debugging

### Watch Provider State
```dart
// In Widget
final state = ref.watch(exampleViewModelProvider);

// In console, add observer
class ProviderLogger extends ProviderObserver {
  void didUpdateProvider(ProviderBase provider, Object? newValue, Object? oldValue, ProviderContainer container) {
    print('[${provider.name ?? provider}] = $newValue');
  }
}

// In main.dart
runApp(
  ProviderScope(observers: [ProviderLogger()], child: const MyApp()),
);
```

### Override Provider in Tests
```dart
testWidgets('Test with overridden provider', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(mockDio),
        exampleRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MyApp(),
    ),
  );
});
```

## 🎯 Common Tasks

| Task | How To |
|------|--------|
| Add API endpoint | Update `AppConstants` + add method to `Repository` + `UseCase` |
| Add screen | Create `views/{feature}/{screen}_screen.dart` + add route in `app_router.dart` |
| Change theme color | Edit `app_theme.dart` Material color schemes |
| Add cache | Use Hive in `Repository` before API call |
| Show notification | Call `NotificationService.showNotification()` |
| Log analytics | Call `AnalyticsService.logEvent()` |
| Add permission | Update `AndroidManifest.xml` + `Info.plist` |
| Use secure storage | `FlutterSecureStorage.read()` + `.write()` |
| Get device ID | `DeviceInfoPlugin.androidInfo.id` or `.iosInfo.identifierForVendor` |
| Upload file | Use Dio FormData: `dio.post(..., data: FormData.fromMap({...}))` |

---

**Keep this guide open while developing!**
