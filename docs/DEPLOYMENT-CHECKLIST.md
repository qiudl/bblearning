# BBLearning 生产部署检查清单

本文档提供BBLearning项目上线前的完整检查清单，确保安全、稳定地部署到生产环境。

---

## 使用说明

- ✅ 表示已完成
- ⏳ 表示进行中
- ❌ 表示未完成
- ⚠️ 表示需要注意

**建议**: 逐项检查，确保每一项都标记为✅后再进行部署。

---

## 一、部署前准备

### 1.1 代码准备

- [ ] 所有功能开发完成
- [ ] 代码已合并到main/master分支
- [ ] 所有单元测试通过
- [ ] 集成测试通过
- [ ] 代码Review完成
- [ ] 版本号已更新（package.json, go.mod）
- [ ] CHANGELOG.md已更新
- [ ] 敏感信息已移除（API keys, passwords）

### 1.2 测试验证

- [ ] 本地环境测试通过
- [ ] Docker环境测试通过
- [ ] 集成测试全部通过（37/37）
- [ ] 性能测试达标
  - [ ] 首屏加载 < 2s
  - [ ] API响应 < 500ms
  - [ ] 登录QPS > 500
- [ ] 安全测试通过
  - [ ] SQL注入测试
  - [ ] XSS测试
  - [ ] CSRF保护
  - [ ] 敏感数据加密
- [ ] 兼容性测试
  - [ ] Chrome (最新版)
  - [ ] Safari (最新版)
  - [ ] Firefox (最新版)
  - [ ] 移动端浏览器

### 1.3 文档准备

- [ ] README.md完整
- [ ] CLAUDE.md更新
- [ ] DEPLOYMENT.md准备就绪
- [ ] API文档完整
- [ ] 用户手册（如需要）
- [ ] 运维手册

---

## 二、服务器准备

### 2.1 服务器资源

- [ ] 服务器已购买/租用
  - **配置**: ≥ 4核 8GB RAM 50GB SSD
  - **操作系统**: Ubuntu 22.04 LTS
  - **网络**: 带宽 ≥ 10Mbps
- [ ] SSH访问已配置
  - [ ] 公钥认证设置
  - [ ] 禁用密码登录
  - [ ] 端口非默认22
- [ ] 防火墙已配置
  - [ ] 允许SSH (自定义端口)
  - [ ] 允许HTTP (80)
  - [ ] 允许HTTPS (443)
  - [ ] 其他端口已关闭

### 2.2 域名和DNS

- [ ] 域名已注册
  - **主域名**: _______________
  - **API域名**: api._______________
- [ ] DNS记录已配置
  - [ ] A记录指向服务器IP
  - [ ] API子域名A记录
  - [ ] TTL设置合理（如300秒）
- [ ] DNS解析已生效（ping测试）

### 2.3 SSL证书

- [ ] Let's Encrypt证书已申请
  - [ ] 主域名证书
  - [ ] API域名证书
- [ ] 证书自动续期已配置
- [ ] HTTPS强制重定向已设置

---

## 三、软件环境

### 3.1 系统更新

```bash
- [ ] sudo apt update
- [ ] sudo apt upgrade -y
- [ ] sudo reboot (如需要)
```

### 3.2 Docker安装

```bash
- [ ] Docker已安装 (版本 ≥ 24.0)
- [ ] Docker Compose已安装 (版本 ≥ 2.20)
- [ ] 当前用户加入docker组
- [ ] Docker服务运行正常
```

### 3.3 Nginx安装

```bash
- [ ] Nginx已安装
- [ ] Nginx配置文件已准备
- [ ] Nginx配置测试通过 (nginx -t)
- [ ] Nginx服务运行正常
```

### 3.4 其他工具

```bash
- [ ] Git已安装
- [ ] certbot已安装（SSL证书）
- [ ] vim/nano已安装（文本编辑）
- [ ] htop/监控工具已安装
```

---

## 四、数据库准备

### 4.1 PostgreSQL

- [ ] PostgreSQL容器已配置
- [ ] 数据库已创建
  - **数据库名**: bblearning_production
  - **用户名**: bblearning_prod
  - **密码**: [强密码，至少16字符]
