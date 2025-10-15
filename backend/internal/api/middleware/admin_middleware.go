package middleware

import (
	"github.com/gin-gonic/gin"
)

// AdminAuthMiddleware 管理员认证中间件
// 要求用户必须是 admin 或 teacher 角色
func AdminAuthMiddleware() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		// 先进行基本认证
		AuthMiddleware()(c)

		// 如果认证失败，已经在 AuthMiddleware 中 Abort 了
		if c.IsAborted() {
			return
		}

		// 验证管理员角色
		RoleMiddleware("admin", "teacher")(c)
	})
}

// SuperAdminMiddleware 超级管理员中间件
// 仅允许 admin 角色访问
func SuperAdminMiddleware() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		// 先进行基本认证
		AuthMiddleware()(c)

		// 如果认证失败，已经在 AuthMiddleware 中 Abort 了
		if c.IsAborted() {
			return
		}

		// 验证超级管理员角色
		RoleMiddleware("admin")(c)
	})
}

// TeacherAuthMiddleware 教师认证中间件
// 仅允许 teacher 角色访问
func TeacherAuthMiddleware() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		// 先进行基本认证
		AuthMiddleware()(c)

		// 如果认证失败，已经在 AuthMiddleware 中 Abort 了
		if c.IsAborted() {
			return
		}

		// 验证教师角色
		RoleMiddleware("teacher")(c)
	})
}
