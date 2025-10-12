package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/api/handlers"
	"github.com/qiudl/bblearning-backend/internal/api/middleware"
	"github.com/qiudl/bblearning-backend/internal/pkg/database"
	"github.com/qiudl/bblearning-backend/internal/repository/postgres"
	"github.com/qiudl/bblearning-backend/internal/service/ai"
	"github.com/qiudl/bblearning-backend/internal/service/analytics"
	"github.com/qiudl/bblearning-backend/internal/service/knowledge"
	"github.com/qiudl/bblearning-backend/internal/service/practice"
	"github.com/qiudl/bblearning-backend/internal/service/user"
)

// Setup 设置所有路由
func Setup(r *gin.Engine) {
	// CORS middleware
	r.Use(middleware.CORS())

	// 初始化依赖
	// 用户认证
	userRepo := postgres.NewUserRepository(database.DB)
	authService := user.NewAuthService(userRepo)
	authHandler := handlers.NewAuthHandler(authService)

	// 知识点管理
	chapterRepo := postgres.NewChapterRepository(database.DB)
	kpRepo := postgres.NewKnowledgePointRepository(database.DB)
	progressRepo := postgres.NewLearningProgressRepository(database.DB)
	knowledgeService := knowledge.NewKnowledgeService(chapterRepo, kpRepo, progressRepo)
	knowledgeHandler := handlers.NewKnowledgeHandler(knowledgeService)

	// 练习题库
	questionRepo := postgres.NewQuestionRepository(database.DB)
	recordRepo := postgres.NewPracticeRecordRepository(database.DB)
	wrongQuestionRepo := postgres.NewWrongQuestionRepository(database.DB)
	practiceService := practice.NewPracticeService(questionRepo, recordRepo, wrongQuestionRepo, progressRepo, kpRepo)
	practiceHandler := handlers.NewPracticeHandler(practiceService)
	wrongQuestionService := practice.NewWrongQuestionService(wrongQuestionRepo, questionRepo, practiceService)
	wrongQuestionHandler := handlers.NewWrongQuestionHandler(wrongQuestionService)

	// AI集成
	conversationRepo := postgres.NewAIConversationRepository(database.DB)
	aiService := ai.NewAIService(kpRepo, questionRepo, recordRepo, progressRepo, conversationRepo)
	aiHandler := handlers.NewAIHandler(aiService)

	// 学习报告
	reportService := analytics.NewReportService(progressRepo, recordRepo, kpRepo, chapterRepo)
	reportHandler := handlers.NewReportHandler(reportService)

	// API v1 路由组
	v1 := r.Group("/api/v1")
	{
		// 健康检查
		v1.GET("/health", handlers.HealthCheck)

		// 认证路由 (不需要JWT验证)
		auth := v1.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/refresh", authHandler.RefreshToken)
			auth.GET("/verify", authHandler.VerifyToken)
		}

		// 公开的知识点路由 (不需要认证)
		v1.GET("/chapters", knowledgeHandler.GetChapterList)
		v1.GET("/chapters/:id", knowledgeHandler.GetChapterDetail)

		// 可选认证的知识点路由 (有token则加载用户进度)
		optionalAuth := v1.Group("")
		optionalAuth.Use(middleware.OptionalAuthMiddleware())
		{
			optionalAuth.GET("/knowledge-points", knowledgeHandler.GetKnowledgePointList)
			optionalAuth.GET("/knowledge-points/:id", knowledgeHandler.GetKnowledgePointDetail)
			optionalAuth.GET("/knowledge/tree", knowledgeHandler.GetKnowledgeTree)
		}

		// 需要JWT验证的路由
		authorized := v1.Group("")
		authorized.Use(middleware.AuthMiddleware())
		{
			// 认证相关
			authorized.POST("/auth/logout", authHandler.Logout)

			// 用户相关
			authorized.GET("/users/me", authHandler.GetCurrentUser)
			authorized.PUT("/users/me", authHandler.UpdateCurrentUser)
			authorized.PUT("/users/me/password", authHandler.ChangePassword)

			// 学习进度相关
			authorized.GET("/learning/progress", knowledgeHandler.GetUserProgress)
			authorized.PUT("/learning/progress", knowledgeHandler.UpdateLearningProgress)

			// 题目相关
			authorized.GET("/questions", practiceHandler.GetQuestionList)
			authorized.GET("/questions/:id", practiceHandler.GetQuestionDetail)

			// 练习相关
			authorized.POST("/practice/generate", practiceHandler.GeneratePractice)
			authorized.POST("/practice/submit", practiceHandler.SubmitAnswer)
			authorized.POST("/practice/batch-submit", practiceHandler.BatchSubmitAnswers)
			authorized.GET("/practice/records", practiceHandler.GetPracticeRecords)
			authorized.GET("/practice/statistics", practiceHandler.GetPracticeStatistics)

			// 错题本
			authorized.GET("/wrong-questions", wrongQuestionHandler.GetWrongQuestionList)
			authorized.GET("/wrong-questions/top", wrongQuestionHandler.GetTopWrongQuestions)
			authorized.GET("/wrong-questions/:id", wrongQuestionHandler.GetWrongQuestionDetail)
			authorized.DELETE("/wrong-questions/:id", wrongQuestionHandler.RemoveWrongQuestion)

			// AI功能
			authorized.POST("/ai/generate-question", aiHandler.GenerateQuestion)
			authorized.POST("/ai/grade", aiHandler.GradeAnswer)
			authorized.POST("/ai/chat", aiHandler.Chat)
			authorized.POST("/ai/diagnose", aiHandler.Diagnose)
			authorized.POST("/ai/explain", aiHandler.Explain)

			// 学习报告
			authorized.GET("/reports/learning", reportHandler.GetLearningReport)
			authorized.GET("/reports/weak-points", reportHandler.GetWeakPoints)
			authorized.GET("/reports/progress", reportHandler.GetProgressOverview)
			authorized.GET("/reports/statistics", reportHandler.GetLearningStatistics)
		}
	}
}