- [ ] 数据库连接测试通过
- [ ] 数据库迁移已准备
  - [ ] 所有migration文件已检查
  - [ ] 备份策略已设置
- [ ] 性能参数已优化
  - [ ] shared_buffers
  - [ ] max_connections
  - [ ] work_mem

### 4.2 Redis

- [ ] Redis容器已配置
- [ ] Redis密码已设置
- [ ] Redis持久化已启用
- [ ] Redis内存限制已配置
- [ ] Redis连接测试通过

### 4.3 备份策略

- [ ] 数据库自动备份脚本已部署
  - **频率**: 每天凌晨2点
  - **保留**: 最近7天
- [ ] 备份存储位置已配置
- [ ] 备份恢复流程已测试

---

## 五、应用配置

### 5.1 后端配置

**环境变量文件**: `backend/.env.production`

```ini
- [ ] APP_ENV=production
- [ ] APP_DEBUG=false
- [ ] SERVER_PORT=8080
- [ ] SERVER_HOST=0.0.0.0

# 数据库
- [ ] DB_HOST=postgres
- [ ] DB_PORT=5432
- [ ] DB_USER=bblearning_prod
- [ ] DB_PASSWORD=[强密码]
- [ ] DB_NAME=bblearning_production
- [ ] DB_SSLMODE=require

# Redis
- [ ] REDIS_HOST=redis
- [ ] REDIS_PORT=6379
- [ ] REDIS_PASSWORD=[强密码]

# JWT
- [ ] JWT_SECRET=[64位随机字符串]
- [ ] JWT_ACCESS_EXPIRE=3600
- [ ] JWT_REFRESH_EXPIRE=604800

# AI服务
- [ ] OPENAI_API_KEY=[生产环境key]
- [ ] OPENAI_MODEL=gpt-4o-mini
- [ ] OPENAI_MAX_TOKENS=2000

# CORS
- [ ] CORS_ALLOWED_ORIGINS=https://yourdomain.com

# 日志
- [ ] LOG_LEVEL=warn
- [ ] LOG_FILE_PATH=/var/log/bblearning/
```

⚠️ **安全检查**:
- [ ] 所有密码都是强密码（≥16字符，包含大小写、数字、特殊字符）
- [ ] JWT_SECRET使用随机生成的64字符串
- [ ] 敏感信息未提交到Git
- [ ] 生产环境API key不同于开发环境

### 5.2 前端配置

**环境变量文件**: `frontend/.env.production`

```ini
- [ ] REACT_APP_API_URL=https://api.yourdomain.com/api/v1
```

**构建验证**:
```bash
- [ ] npm run build 成功
- [ ] 构建产物大小合理 (< 500KB gzipped)
- [ ] 无ESLint错误
- [ ] 无TypeScript错误
```

### 5.3 Docker Compose生产配置

**文件**: `docker-compose.prod.yml`

- [ ] 所有服务使用生产配置
- [ ] 数据卷持久化配置
- [ ] 网络隔离配置
- [ ] 资源限制已设置
  - [ ] CPU限制
  - [ ] 内存限制
- [ ] 健康检查已配置
- [ ] 重启策略设置为always

---

## 六、Nginx配置

### 6.1 主站点配置

**文件**: `/etc/nginx/sites-available/bblearning`

- [ ] HTTP到HTTPS重定向
- [ ] SSL证书路径正确
- [ ] SSL安全参数已配置
- [ ] Gzip压缩已启用
- [ ] 静态资源缓存已配置
- [ ] 安全头已添加
  - [ ] X-Frame-Options
  - [ ] X-Content-Type-Options
  - [ ] X-XSS-Protection
  - [ ] Strict-Transport-Security

### 6.2 API配置

- [ ] 反向代理到后端容器
- [ ] WebSocket支持（如需要）
- [ ] 超时时间合理设置
- [ ] 速率限制已配置
- [ ] CORS头配置正确

### 6.3 Nginx测试

