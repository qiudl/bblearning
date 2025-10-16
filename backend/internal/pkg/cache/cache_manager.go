package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"
)

// CacheKey 缓存键前缀
const (
	// 用户相关
	KeyUserInfo    = "user:info:%d"           // 用户信息
	KeyUserSession = "user:session:%s"        // 用户会话

	// 知识点相关
	KeyKnowledgeTree   = "knowledge:tree:grade:%d"  // 知识点树
	KeyKnowledgePoint  = "knowledge:point:%d"       // 知识点详情
	KeyKnowledgeList   = "knowledge:list:all"       // 所有知识点列表

	// 题目相关
	KeyQuestion       = "question:%d"                    // 题目详情
	KeyQuestionList   = "question:list:kp:%d:page:%d"   // 题目列表（按知识点分页）

	// 练习记录
	KeyUserPractice   = "practice:user:%d:page:%d"      // 用户练习记录
	KeyUserWrongQ     = "wrong:user:%d:page:%d"         // 用户错题记录

	// 统计数据
	KeyUserStats      = "stats:user:%d"                 // 用户统计
	KeyDailyStats     = "stats:daily:user:%d:date:%s"   // 每日统计

	// AI配额
	KeyUserQuota      = "quota:user:%d"                 // 用户配额

	// 热点数据
	KeyHotQuestions   = "hot:questions:top100"          // 热门题目
	KeyHotKnowledge   = "hot:knowledge:top50"           // 热门知识点
)

// TTL 缓存过期时间
const (
	TTLUserInfo       = 30 * time.Minute   // 用户信息
	TTLUserSession    = 24 * time.Hour     // 用户会话
	TTLKnowledgeTree  = 24 * time.Hour     // 知识点树
	TTLKnowledgePoint = 6 * time.Hour      // 知识点详情
	TTLQuestion       = 1 * time.Hour      // 题目详情
	TTLQuestionList   = 10 * time.Minute   // 题目列表
	TTLUserPractice   = 5 * time.Minute    // 练习记录
	TTLUserStats      = 10 * time.Minute   // 统计数据
	TTLUserQuota      = 5 * time.Minute    // 用户配额
	TTLHotData        = 1 * time.Hour      // 热点数据
)

// CacheManager 缓存管理器
type CacheManager struct{}

// NewCacheManager 创建缓存管理器
func NewCacheManager() *CacheManager {
	return &CacheManager{}
}

// GetOrSet 获取缓存，如果不存在则执行loader并设置缓存
func (m *CacheManager) GetOrSet(ctx context.Context, key string, ttl time.Duration, dest interface{}, loader func() (interface{}, error)) error {
	// 先尝试从缓存获取
	err := Get(ctx, key, dest)
	if err == nil {
		return nil // 缓存命中
	}

	// 缓存未命中，执行loader
	data, err := loader()
	if err != nil {
		return err
	}

	// 设置缓存
	if err := Set(ctx, key, data, ttl); err != nil {
		// 缓存设置失败不影响业务逻辑，只记录日志
		fmt.Printf("Failed to set cache for key %s: %v\n", key, err)
	}

	// 将加载的数据复制到dest
	return m.copyData(data, dest)
}

// InvalidateUserCache 清除用户相关缓存
func (m *CacheManager) InvalidateUserCache(ctx context.Context, userID uint) error {
	keys := []string{
		fmt.Sprintf(KeyUserInfo, userID),
		fmt.Sprintf(KeyUserStats, userID),
		fmt.Sprintf(KeyUserQuota, userID),
	}
	return Delete(ctx, keys...)
}

// InvalidateKnowledgeCache 清除知识点相关缓存
func (m *CacheManager) InvalidateKnowledgeCache(ctx context.Context, knowledgePointID uint) error {
	keys := []string{
		fmt.Sprintf(KeyKnowledgePoint, knowledgePointID),
		KeyKnowledgeList,
	}

	// 清除所有年级的知识点树缓存
	for grade := 7; grade <= 9; grade++ {
		keys = append(keys, fmt.Sprintf(KeyKnowledgeTree, grade))
	}

	return Delete(ctx, keys...)
}

// InvalidateQuestionCache 清除题目相关缓存
func (m *CacheManager) InvalidateQuestionCache(ctx context.Context, questionID uint) error {
	key := fmt.Sprintf(KeyQuestion, questionID)
	return Delete(ctx, key)
}

// InvalidatePracticeCache 清除练习记录缓存
func (m *CacheManager) InvalidatePracticeCache(ctx context.Context, userID uint) error {
	// 清除用户练习记录的所有分页缓存
	// 实际应用中可能需要更精细的控制
	keys := []string{
		fmt.Sprintf(KeyUserStats, userID),
	}

	// 清除前10页的缓存
	for page := 1; page <= 10; page++ {
		keys = append(keys, fmt.Sprintf(KeyUserPractice, userID, page))
		keys = append(keys, fmt.Sprintf(KeyUserWrongQ, userID, page))
	}

	return Delete(ctx, keys...)
}

// WarmUpCache 预热缓存
func (m *CacheManager) WarmUpCache(ctx context.Context) error {
	// 预热知识点树缓存
	// 这里只是示例，实际应该调用相应的service方法
	fmt.Println("Warming up cache...")
	return nil
}

// copyData 复制数据到目标对象
func (m *CacheManager) copyData(src, dest interface{}) error {
	// 使用JSON序列化/反序列化来复制数据
	data, err := json.Marshal(src)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, dest)
}
