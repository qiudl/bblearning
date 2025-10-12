package practice

import (
	"context"
	"fmt"

	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/repository/postgres"
)

// WrongQuestionService 错题本服务
type WrongQuestionService struct {
	wrongQuestionRepo *postgres.WrongQuestionRepository
	questionRepo      *postgres.QuestionRepository
	practiceService   *PracticeService
}

// NewWrongQuestionService 创建错题本服务
func NewWrongQuestionService(
	wrongQuestionRepo *postgres.WrongQuestionRepository,
	questionRepo *postgres.QuestionRepository,
	practiceService *PracticeService,
) *WrongQuestionService {
	return &WrongQuestionService{
		wrongQuestionRepo: wrongQuestionRepo,
		questionRepo:      questionRepo,
		practiceService:   practiceService,
	}
}

// GetWrongQuestionList 获取错题列表
func (s *WrongQuestionService) GetWrongQuestionList(ctx context.Context, userID uint, req *dto.WrongQuestionListRequest) (*dto.WrongQuestionListResponse, error) {
	// 构建过滤条件
	filters := map[string]interface{}{"user_id": userID}
	if req.KnowledgePointID != nil {
		filters["knowledge_point_id"] = *req.KnowledgePointID
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

	// 查询错题列表
	wrongQuestions, total, err := s.wrongQuestionRepo.List(ctx, filters, pageSize, offset)
	if err != nil {
		return nil, fmt.Errorf("query wrong questions failed: %w", err)
	}

	// 转换为DTO
	items := make([]*dto.WrongQuestionInfo, 0, len(wrongQuestions))
	for _, wq := range wrongQuestions {
		item := &dto.WrongQuestionInfo{
			ID:            wq.ID,
			UserID:        wq.UserID,
			QuestionID:    wq.QuestionID,
			WrongCount:    wq.WrongCount,
			LastWrongTime: wq.LastWrongTime.Format("2006-01-02 15:04:05"),
			CreatedAt:     wq.CreatedAt.Format("2006-01-02 15:04:05"),
		}

		if wq.Question != nil {
			item.Question = s.practiceService.toQuestionInfo(wq.Question, false)
		}

		items = append(items, item)
	}

	return &dto.WrongQuestionListResponse{
		Items: items,
		Total: total,
		Page:  page,
		Size:  pageSize,
	}, nil
}

// GetWrongQuestionDetail 获取错题详情
func (s *WrongQuestionService) GetWrongQuestionDetail(ctx context.Context, userID, wrongQuestionID uint) (*dto.WrongQuestionInfo, error) {
	wq, err := s.wrongQuestionRepo.FindByID(ctx, wrongQuestionID)
	if err != nil {
		return nil, fmt.Errorf("wrong question not found: %w", err)
	}

	// 验证归属
	if wq.UserID != userID {
		return nil, fmt.Errorf("permission denied")
	}

	item := &dto.WrongQuestionInfo{
		ID:            wq.ID,
		UserID:        wq.UserID,
		QuestionID:    wq.QuestionID,
		WrongCount:    wq.WrongCount,
		LastWrongTime: wq.LastWrongTime.Format("2006-01-02 15:04:05"),
		CreatedAt:     wq.CreatedAt.Format("2006-01-02 15:04:05"),
	}

	if wq.Question != nil {
		item.Question = s.practiceService.toQuestionInfo(wq.Question, true) // 包含答案
	}

	return item, nil
}

// RemoveWrongQuestion 从错题本移除(表示已掌握)
func (s *WrongQuestionService) RemoveWrongQuestion(ctx context.Context, userID, wrongQuestionID uint) error {
	// 查询错题
	wq, err := s.wrongQuestionRepo.FindByID(ctx, wrongQuestionID)
	if err != nil {
		return fmt.Errorf("wrong question not found: %w", err)
	}

	// 验证归属
	if wq.UserID != userID {
		return fmt.Errorf("permission denied")
	}

	// 删除错题记录
	return s.wrongQuestionRepo.Delete(ctx, wrongQuestionID)
}

// GetTopWrongQuestions 获取错误最多的题目
func (s *WrongQuestionService) GetTopWrongQuestions(ctx context.Context, userID uint, limit int) ([]*dto.WrongQuestionInfo, error) {
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	wrongQuestions, err := s.wrongQuestionRepo.GetTopWrongQuestions(ctx, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("query top wrong questions failed: %w", err)
	}

	items := make([]*dto.WrongQuestionInfo, 0, len(wrongQuestions))
	for _, wq := range wrongQuestions {
		item := &dto.WrongQuestionInfo{
			ID:            wq.ID,
			UserID:        wq.UserID,
			QuestionID:    wq.QuestionID,
			WrongCount:    wq.WrongCount,
			LastWrongTime: wq.LastWrongTime.Format("2006-01-02 15:04:05"),
			CreatedAt:     wq.CreatedAt.Format("2006-01-02 15:04:05"),
		}

		if wq.Question != nil {
			item.Question = s.practiceService.toQuestionInfo(wq.Question, false)
		}

		items = append(items, item)
	}

	return items, nil
}
