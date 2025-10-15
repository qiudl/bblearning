package routes

import (
	"github.com/gin-gonic/gin"
	adminHandlers "github.com/qiudl/bblearning-backend/internal/api/handlers/admin"
	"github.com/qiudl/bblearning-backend/internal/api/middleware"
	"github.com/qiudl/bblearning-backend/internal/pkg/database"
	"github.com/qiudl/bblearning-backend/internal/repository/postgres"
	adminServices "github.com/qiudl/bblearning-backend/internal/service/admin"
	"github.com/qiudl/bblearning-backend/internal/service/ai"
)

// SetupAdminRoutes 设置管理员路由
func SetupAdminRoutes(r *gin.RouterGroup, aiService *ai.AIService) {
	// 初始化仓库层
	userRepo := postgres.NewUserRepository(database.DB)
	chapterRepo := postgres.NewChapterRepository(database.DB)
	kpRepo := postgres.NewKnowledgePointRepository(database.DB)
	questionRepo := postgres.NewQuestionRepository(database.DB)
	recordRepo := postgres.NewPracticeRecordRepository(database.DB)

	// 初始化服务层
	userService := adminServices.NewUserService(userRepo)
	contentService := adminServices.NewContentService(chapterRepo, kpRepo)
	aiQuestionService := adminServices.NewAIQuestionService(aiService, kpRepo, questionRepo)
	dashboardService := adminServices.NewDashboardService(userRepo, questionRepo, recordRepo, kpRepo)

	// 初始化处理器
	userHandler := adminHandlers.NewUserHandler(userService)
	contentHandler := adminHandlers.NewContentHandler(contentService)
	aiQuestionHandler := adminHandlers.NewAIQuestionHandler(aiQuestionService)
	dashboardHandler := adminHandlers.NewDashboardHandler(dashboardService)

	// 管理员路由组 - 需要管理员权限
	admin := r.Group("/admin")
	admin.Use(middleware.AdminAuthMiddleware())
	{
		// 仪表板
		admin.GET("/dashboard/statistics", dashboardHandler.GetStatistics)

		// 用户管理
		users := admin.Group("/users")
		{
			users.GET("", userHandler.GetUserList)
			users.GET("/statistics", userHandler.GetUserStatistics)
			users.GET("/:id", userHandler.GetUserDetail)
			users.PUT("/:id/status", userHandler.UpdateUserStatus)
		}

		// 内容管理 - 章节
		chapters := admin.Group("/chapters")
		{
			chapters.GET("", contentHandler.GetChapterList)
			chapters.POST("", contentHandler.CreateChapter)
			chapters.PUT("/:id", contentHandler.UpdateChapter)
			chapters.DELETE("/:id", contentHandler.DeleteChapter)
		}

		// 内容管理 - 知识点
		knowledgePoints := admin.Group("/knowledge-points")
		{
			knowledgePoints.GET("", contentHandler.GetKnowledgePointList)
			knowledgePoints.POST("", contentHandler.CreateKnowledgePoint)
			knowledgePoints.PUT("/:id", contentHandler.UpdateKnowledgePoint)
			knowledgePoints.DELETE("/:id", contentHandler.DeleteKnowledgePoint)
		}

		// 题目管理 - AI生成
		questions := admin.Group("/questions")
		{
			questions.GET("", aiQuestionHandler.GetQuestionList)
			questions.POST("/ai-generate", aiQuestionHandler.GenerateQuestions)
			questions.POST("/batch-save", aiQuestionHandler.BatchSaveQuestions)
			questions.GET("/generation-history", aiQuestionHandler.GetGenerationHistory)
			questions.PUT("/:id", aiQuestionHandler.UpdateQuestion)
			questions.DELETE("/:id", aiQuestionHandler.DeleteQuestion)
		}
	}
}
