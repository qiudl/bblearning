import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.isLoggedIn {
            MainTabView()
        } else {
            LoginViewWithBiometric()
                .environmentObject(appState)
        }
    }
}

// MARK: - Biometric Types

enum BiometricType {
    case touchID
    case faceID
    case none

    var displayName: String {
        switch self {
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .none:
            return "不支持"
        }
    }

    var iconName: String {
        switch self {
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        case .none:
            return "xmark.circle"
        }
    }
}

// MARK: - Login View with Biometric

struct LoginViewWithBiometric: View {
    @State private var username = ""
    @State private var password = ""
    @State private var rememberPassword = false
    @State private var navigateToRegister = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    // Biometric state
    @State private var isBiometricAvailable = false
    @State private var isBiometricEnabled = false
    @State private var biometricType: BiometricType = .none
    @State private var showBiometricEnablePrompt = false

    @EnvironmentObject var appState: AppState

    var body: some View {
        let _ = print("🖥️ [LoginView] Rendering with:")
        let _ = print("   - isBiometricAvailable: \(isBiometricAvailable)")
        let _ = print("   - isBiometricEnabled: \(isBiometricEnabled)")
        let _ = print("   - biometricType: \(biometricType)")

        return NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo和标题
                    VStack(spacing: 16) {
                        Image(systemName: "graduationcap.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.primary)

                        Text("BBLearning")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("初中数学AI学习平台")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)

                    // 生物识别快速登录按钮
                    if isBiometricAvailable {
                        if isBiometricEnabled {
                            // 已启用：显示快速登录按钮
                            BiometricLoginButton(
                                biometricType: biometricType,
                                action: loginWithBiometric
                            )
                            .padding(.top, 20)
                        } else {
                            // 未启用：显示提示信息
                            BiometricPromptView(biometricType: biometricType) {
                                // 点击提示框显示说明
                                errorMessage = "请先使用账号密码登录，登录成功后系统会自动提示您启用\(biometricType.displayName)快速登录功能。"
                                showError = true
                            }
                            .padding(.top, 20)
                        }
                    }

                    // 登录表单
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("用户名")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(.secondary)
                                TextField("请输入用户名", text: $username)
                                    .autocapitalization(.none)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("密码")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.secondary)
                                SecureField("请输入密码", text: $password)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }

                        // 记住密码
                        HStack {
                            Toggle("记住密码", isOn: $rememberPassword)
                                .font(.subheadline)

                            Spacer()

                            Button("忘记密码?") {
                                // TODO: 忘记密码逻辑
                            }
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 32)

