# N-SCRRA Implementation Guide - Next Phases

## Phase 1: Authentication System (Priority: CRITICAL)

### 1.1 Auth Repository Implementation
**File**: `lib/data/repositories/auth_repository.dart`

```dart
abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password, String orgId);
  Future<void> logout();
  Future<AuthResponse> refreshToken();
  Future<List<OrganizationModel>> getOrganizations();
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<String?> getAccessToken();
}

class AuthRepositoryImpl implements AuthRepository {
  final Dio dio; // injected from dioProvider
  final FlutterSecureStorage storage;
  
  @override
  Future<AuthResponse> login(String email, String password, String orgId) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'org_id': orgId,
          'device_id': '...',
          'fcm_token': '...'
        }
      );
      final result = AuthResponse.fromJson(response.data);
      await saveTokens(result.accessToken, result.refreshToken);
      return result;
    } on AppException {
      rethrow;
    }
  }
  // ... other methods
}
```

**API Endpoint**:
- POST `/auth/login`
- Request: `{email, password, org_id, device_id, fcm_token}`
- Response: `{access_token, refresh_token, expires_in, user_profile, permissions[]}`
- Errors: 401 (invalid), 423 (locked), 403 (org access denied)

### 1.2 Login UseCase
**File**: `lib/domain/usecases/login_usecase.dart`

```dart
class LoginParams {
  final String email;
  final String password;
  final String organizationId;
}

class LoginUseCase extends UseCase<LoginParams, AuthResponse> {
  final AuthRepository _repository;
  
  LoginUseCase(this._repository);
  
  @override
  Future<AuthResponse> call(LoginParams params) async {
    // Validate email format
    if (!_isValidEmail(params.email)) {
      throw ValidationException(fieldErrors: {'email': 'Invalid email format'});
    }
    // Validate password strength
    if (params.password.length < 8) {
      throw ValidationException(fieldErrors: {'password': 'Minimum 8 characters'});
    }
    return await _repository.login(
      params.email,
      params.password,
      params.organizationId
    );
  }
}
```

### 1.3 Auth ViewModel
**File**: `lib/presentation/viewmodels/auth/auth_viewmodel.dart`

```dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default('') String email,
    @Default('') String password,
    @Default(false) bool isPasswordVisible,
    @Default(false) bool isLoading,
    @Default(false) bool rememberMe,
    String? error,
    AuthResponse? authResponse,
  }) = _AuthState;
}

class AuthViewModel extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  
  AuthViewModel(this._loginUseCase) : super(const AuthState());
  
  void setEmail(String email) => state = state.copyWith(email: email);
  void setPassword(String password) => state = state.copyWith(password: password);
  void togglePasswordVisibility() => 
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  
  Future<void> login(String orgId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _loginUseCase(LoginParams(
        email: state.email,
        password: state.password,
        organizationId: orgId,
      ));
      state = state.copyWith(authResponse: result, isLoading: false);
      // Navigate to dashboard
    } on ValidationException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    }
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  return AuthViewModel(loginUseCase);
});
```

## Phase 2: Core Features

### 2.1 Dashboard Repository
**File**: `lib/data/repositories/dashboard_repository.dart`

- Methods: `getDashboardSummary()`, `getSectorRisks()`, `getAlerts()`, `getTrendMetrics()`
- Caching strategy: 1-minute cache for dashboard, 5-minute for alerts
- Auto-refresh every 30 seconds when screen active

### 2.2 Alert Management
**File**: `lib/data/repositories/alert_repository.dart`

- Methods: `getAlerts()`, `acknowledgeAlert()`, `snoozeAlert()`, `updatePreferences()`
- WebSocket integration: Listen to `/ws/alerts` for real-time updates
- Notification display: Integration with FCM + flutter_local_notifications

### 2.3 Supplier Management
**File**: `lib/data/repositories/supplier_repository.dart`

- Methods: `getSupplierDetail()`, `getSuppliersNear()`, `getDependencies()`, `getRecommendations()`
- Data models: Supplier, Dependency, SupplierRecommendation
- Risk calculation: Based on API risk_score + manual risk adjustments

## Phase 3: Widget Component Library

### 3.1 NRI Gauge Chart
**File**: `lib/presentation/widgets/charts/nri_gauge.dart`

Features:
- Half-circle arc indicator (0-100)
- Color zones: Green (0-30), Yellow (31-60), Orange (61-80), Red (81-100)
- Animated value changes
- Delta badge (+/- percentage)
- "Updated X mins ago" label

### 3.2 Reusable Cards
**File**: `lib/presentation/widgets/cards/sector_risk_card.dart`
- Sector name, risk score, colored indicator circle

**File**: `lib/presentation/widgets/cards/alert_card.dart`
- Severity indicator, title, timestamp, action chips

**File**: `lib/presentation/widgets/cards/supplier_card.dart`
- Logo, name, risk level, location, action buttons

### 3.3 Common Widgets
**File**: `lib/presentation/widgets/common/loading_overlay.dart`
- Modal loading spinner

**File**: `lib/presentation/widgets/common/error_banner.dart`
- Error message display with retry button

## Phase 4: Advanced Screens

### 4.1 Prediction Screen
**File**: `lib/presentation/views/prediction/prediction_screen.dart`

