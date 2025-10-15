package practice

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"github.com/qiudl/bblearning-backend/internal/repository/postgres"
)

// PracticeService 练习服务
type PracticeService struct {
	questionRepo      *postgres.QuestionRepository
	recordRepo        *postgres.PracticeRecordRepository
	wrongQuestionRepo *postgres.WrongQuestionRepository
	progressRepo      *postgres.LearningProgressRepository
	kpRepo            *postgres.KnowledgePointRepository
}

// NewPracticeService 创建练习服务
func NewPracticeService(
	questionRepo *postgres.QuestionRepository,
	recordRepo *postgres.PracticeRecordRepository,
	wrongQuestionRepo *postgres.WrongQuestionRepository,
	progressRepo *postgres.LearningProgressRepository,
	kpRepo *postgres.KnowledgePointRepository,
) *PracticeService {
	return &PracticeService{
		questionRepo:      questionRepo,
		recordRepo:        recordRepo,
		wrongQuestionRepo: wrongQuestionRepo,
		progressRepo:      progressRepo,
		kpRepo:            kpRepo,
	}
}

// GetQuestionList 获取题目列表
func (s *PracticeService) GetQuestionList(ctx context.Context, req *dto.QuestionListRequest) (*dto.QuestionListResponse, error) {
	// 构建过滤条件
	filters := make(map[string]interface{})
	if req.KnowledgePointID != nil {
		filters["knowledge_point_id"] = *req.KnowledgePointID
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

	// 查询题目列表
	questions, total, err := s.questionRepo.List(ctx, filters, pageSize, offset)
	if err != nil {
		return nil, fmt.Errorf("query questions failed: %w", err)
	}

	// 转换为DTO (不包含答案)
	items := make([]*dto.QuestionInfo, 0, len(questions))
	for _, q := range questions {
		items = append(items, s.toQuestionInfo(q, false))
	}

	return &dto.QuestionListResponse{
		Items: items,
		Total: total,
		Page:  page,
		Size:  pageSize,
	}, nil
}

// GetQuestionDetail 获取题目详情
func (s *PracticeService) GetQuestionDetail(ctx context.Context, questionID uint, includeAnswer bool) (*dto.QuestionInfo, error) {
	question, err := s.questionRepo.FindByID(ctx, questionID)
	if err != nil {
		return nil, fmt.Errorf("question not found: %w", err)
	}

	return s.toQuestionInfo(question, includeAnswer), nil
}

// GeneratePractice 生成练习题目
func (s *PracticeService) GeneratePractice(ctx context.Context, req *dto.GeneratePracticeRequest) (*dto.GeneratePracticeResponse, error) {
	// 检查知识点是否存在
	_, err := s.kpRepo.FindByID(ctx, req.KnowledgePointID)
	if err != nil {
		return nil, errors.New("knowledge point not found")
	}

	// 构建过滤条件
	filters := make(map[string]interface{})
	if req.Type != "" {
		filters["type"] = req.Type
	}
	if req.Difficulty != "" {
		filters["difficulty"] = req.Difficulty
	}

	// 随机获取题目
	questions, err := s.questionRepo.FindRandomByKnowledgePoint(ctx, req.KnowledgePointID, req.Count, filters)
	if err != nil {
		return nil, fmt.Errorf("generate practice failed: %w", err)
	}

	if len(questions) == 0 {
		return nil, errors.New("no questions available")
	}

	// 转换为DTO (不包含答案)
	questionInfos := make([]*dto.QuestionInfo, 0, len(questions))
	for _, q := range questions {
		questionInfos = append(questionInfos, s.toQuestionInfo(q, false))
	}

	return &dto.GeneratePracticeResponse{
		Questions: questionInfos,
		Count:     len(questionInfos),
	}, nil
}

// SubmitAnswer 提交答案
func (s *PracticeService) SubmitAnswer(ctx context.Context, userID uint, req *dto.SubmitAnswerRequest) (*dto.SubmitAnswerResponse, error) {
	// 查询题目
	question, err := s.questionRepo.FindByID(ctx, req.QuestionID)
	if err != nil {
		return nil, errors.New("question not found")
	}

	// 判断答案是否正确
	isCorrect := s.checkAnswer(question, req.UserAnswer)

	// 创建练习记录
	record := &models.PracticeRecord{
		UserID:     userID,
		QuestionID: req.QuestionID,
		UserAnswer: req.UserAnswer,
		IsCorrect:  isCorrect,
		TimeSpent:  0, // TODO: 从前端传入实际用时
	}

	err = s.recordRepo.Create(ctx, record)
	if err != nil {
		return nil, fmt.Errorf("create practice record failed: %w", err)
	}

	// 如果答错,添加到错题本
	if !isCorrect {
		wrongQuestion := &models.WrongQuestion{
			UserID:        userID,
			QuestionID:    req.QuestionID,
			WrongCount:    1,
			LastWrongTime: time.Now(),
		}
		_ = s.wrongQuestionRepo.Upsert(ctx, wrongQuestion)
	}

	// 更新学习进度
	go s.updateLearningProgressAsync(context.Background(), userID, question.KnowledgePointID, isCorrect)

	return &dto.SubmitAnswerResponse{
		QuestionID:  req.QuestionID,
		UserAnswer:  req.UserAnswer,
		IsCorrect:   isCorrect,
		Answer:      question.Answer,
		Explanation: question.Explanation,
		RecordID:    record.ID,
	}, nil
}

// BatchSubmitAnswers 批量提交答案
func (s *PracticeService) BatchSubmitAnswers(ctx context.Context, userID uint, req *dto.BatchSubmitRequest) (*dto.BatchSubmitResponse, error) {
	results := make([]*dto.SubmitAnswerResponse, 0, len(req.Answers))
	correctCount := 0

	// 获取所有题目ID
	questionIDs := make([]uint, len(req.Answers))
	for i, ans := range req.Answers {
		questionIDs[i] = ans.QuestionID
	}

	// 批量查询题目
	questions, err := s.questionRepo.FindByIDs(ctx, questionIDs)
	if err != nil {
		return nil, fmt.Errorf("query questions failed: %w", err)
	}

	// 构建题目ID到题目的映射
	questionMap := make(map[uint]*models.Question)
	for _, q := range questions {
		questionMap[q.ID] = q
	}

	// 批量创建记录
	records := make([]*models.PracticeRecord, 0, len(req.Answers))
	wrongQuestions := make([]*models.WrongQuestion, 0)

	for _, ans := range req.Answers {
		question, ok := questionMap[ans.QuestionID]
		if !ok {
			continue
		}

		isCorrect := s.checkAnswer(question, ans.UserAnswer)
		if isCorrect {
			correctCount++
		}

		// 创建练习记录
		record := &models.PracticeRecord{
			UserID:     userID,
			QuestionID: ans.QuestionID,
			UserAnswer: ans.UserAnswer,
			IsCorrect:  isCorrect,
			TimeSpent:  0, // TODO: 从前端传入实际用时
		}
		records = append(records, record)

		// 如果答错,添加到错题本
		if !isCorrect {
			wrongQuestions = append(wrongQuestions, &models.WrongQuestion{
				UserID:        userID,
				QuestionID:    ans.QuestionID,
				WrongCount:    1,
				LastWrongTime: time.Now(),
			})
		}

		// 添加到结果
		results = append(results, &dto.SubmitAnswerResponse{
			QuestionID:  ans.QuestionID,
			UserAnswer:  ans.UserAnswer,
			IsCorrect:   isCorrect,
			Answer:      question.Answer,
			Explanation: question.Explanation,
		})
	}

	// 批量创建练习记录
	if len(records) > 0 {
		err = s.recordRepo.BatchCreate(ctx, records)
		if err != nil {
			return nil, fmt.Errorf("batch create records failed: %w", err)
		}

		// 更新记录ID到结果
		for i, record := range records {
			if i < len(results) {
				results[i].RecordID = record.ID
			}
		}
	}

	// 批量添加错题
	for _, wq := range wrongQuestions {
		_ = s.wrongQuestionRepo.Upsert(ctx, wq)
	}

	// 计算正确率
	accuracy := 0.0
	if len(results) > 0 {
		accuracy = float64(correctCount) / float64(len(results)) * 100
	}

	// 异步更新学习进度
	go s.batchUpdateLearningProgressAsync(context.Background(), userID, records)

	return &dto.BatchSubmitResponse{
		Results:      results,
		TotalCount:   len(results),
		CorrectCount: correctCount,
		Accuracy:     accuracy,
	}, nil
}

// GetPracticeRecords 获取练习记录
func (s *PracticeService) GetPracticeRecords(ctx context.Context, userID uint, req *dto.PracticeRecordListRequest) (*dto.PracticeRecordListResponse, error) {
	// 构建过滤条件
	filters := map[string]interface{}{"user_id": userID}
	if req.KnowledgePointID != nil {
		filters["knowledge_point_id"] = *req.KnowledgePointID
	}
	if req.IsCorrect != nil {
		filters["is_correct"] = *req.IsCorrect
	}
	if req.StartDate != "" {
		filters["start_date"] = req.StartDate
	}
	if req.EndDate != "" {
		filters["end_date"] = req.EndDate
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

	// 查询练习记录
	records, total, err := s.recordRepo.List(ctx, filters, pageSize, offset)
	if err != nil {
		return nil, fmt.Errorf("query practice records failed: %w", err)
	}

	// 转换为DTO
	items := make([]*dto.PracticeRecordInfo, 0, len(records))
	for _, record := range records {
		item := &dto.PracticeRecordInfo{
			ID:         record.ID,
			UserID:     record.UserID,
			QuestionID: record.QuestionID,
			UserAnswer: record.UserAnswer,
			IsCorrect:  record.IsCorrect,
			Timestamp:  record.CreatedAt.Format(time.RFC3339),
		}

		if record.Question != nil {
			item.Question = s.toQuestionInfo(record.Question, true)
		}

		items = append(items, item)
	}

	return &dto.PracticeRecordListResponse{
		Items: items,
		Total: total,
		Page:  page,
		Size:  pageSize,
	}, nil
}

// GetPracticeStatistics 获取练习统计
func (s *PracticeService) GetPracticeStatistics(ctx context.Context, userID uint) (*dto.PracticeStatistics, error) {
	// 获取基础统计
	stats, err := s.recordRepo.GetStatistics(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get statistics failed: %w", err)
	}

	// 获取今日统计
	todayCount, _ := s.recordRepo.GetTodayStatistics(ctx, userID)

	// 获取本周统计
	weekCount, _ := s.recordRepo.GetWeekStatistics(ctx, userID)

	// 获取最后练习时间
	lastPracticeAt, _ := s.recordRepo.GetLastPracticeTime(ctx, userID)
	var lastPracticeStr *string
	if lastPracticeAt != nil {
		str := lastPracticeAt.Format(time.RFC3339)
		lastPracticeStr = &str
	}

	// 获取强项和弱项
	kpAccuracy, _ := s.recordRepo.GetKnowledgePointAccuracy(ctx, userID)
	strongPoints, weakPoints := s.analyzeKnowledgePoints(ctx, kpAccuracy)

	return &dto.PracticeStatistics{
		TotalPractice:  int(stats["total_practice"].(int64)),
		TotalCorrect:   int(stats["total_correct"].(int64)),
		TotalWrong:     int(stats["total_wrong"].(int64)),
		Accuracy:       stats["accuracy"].(float64),
		TodayPractice:  int(todayCount),
		WeekPractice:   int(weekCount),
		LastPracticeAt: lastPracticeStr,
		StrongPoints:   strongPoints,
		WeakPoints:     weakPoints,
	}, nil
}

// checkAnswer 检查答案是否正确
func (s *PracticeService) checkAnswer(question *models.Question, userAnswer string) bool {
	// 标准化答案(去除空格,转小写)
	standardAnswer := strings.TrimSpace(strings.ToLower(question.Answer))
	standardUserAnswer := strings.TrimSpace(strings.ToLower(userAnswer))

	return standardAnswer == standardUserAnswer
}

// toQuestionInfo 将Question模型转换为QuestionInfo
func (s *PracticeService) toQuestionInfo(q *models.Question, includeAnswer bool) *dto.QuestionInfo {
	info := &dto.QuestionInfo{
		ID:               q.ID,
		KnowledgePointID: q.KnowledgePointID,
		Type:             q.Type,
		Content:          q.Content,
		Difficulty:       q.Difficulty,
	}

	// 解析选项(JSON数组)
	if q.Options != "" {
		var options []string
		_ = json.Unmarshal([]byte(q.Options), &options)
		info.Options = options
	}

	// 只有明确要求才包含答案
	if includeAnswer {
		info.Answer = q.Answer
		info.Explanation = q.Explanation
	}

	return info
}

// updateLearningProgressAsync 异步更新学习进度
func (s *PracticeService) updateLearningProgressAsync(ctx context.Context, userID, kpID uint, isCorrect bool) {
	progress, err := s.progressRepo.FindByUserAndKnowledgePoint(ctx, userID, kpID)
	if err != nil {
		// 不存在,创建新进度
		now := time.Now()
		progress = &models.LearningProgress{
			UserID:           userID,
			KnowledgePointID: kpID,
			MasteryLevel:     0,
			PracticeCount:    0,
			CorrectCount:     0,
			LastPracticeAt:   &now,
		}
	}

	// 更新统计
	progress.PracticeCount++
	if isCorrect {
		progress.CorrectCount++
	}
	now := time.Now()
	progress.LastPracticeAt = &now

	// 计算掌握度(简单算法: 正确率 * 练习次数权重)
	accuracy := float64(progress.CorrectCount) / float64(progress.PracticeCount) * 100
	practiceWeight := 1.0
	if progress.PracticeCount < 5 {
		practiceWeight = float64(progress.PracticeCount) / 5.0
	}
	progress.MasteryLevel = accuracy * practiceWeight

	// 保存进度
	_ = s.progressRepo.Upsert(ctx, progress)
}

// batchUpdateLearningProgressAsync 批量更新学习进度
func (s *PracticeService) batchUpdateLearningProgressAsync(ctx context.Context, userID uint, records []*models.PracticeRecord) {
	// 按知识点分组
	kpMap := make(map[uint]struct {
		correctCount  int
		practiceCount int
	})

	for _, record := range records {
		// 需要查询题目获取knowledge_point_id
		question, err := s.questionRepo.FindByID(ctx, record.QuestionID)
		if err != nil {
			continue
		}

		stat := kpMap[question.KnowledgePointID]
		stat.practiceCount++
		if record.IsCorrect {
			stat.correctCount++
		}
		kpMap[question.KnowledgePointID] = stat
	}

	// 更新每个知识点的进度
	for kpID, stat := range kpMap {
		s.updateLearningProgressWithStats(ctx, userID, kpID, stat.correctCount, stat.practiceCount)
	}
}

// updateLearningProgressWithStats 根据统计更新学习进度
func (s *PracticeService) updateLearningProgressWithStats(ctx context.Context, userID, kpID uint, correctCount, practiceCount int) {
	progress, err := s.progressRepo.FindByUserAndKnowledgePoint(ctx, userID, kpID)
	if err != nil {
		now := time.Now()
		progress = &models.LearningProgress{
			UserID:           userID,
			KnowledgePointID: kpID,
			MasteryLevel:     0,
			PracticeCount:    0,
			CorrectCount:     0,
			LastPracticeAt:   &now,
		}
	}

	progress.PracticeCount += practiceCount
	progress.CorrectCount += correctCount
	now := time.Now()
	progress.LastPracticeAt = &now

	// 计算掌握度
	accuracy := float64(progress.CorrectCount) / float64(progress.PracticeCount) * 100
	practiceWeight := 1.0
	if progress.PracticeCount < 5 {
		practiceWeight = float64(progress.PracticeCount) / 5.0
	}
	progress.MasteryLevel = accuracy * practiceWeight

	_ = s.progressRepo.Upsert(ctx, progress)
}

// analyzeKnowledgePoints 分析强项和弱项知识点
func (s *PracticeService) analyzeKnowledgePoints(ctx context.Context, kpAccuracy []map[string]interface{}) ([]string, []string) {
	strongPoints := make([]string, 0)
	weakPoints := make([]string, 0)

	for _, kp := range kpAccuracy {
		accuracy := kp["accuracy"].(float64)
		totalCount := kp["total_count"].(int64)
		kpID := kp["knowledge_point_id"].(uint)

		// 至少练习5次才统计
		if totalCount < 5 {
			continue
		}

		// 获取知识点名称
		kpModel, err := s.kpRepo.FindByID(ctx, kpID)
		if err != nil {
			continue
		}

		if accuracy >= 80 {
			strongPoints = append(strongPoints, kpModel.Name)
		} else if accuracy < 50 {
			weakPoints = append(weakPoints, kpModel.Name)
		}
	}

	return strongPoints, weakPoints
}