                    // 登录按钮
                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("登录")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((!username.isEmpty && !password.isEmpty) ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(username.isEmpty || password.isEmpty || isLoading)
                    .padding(.top, 16)

                    // 注册
                    HStack {
                        Text("还没有账号?")
                            .foregroundColor(.secondary)

                        Button("立即注册") {
                            navigateToRegister = true
                        }
                        .foregroundColor(.primary)
                    }
                    .font(.subheadline)
                    .padding(.top, 8)

                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                print("🎬 [LoginView] onAppear - 检查生物识别状态")
                checkBiometricAvailability()
            }
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
        .alert("启用生物识别登录", isPresented: $showBiometricEnablePrompt) {
            Button("启用") {
                enableBiometric()
            }
            Button("暂不启用", role: .cancel) {
                print("ℹ️ 用户选择暂不启用生物识别")
                showBiometricEnablePrompt = false
                // 无论是否启用，都要完成登录流程
                appState.login()
            }
        } message: {
            Text("使用\(biometricType.displayName)快速登录")
        }
        .sheet(isPresented: $navigateToRegister) {
            Text("注册页面")
        }
    }

    // MARK: - Actions

    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        isBiometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if isBiometricAvailable {
            switch context.biometryType {
            case .touchID:
                biometricType = .touchID
            case .faceID:
                biometricType = .faceID
            case .none:
                biometricType = .none
                isBiometricAvailable = false
            @unknown default:
                biometricType = .none
                isBiometricAvailable = false
            }

            // 检查是否已启用
            isBiometricEnabled = UserDefaults.standard.bool(forKey: "biometric_enabled")

            print("🔐 [LoginView] 生物识别检查完成:")
            print("   - 设备支持: \(isBiometricAvailable)")
            print("   - 已启用: \(isBiometricEnabled)")
            print("   - 类型: \(biometricType.displayName)")
        } else {
            print("❌ [LoginView] 设备不支持生物识别: \(error?.localizedDescription ?? "未知原因")")
        }
    }

    private func login() {
        isLoading = true

        // 简化的登录逻辑（演示版）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false

            // 验证用户名和密码（演示版：任何非空值都可以登录）
            if !username.isEmpty && !password.isEmpty {
                print("✅ 登录成功")

                // 如果支持生物识别但未启用，提示用户启用
                if isBiometricAvailable && !isBiometricEnabled {
                    print("🔐 [登录成功] 准备显示生物识别启用提示")
                    // 延迟一下确保UI稳定后再显示alert
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showBiometricEnablePrompt = true
                    }
                } else {
                    // 如果不需要提示启用，直接登录
                    appState.login()
                }
            } else {
                errorMessage = "用户名或密码不能为空"
                showError = true
            }
        }
    }

    private func loginWithBiometric() {
        let context = LAContext()
        context.localizedCancelTitle = "取消"
        context.localizedFallbackTitle = "使用密码登录"

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "使用\(biometricType.displayName)快速登录"
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ 生物识别认证成功")
                    // 从UserDefaults读取保存的用户名
                    if let savedUsername = UserDefaults.standard.string(forKey: "biometric_username") {
                        username = savedUsername
                        print("📱 使用保存的用户名: \(savedUsername)")
                    }
                    appState.login()
                } else {
                    if let laError = error as? LAError {
                        switch laError.code {
                        case .userCancel:
                            print("ℹ️ 用户取消了认证")
                        case .userFallback:
                            print("ℹ️ 用户选择密码登录")
                        default:
                            errorMessage = "生物识别认证失败: \(laError.localizedDescription)"
                            showError = true
                        }
                    }
                }
            }
        }
    }

    private func enableBiometric() {
        print("🔐 [启用生物识别] 开始验证...")

        let context = LAContext()
        context.localizedCancelTitle = "取消"
        context.localizedFallbackTitle = "使用密码登录"

        // 先进行一次生物识别认证，确认用户同意
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "验证您的身份以启用\(biometricType.displayName)快速登录"
        ) { [self] success, error in
            DispatchQueue.main.async {
                if success {
                    // 认证成功，保存凭证
                    UserDefaults.standard.set(true, forKey: "biometric_enabled")
                    UserDefaults.standard.set(self.username, forKey: "biometric_username")

                    self.isBiometricEnabled = true
                    self.showBiometricEnablePrompt = false

                    print("✅ 生物识别已启用")
                    print("   - 用户名: \(self.username)")
                    print("   - 类型: \(self.biometricType.displayName)")
                } else {
                    if let laError = error as? LAError {
                        switch laError.code {
                        case .userCancel:
                            print("ℹ️ 用户取消了启用")
                            self.showBiometricEnablePrompt = false
                        default:
                            self.errorMessage = "启用失败: \(laError.localizedDescription)"
                            self.showError = true
                            self.showBiometricEnablePrompt = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Biometric Components

struct BiometricLoginButton: View {
    let biometricType: BiometricType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: biometricType.iconName)
                    .font(.title2)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 4) {
                    Text("快速登录")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("使用\(biometricType.displayName)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.body)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BiometricPromptView: View {
    let biometricType: BiometricType
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: biometricType.iconName)
                    .font(.title2)
                    .foregroundColor(.blue.opacity(0.7))

                VStack(alignment: .leading, spacing: 4) {
                    Text("支持\(biometricType.displayName)登录")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("点击了解如何启用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.blue.opacity(0.7))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 首页
            NavigationView {
                HomeView()
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            .tag(0)

            // 知识点
            NavigationView {
                KnowledgeView()
            }
            .tabItem {
                Label("知识点", systemImage: "book.fill")
            }
            .tag(1)

            // 练习
            NavigationView {
                PracticeView()
            }
            .tabItem {
                Label("练习", systemImage: "pencil")
            }
            .tag(2)

            // AI辅导
            NavigationView {
                AITutorView()
            }
            .tabItem {
                Label("AI辅导", systemImage: "brain")
            }
            .tag(3)

            // 我的
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
            .tag(4)
        }
        .accentColor(.blue)
    }
}

// MARK: - Placeholder Views

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Banner
                VStack(alignment: .leading, spacing: 10) {
                    Text("欢迎来到 BBLearning")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("开始你的智能学习之旅")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)

                // Quick Actions
                VStack(alignment: .leading, spacing: 15) {
                    Text("快速开始")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        QuickActionCard(icon: "book.fill", title: "知识点", color: .blue)
                        QuickActionCard(icon: "pencil", title: "练习题", color: .green)
                        QuickActionCard(icon: "brain", title: "AI辅导", color: .purple)
                        QuickActionCard(icon: "chart.bar.fill", title: "学习统计", color: .orange)
                    }
                    .padding(.horizontal)
                }

                // Recent Activities
                VStack(alignment: .leading, spacing: 10) {
                    Text("最近学习")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(0..<3) { index in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("完成练习 \(index + 1)")
                                    .font(.subheadline)
                                Text("2分钟前")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("首页")
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(15)
    }
}

struct KnowledgeView: View {
    var body: some View {
        List {
            Section(header: Text("数学")) {
                NavigationLink("代数") {
                    Text("代数内容")
                }
                NavigationLink("几何") {
                    Text("几何内容")
                }
            }

            Section(header: Text("物理")) {
                NavigationLink("力学") {
                    Text("力学内容")
                }
                NavigationLink("电学") {
                    Text("电学内容")
                }
            }

            Section(header: Text("化学")) {
                NavigationLink("有机化学") {
                    Text("有机化学内容")
                }
                NavigationLink("无机化学") {
                    Text("无机化学内容")
                }
            }
        }
        .navigationTitle("知识点")
    }
}

struct PracticeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Practice Stats
                HStack(spacing: 20) {
                    StatCard(title: "已练习", value: "125", color: .blue)
                    StatCard(title: "正确率", value: "85%", color: .green)
                }
                .padding(.horizontal)

                // Practice Categories
                VStack(alignment: .leading, spacing: 15) {
                    Text("选择练习类型")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(["随机练习", "错题重做", "专项练习", "模拟考试"], id: \.self) { type in
                        Button(action: {}) {
                            HStack {
                                Text(type)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("练习")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct AITutorView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "你好！我是 AI 学习助手，有什么可以帮到你的吗？", isUser: false)
    ]
    @State private var inputText = ""

    var body: some View {
        VStack {
            // Messages
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(messages) { message in
                        HStack {
                            if message.isUser {
                                Spacer()
                            }

                            Text(message.text)
                                .padding()
                                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(message.isUser ? .white : .primary)
                                .cornerRadius(15)
                                .frame(maxWidth: 250, alignment: message.isUser ? .trailing : .leading)

                            if !message.isUser {
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }

            // Input
            HStack {
                TextField("输入消息...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(inputText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("AI 辅导")
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }

        // Add user message
        messages.append(ChatMessage(text: inputText, isUser: true))

        let userInput = inputText
        inputText = ""

        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let responses = [
                "这是一个很好的问题！让我来解答...",
                "我理解你的困惑，让我详细说明一下。",
                "根据你的问题，我建议...",
                "很高兴能帮到你！"
            ]
            messages.append(ChatMessage(text: responses.randomElement() ?? "收到！", isUser: false))
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("演示用户")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("demo@bblearning.com")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 10)
                }
                .padding(.vertical, 10)
            }

            Section(header: Text("学习数据")) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("学习统计")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "star.fill")
                    Text("我的收藏")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("错题本")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("设置")) {
                HStack {
                    Image(systemName: "gear")
                    Text("偏好设置")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "bell.fill")
                    Text("通知设置")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button(action: {
                    appState.logout()
                }) {
                    HStack {
                        Spacer()
                        Text("退出登录")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("我的")
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
