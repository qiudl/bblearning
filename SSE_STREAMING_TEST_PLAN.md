# SSE 流式输出功能测试计划

## 测试目标
验证 AI 聊天的 SSE (Server-Sent Events) 流式输出功能是否正常工作，包括前后端集成、UI 动画效果和错误处理。

## 前置条件

### 1. 启动开发环境

```bash
# 在项目根目录
cd /Users/johnqiu/coding/www/projects/bblearning

# 启动 Docker 服务
open -a OrbStack  # 或启动 Docker Desktop

# 启动数据库和其他依赖服务
docker-compose up -d postgres redis minio

# 等待服务就绪
sleep 5
```

### 2. 启动后端服务

```bash
# 在 backend 目录
cd backend

# 检查配置
cat config/config.yaml

# 启动后端（确保 OpenAI API key 已配置）
go run cmd/server/main.go
```

### 3. 启动前端服务

```bash
# 在 frontend 目录
cd frontend

# 安装依赖（如果需要）
npm install

# 启动前端
npm start
```

## 功能测试用例

### 测试用例 1: 基本流式输出

**步骤：**
1. 访问 http://localhost:3000
2. 登录用户账号
3. 进入 "AI问答助手" 页面
4. 在输入框输入简单问题："什么是勾股定理？"
5. 点击 "发送" 按钮

**预期结果：**
- ✅ 用户消息立即显示在聊天窗口中
- ✅ AI 消息以空内容出现
- ✅ AI 回复逐字逐句流式显示
- ✅ 流式输出时显示闪烁光标 `▋`
- ✅ loading 状态正确显示和隐藏
- ✅ 消息自动滚动到底部
- ✅ 完成后光标消失，显示完整回复

### 测试用例 2: 长文本流式输出

**步骤：**
1. 输入复杂问题："请详细讲解一元二次方程的求根公式推导过程，包括配方法的每一步。"
2. 点击发送

**预期结果：**
- ✅ 长文本逐步显示，无卡顿
- ✅ 流式输出过程中可以看到内容逐渐增加
- ✅ 换行符正确处理
- ✅ 消息框随内容增长自动调整大小
- ✅ 自动滚动跟随最新内容

### 测试用例 3: 连续对话

**步骤：**
1. 发送第一个问题："什么是等差数列？"
2. 等待回复完成
3. 立即发送第二个问题："等差数列的求和公式是什么？"
4. 等待回复完成
5. 再发送："请举个例子"

**预期结果：**
- ✅ 每条消息都能正确流式显示
- ✅ 消息顺序正确
- ✅ 不会出现消息混淆
- ✅ conversation_id 正确保存
- ✅ 上下文连贯

### 测试用例 4: UI 动画效果

**步骤：**
1. 发送任意问题
2. 观察流式输出过程

**预期结果：**
- ✅ 新消息出现时有淡入动画 (fadeIn 0.3s)
- ✅ 流式输出时显示绿色闪烁光标
- ✅ 光标每 0.8 秒闪烁一次
- ✅ 完成后光标消失
- ✅ "AI正在思考..." 显示时有闪烁动画

### 测试用例 5: 错误处理

**测试 5.1: 网络中断**
**步骤：**
1. 开始发送消息
2. 在流式输出过程中关闭后端服务
3. 观察前端反应

**预期结果：**
- ✅ 显示错误提示消息
- ✅ loading 状态正确重置
- ✅ 不会导致页面崩溃
- ✅ 可以继续发送新消息

**测试 5.2: 未登录**
**步骤：**
1. 清除 localStorage 中的 token
2. 发送消息

**预期结果：**
- ✅ 显示 "未登录，请先登录" 错误
- ✅ 不会发起请求

**测试 5.3: API 错误**
**步骤：**
1. 使用无效的 OpenAI API key
2. 发送消息

**预期结果：**
- ✅ 接收到 error 事件
- ✅ 显示友好的错误提示
- ✅ AI 消息更新为错误提示

### 测试用例 6: 性能测试

**步骤：**
1. 连续快速发送 5 条消息
2. 观察系统表现

**预期结果：**
- ✅ 所有消息都能正确处理
- ✅ 流式输出不会互相干扰
- ✅ 内存使用正常
- ✅ 无明显卡顿

### 测试用例 7: 浏览器兼容性

**测试浏览器：**
- Chrome (推荐)
- Safari
- Firefox
- Edge

**预期结果：**
- ✅ 所有浏览器都能正常显示流式输出
- ✅ 动画效果一致
- ✅ SSE 连接稳定

## 后端 API 测试

### 测试 SSE 端点

使用 curl 测试流式输出：

```bash
# 1. 先登录获取 token
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}' | jq -r '.data.access_token')

# 2. 测试流式 API
curl -N -X POST http://localhost:8080/api/v1/ai/chat/stream \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message":"什么是勾股定理？"}'
```

