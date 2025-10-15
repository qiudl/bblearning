# BBLearning 后台管理系统MVP - Git Worktree 多AI并行开发指南

## 📋 项目概述

**任务**: #2576 - 后台管理系统MVP - AI驱动的内容管理方案设计
**子任务数量**: 8个
**预估总工时**: 66小时（AI效率）
**开发阶段**: 3个阶段（串行+并行）

## 🌳 Worktree 架构设计

### 目录结构
```
/Users/johnqiu/coding/www/projects/
├── bblearning/                          # 主仓库 (develop分支)
│   ├── .worktree-config.json           # Worktree配置文件
│   ├── bblearning-admin-ai-config.json # AI专家配置文件
│   └── ADMIN_MVP_WORKTREE_GUIDE.md     # 本指南
└── bblearning-worktrees/                # Worktree根目录
    ├── db-migration/                    # Phase 1: 数据库迁移
    ├── knowledge-question-api/          # Phase 2: 知识点+题目API
    ├── user-ai-api/                     # Phase 2: 用户+AI API
    ├── knowledge-question-admin/        # Phase 3: 知识点+题目前端
    └── user-admin/                      # Phase 3: 用户管理前端
```

### 分支策略
```
develop (主开发分支)
  └── feature/admin-system-mvp (MVP特性集成分支)
       ├── db/admin-tables (数据库)
       ├── backend/knowledge-question-api (知识点+题目API)
       ├── backend/user-ai-api (用户+AI API)
       ├── frontend/knowledge-question-admin (知识点+题目前端)
       └── frontend/user-admin (用户前端)
```

## 🚀 快速开始

### 第一步: 初始化 Worktree 环境

```bash
# 进入项目目录
cd /Users/johnqiu/coding/www/projects/bblearning

# 初始化 worktree 配置
wt init

# 检查配置
cat .worktree-config.json
```

### 第二步: 创建所有 Worktree

```bash
# 创建所有 worktree（根据配置文件）
wt-all

# 验证创建结果
wt list
wt status
```

### 第三步: 启动分阶段开发

#### Phase 1: 数据库设计（串行，必须先完成）

```bash
# 启动数据库专家
multi-ai bblearning-admin-ai-config.json --phase 1

# 或者手动切换到 worktree
wt-cd db-migration
claude

# 完成后验证迁移脚本
cd backend
make migrate-up
make seed
```

#### Phase 2: 后端API开发（并行）

等待 Phase 1 完成后：

```bash
# 启动所有后端API专家（并行）
multi-ai bblearning-admin-ai-config.json --phase 2

# 手动方式：分别打开两个终端
# 终端1: 知识点+题目API
wt-cd knowledge-question-api
claude

# 终端2: 用户+AI API
wt-cd user-ai-api
claude
```

#### Phase 3: 前端界面开发（并行）

等待 Phase 2 完成后：

```bash
# 启动所有前端专家（并行）
multi-ai bblearning-admin-ai-config.json --phase 3

# 手动方式：分别打开两个终端
# 终端1: 知识点+题目前端
wt-cd knowledge-question-admin
claude

# 终端2: 用户管理前端
wt-cd user-admin
claude
```

## 📊 任务分配与依赖关系

### Phase 1: 基础设施（4小时）

| Worktree | AI专家 | 任务ID | 描述 | 依赖 |
|----------|--------|--------|------|------|
| db-migration | 🗄️ 数据库架构专家 | #2577 | 管理员表、日志表、权限表 | 无 |

**交付物**:
- `backend/migrations/XXX_create_admin_tables.up.sql`
- `backend/migrations/XXX_create_admin_tables.down.sql`
- `backend/scripts/seed_admin_data.sql`

### Phase 2: 后端API开发（34小时，并行）

| Worktree | AI专家 | 任务ID | 描述 | 依赖 |
|----------|--------|--------|------|------|
| knowledge-question-api | 🔧 后端API专家1 | #2578, #2579 | 知识点+题目管理API | Phase 1 |
| user-ai-api | 🔧 后端API专家2 | #2580, #2584 | 用户管理+AI集成 | Phase 1 |

**交付物**:
- 知识点CRUD API (`knowledge_handler.go`, `knowledge_admin_service.go`)
- 题目CRUD API (`question_handler.go`, `question_admin_service.go`)
- 用户管理API (`user_handler.go`, `user_admin_service.go`)
- AI集成API (`ai_handler.go`, `ai_admin_service.go`)
- 权限中间件 (`admin_auth.go`, `rbac.go`)

### Phase 3: 前端界面开发（28小时，并行）

