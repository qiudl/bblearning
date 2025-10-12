# API接口规范文档

## 1. 基础信息

### 1.1 接口域名
- 开发环境: `http://localhost:8080`
- 生产环境: `https://api.bblearning.com`

### 1.2 通用规范

#### 请求头
```
Content-Type: application/json
Authorization: Bearer {access_token}
X-Request-ID: {uuid} // 可选，用于追踪
```

#### 响应格式
```json
{
  "code": 0,           // 0: 成功, 非0: 错误码
  "message": "success", // 响应消息
  "data": {},          // 响应数据
  "request_id": ""     // 请求ID
}
```

#### 错误码
```
0     - 成功
1000  - 参数错误
1001  - 未授权
1002  - Token过期
1003  - 权限不足
2000  - 资源不存在
3000  - 服务器内部错误
4000  - 第三方服务错误
```

## 2. 认证接口

### 2.1 用户注册
```
POST /api/v1/auth/register
```

**请求参数**
```json
{
  "username": "student01",
  "password": "password123",
  "email": "student01@example.com",
  "grade": 7
}
```

**响应**
```json
{
  "code": 0,
  "message": "注册成功",
  "data": {
    "user": {
      "id": "uuid",
      "username": "student01",
      "email": "student01@example.com",
      "grade": 7,
      "created_at": "2024-01-01T00:00:00Z"
    },
    "tokens": {
      "access_token": "eyJhbGc...",
      "refresh_token": "eyJhbGc...",
      "expires_in": 3600
    }
  }
}
```

### 2.2 用户登录
```
POST /api/v1/auth/login
```

**请求参数**
```json
{
  "username": "student01",
  "password": "password123"
}
```

**响应**
```json
{
  "code": 0,
  "message": "登录成功",
  "data": {
    "user": {
      "id": "uuid",
      "username": "student01",
      "grade": 7
    },
    "tokens": {
      "access_token": "eyJhbGc...",
      "refresh_token": "eyJhbGc...",
      "expires_in": 3600
    }
  }
}
```

### 2.3 刷新Token
```
POST /api/v1/auth/refresh
```

**请求参数**
```json
{
  "refresh_token": "eyJhbGc..."
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJhbGc...",
    "refresh_token": "eyJhbGc...",
    "expires_in": 3600
  }
}
```

### 2.4 登出
```
POST /api/v1/auth/logout
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "code": 0,
  "message": "登出成功"
}
```

## 3. 知识点接口

### 3.1 获取知识点树
```
GET /api/v1/knowledge/tree?grade=7
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "nodes": [
      {
        "id": "uuid",
        "code": "7-1",
        "name": "有理数",
        "grade": 7,
        "parent_id": null,
        "description": "有理数的概念和运算",
        "order_index": 1,
        "children": [
          {
            "id": "uuid",
            "code": "7-1-1",
            "name": "正数和负数",
            "grade": 7,
            "parent_id": "uuid",
            "order_index": 1,
            "children": []
          }
        ]
      }
    ]
  }
}
```

### 3.2 获取知识点详情
```
GET /api/v1/knowledge/:id
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "knowledge_point": {
      "id": "uuid",
      "code": "7-1-1",
      "name": "正数和负数",
      "description": "详细描述...",
      "content": {
        "definition": "正数和负数的定义",
        "examples": ["例题1", "例题2"],
        "key_points": ["重点1", "重点2"],
        "common_mistakes": ["易错点1"]
      },
      "difficulty": 1,
      "prerequisite_ids": [],
      "related_ids": []
    },
    "learning_progress": {
      "user_id": "uuid",
      "status": "learning", // not_started, learning, mastered
      "mastery_level": 0.6,
      "last_learned_at": "2024-01-01T00:00:00Z"
    }
  }
}
```

### 3.3 更新学习进度
```
PUT /api/v1/knowledge/:id/progress
Authorization: Bearer {access_token}
```

**请求参数**
```json
{
  "status": "learning",
  "mastery_level": 0.6
}
```

**响应**
```json
{
  "code": 0,
  "message": "更新成功"
}
```