Features:
- Line chart showing probability curves (fl_chart)
- Confidence bands (95%, 80%)
- Time window selector (1 week, 1 month, 3 months)
- Economic impact visualization
- Backtesting results

### 4.2 Simulation Screen
**File**: `lib/presentation/views/simulation/simulation_screen.dart`

Features:
- Monte Carlo simulation controller (# iterations)
- Animated network cascade visualization
- Impact results (suppliers affected, revenue impact, duration)
- Export simulation results

### 4.3 Recommendations Screen
**File**: `lib/presentation/views/recommendations/recommendations_screen.dart`

Features:
- Tab 1: Supplier Alternatives (with cost/risk comparison)
- Tab 2: Route Optimization (port alternatives, logistics)
- Tab 3: Safety Stock Configuration (by SKU)
- Tab 4: Supply Diversification Strategy

## Phase 5: Background Services

### 5.1 WebSocket Service
**File**: `lib/services/websocket_service.dart`

```dart
class WebSocketService {
  late final Socket socket;
  
  Future<void> connect(String token) async {
    socket = io('${AppConfig.current.baseUrl}/ws', SocketIoClientOptions(
      auth: {'Authorization': 'Bearer $token'},
      reconnection: true,
    ));
    
    socket.on('alert', (data) {
      // Handle real-time alert
      // Display notification
      // Update local cache
    });
    
    socket.connect();
  }
  
  void disconnect() => socket.disconnect();
}
```

### 5.2 Firebase Messaging Setup
**File**: `lib/services/notification_service.dart`

```dart
class NotificationService {
  Future<void> initialize() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // Request permission
    await messaging.requestPermission();
    
    // Get FCM token and send to backend
    String? token = await messaging.getToken();
    // Save to backend during login
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Display local notification with flutter_local_notifications
    });
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
```

### 5.3 Background Sync (Optional)
**File**: `lib/services/background_sync_service.dart`

- Use `workmanager` package for periodic tasks
- Sync offline alerts every 15 minutes when online
- Refresh cache every 30 minutes

## Testing Structure

### Unit Tests
```dart
// test/repositories/auth_repository_test.dart
void main() {
  group('AuthRepository', () {
    test('login should return AuthResponse on success', () async {
      // Mock dio and repository
      // Verify API call with correct parameters
      // Verify token storage
    });
    
    test('login should throw AuthException on 401', () async {
      // Mock dio to return 401
      // Verify AuthException thrown
    });
  });
}

// test/viewmodels/auth_viewmodel_test.dart
void main() {
  group('AuthViewModel', () {
    test('login should update state correctly', () async {
      // Mock LoginUseCase
      // Call login()
      // Verify state changes (isLoading, authResponse, error)
    });
  });
}
```

## Implementation Checklist

### Essential (Complete Before MVP)
- [ ] AuthRepository and LoginUseCase
- [ ] AuthViewModel and updated LoginScreen
- [ ] DashboardRepository and DashboardViewModel
- [ ] AlertRepository with WebSocket service
- [ ] Notification service integration
- [ ] Token persistence and refresh
- [ ] Navigation protecting authenticated routes

### Important (Complete in v1.0)
- [ ] Supplier detail screen and ViewModels
- [ ] Settings and preferences management
- [ ] Report generation and export
- [ ] Profile screen implementation
- [ ] Offline cache strategy

### Nice-to-Have (Post-launch)
- [ ] Advanced prediction screen
- [ ] Simulation capabilities
- [ ] Network map visualization
- [ ] Analytics tracking
- [ ] Performance optimization

## Development Tips

1. **Start with Authentication**: Everything depends on tokens, so complete this first
2. **Test Interceptors**: Verify token attachment and error handling locally
3. **Use Riverpod DevTools**: Debug state changes with `riverpod_generator` and DevTools
4. **Mock APIs**: Use `mockito` or `mocktail` for testing without real backend
5. **Incremental Testing**: Test each layer separately before integration
6. **Performance**: Profile with DevTools to identify bottlenecks early

## File Template for New Repository

```dart
// lib/data/repositories/{name}_repository.dart

abstract class {Name}Repository {
  Future<{Model}> get{Method}();
}

class {Name}RepositoryImpl implements {Name}Repository {
  final Dio dio;
  final {LocalStorage} storage;
  
  {Name}RepositoryImpl({
    required this.dio,
    required this.storage,
  });
  
  @override
  Future<{Model}> get{Method}() async {
    try {
      // Try to get from cache first
      final cached = await storage.get{Method}();
      if (cached != null) return cached;
      
      // Fetch from API
      final response = await dio.get('/{endpoint}');
      final model = {Model}.fromJson(response.data);
      
      // Cache result
      await storage.save{Method}(model);
      return model;
    } on AppException {
      rethrow;
    }
  }
}

final {name}RepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch({localStorageProvider});
  return {Name}RepositoryImpl(dio: dio, storage: storage);
});
```

---
**Total Estimated Implementation Time**: 40-60 hours
- Phase 1 (Auth): 8 hours
- Phase 2 (Core Features): 12 hours
- Phase 3 (Widgets): 8 hours
- Phase 4 (Advanced Screens): 16 hours
- Phase 5 (Services): 8 hours
- Testing & Polish: 8 hours
