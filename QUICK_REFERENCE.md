# BBLearning 快速参考手册

## 📂 关键文档位置

### iOS开发
| 文档 | 路径 | 说明 |
|------|------|------|
| iOS任务完成报告 | `ios/TASKS_2552-2556_COMPLETION_REPORT.md` | 任务2552-2556详细完成报告 |
| iOS应用代码 | `ios/BBLearningApp/BBLearningApp/` | 所有iOS源代码 |

### 部署相关
| 文档 | 路径 | 说明 |
|------|------|------|
| 完整部署指南 | `DEPLOYMENT_GUIDE.md` | 详细的部署流程文档 |
| 部署命令速查 | `scripts/DEPLOYMENT_COMMANDS.md` | 运维常用命令参考 |
| 部署总结 | `DEPLOYMENT_SUMMARY.md` | 部署基础设施总结 |
| 一键部署脚本 | `scripts/deploy-production.sh` | 自动化部署脚本 |
| 服务器初始化脚本 | `scripts/setup-production-server.sh` | 新服务器配置脚本 |

### 项目总结
| 文档 | 路径 | 说明 |
|------|------|------|
| 项目完成总结 | `PROJECT_COMPLETION_SUMMARY.md` | 本阶段工作总结 |
| 快速参考 | `QUICK_REFERENCE.md` | 本文档 |

---

## 🚀 快速命令

### 部署命令

```bash
# 一键部署到生产环境
./scripts/deploy-production.sh

# 初始化全新服务器（仅首次）
./scripts/setup-production-server.sh
```

### 常用运维命令

```bash
# 查看所有服务状态
docker-compose -f docker-compose.prod.yml ps

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f

# 重启后端服务
docker-compose -f docker-compose.prod.yml restart backend

# 数据库备份
docker exec bblearning-postgres-prod \
    pg_dump -U bblearning bblearning | gzip > backup-$(date +%Y%m%d).sql.gz

# 连接数据库
docker-compose -f docker-compose.prod.yml exec postgres \
    psql -U bblearning -d bblearning
```

详细命令请参考: `scripts/DEPLOYMENT_COMMANDS.md`

---

## 📱 iOS核心功能一览

### 任务2556: 个人中心优化
- **等级系统**: 经验值公式 `100 * level^1.5`
- **设置管理**: 通知、隐私、学习偏好
- **个人资料**: 编辑界面、头像管理

### 任务2554: 错题本增强
- **艾宾浩斯遗忘曲线**: [1, 2, 4, 7, 15] 天复习间隔
- **错误分析**: 概念/计算/粗心/方法四种类型
- **数据可视化**: Swift Charts多维度图表
- **PDF导出**: 专业格式，多页排版

### 任务2552: 练习模块增强
- **智能选题**: 标准/自适应/错题三种模式
- **断点续练**: 自动保存，LRU缓存
- **精确计时**: 会话+题目双重计时，暂停不计时

### 任务2553: AI辅导优化
- **对话系统**: 消息历史，上下文管理
- **解题步骤**: 可视化展示，分步导航

### 任务2555: 学习报告模块
- **报告类型**: 周报/月报/学期报告
- **数据分析**: 进步曲线、知识掌握、错题统计
- **AI建议**: 个性化学习建议

---

## 🏗️ 部署架构

### 服务器信息
- **IP**: 192.144.174.87
- **系统**: Ubuntu 20.04+
- **部署目录**: /opt/bblearning
- **备份目录**: /var/www/bblearning/backups

### 域名
- **前端**: https://bblearning.joylodging.com
- **API**: https://api.bblearning.joylodging.com

### Docker服务
1. **PostgreSQL** (postgres:15-alpine) - 数据库, 1GB内存
2. **Redis** (redis:7-alpine) - 缓存, 512MB内存
3. **MinIO** (minio/minio:latest) - 对象存储, 512MB内存
4. **Backend** (自构建) - Go后端, 2GB内存
5. **Nginx** (nginx:alpine) - 反向代理

### 端口
- HTTP: 80
- HTTPS: 443
- SSH: 22
- Backend: 8080 (内部)
- PostgreSQL: 5432 (内部)
- Redis: 6379 (内部)
- MinIO: 9000/9001 (内部)

---

## 📊 统计数据

### iOS开发
- **任务数**: 5个
- **文件数**: 24个
- **代码行数**: ~5200行
- **工时**: 14小时

### 部署基础设施
- **脚本数**: 2个
- **配置文件**: 3个
- **文档数**: 5个
- **自动化程度**: 10步全自动

---

## ✅ 部署检查清单

### 部署前
- [ ] 复制 `.env.production.example` 为 `.env.production`
- [ ] 填入所有必需的环境变量（密码、密钥等）
- [ ] 确认SSH可以连接到服务器
- [ ] 确认域名DNS已正确解析
- [ ] 准备好OpenAI API密钥

### 部署后
- [ ] 前端页面可访问 (https://bblearning.joylodging.com)
- [ ] API健康检查正常 (https://api.bblearning.joylodging.com/health)
- [ ] SSL证书有效，无浏览器警告
- [ ] 用户注册功能正常
- [ ] 用户登录功能正常
- [ ] 数据库连接正常
- [ ] Redis缓存正常
- [ ] MinIO文件上传正常
- [ ] 自动备份任务已配置 (cron)
- [ ] 防火墙规则正确 (UFW)

---

## 🎯 下一步行动

### 立即执行
1. 配置 `.env.production` 文件
2. 运行 `./scripts/deploy-production.sh`
3. 验证所有检查清单项目

### 短期计划
1. iOS真实API集成
2. 单元测试编写
3. 性能测试与优化
4. 用户体验优化

### 中期计划
1. CI/CD流程配置
2. 监控告警系统
3. 数据分析仪表板
4. 家长端应用

---

## 📞 技术支持

### 相关文档
- [iOS开发报告](ios/TASKS_2552-2556_COMPLETION_REPORT.md)
- [部署指南](DEPLOYMENT_GUIDE.md)
- [运维命令](scripts/DEPLOYMENT_COMMANDS.md)
- [项目总结](PROJECT_COMPLETION_SUMMARY.md)

### 故障排查
详见 `DEPLOYMENT_GUIDE.md` 的故障排查章节

---

**最后更新**: 2025-10-15  
**版本**: 1.0.0  
**状态**: ✅ 完成