## 4. 练习接口

### 4.1 生成练习题
```
POST /api/v1/practice/generate
Authorization: Bearer {access_token}
```

**请求参数**
```json
{
  "knowledge_point_ids": ["uuid1", "uuid2"],
  "difficulty": 3,
  "question_count": 10,
  "question_types": ["choice", "blank", "solve"]
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "practice_id": "uuid",
    "questions": [
      {
        "id": "uuid",
        "type": "choice",
        "difficulty": 3,
        "content": {
          "question": "计算: $2 + 3 = ?$",
          "options": ["3", "4", "5", "6"],
          "images": []
        },
        "knowledge_point_ids": ["uuid1"]
      }
    ]
  }
}
```

### 4.2 提交答案
```
POST /api/v1/practice/submit
Authorization: Bearer {access_token}
```

**请求参数**
```json
{
  "practice_id": "uuid",
  "answers": [
    {
      "question_id": "uuid",
      "answer": "5",
      "time_spent": 30,
      "solution_steps": [
        {
          "step": 1,
          "content": "解题步骤1",
          "image": ""
        }
      ]
    }
  ]
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "results": [
      {
        "question_id": "uuid",
        "is_correct": true,
        "score": 10,
        "standard_answer": "5",
        "user_answer": "5",
        "ai_feedback": {
          "correctness": "完全正确",
          "analysis": "解题思路清晰",
          "suggestions": []
        },
        "solution": {
          "steps": ["步骤1", "步骤2"],
          "explanation": "详细解释"
        }
      }
    ],
    "summary": {
      "total_questions": 10,
      "correct_count": 8,
      "score": 85,
      "time_spent": 300
    }
  }
}
```

### 4.3 获取练习历史
```
GET /api/v1/practice/history?page=1&size=20
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "records": [
      {
        "id": "uuid",
        "practice_id": "uuid",
        "knowledge_points": ["有理数", "绝对值"],
        "question_count": 10,
        "correct_count": 8,
        "score": 85,
        "time_spent": 300,
        "created_at": "2024-01-01T00:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "total": 50
    }
  }
}
```

### 4.4 获取错题本
```
GET /api/v1/practice/wrong-questions?knowledge_point_id=uuid&page=1&size=20
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "questions": [
      {
        "id": "uuid",
        "question": {
          "type": "solve",
          "difficulty": 3,
          "content": {
            "question": "题目内容"
          }
        },
        "wrong_count": 3,
        "last_wrong_at": "2024-01-01T00:00:00Z",
        "is_resolved": false,
        "user_notes": "这题总是算错"
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "total": 15
    }
  }
}
```

### 4.5 标记错题已解决
```
PUT /api/v1/practice/wrong-questions/:id/resolve
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "code": 0,
  "message": "标记成功"
}
```

## 5. AI服务接口

### 5.1 AI生成题目
```
POST /api/v1/ai/generate-question
Authorization: Bearer {access_token}
```

**请求参数**
```json
{
  "knowledge_point_id": "uuid",
  "difficulty": 3,
  "question_type": "solve",
  "requirements": "需要涉及实际应用场景"
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "question": {
      "id": "uuid",
      "type": "solve",
      "difficulty": 3,
      "content": {
        "question": "AI生成的题目",
        "images": []
      },
      "answer": {
        "content": "标准答案"
      },
      "solution": {
        "steps": ["步骤1", "步骤2"],
        "explanation": "详细解释"
      },
      "difficulty_analysis": "难点分析",
      "knowledge_points": ["知识点1", "知识点2"]
    }
  }
}
```

### 5.2 AI批改
```
POST /api/v1/ai/grade
Authorization: Bearer {access_token}
```

**请求参数**
```json
{
  "question_id": "uuid",
  "user_answer": {
    "content": "用户答案",
    "solution_steps": []
  }
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "result": {
      "is_correct": true,
      "score": 95,
      "analysis": {
        "correctness": "答案正确",
        "process": "解题过程完整",
        "errors": [],
        "suggestions": ["建议使用更简洁的方法"]
      },
      "detailed_feedback": "详细的反馈内容"
    }
  }
}
```

