package knowledge

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"github.com/qiudl/bblearning-backend/internal/pkg/cache"
	"github.com/qiudl/bblearning-backend/internal/repository/postgres"
)

// KnowledgeService 知识点服务
type KnowledgeService struct {
	chapterRepo  *postgres.ChapterRepository
	kpRepo       *postgres.KnowledgePointRepository
	progressRepo *postgres.LearningProgressRepository
}

// NewKnowledgeService 创建知识点服务
func NewKnowledgeService(
	chapterRepo *postgres.ChapterRepository,
	kpRepo *postgres.KnowledgePointRepository,
	progressRepo *postgres.LearningProgressRepository,
) *KnowledgeService {
	return &KnowledgeService{
		chapterRepo:  chapterRepo,
		kpRepo:       kpRepo,
		progressRepo: progressRepo,
	}
}

// GetChapterList 获取章节列表
func (s *KnowledgeService) GetChapterList(ctx context.Context, req *dto.ChapterListRequest) (*dto.ChapterListResponse, error) {
	// 构建过滤条件
	filters := make(map[string]interface{})
	if req.Grade != "" {
		filters["grade"] = req.Grade
	}
	if req.Subject != "" {
		filters["subject"] = req.Subject
	}
	if req.Semester != "" {
		filters["semester"] = req.Semester
	}

	// 设置默认分页
	page := req.Page
	if page < 1 {
		page = 1
	}
	pageSize := req.PageSize
	if pageSize < 1 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}

	offset := (page - 1) * pageSize

	// 查询章节列表
	chapters, total, err := s.chapterRepo.List(ctx, filters, pageSize, offset)
	if err != nil {
		return nil, fmt.Errorf("query chapters failed: %w", err)
	}

	// 转换为DTO
	items := make([]*dto.ChapterInfo, 0, len(chapters))
	for _, chapter := range chapters {
		// 查询每个章节的知识点数量
		count, _ := s.kpRepo.CountByChapterID(ctx, chapter.ID)
		info := dto.ToChapterInfo(chapter)
		info.KnowledgePoints = int(count)
		items = append(items, info)
	}

	return &dto.ChapterListResponse{
		Items: items,
		Total: total,
		Page:  page,
		Size:  pageSize,
	}, nil
}

// GetChapterDetail 获取章节详情(包含知识点)
func (s *KnowledgeService) GetChapterDetail(ctx context.Context, chapterID uint) (*dto.ChapterDetailResponse, error) {
	// 尝试从缓存获取
	cacheKey := fmt.Sprintf("chapter:detail:%d", chapterID)
	var detail dto.ChapterDetailResponse
	if err := cache.Get(ctx, cacheKey, &detail); err == nil {
		return &detail, nil
	}

	// 查询章节(包含知识点)
	chapter, err := s.chapterRepo.FindByIDWithKnowledgePoints(ctx, chapterID)
	if err != nil {
		return nil, fmt.Errorf("chapter not found: %w", err)
	}

	// 转换为DTO
	chapterInfo := dto.ToChapterInfo(chapter)
	kpInfos := make([]*dto.KnowledgePointInfo, 0, len(chapter.KnowledgePoints))
	for _, kp := range chapter.KnowledgePoints {
		kpInfos = append(kpInfos, dto.ToKnowledgePointInfo(&kp))
	}

	detail = dto.ChapterDetailResponse{
		ChapterInfo:     chapterInfo,
		KnowledgePoints: kpInfos,
	}

	// 缓存结果(1小时)
	_ = cache.Set(ctx, cacheKey, detail, 1*time.Hour)

	return &detail, nil
}