| Worktree | AI专家 | 任务ID | 描述 | 依赖 |
|----------|--------|--------|------|------|
| knowledge-question-admin | 🎨 前端专家1 | #2581, #2582 | 知识点+题目管理界面 | #2578, #2579 |
| user-admin | 🎨 前端专家2 | #2583 | 用户管理界面 | #2580 |

**交付物**:
- 知识点管理页面 (`KnowledgeManage.tsx`, `KnowledgeTree.tsx`)
- 题目管理页面 (`QuestionManage.tsx`, `QuestionEditor.tsx`)
- AI题目生成 (`AIQuestionGenerator.tsx`)
- 用户管理页面 (`UserManage.tsx`, `UserDetail.tsx`)
- 数据可视化 (`UserStatistics.tsx`)

## 🔄 工作流程

### 1. 开发流程

```bash
# 每个 AI 专家的工作流程
1. 切换到对应 worktree: wt-cd <worktree-id>
2. 拉取最新代码: git pull origin develop
3. 开始开发任务
4. 提交代码: git add . && git commit -m "feat: ..."
5. 推送到远程: git push origin <branch-name>
6. 创建 Pull Request 到 feature/admin-system-mvp
```

### 2. 代码合并策略

```bash
# Phase 1 完成后
1. db/admin-tables → feature/admin-system-mvp
2. 合并后，Phase 2 的 worktree 从 feature/admin-system-mvp 拉取最新代码

# Phase 2 完成后
1. backend/knowledge-question-api → feature/admin-system-mvp
2. backend/user-ai-api → feature/admin-system-mvp
3. 合并后，Phase 3 的 worktree 从 feature/admin-system-mvp 拉取最新代码

# Phase 3 完成后
1. frontend/knowledge-question-admin → feature/admin-system-mvp
2. frontend/user-admin → feature/admin-system-mvp
3. feature/admin-system-mvp → develop
4. develop → main (经过测试后)
```

### 3. 同步策略

```bash
# 在每个 worktree 中定期同步
git fetch origin
git rebase origin/feature/admin-system-mvp

# 或使用 worktree 工具
wt sync
```

## 🎯 AI 专家配置

### 专家1: 🗄️ 数据库架构专家
- **任务**: #2577
- **Worktree**: `db-migration`
- **分支**: `db/admin-tables`
- **技能**: PostgreSQL, GORM, 数据库设计, 索引优化

### 专家2: 🔧 后端API专家1 (知识点+题目)
- **任务**: #2578, #2579
- **Worktree**: `knowledge-question-api`
- **分支**: `backend/knowledge-question-api`
- **技能**: Golang, Gin, GORM, RESTful API, LaTeX存储

### 专家3: 🔧 后端API专家2 (用户+AI)
- **任务**: #2580, #2584
- **Worktree**: `user-ai-api`
- **分支**: `backend/user-ai-api`
- **技能**: Golang, RBAC, OpenAI API, Claude API, Prompt工程

### 专家4: 🎨 前端专家1 (知识点+题目)
- **任务**: #2581, #2582
- **Worktree**: `knowledge-question-admin`
- **分支**: `frontend/knowledge-question-admin`
- **技能**: React, TypeScript, Ant Design, 富文本, KaTeX

### 专家5: 🎨 前端专家2 (用户管理)
- **任务**: #2583
- **Worktree**: `user-admin`
- **分支**: `frontend/user-admin`
- **技能**: React, TypeScript, ECharts, 数据可视化

## 📝 常用命令速查

### Worktree 管理
```bash
wt init                    # 初始化配置
wt-all                     # 创建所有 worktree
wt list                    # 列出所有 worktree
wt status                  # 查看所有 worktree 状态
wt-cd <id>                 # 切换到指定 worktree
wt sync                    # 同步所有 worktree
wt cleanup                 # 清理无效 worktree
```

### 多AI启动
```bash
multi-ai bblearning-admin-ai-config.json                # 启动所有专家
multi-ai bblearning-admin-ai-config.json --phase 1      # 只启动 Phase 1
multi-ai bblearning-admin-ai-config.json --phase 2      # 只启动 Phase 2
multi-ai bblearning-admin-ai-config.json --phase 3      # 只启动 Phase 3
```

### Git 操作
```bash
# 在 worktree 中提交
git add .
git commit -m "feat(admin): 实现知识点管理API"
git push origin backend/knowledge-question-api

# 创建 PR
gh pr create --base feature/admin-system-mvp --head backend/knowledge-question-api

# 同步上游更新
git fetch origin
git rebase origin/feature/admin-system-mvp
```

### 后端开发
```bash
# 在 backend/ 目录
make run                   # 运行开发服务器
make test                  # 运行测试
make migrate-up            # 应用数据库迁移
make migrate-down          # 回滚数据库迁移
make seed                  # 插入种子数据
```