**预期输出格式：**
```
event: message
data: {"content":"勾"}

event: message
data: {"content":"股"}

event: message
data: {"content":"定理"}

...

event: done
data: {"done":true,"conversation_id":123}
```

### 后端日志检查

检查后端日志是否有错误：

```bash
tail -f /tmp/bblearning.log
```

**应该看到：**
- ✅ SSE 连接建立日志
- ✅ OpenAI API 调用成功
- ✅ 流式内容发送日志
- ✅ 对话记录保存成功
- ❌ 无错误或异常

## 数据验证

### 检查数据库记录

```sql
-- 连接到数据库
psql -U bblearning -d bblearning_dev

-- 查看最近的对话记录
SELECT id, user_id, role,
       LEFT(content, 50) as content_preview,
       created_at
FROM ai_conversations
ORDER BY created_at DESC
LIMIT 10;

-- 验证对话完整性
SELECT role, content
FROM ai_conversations
WHERE user_id = 1
ORDER BY created_at DESC
LIMIT 6;
```

**预期结果：**
- ✅ 每次对话有两条记录（user + assistant）
- ✅ 内容完整，无截断
- ✅ 时间戳正确
- ✅ conversation_id 关联正确

## 网络监控

### 使用浏览器开发者工具

1. 打开 Chrome DevTools (F12)
2. 切换到 Network 标签
3. 发送消息
4. 观察 `/api/v1/ai/chat/stream` 请求

**检查项：**
- ✅ Request Method: POST
- ✅ Status Code: 200 OK
- ✅ Content-Type: text/event-stream
- ✅ Transfer-Encoding: chunked
- ✅ X-Accel-Buffering: no
- ✅ EventStream 标签显示实时事件
- ✅ 可以看到 message 和 done 事件

## 回归测试

确保原有功能不受影响：

### 测试非流式 API（兼容性）

```bash
# 测试原有的非流式 API
curl -X POST http://localhost:8080/api/v1/ai/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message":"2+2等于多少？"}'
```

**预期结果：**
- ✅ 仍然正常工作
- ✅ 返回完整的 JSON 响应
- ✅ conversation_id 正确

### 测试其他 AI 功能

- ✅ 拍照识题 (OCR)
- ✅ AI 生成题目
- ✅ AI 批改答案
- ✅ 学习诊断
- ✅ 解题讲解

## 问题排查指南

### 问题 1: 流式输出不显示

**可能原因：**
- OpenAI API key 未配置或无效
- 后端未正确处理流式响应
- 前端 SSE 解析错误

**排查步骤：**
1. 检查 `config/config.yaml` 中的 AI 配置
2. 查看后端日志：`tail -f /tmp/bblearning.log`
3. 检查浏览器控制台是否有错误
4. 使用 curl 测试后端 API

### 问题 2: 光标不显示

**可能原因：**
- CSS 未正确加载
- isStreaming 状态未正确设置

**排查步骤：**
1. 检查浏览器开发者工具的 Elements 标签
2. 查看消息是否有 `streaming-message` class
3. 检查 CSS 文件是否正确导入

### 问题 3: 内存泄漏

**可能原因：**
- SSE 连接未正确关闭
- React state 更新过于频繁

**排查步骤：**
1. 打开 Chrome DevTools Memory 标签
2. 记录 Heap snapshot
3. 发送多条消息
4. 再次记录 snapshot 并比较

### 问题 4: 消息乱序

**可能原因：**
- 并发请求处理不当
- React state 更新时序问题

**排查步骤：**
1. 检查 conversation_id
2. 查看数据库中的时间戳
3. 测试快速连续发送

## 测试完成标准

所有以下测试项通过：
- [ ] 基本流式输出正常
- [ ] 长文本流式输出无问题
- [ ] 连续对话正确
- [ ] UI 动画效果符合预期
- [ ] 错误处理正确
- [ ] 性能表现良好
- [ ] 浏览器兼容性正常
- [ ] 后端 API 响应正确
- [ ] 数据库记录完整
- [ ] 网络请求正常
- [ ] 原有功能不受影响

## 已知限制

1. **SSE 不支持请求进度**：无法显示"已接收 X/Y 字符"
2. **浏览器连接限制**：同一域名最多 6 个 SSE 连接
3. **移动端兼容性**：某些旧版移动浏览器可能不支持 EventSource
4. **代理问题**：某些代理服务器可能缓冲 SSE 响应

## 下一步优化

1. 添加消息重发机制
2. 实现流式输出中断功能（停止按钮）
3. 优化网络断线重连
4. 添加打字音效（可选）
5. 支持 Markdown 实时渲染
6. 添加代码块语法高亮

---

**测试负责人：** Claude Code
**创建日期：** 2025-10-15
**版本：** v1.0
**相关任务：** #2573 实现AI回复SSE流式输出