### 5.3 学习诊断
```
GET /api/v1/ai/diagnose
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "report": {
      "generated_at": "2024-01-01T00:00:00Z",
      "weak_points": [
        {
          "knowledge_point": "有理数的乘法",
          "mastery_level": 0.4,
          "error_rate": 0.6,
          "common_errors": ["符号判断错误", "运算顺序错误"]
        }
      ],
      "analysis": "整体分析内容",
      "suggestions": [
        "建议加强有理数乘法的练习",
        "重点关注符号问题"
      ],
      "recommended_practice": [
        {
          "knowledge_point_id": "uuid",
          "priority": "high",
          "question_count": 20
        }
      ]
    },
    "statistics": {
      "total_questions": 100,
      "correct_rate": 0.75,
      "avg_time_per_question": 45,
      "mastered_knowledge_points": 15,
      "learning_knowledge_points": 8,
      "not_started_knowledge_points": 5
    }
  }
}
```

### 5.4 获取学习推荐
```
GET /api/v1/ai/recommend
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "learning_path": {
      "current_level": "初级",
      "target_level": "中级",
      "recommended_sequence": [
        {
          "knowledge_point_id": "uuid",
          "knowledge_point_name": "有理数的加法",
          "priority": 1,
          "reason": "基础知识，需要先掌握",
          "estimated_time": "2小时"
        }
      ]
    },
    "daily_practice": {
      "date": "2024-01-01",
      "questions": [
        {
          "knowledge_point_id": "uuid",
          "difficulty": 2,
          "count": 5
        }
      ],
      "estimated_time": "30分钟"
    }
  }
}
```

## 6. 统计分析接口

### 6.1 获取学习统计
```
GET /api/v1/statistics/learning?start_date=2024-01-01&end_date=2024-01-31
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "daily_stats": [
      {
        "date": "2024-01-01",
        "study_time": 60,
        "questions_completed": 20,
        "correct_rate": 0.85,
        "knowledge_points_learned": 3
      }
    ],
    "summary": {
      "total_study_time": 1800,
      "total_questions": 500,
      "avg_correct_rate": 0.82,
      "mastered_knowledge_points": 15
    }
  }
}
```

### 6.2 获取知识点掌握情况
```
GET /api/v1/statistics/knowledge-mastery?grade=7
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "knowledge_points": [
      {
        "id": "uuid",
        "name": "有理数",
        "status": "mastered",
        "mastery_level": 0.9,
        "practice_count": 50,
        "correct_rate": 0.92,
        "last_practiced_at": "2024-01-01T00:00:00Z"
      }
    ],
    "overall": {
      "total_points": 30,
      "mastered": 15,
      "learning": 10,
      "not_started": 5,
      "avg_mastery_level": 0.65
    }
  }
}
```

### 6.3 获取进步曲线
```
GET /api/v1/statistics/progress?days=30
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "progress_curve": [
      {
        "date": "2024-01-01",
        "correct_rate": 0.75,
        "avg_difficulty": 2.5,
        "mastery_level": 0.6
      }
    ],
    "trend": {
      "direction": "up",
      "change_rate": 0.15,
      "prediction": "预计一周后正确率可达90%"
    }
  }
}
```

## 7. 用户个人中心

### 7.1 获取用户信息
```
GET /api/v1/user/profile
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "user": {
      "id": "uuid",
      "username": "student01",
      "email": "student01@example.com",
      "grade": 7,
      "avatar_url": "https://...",
      "created_at": "2024-01-01T00:00:00Z",
      "stats": {
        "total_study_time": 3600,
        "total_questions": 500,
        "correct_rate": 0.85,
        "rank": 10,
        "achievements": ["新手上路", "题海高手"]
      }
    }
  }
}
```

### 7.2 更新用户信息
```
PUT /api/v1/user/profile
Authorization: Bearer {access_token}
```

**请求参数**
```json
{
  "email": "newemail@example.com",
  "grade": 8,
  "avatar_url": "https://..."
}
```