### 前端开发
```bash
# 在 frontend/ 目录
npm start                  # 启动开发服务器
npm run build              # 生产构建
npm test                   # 运行测试
npm run lint               # 代码检查
```

## ⚠️ 注意事项

### 1. 依赖管理
- **Phase 2 必须等待 Phase 1 完成**，否则缺少数据库表
- **Phase 3 必须等待 Phase 2 完成**，否则缺少API接口
- 每个阶段开始前，确保依赖的分支已合并到 `feature/admin-system-mvp`

### 2. 冲突处理
- 不同 worktree 修改同一文件时，合并时会冲突
- 建议：
  - 后端专家1负责 `internal/api/admin/knowledge_*` 和 `question_*`
  - 后端专家2负责 `internal/api/admin/user_*` 和 `ai_*`
  - 前端专家1负责 `pages/Admin/Knowledge*` 和 `Question*`
  - 前端专家2负责 `pages/Admin/User*`

### 3. 代码同步
- 每天开始工作前，从 `feature/admin-system-mvp` 拉取最新代码
- 提交前先 rebase，避免合并冲突
- 使用 `wt sync` 批量同步所有 worktree

### 4. 测试要求
- 后端：单元测试覆盖率 > 80%
- 前端：关键组件需要测试
- 每个 PR 必须通过 CI/CD 测试

### 5. 代码审查
- 每个 worktree 的代码独立提交 PR
- PR 标题格式: `feat(admin): <功能描述> (#<任务ID>)`
- 需要至少1人 approve 才能合并

## 📈 进度跟踪

### 使用 ai-proj 任务系统
```bash
# 启动任务并开始计时
mcp__ai-proj__start_task_with_timer --taskIdOrTitle="2577"

# 查看当前任务
mcp__ai-proj__get_current_timer

# 完成任务
mcp__ai-proj__complete_task --id=2577

# 查看所有子任务进度
mcp__ai-proj__get_detailed_task_info --taskId=2576
```

### Git 分支进度
```bash
# 查看所有分支状态
wt status

# 查看已合并的分支
git branch --merged feature/admin-system-mvp

# 查看未合并的分支
git branch --no-merged feature/admin-system-mvp
```

## 🎉 完成检查清单

### Phase 1: 数据库设计
- [ ] 所有表结构设计完成
- [ ] 迁移脚本编写并测试通过
- [ ] 种子数据脚本运行成功
- [ ] 索引和外键约束添加完成
- [ ] 分支合并到 `feature/admin-system-mvp`

### Phase 2: 后端API开发
- [ ] 知识点管理API完成并测试通过
- [ ] 题目管理API完成并测试通过
- [ ] 用户管理API完成并测试通过
- [ ] AI集成API完成并测试通过
- [ ] 权限中间件实现并验证
- [ ] 单元测试覆盖率 > 80%
- [ ] API文档更新完成
- [ ] 所有分支合并到 `feature/admin-system-mvp`

### Phase 3: 前端界面开发
- [ ] 知识点管理页面完成
- [ ] 题目管理页面完成
- [ ] 用户管理页面完成
- [ ] 所有页面联调通过
- [ ] UI/UX走查通过
- [ ] 浏览器兼容性测试通过
- [ ] 所有分支合并到 `feature/admin-system-mvp`

### 最终集成
- [ ] `feature/admin-system-mvp` → `develop`
- [ ] 集成测试通过
- [ ] 性能测试通过
- [ ] 安全测试通过
- [ ] 部署到测试环境
- [ ] UAT测试通过
- [ ] `develop` → `main`
- [ ] 部署到生产环境

## 🔗 相关资源

- **项目文档**: `/Users/johnqiu/coding/www/projects/bblearning/CLAUDE.md`
- **技术架构**: `/Users/johnqiu/coding/www/projects/bblearning/docs/architecture/tech-architecture.md`
- **API规范**: `/Users/johnqiu/coding/www/projects/bblearning/docs/architecture/api-specification.md`
- **Worktree配置**: `.worktree-config.json`
- **AI专家配置**: `bblearning-admin-ai-config.json`
- **任务系统**: http://localhost:8081 (ai-proj 项目 #1)

## 📞 支持

遇到问题？参考以下资源：
- Worktree文档: `~/.claude/docs/WORKTREE_GUIDE.md`
- 多AI系统: `~/.claude/docs/MULTI_AI_SYSTEM.md`
- Git Worktree官方文档: `git worktree --help`

---

**创建时间**: 2025-10-15
**版本**: v1.0
**维护者**: BBLearning Team