// GetKnowledgePointList 获取知识点列表
func (s *KnowledgeService) GetKnowledgePointList(ctx context.Context, req *dto.KnowledgePointListRequest, userID uint) (*dto.KnowledgePointListResponse, error) {
	// 构建过滤条件
	filters := make(map[string]interface{})
	if req.ChapterID != nil {
		filters["chapter_id"] = *req.ChapterID
	}
	if req.Type != "" {
		filters["type"] = req.Type
	}
	if req.Difficulty != "" {
		filters["difficulty"] = req.Difficulty
	}

	// 设置默认分页
	page := req.Page
	if page < 1 {
		page = 1
	}
	pageSize := req.PageSize
	if pageSize < 1 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}

	offset := (page - 1) * pageSize

	// 查询知识点列表
	kps, total, err := s.kpRepo.List(ctx, filters, pageSize, offset)
	if err != nil {
		return nil, fmt.Errorf("query knowledge points failed: %w", err)
	}

	// 转换为DTO并获取用户掌握度
	items := make([]*dto.KnowledgePointInfo, 0, len(kps))
	for _, kp := range kps {
		info := dto.ToKnowledgePointInfo(kp)

		// 获取用户学习进度
		if userID > 0 {
			progress, err := s.progressRepo.FindByUserAndKnowledgePoint(ctx, userID, kp.ID)
			if err == nil {
				info.MasteryLevel = &progress.MasteryLevel
			}
		}

		items = append(items, info)
	}

	return &dto.KnowledgePointListResponse{
		Items: items,
		Total: total,
		Page:  page,
		Size:  pageSize,
	}, nil
}

// GetKnowledgePointDetail 获取知识点详情
func (s *KnowledgeService) GetKnowledgePointDetail(ctx context.Context, kpID uint, userID uint) (*dto.KnowledgePointInfo, error) {
	// 查询知识点
	kp, err := s.kpRepo.FindByID(ctx, kpID)
	if err != nil {
		return nil, fmt.Errorf("knowledge point not found: %w", err)
	}

	// 转换为DTO
	info := dto.ToKnowledgePointInfo(kp)

	// 获取用户学习进度
	if userID > 0 {
		progress, err := s.progressRepo.FindByUserAndKnowledgePoint(ctx, userID, kp.ID)
		if err == nil {
			info.MasteryLevel = &progress.MasteryLevel
		}
	}

	// 查询子知识点
	children, err := s.kpRepo.FindChildrenByParentID(ctx, kpID)
	if err == nil && len(children) > 0 {
		childInfos := make([]*dto.KnowledgePointInfo, 0, len(children))
		for _, child := range children {
			childInfo := dto.ToKnowledgePointInfo(child)

			// 获取子知识点的用户进度
			if userID > 0 {
				childProgress, err := s.progressRepo.FindByUserAndKnowledgePoint(ctx, userID, child.ID)
				if err == nil {
					childInfo.MasteryLevel = &childProgress.MasteryLevel
				}
			}

			childInfos = append(childInfos, childInfo)
		}
		info.Children = childInfos
	}

	return info, nil
}

// GetKnowledgeTree 获取知识树(按年级)
func (s *KnowledgeService) GetKnowledgeTree(ctx context.Context, grade string, userID uint) (*dto.KnowledgeTreeResponse, error) {
	// 尝试从缓存获取
	cacheKey := fmt.Sprintf("knowledge:tree:%s", grade)
	var tree dto.KnowledgeTreeResponse
	if userID == 0 { // 只有未登录用户才使用缓存
		if err := cache.Get(ctx, cacheKey, &tree); err == nil {
			return &tree, nil
		}
	}

	// 查询所有章节(包含知识点)
	chapters, err := s.chapterRepo.FindByGradeWithKnowledgePoints(ctx, grade)
	if err != nil {
		return nil, fmt.Errorf("query chapters failed: %w", err)
	}

	// 转换为树形结构
	chapterInfos := make([]*dto.ChapterWithKnowledge, 0, len(chapters))
	for _, chapter := range chapters {
		chapterInfo := dto.ToChapterInfo(chapter)

		// 只获取根知识点
		rootKPs := make([]*dto.KnowledgePointInfo, 0)
		for _, kp := range chapter.KnowledgePoints {
			if kp.ParentID == nil {
				kpInfo := dto.ToKnowledgePointInfo(&kp)

				// 获取用户进度
				if userID > 0 {
					progress, err := s.progressRepo.FindByUserAndKnowledgePoint(ctx, userID, kp.ID)
					if err == nil {
						kpInfo.MasteryLevel = &progress.MasteryLevel
					}
				}

				// 递归构建子树
				s.buildKnowledgeTree(ctx, kpInfo, chapter.KnowledgePoints, userID)
				rootKPs = append(rootKPs, kpInfo)
			}
		}

		chapterInfos = append(chapterInfos, &dto.ChapterWithKnowledge{
			ChapterInfo:     chapterInfo,
			KnowledgePoints: rootKPs,
		})
	}

	tree = dto.KnowledgeTreeResponse{
		Grade:    grade,
		Chapters: chapterInfos,
	}

	// 缓存结果(只缓存未登录用户的结果)
	if userID == 0 {
		_ = cache.Set(ctx, cacheKey, tree, 24*time.Hour)
	}

	return &tree, nil
}

