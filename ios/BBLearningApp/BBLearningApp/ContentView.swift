import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.isLoggedIn {
            MainTabView()
        } else {
            LoginView()
        }
    }
}

// MARK: - Login View

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var username = ""
    @State private var password = ""
    @State private var isShowingAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Spacer()
                
                // Logo and Title
                VStack(spacing: 10) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("BBLearning")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("智能学习助手")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Login Form
                VStack(spacing: 15) {
                    TextField("用户名", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .autocapitalization(.none)
                    
                    SecureField("密码", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                
                // Login Button
                Button(action: login) {
                    Text("登录")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Demo hint
                Text("提示：演示版本，直接点击登录即可")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
                
                Spacer()
                Spacer()
            }
            .navigationTitle("登录")
            .alert("登录成功", isPresented: $isShowingAlert) {
                Button("确定", role: .cancel) { }
            }
        }
    }
    
    private func login() {
        // Demo login - no validation required
        appState.login()
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
