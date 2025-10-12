# 数据库迁移说明

本目录包含数据库迁移文件,用于管理数据库结构的版本控制。

## 迁移工具

本项目使用两种方式管理数据库迁移:

### 1. GORM AutoMigrate (推荐用于开发)

后端服务启动时会自动执行 GORM AutoMigrate,根据模型定义自动创建/更新表结构:

```go
// 在 cmd/server/main.go 中
database.AutoMigrate()
```

**优点:**
- 自动根据代码模型生成表结构
- 无需手动编写迁移脚本
- 适合快速开发和原型设计

**缺点:**
- 只能向前迁移,无法回滚
- 可能产生意外的结构变更
- 不适合生产环境

### 2. SQL 迁移文件 (推荐用于生产)

使用 [golang-migrate](https://github.com/golang-migrate/migrate) 工具执行 SQL 迁移文件:

**安装工具:**
```bash
# macOS
brew install golang-migrate

# Linux
curl -L https://github.com/golang-migrate/migrate/releases/download/v4.17.0/migrate.linux-amd64.tar.gz | tar xvz
sudo mv migrate /usr/local/bin/

# 或使用 Go 安装
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
```

**执行迁移:**
```bash
# 向上迁移(应用所有未执行的迁移)
make migrate-up

# 向下迁移(回滚最近一次迁移)
make migrate-down

# 查看迁移状态
migrate -path migrations -database "postgresql://bblearning:bblearning_dev_password@localhost:5432/bblearning_dev?sslmode=disable" version

# 强制设置版本(慎用)
migrate -path migrations -database "postgresql://bblearning:bblearning_dev_password@localhost:5432/bblearning_dev?sslmode=disable" force VERSION
```

## 迁移文件命名规则

迁移文件遵循以下命名规则:

```
{version}_{description}.{direction}.sql
```

例如:
- `000001_init_schema.up.sql` - 初始化表结构(向上迁移)
- `000001_init_schema.down.sql` - 回滚初始化(向下迁移)
- `000002_seed_data.up.sql` - 插入种子数据(向上迁移)
- `000002_seed_data.down.sql` - 删除种子数据(向下迁移)

## 现有迁移文件

### 000001_init_schema

创建所有基础表:
- users - 用户表
- chapters - 章节表
- knowledge_points - 知识点表
- questions - 题目表
- practice_records - 练习记录表
- wrong_questions - 错题表
- learning_progresses - 学习进度表

包含:
- 外键约束
- 索引优化
- 自动更新 updated_at 的触发器

### 000002_seed_data

插入初始测试数据:
- 七年级上学期的章节数据
- 三角形和整式的乘除的知识点
- 示例题目
- 示例用户账号

## 创建新的迁移

### 1. 手动创建

```bash
# 创建新的迁移文件
touch migrations/000003_your_migration_name.up.sql
touch migrations/000003_your_migration_name.down.sql
```

### 2. 使用 migrate 工具创建

```bash
migrate create -ext sql -dir migrations -seq your_migration_name
```

### 3. 编写迁移内容

**向上迁移 (.up.sql):**
```sql
-- 添加新列
ALTER TABLE users ADD COLUMN email VARCHAR(100);

-- 创建新表
CREATE TABLE new_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);
```

**向下迁移 (.down.sql):**
```sql
-- 删除新列
ALTER TABLE users DROP COLUMN email;

-- 删除新表
DROP TABLE new_table;
```

## Docker 环境中的迁移

在 Docker 环境中,迁移会在容器启动时自动执行:

1. PostgreSQL 容器启动时会执行 `scripts/init-db.sql`(基础初始化)
2. 后端容器启动时会执行 GORM AutoMigrate(表结构创建)

如果需要手动执行迁移:

```bash
# 进入后端容器
docker-compose exec backend sh

# 执行迁移
make migrate-up

# 插入种子数据
make seed
```

## 最佳实践

1. **开发环境**: 使用 GORM AutoMigrate 快速迭代
2. **生产环境**: 使用 SQL 迁移文件,便于版本控制和回滚
3. **备份**: 执行迁移前务必备份数据库
4. **测试**: 在测试环境先执行迁移,确认无误后再应用到生产环境
5. **版本控制**: 所有迁移文件都应该提交到版本控制系统
6. **向下兼容**: 尽量保持迁移的向下兼容性
7. **原子性**: 每个迁移文件应该是原子的,要么全部成功,要么全部失败

## 常见问题

### 迁移失败

如果迁移执行失败:

1. 查看错误信息
2. 检查数据库连接
3. 检查 SQL 语法
4. 必要时手动回滚

```bash
# 查看当前版本
migrate -path migrations -database "..." version

# 强制设置到某个版本(慎用)
migrate -path migrations -database "..." force VERSION

# 手动回滚
make migrate-down
```

### 迁移文件冲突

如果多人同时创建迁移文件导致版本号冲突:

1. 重命名冲突的文件,使用新的版本号
2. 更新文件内容
3. 重新执行迁移

### 数据丢失

为避免数据丢失:

1. 执行迁移前备份数据库
2. 先在测试环境验证
3. 谨慎使用 DROP 和 DELETE 语句
4. 保留历史迁移文件

## 参考资源

- [golang-migrate 文档](https://github.com/golang-migrate/migrate)
- [GORM 迁移文档](https://gorm.io/docs/migration.html)
- [PostgreSQL 官方文档](https://www.postgresql.org/docs/)