// buildKnowledgeTree 递归构建知识点树
func (s *KnowledgeService) buildKnowledgeTree(ctx context.Context, parent *dto.KnowledgePointInfo, allKPs []models.KnowledgePoint, userID uint) {
	children := make([]*dto.KnowledgePointInfo, 0)

	for _, kp := range allKPs {
		if kp.ParentID != nil && *kp.ParentID == parent.ID {
			childInfo := dto.ToKnowledgePointInfo(&kp)

			// 获取用户进度
			if userID > 0 {
				progress, err := s.progressRepo.FindByUserAndKnowledgePoint(ctx, userID, kp.ID)
				if err == nil {
					childInfo.MasteryLevel = &progress.MasteryLevel
				}
			}

			// 递归构建
			s.buildKnowledgeTree(ctx, childInfo, allKPs, userID)
			children = append(children, childInfo)
		}
	}

	if len(children) > 0 {
		parent.Children = children
	}
}

// UpdateLearningProgress 更新学习进度
func (s *KnowledgeService) UpdateLearningProgress(ctx context.Context, userID uint, req *dto.LearningProgressRequest) error {
	// 检查知识点是否存在
	_, err := s.kpRepo.FindByID(ctx, req.KnowledgePointID)
	if err != nil {
		return errors.New("knowledge point not found")
	}

	// 查询现有进度
	progress, err := s.progressRepo.FindByUserAndKnowledgePoint(ctx, userID, req.KnowledgePointID)

	now := time.Now()

	if err != nil {
		// 创建新进度
		progress = &models.LearningProgress{
			UserID:           userID,
			KnowledgePointID: req.KnowledgePointID,
			MasteryLevel:     0,
			PracticeCount:    0,
			CorrectCount:     0,
			LastPracticeAt:   &now,
		}

		if req.MasteryLevel != nil {
			progress.MasteryLevel = *req.MasteryLevel
		}

		return s.progressRepo.Create(ctx, progress)
	}

	// 更新现有进度
	if req.MasteryLevel != nil {
		progress.MasteryLevel = *req.MasteryLevel
	}
	progress.LastPracticeAt = &now

	err = s.progressRepo.Update(ctx, progress)
	if err != nil {
		return fmt.Errorf("update learning progress failed: %w", err)
	}

	// 清除用户相关缓存
	_ = cache.Delete(ctx, fmt.Sprintf("user:%d:progress", userID))

	return nil
}

// GetUserProgress 获取用户学习进度
func (s *KnowledgeService) GetUserProgress(ctx context.Context, userID uint, page, pageSize int) (*dto.UserProgressListResponse, error) {
	// 设置默认分页
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}

	offset := (page - 1) * pageSize

	// 查询用户进度
	progresses, total, err := s.progressRepo.FindByUserID(ctx, userID, pageSize, offset)
	if err != nil {
		return nil, fmt.Errorf("query user progress failed: %w", err)
	}

	// 转换为DTO并加载知识点信息
	items := make([]*dto.LearningProgressInfo, 0, len(progresses))
	for _, progress := range progresses {
		info := &dto.LearningProgressInfo{
			ID:               progress.ID,
			UserID:           progress.UserID,
			KnowledgePointID: progress.KnowledgePointID,
			MasteryLevel:     progress.MasteryLevel,
			PracticeCount:    progress.PracticeCount,
			CorrectCount:     progress.CorrectCount,
		}

		if progress.LastPracticeAt != nil {
			timestamp := progress.LastPracticeAt.Format(time.RFC3339)
			info.LastPracticeAt = &timestamp
		}

		// 加载知识点详情
		kp, err := s.kpRepo.FindByID(ctx, progress.KnowledgePointID)
		if err == nil {
			info.KnowledgePoint = dto.ToKnowledgePointInfo(kp)
		}

		items = append(items, info)
	}

	return &dto.UserProgressListResponse{
		Items: items,
		Total: total,
	}, nil
}
