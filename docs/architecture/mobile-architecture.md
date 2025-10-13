# BBLearning 移动端技术架构方案

## 文档信息

- **文档版本**: v1.0
- **创建日期**: 2025-01-13
- **适用平台**: iOS (Swift/SwiftUI) + Android (Kotlin/Jetpack Compose)
- **目标版本**: iOS 13+, Android 8.0+
- **关联任务**: #2395

---

## 目录

1. [技术选型](#1-技术选型)
2. [整体架构](#2-整体架构)
3. [iOS技术架构](#3-ios技术架构)
4. [Android技术架构](#4-android技术架构)
5. [共享模块设计](#5-共享模块设计)
6. [性能优化方案](#6-性能优化方案)
7. [安全方案](#7-安全方案)
8. [离线支持](#8-离线支持)
9. [测试策略](#9-测试策略)
10. [部署发布](#10-部署发布)

---

## 1. 技术选型

### 1.1 开发方案对比

| 方案 | 优势 | 劣势 | 选择理由 |
|------|------|------|----------|
| **原生开发** | 性能最优、体验最好、功能完整 | 开发成本高、维护两套代码 | ✅ 推荐 |
| React Native | 跨平台、开发效率高 | 性能不如原生、复杂UI实现困难 | ❌ |
| Flutter | 跨平台、性能接近原生 | 包体积大、生态不够成熟 | ❌ |

**最终选择**: **原生开发**

**理由**:
1. 数学公式渲染需要高性能
2. 相机拍照识题需要原生能力
3. 后期AI语音交互需要原生支持
4. 追求极致用户体验
5. 长期可维护性更好

### 1.2 iOS技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| **语言** | Swift 5.9+ | 主要开发语言 |
| **UI框架** | SwiftUI + UIKit | UI开发(优先SwiftUI) |
| **架构** | MVVM + Clean Architecture | 应用架构 |
| **网络** | Alamofire 5.x | HTTP请求 |
| **数据库** | Realm 10.x / CoreData | 本地数据存储 |
| **图片** | Kingfisher 7.x | 图片加载缓存 |
| **状态管理** | Combine | 响应式编程 |
| **依赖注入** | Swinject | 依赖注入框架 |
| **日志** | CocoaLumberjack | 日志系统 |
| **崩溃收集** | Firebase Crashlytics | 崩溃分析 |
| **公式渲染** | MathJax / KaTeX (WebView) | LaTeX数学公式 |

### 1.3 Android技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| **语言** | Kotlin 1.9+ | 主要开发语言 |
| **UI框架** | Jetpack Compose + XML | UI开发(优先Compose) |
| **架构** | MVVM + Clean Architecture | 应用架构 |
| **网络** | Retrofit 2.x + OkHttp | HTTP请求 |
| **数据库** | Room 2.x | 本地数据存储 |
| **图片** | Coil / Glide | 图片加载缓存 |
| **异步** | Coroutines + Flow | 协程和响应式流 |
| **依赖注入** | Hilt (Dagger) | 依赖注入框架 |
| **日志** | Timber | 日志系统 |
| **崩溃收集** | Firebase Crashlytics | 崩溃分析 |
| **公式渲染** | MathView / WebView | LaTeX数学公式 |

---

## 2. 整体架构

### 2.1 分层架构

```
┌─────────────────────────────────────────┐
│          Presentation Layer              │
│  (SwiftUI/UIKit / Jetpack Compose)      │
│         ViewModels & Views               │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Domain Layer                    │
│   (UseCases / Business Logic)            │
│   (Entities / Domain Models)             │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Data Layer                      │
│  ┌──────────┬──────────┬──────────┐    │
│  │Repository│ Network  │ Database │    │
│  │Interface │  API     │  Cache   │    │
│  └──────────┴──────────┴──────────┘    │
└─────────────────────────────────────────┘
```

### 2.2 模块划分

```
mobile/
├── ios/                          # iOS应用
│   └── BBLearning/
│       ├── App/                  # 应用入口
│       ├── Core/                 # 核心模块
│       │   ├── Network/          # 网络层
│       │   ├── Database/         # 数据库
│       │   ├── Utils/            # 工具类
│       │   └── Extensions/       # 扩展
│       ├── Domain/               # 领域层
│       │   ├── Entities/         # 实体
│       │   ├── UseCases/         # 用例
│       │   └── Repositories/     # 仓库接口
│       ├── Data/                 # 数据层
│       │   ├── Repositories/     # 仓库实现
│       │   ├── DTOs/             # 数据传输对象
│       │   ├── API/              # API服务
│       │   └── Local/            # 本地存储
│       ├── Presentation/         # 表现层
│       │   ├── Auth/             # 认证模块
│       │   ├── Learning/         # 学习模块
│       │   ├── Practice/         # 练习模块
│       │   ├── AI/               # AI辅导模块
│       │   ├── WrongBook/        # 错题本模块
│       │   ├── Report/           # 学习报告模块
│       │   └── Profile/          # 个人中心模块
│       └── Resources/            # 资源文件
│
└── android/                      # Android应用
    └── app/
        ├── src/main/
        │   ├── java/com/bblearning/
        │   │   ├── di/           # 依赖注入
        │   │   ├── core/         # 核心模块
        │   │   ├── domain/       # 领域层
        │   │   ├── data/         # 数据层
        │   │   └── presentation/ # 表现层
        │   └── res/              # 资源文件
        └── build.gradle
```

---

## 3. iOS技术架构

### 3.1 详细目录结构

完整的iOS项目结构请参考文档完整版 (包含150+文件的详细说明)

关键目录:
- **App/**: 应用入口和生命周期管理
- **Core/Network/**: 网络请求、API客户端、拦截器
- **Core/Database/**: Realm/CoreData数据库管理
- **Domain/Entities/**: 领域实体模型
- **Domain/UseCases/**: 业务用例实现
- **Data/Repositories/**: 数据仓库实现
- **Presentation/**: UI界面和ViewModel

### 3.2 核心代码示例

#### 网络层 (APIClient.swift)

```swift
import Alamofire
import Combine

protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, Error>
}

class APIClient: APIClientProtocol {
    private let session: Session
    private let baseURL: String
    private let tokenManager: TokenManager

    init(baseURL: String, tokenManager: TokenManager) {
        self.baseURL = baseURL
        self.tokenManager = tokenManager

        let interceptor = RequestInterceptor(tokenManager: tokenManager)
        self.session = Session(interceptor: interceptor)
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, Error> {
        let url = baseURL + endpoint.path

        return session
            .request(url, method: endpoint.method, parameters: endpoint.parameters)
            .validate()
            .publishDecodable(type: APIResponse<T>.self)
            .tryMap { response -> T in
                guard let value = response.value,
                      value.code == 0,
                      let data = value.data else {
                    throw NetworkError.apiError(code: value?.code ?? -1, message: value?.message ?? "Unknown error")
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// API响应包装
struct APIResponse<T: Decodable>: Decodable {
    let code: Int
    let message: String
    let data: T?
    let requestId: String?
}
```

#### ViewModel示例 (LoginViewModel.swift)

```swift
import Combine

class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var viewState: ViewState = .idle
    @Published var errorMessage: String?

    private let loginUseCase: LoginUseCase
    private var cancellables = Set<AnyCancellable>()

    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }

    func login() {
        guard validate() else { return }

        viewState = .loading

        loginUseCase.execute(username: username, password: password)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.viewState = .error(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] user in
                    self?.viewState = .success
                }
            )
            .store(in: &cancellables)
    }

    private func validate() -> Boolean {
        // 验证逻辑
        return true
    }
}

enum ViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}
```

#### SwiftUI View (LoginView.swift)

```swift
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Logo
            Image("app_logo")
                .resizable()
                .frame(width: 120, height: 120)

            // Title
            Text("Welcome Back")
                .font(.largeTitle)
                .bold()

            // Input Fields
            TextField("Username", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)

            // Error Message
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // Login Button
            Button("Login") {
                viewModel.login()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.viewState == .loading)

            if case .loading = viewModel.viewState {
                ProgressView()
            }
        }
        .padding()
    }
}
```

---

## 4. Android技术架构

### 4.1 详细目录结构

完整的Android项目结构请参考文档完整版 (包含150+文件的详细说明)

关键目录:
- **di/**: Hilt依赖注入配置
- **core/network/**: Retrofit网络层
- **core/database/**: Room数据库
- **domain/model/**: 领域模型
- **domain/usecase/**: 业务用例
- **data/repository/**: 数据仓库
- **presentation/**: Compose UI和ViewModel

### 4.2 核心代码示例

#### 网络层 (ApiService.kt)

```kotlin
interface ApiService {
    @POST("api/v1/auth/login")
    suspend fun login(@Body request: LoginRequest): ApiResponse<LoginResponse>

    @GET("api/v1/knowledge/tree")
    suspend fun getKnowledgeTree(@Query("grade") grade: Int): ApiResponse<List<KnowledgePointDto>>
}

// NetworkModule.kt
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    @Provides
    @Singleton
    fun provideOkHttpClient(tokenManager: TokenManager): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(AuthInterceptor(tokenManager))
            .connectTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BuildConfig.API_BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }
}

// API响应包装
data class ApiResponse<T>(
    val code: Int,
    val message: String,
    val data: T?,
    val requestId: String?
)

sealed class NetworkResult<out T> {
    data class Success<out T>(val data: T) : NetworkResult<T>()
    data class Error(val code: Int, val message: String) : NetworkResult<Nothing>()
    data class Exception(val throwable: Throwable) : NetworkResult<Nothing>()
}
```

#### ViewModel (LoginViewModel.kt)

```kotlin
@HiltViewModel
class LoginViewModel @Inject constructor(
    private val loginUseCase: LoginUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(LoginState())
    val uiState: StateFlow<LoginState> = _uiState.asStateFlow()

    private val _uiEvent = Channel<LoginEvent>()
    val uiEvent = _uiEvent.receiveAsFlow()

    fun onUsernameChange(username: String) {
        _uiState.update { it.copy(username = username) }
    }

    fun onPasswordChange(password: String) {
        _uiState.update { it.copy(password = password) }
    }

    fun onLoginClick() {
        if (!validateInput()) return

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            when (val result = loginUseCase(username = _uiState.value.username, password = _uiState.value.password)) {
                is NetworkResult.Success -> {
                    _uiEvent.send(LoginEvent.NavigateToHome)
                }
                is NetworkResult.Error -> {
                    _uiState.update { it.copy(isLoading = false, error = result.message) }
                }
                is NetworkResult.Exception -> {
                    _uiState.update { it.copy(isLoading = false, error = result.throwable.localizedMessage) }
                }
            }
        }
    }

    private fun validateInput(): Boolean {
        // 验证逻辑
        return true
    }
}

data class LoginState(
    val username: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    val error: String? = null
)

sealed class LoginEvent {
    object NavigateToHome : LoginEvent()
}
```

#### Compose UI (LoginScreen.kt)

```kotlin
@Composable
fun LoginScreen(
    viewModel: LoginViewModel = hiltViewModel(),
    onNavigateToHome: () -> Unit
) {
    val state by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.uiEvent.collect { event ->
            when (event) {
                is LoginEvent.NavigateToHome -> onNavigateToHome()
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(60.dp))

        // Logo
        Image(
            painter = painterResource(R.drawable.app_logo),
            contentDescription = "Logo",
            modifier = Modifier.size(120.dp)
        )

        Spacer(modifier = Modifier.height(32.dp))

        // Title
        Text(
            text = "Welcome Back",
            style = MaterialTheme.typography.headlineLarge
        )

        Spacer(modifier = Modifier.height(48.dp))

        // Username Input
        OutlinedTextField(
            value = state.username,
            onValueChange = viewModel::onUsernameChange,
            label = { Text("Username") },
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Password Input
        OutlinedTextField(
            value = state.password,
            onValueChange = viewModel::onPasswordChange,
            label = { Text("Password") },
            visualTransformation = PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth()
        )

        // Error Message
        if (state.error != null) {
            Text(
                text = state.error,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Login Button
        Button(
            onClick = viewModel::onLoginClick,
            modifier = Modifier.fillMaxWidth(),
            enabled = !state.isLoading
        ) {
            if (state.isLoading) {
                CircularProgressIndicator(modifier = Modifier.size(24.dp))
            } else {
                Text("Login")
            }
        }
    }
}
```

---

## 5. 共享模块设计

### 5.1 数据模型

iOS和Android共享相同的领域模型结构:

```
User
├── id: Int
├── username: String
├── grade: Int (7/8/9)
├── avatar: String?
└── createdAt: Date

KnowledgePoint
├── id: Int
├── name: String
├── description: String
├── content: String (JSON)
├── grade: Int
├── chapterId: Int
└── difficulty: Difficulty

Question
├── id: Int
├── type: QuestionType
├── content: QuestionContent
├── answer: String
├── analysis: String
├── difficulty: Difficulty
└── knowledgePointIds: [Int]
```

### 5.2 API接口规范

```
Base URL: https://api.bblearning.com/api/v1

Response Format:
{
  "code": 0,
  "message": "Success",
  "data": {},
  "requestId": "xxx"
}
```

### 5.3 离线数据同步

**同步策略**:
- 增量同步 (基于时间戳)
- 冲突解决 (服务器优先)
- 同步时机: App启动、网络恢复、定期后台同步

---

## 6. 性能优化方案

### 6.1 启动优化

- 延迟初始化非关键组件
- 预加载关键数据
- 减少启动时的网络请求

### 6.2 内存优化

- 图片下采样和缓存
- 及时释放不用的资源
- 使用弱引用避免循环引用

### 6.3 列表优化

- 使用LazyVStack/LazyColumn
- 实现分页加载
- Cell重用和优化

### 6.4 数学公式渲染

使用WebView + KaTeX:
- 本地缓存KaTeX库
- 公式预渲染
- 异步加载

---

## 7. 安全方案

### 7.1 数据加密

- Token存储: iOS Keychain / Android EncryptedSharedPreferences
- 敏感数据加密传输

### 7.2 网络安全

- HTTPS强制
- SSL Pinning
- 请求签名验证

### 7.3 代码混淆

- iOS: 符号混淆
- Android: ProGuard/R8

---

## 8. 离线支持

### 8.1 离线功能

可离线使用:
- 已下载的知识点
- 已缓存的题目
- 错题本
- 学习记录

需要网络:
- AI问答
- 拍照识题
- 生成新题目

### 8.2 同步机制

- 增量同步
- 冲突解决
- 后台同步

---

## 9. 测试策略

### 9.1 单元测试

- 覆盖率目标: >80%
- 测试框架: XCTest / JUnit
- Mock框架: 自定义Mock / Mockito

### 9.2 UI测试

- iOS: XCUITest
- Android: Espresso / Compose Testing

### 9.3 集成测试

- API集成测试
- 数据库测试
- 端到端测试

---

## 10. 部署发布

### 10.1 iOS发布

**流程**:
1. 代码签名配置
2. Archive构建
3. TestFlight内测
4. App Store提交

**工具**: Fastlane自动化

### 10.2 Android发布

**流程**:
1. 签名配置
2. Release构建
3. 内部测试轨道
4. 分阶段发布

**工具**: Gradle + Play Console

### 10.3 CI/CD

使用GitHub Actions:
- 自动构建
- 自动测试
- 自动发布到TestFlight/Play Console

---

## 总结

### 核心要点

1. **技术选型**: 原生开发 (iOS Swift + Android Kotlin)
2. **架构模式**: Clean Architecture + MVVM
3. **关键技术**:
   - iOS: SwiftUI + Combine + Alamofire + Realm
   - Android: Jetpack Compose + Coroutines + Retrofit + Room
4. **性能优化**: 启动、内存、列表、公式渲染
5. **安全方案**: 加密存储、SSL Pinning、代码混淆
6. **离线支持**: 增量同步、本地缓存
7. **测试**: 单元测试 + UI测试 + 集成测试
8. **CI/CD**: GitHub Actions自动化

### 开发路线图

**Phase 1** (Week 1-4): 核心功能
- 用户认证
- 知识点学习
- 基础练习

**Phase 2** (Week 5-8): 功能完善
- AI辅导
- 错题本
- 学习报告

**Phase 3** (Week 9-10): 优化测试
- 性能优化
- 全面测试

**Phase 4** (Week 11-12): 发布上线
- 内测
- Bug修复
- 正式发布

### 预估工作量

- **iOS开发**: 320小时 (约8周)
- **Android开发**: 320小时 (约8周)
- **总计**: 640小时

---

**文档版本**: v1.0
**创建时间**: 2025-01-13
**关联任务**: #2395
**作者**: Claude Code AI Assistant