```bash
- [ ] sudo nginx -t (配置测试)
- [ ] curl http://localhost (本地测试)
- [ ] 从外网访问测试
- [ ] HTTPS测试
- [ ] SSL等级测试 (ssllabs.com)
```

---

## 七、部署执行

### 7.1 代码部署

```bash
- [ ] 代码已上传/克隆到服务器
- [ ] 分支已切换到main/master
- [ ] 最新代码已拉取 (git pull)
- [ ] 子模块已更新 (如有)
```

### 7.2 环境变量设置

```bash
- [ ] backend/.env.production已创建
- [ ] 环境变量值已填写
- [ ] 敏感信息权限已设置 (chmod 600)
- [ ] 环境变量已验证 (printenv)
```

### 7.3 Docker镜像构建

```bash
- [ ] docker-compose -f docker-compose.prod.yml build
- [ ] 构建日志无错误
- [ ] 镜像大小合理
```

### 7.4 数据库初始化

```bash
- [ ] 数据库容器已启动
- [ ] 数据库迁移已执行
- [ ] 种子数据已插入（如需要）
- [ ] 数据完整性已验证
```

### 7.5 服务启动

```bash
- [ ] docker-compose -f docker-compose.prod.yml up -d
- [ ] 所有容器状态healthy
- [ ] 日志无ERROR
- [ ] 端口监听正常
```

---

## 八、部署后验证

### 8.1 服务可用性