**响应**
```json
{
  "code": 0,
  "message": "更新成功",
  "data": {
    "user": {
      "id": "uuid",
      "username": "student01",
      "email": "newemail@example.com",
      "grade": 8
    }
  }
}
```

### 7.3 修改密码
```
POST /api/v1/user/change-password
Authorization: Bearer {access_token}
```

**请求参数**
```json
{
  "old_password": "oldpass123",
  "new_password": "newpass456"
}
```

**响应**
```json
{
  "code": 0,
  "message": "密码修改成功"
}
```

## 8. 数据同步接口（iOS App专用）

### 8.1 获取增量更新
```
GET /api/v1/sync/delta?last_sync_time=2024-01-01T00:00:00Z
Authorization: Bearer {access_token}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "sync_time": "2024-01-01T12:00:00Z",
    "updates": {
      "knowledge_points": [],
      "practice_records": [],
      "learning_progress": []
    },
    "deletions": {
      "practice_record_ids": []
    }
  }
}
```

### 8.2 批量上传离线数据
```
POST /api/v1/sync/upload
Authorization: Bearer {access_token}
```

**请求参数**
```json
{
  "practice_records": [
    {
      "temp_id": "local_uuid",
      "question_id": "uuid",
      "user_answer": {},
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "learning_progress": []
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "success_count": 10,
    "failed_items": [],
    "id_mapping": {
      "local_uuid": "server_uuid"
    }
  }
}
```

## 9. 文件上传接口

### 9.1 上传图片
```
POST /api/v1/upload/image
Authorization: Bearer {access_token}
Content-Type: multipart/form-data
```

**请求参数**
```
file: [binary]
type: question_image | avatar | solution_image
```

**响应**
```json
{
  "code": 0,
  "data": {
    "url": "https://cdn.bblearning.com/images/xxx.jpg",
    "thumbnail_url": "https://cdn.bblearning.com/images/xxx_thumb.jpg",
    "size": 102400,
    "mime_type": "image/jpeg"
  }
}
```

## 10. WebSocket接口（实时功能）

### 10.1 连接
```
ws://localhost:8080/ws?token={access_token}
```

### 10.2 消息格式

**心跳**
```json
{
  "type": "ping",
  "timestamp": 1234567890
}
```

**学习状态更新**
```json
{
  "type": "learning_status",
  "data": {
    "status": "practicing",
    "current_question_id": "uuid"
  }
}
```

**AI批改实时反馈**
```json
{
  "type": "ai_grading",
  "data": {
    "question_id": "uuid",
    "progress": 50,
    "status": "processing"
  }
}
```

## 11. 错误处理示例

### 11.1 参数错误
```json
{
  "code": 1000,
  "message": "参数错误",
  "data": {
    "errors": [
      {
        "field": "username",
        "message": "用户名不能为空"
      }
    ]
  }
}
```

### 11.2 未授权
```json
{
  "code": 1001,
  "message": "未授权，请先登录"
}
```

### 11.3 Token过期
```json
{
  "code": 1002,
  "message": "Token已过期，请刷新Token"
}
```

### 11.4 服务器错误
```json
{
  "code": 3000,
  "message": "服务器内部错误",
  "data": {
    "request_id": "uuid",
    "timestamp": 1234567890
  }
}
```

## 12. 接口性能要求

| 接口类型 | 响应时间要求 | 并发要求 |
|---------|-------------|---------|
| 认证接口 | < 500ms | 100 QPS |
| 查询接口 | < 300ms | 500 QPS |
| 提交接口 | < 1000ms | 200 QPS |
| AI接口 | < 5000ms | 50 QPS |
| 文件上传 | < 3000ms | 100 QPS |

## 13. 接口版本管理

所有接口都包含版本号 `/api/v1/`，当需要重大变更时，会发布新版本如 `/api/v2/`，旧版本会保持兼容至少6个月。

## 14. 接口限流

- 普通用户: 每分钟最多100次请求
- AI接口: 每小时最多50次请求
- 文件上传: 每天最多100个文件

超过限流会返回 HTTP 429 Too Many Requests。