- [ ] 前端页面可访问 (https://yourdomain.com)
- [ ] 后端API可访问 (https://api.yourdomain.com/health)
- [ ] API文档可访问（如有）
- [ ] 所有主要页面可访问
  - [ ] 登录页
  - [ ] 注册页
  - [ ] 学习页
  - [ ] 练习页

### 8.2 功能测试

- [ ] 用户注册功能正常
- [ ] 用户登录功能正常
- [ ] Token刷新正常
- [ ] 知识点加载正常
- [ ] 练习功能正常
- [ ] AI对话功能正常（如启用）
- [ ] 错题本功能正常
- [ ] 学习报告正常

### 8.3 性能验证

```bash
- [ ] 首屏加载时间 < 2s
- [ ] API平均响应时间 < 500ms
- [ ] 并发测试 (100用户) 通过
- [ ] 数据库查询性能正常
- [ ] Redis缓存命中率 > 80%
```

### 8.4 安全验证

- [ ] HTTPS正常工作
- [ ] HTTP自动重定向到HTTPS
- [ ] SSL证书有效
- [ ] 安全头正确设置
- [ ] CORS策略正确
- [ ] 敏感端点需要认证
- [ ] SQL注入测试通过
- [ ] XSS测试通过

### 8.5 日志检查

```bash
- [ ] Nginx access.log正常
- [ ] Nginx error.log无严重错误
- [ ] 后端日志正常
- [ ] 数据库日志正常
- [ ] Docker容器日志正常
```

---

## 九、监控和告警

### 9.1 服务监控

- [ ] 服务器CPU/内存/磁盘监控
- [ ] Docker容器监控
- [ ] 应用进程监控
- [ ] 数据库连接数监控
- [ ] Redis内存使用监控

### 9.2 应用监控

- [ ] API响应时间监控
- [ ] 错误率监控
- [ ] QPS监控
- [ ] 用户活跃度监控

### 9.3 告警配置

- [ ] 服务down告警
- [ ] CPU使用率 > 80%告警
- [ ] 内存使用率 > 90%告警
- [ ] 磁盘使用率 > 85%告警
- [ ] API错误率 > 5%告警
- [ ] 数据库连接数 > 80%告警
- [ ] 告警通知渠道已配置
  - [ ] 邮件
  - [ ] 短信
  - [ ] Slack/钉钉（可选）

---

## 十、备份和恢复

### 10.1 备份验证

- [ ] 数据库备份脚本运行正常
- [ ] 备份文件生成成功
- [ ] 备份文件完整性验证
- [ ] 备份文件可恢复
- [ ] 自动备份定时任务已设置

### 10.2 恢复演练

- [ ] 数据库恢复流程已文档化
- [ ] 恢复流程已测试
- [ ] 恢复时间在可接受范围（< 1小时）

---

## 十一、文档和培训

### 11.1 文档完善

- [ ] 部署文档已更新
- [ ] 运维手册已准备
- [ ] 故障排查文档已准备
- [ ] 用户手册已准备（如需要）
- [ ] API文档已发布

### 11.2 团队培训

- [ ] 运维团队已培训
  - [ ] 部署流程
  - [ ] 监控方法
  - [ ] 故障排查
- [ ] 开发团队已知晓
  - [ ] 生产环境访问方式
  - [ ] 日志查看方法
  - [ ] 紧急发布流程

---

## 十二、应急预案

### 12.1 回滚方案

- [ ] 回滚脚本已准备
- [ ] 回滚流程已测试
- [ ] 数据库回滚方案
- [ ] 预计回滚时间 < 5分钟

### 12.2 紧急联系人

- [ ] 项目负责人: _____________ (电话: _________)
- [ ] 技术负责人: _____________ (电话: _________)
- [ ] 运维负责人: _____________ (电话: _________)
- [ ] 紧急联系流程已确定

### 12.3 常见问题预案

- [ ] 服务宕机处理流程
- [ ] 数据库故障处理流程
- [ ] 网络故障处理流程
- [ ] 性能问题处理流程
- [ ] 安全事件处理流程

---

## 十三、发布流程

### 13.1 发布前

- [ ] 发布通知已发送（提前24小时）
- [ ] 维护窗口已确定
- [ ] 相关方已确认
- [ ] 备份已完成
- [ ] 回滚方案已确认

### 13.2 发布中

- [ ] 服务状态监控
- [ ] 实时日志监控
- [ ] 错误率监控
- [ ] 性能指标监控

### 13.3 发布后

- [ ] 发布总结文档
- [ ] 问题记录和解决
- [ ] 经验教训总结
- [ ] 流程改进建议

---

## 十四、最终确认

### 14.1 技术负责人确认

- [ ] 所有技术检查项已完成
- [ ] 测试结果符合预期
- [ ] 已知问题已记录
- [ ] 签名: _____________ 日期: _______

### 14.2 项目负责人确认

- [ ] 所有准备工作已就绪
- [ ] 风险已识别和评估
- [ ] 应急方案已准备
- [ ] 批准上线
- [ ] 签名: _____________ 日期: _______

---

## 附录

### A. 快速命令参考

```bash
# 查看容器状态
docker-compose -f docker-compose.prod.yml ps

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f [service]

# 重启服务
docker-compose -f docker-compose.prod.yml restart [service]

# 停止所有服务
docker-compose -f docker-compose.prod.yml down

# 启动所有服务
docker-compose -f docker-compose.prod.yml up -d

# 查看资源使用
docker stats

# 备份数据库
docker-compose -f docker-compose.prod.yml exec -T postgres \
  pg_dump -U bblearning_prod bblearning_production > backup.sql

# 恢复数据库
cat backup.sql | docker-compose -f docker-compose.prod.yml exec -T postgres \
  psql -U bblearning_prod bblearning_production

# 查看Nginx配置
sudo nginx -t

# 重载Nginx
sudo systemctl reload nginx

# 查看SSL证书
sudo certbot certificates

# 续期SSL证书
sudo certbot renew
```

### B. 检查清单统计

- **总检查项**: 200+
- **预计检查时间**: 4-6小时
- **建议完成时间**: 部署前1天

### C. 风险等级

| 风险 | 等级 | 影响 | 缓解措施 |
|------|------|------|---------|
| 数据丢失 | 🔴 高 | 业务中断 | 定期备份+恢复测试 |
| 服务宕机 | 🔴 高 | 用户无法访问 | 健康检查+自动重启 |
| 性能下降 | 🟡 中 | 用户体验差 | 性能监控+优化 |
| 安全漏洞 | 🔴 高 | 数据泄露 | 安全扫描+及时更新 |

---

**文档版本**: v1.0
**最后更新**: 2025-10-13
**下次审查**: 部署后1周
