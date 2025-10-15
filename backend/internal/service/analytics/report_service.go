package analytics

import (
	"context"
	"fmt"
	"sort"
	"time"

	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/repository/postgres"
)

// ReportService 学习报告服务
type ReportService struct {
	progressRepo *postgres.LearningProgressRepository
	recordRepo   *postgres.PracticeRecordRepository
	kpRepo       *postgres.KnowledgePointRepository
	chapterRepo  *postgres.ChapterRepository
}

// NewReportService 创建学习报告服务
func NewReportService(
	progressRepo *postgres.LearningProgressRepository,
	recordRepo *postgres.PracticeRecordRepository,
	kpRepo *postgres.KnowledgePointRepository,
	chapterRepo *postgres.ChapterRepository,
) *ReportService {
	return &ReportService{
		progressRepo: progressRepo,
		recordRepo:   recordRepo,
		kpRepo:       kpRepo,
		chapterRepo:  chapterRepo,
	}
}

// GetLearningReport 获取学习报告
func (s *ReportService) GetLearningReport(ctx context.Context, userID uint, req *dto.LearningReportRequest) (*dto.LearningReportResponse, error) {
	// 解析时间范围
	startDate, endDate, err := s.parseDateRange(req)
	if err != nil {
		return nil, err
	}

	// 获取报告概况
	summary, err := s.getReportSummary(ctx, userID, startDate, endDate)
	if err != nil {
		return nil, err
	}

	// 获取练习分析
	practiceAnalysis, err := s.getPracticeAnalysis(ctx, userID, startDate, endDate)
	if err != nil {
		return nil, err
	}

	// 获取知识点分析
	knowledgeAnalysis, err := s.getKnowledgeAnalysis(ctx, userID)
	if err != nil {
		return nil, err
	}

	// 获取进度曲线
	progressCurve, err := s.getProgressCurve(ctx, userID, startDate, endDate)
	if err != nil {
		return nil, err
	}

	// 获取成就列表
	achievements := s.getAchievements(ctx, userID)

	period := req.Period
	if period == "" {
		period = "week"
	}

	return &dto.LearningReportResponse{
		Period:            period,
		StartDate:         startDate.Format("2006-01-02"),
		EndDate:           endDate.Format("2006-01-02"),
		Summary:           summary,
		PracticeAnalysis:  practiceAnalysis,
		KnowledgeAnalysis: knowledgeAnalysis,
		ProgressCurve:     progressCurve,
		Achievements:      achievements,
	}, nil
}

// GetWeakPoints 获取薄弱点
func (s *ReportService) GetWeakPoints(ctx context.Context, userID uint) (*dto.WeakPointsResponse, error) {
	// 获取用户所有学习进度
	progresses, _, err := s.progressRepo.FindByUserID(ctx, userID, 1000, 0)
	if err != nil {
		return nil, err
	}

	weakPoints := make([]dto.KnowledgeMastery, 0)

	for _, progress := range progresses {
		// 薄弱知识点: 掌握度 < 60
		if progress.MasteryLevel < 60 && progress.PracticeCount > 0 {
			kp, err := s.kpRepo.FindByID(ctx, progress.KnowledgePointID)
			if err != nil {
				continue
			}

			chapter, _ := s.chapterRepo.FindByID(ctx, kp.ChapterID)
			chapterName := ""
			if chapter != nil {
				chapterName = chapter.Name
			}

			correctRate := 0.0
			if progress.PracticeCount > 0 {
				correctRate = float64(progress.CorrectCount) / float64(progress.PracticeCount) * 100
			}

			lastPractice := progress.LastPracticeAt.Format("2006-01-02 15:04:05")

			weakPoints = append(weakPoints, dto.KnowledgeMastery{
				KnowledgePointID:   progress.KnowledgePointID,
				KnowledgePointName: kp.Name,
				ChapterName:        chapterName,
				MasteryLevel:       progress.MasteryLevel,
				PracticeCount:      progress.PracticeCount,
				CorrectRate:        correctRate,
				LastPracticeTime:   &lastPractice,
				Trend:              s.calculateTrend(progress),
			})
		}
	}

	// 按掌握度排序
	sort.Slice(weakPoints, func(i, j int) bool {
		return weakPoints[i].MasteryLevel < weakPoints[j].MasteryLevel
	})

	return &dto.WeakPointsResponse{
		WeakPoints: weakPoints,
		Total:      len(weakPoints),
	}, nil
}

// GetProgressOverview 获取进度总览
func (s *ReportService) GetProgressOverview(ctx context.Context, userID uint, grade string) (*dto.ProgressOverviewResponse, error) {
	// 获取章节进度
	chapterProgress, err := s.getChapterProgressByGrade(ctx, userID, grade)
	if err != nil {
		return nil, err
	}

	// 计算整体进度
	totalPoints := 0
	learnedPoints := 0
	for _, cp := range chapterProgress {
		totalPoints += cp.TotalPoints
		learnedPoints += cp.LearnedPoints
	}

	overallProgress := 0.0
	if totalPoints > 0 {
		overallProgress = float64(learnedPoints) / float64(totalPoints) * 100
	}

	// 获取最近活动
	recentActivity, err := s.getRecentActivity(ctx, userID, 7)
	if err != nil {
		return nil, err
	}

	// 获取下一步推荐
	recommendations, err := s.getNextRecommendations(ctx, userID, grade)
	if err != nil {
		return nil, err
	}

	return &dto.ProgressOverviewResponse{
		OverallProgress:     overallProgress,
		Grade:               grade,
		ChapterProgress:     chapterProgress,
		RecentActivity:      recentActivity,
		NextRecommendations: recommendations,
	}, nil
}

// GetLearningStatistics 获取学习统计
func (s *ReportService) GetLearningStatistics(ctx context.Context, userID uint) (*dto.LearningStatisticsResponse, error) {
	now := time.Now()

	// 今日统计
	daily, err := s.getDailyStatistics(ctx, userID, now)
	if err != nil {
		return nil, err
	}

	// 本周统计
	weekly, err := s.getWeeklyStatistics(ctx, userID, now)
	if err != nil {
		return nil, err
	}

	// 本月统计
	monthly, err := s.getMonthlyStatistics(ctx, userID, now)
	if err != nil {
		return nil, err
	}

	// 总计统计
	total, err := s.getTotalStatistics(ctx, userID)
	if err != nil {
		return nil, err
	}

	return &dto.LearningStatisticsResponse{
		Daily:   daily,
		Weekly:  weekly,
		Monthly: monthly,
		Total:   total,
	}, nil
}

// parseDateRange 解析日期范围
func (s *ReportService) parseDateRange(req *dto.LearningReportRequest) (time.Time, time.Time, error) {
	now := time.Now()
	var startDate, endDate time.Time

	if req.StartDate != "" && req.EndDate != "" {
		var err error
		startDate, err = time.Parse("2006-01-02", req.StartDate)
		if err != nil {
			return time.Time{}, time.Time{}, fmt.Errorf("invalid start_date format")
		}
		endDate, err = time.Parse("2006-01-02", req.EndDate)
		if err != nil {
			return time.Time{}, time.Time{}, fmt.Errorf("invalid end_date format")
		}
	} else {
		// 根据period自动计算
		period := req.Period
		if period == "" {
			period = "week"
		}

		endDate = now
		switch period {
		case "day":
			startDate = now.AddDate(0, 0, -1)
		case "week":
			startDate = now.AddDate(0, 0, -7)
		case "month":
			startDate = now.AddDate(0, -1, 0)
		default:
			startDate = now.AddDate(0, 0, -7)
		}
	}

	return startDate, endDate, nil
}

// getReportSummary 获取报告概况
func (s *ReportService) getReportSummary(ctx context.Context, userID uint, startDate, endDate time.Time) (*dto.ReportSummary, error) {
	// 获取时间范围内的练习记录
	records, err := s.recordRepo.FindByDateRange(ctx, userID, startDate, endDate)
	if err != nil {
		return nil, err
	}

	totalPractice := len(records)
	totalCorrect := 0
	studyDays := make(map[string]bool)

	for _, record := range records {
		if record.IsCorrect {
			totalCorrect++
		}
		dateKey := record.CreatedAt.Format("2006-01-02")
		studyDays[dateKey] = true
	}

	accuracy := 0.0
	if totalPractice > 0 {
		accuracy = float64(totalCorrect) / float64(totalPractice) * 100
	}

	// 获取知识点统计
	progresses, _, err := s.progressRepo.FindByUserID(ctx, userID, 1000, 0)
	if err != nil {
		return nil, err
	}

	knowledgePoints := len(progresses)
	masteredPoints := 0
	weakPoints := 0

	for _, progress := range progresses {
		if progress.MasteryLevel >= 80 {
			masteredPoints++
		} else if progress.MasteryLevel < 60 {
			weakPoints++
		}
	}

	return &dto.ReportSummary{
		TotalStudyDays:  len(studyDays),
		TotalStudyTime:  0, // TODO: 实现学习时长统计
		TotalPractice:   totalPractice,
		TotalCorrect:    totalCorrect,
		AverageAccuracy: accuracy,
		KnowledgePoints: knowledgePoints,
		MasteredPoints:  masteredPoints,
		WeakPoints:      weakPoints,
	}, nil
}

// getPracticeAnalysis 获取练习分析
func (s *ReportService) getPracticeAnalysis(ctx context.Context, userID uint, startDate, endDate time.Time) (*dto.PracticeAnalysis, error) {
	records, err := s.recordRepo.FindByDateRange(ctx, userID, startDate, endDate)
	if err != nil {
		return nil, err
	}

	days := endDate.Sub(startDate).Hours() / 24
	dailyAverage := 0.0
	if days > 0 {
		dailyAverage = float64(len(records)) / days
	}

	// 统计题型分布
	typeDistribution := make(map[string]int)
	difficultyDistribution := make(map[string]int)
	weekdayDistribution := make(map[string]int)
	hourDistribution := make(map[int]int)

	for _, record := range records {
		// TODO: 需要join question表获取题型和难度
		// 暂时使用模拟数据
		weekday := record.CreatedAt.Weekday().String()
		weekdayDistribution[weekday]++

		hour := record.CreatedAt.Hour()
		hourDistribution[hour]++
	}

	// 找出高峰时段
	peakHours := s.findPeakHours(hourDistribution, 3)

	// 计算正确率趋势
	accuracyTrend := s.calculateAccuracyTrend(records, startDate, endDate)

	return &dto.PracticeAnalysis{
		DailyAverage:           dailyAverage,
		PeakHours:              peakHours,
		TypeDistribution:       typeDistribution,
		DifficultyDistribution: difficultyDistribution,
		AccuracyTrend:          accuracyTrend,
		WeekdayDistribution:    weekdayDistribution,
	}, nil
}

// getKnowledgeAnalysis 获取知识点分析
func (s *ReportService) getKnowledgeAnalysis(ctx context.Context, userID uint) (*dto.KnowledgeAnalysis, error) {
	progresses, _, err := s.progressRepo.FindByUserID(ctx, userID, 1000, 0)
	if err != nil {
		return nil, err
	}

	masteredPoints := make([]dto.KnowledgeMastery, 0)
	learningPoints := make([]dto.KnowledgeMastery, 0)
	weakPoints := make([]dto.KnowledgeMastery, 0)

	for _, progress := range progresses {
		kp, err := s.kpRepo.FindByID(ctx, progress.KnowledgePointID)
		if err != nil {
			continue
		}

		chapter, _ := s.chapterRepo.FindByID(ctx, kp.ChapterID)
		chapterName := ""
		if chapter != nil {
			chapterName = chapter.Name
		}

		correctRate := 0.0
		if progress.PracticeCount > 0 {
			correctRate = float64(progress.CorrectCount) / float64(progress.PracticeCount) * 100
		}

		lastPractice := progress.LastPracticeAt.Format("2006-01-02 15:04:05")

		mastery := dto.KnowledgeMastery{
			KnowledgePointID:   progress.KnowledgePointID,
			KnowledgePointName: kp.Name,
			ChapterName:        chapterName,
			MasteryLevel:       progress.MasteryLevel,
			PracticeCount:      progress.PracticeCount,
			CorrectRate:        correctRate,
			LastPracticeTime:   &lastPractice,
			Trend:              s.calculateTrend(progress),
		}

		if progress.MasteryLevel >= 80 {
			masteredPoints = append(masteredPoints, mastery)
		} else if progress.MasteryLevel >= 50 {
			learningPoints = append(learningPoints, mastery)
		} else {
			weakPoints = append(weakPoints, mastery)
		}
	}

	// 获取章节进度
	chapterProgress, _ := s.getChapterProgressByGrade(ctx, userID, "")

	return &dto.KnowledgeAnalysis{
		MasteredPoints:    masteredPoints,
		LearningPoints:    learningPoints,
		WeakPoints:        weakPoints,
		RecommendedPoints: []dto.KnowledgeMastery{}, // TODO: 实现推荐算法
		ChapterProgress:   chapterProgress,
	}, nil
}

// getProgressCurve 获取进度曲线
func (s *ReportService) getProgressCurve(ctx context.Context, userID uint, startDate, endDate time.Time) ([]dto.ProgressPoint, error) {
	records, err := s.recordRepo.FindByDateRange(ctx, userID, startDate, endDate)
	if err != nil {
		return nil, err
	}

	// 按日期分组
	dailyMap := make(map[string]*dto.ProgressPoint)

	for _, record := range records {
		dateKey := record.CreatedAt.Format("2006-01-02")
		if _, exists := dailyMap[dateKey]; !exists {
			dailyMap[dateKey] = &dto.ProgressPoint{
				Date:          dateKey,
				PracticeCount: 0,
				CorrectCount:  0,
				StudyTime:     0,
			}
		}

		dailyMap[dateKey].PracticeCount++
		if record.IsCorrect {
			dailyMap[dateKey].CorrectCount++
		}
	}

	// 转换为数组并排序
	curve := make([]dto.ProgressPoint, 0)
	for _, point := range dailyMap {
		if point.PracticeCount > 0 {
			point.Accuracy = float64(point.CorrectCount) / float64(point.PracticeCount) * 100
		}
		curve = append(curve, *point)
	}

	sort.Slice(curve, func(i, j int) bool {
		return curve[i].Date < curve[j].Date
	})

	return curve, nil
}

// getAchievements 获取成就列表
func (s *ReportService) getAchievements(ctx context.Context, userID uint) []dto.Achievement {
	// TODO: 实现成就系统
	return []dto.Achievement{}
}

// getDailyStatistics 获取今日统计
func (s *ReportService) getDailyStatistics(ctx context.Context, userID uint, date time.Time) (*dto.DailyStatistics, error) {
	startOfDay := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, date.Location())
	endOfDay := startOfDay.Add(24 * time.Hour)

	records, err := s.recordRepo.FindByDateRange(ctx, userID, startOfDay, endOfDay)
	if err != nil {
		return nil, err
	}

	practiceCount := len(records)
	correctCount := 0
	for _, record := range records {
		if record.IsCorrect {
			correctCount++
		}
	}

	accuracy := 0.0
	if practiceCount > 0 {
		accuracy = float64(correctCount) / float64(practiceCount) * 100
	}

	return &dto.DailyStatistics{
		Date:          date.Format("2006-01-02"),
		PracticeCount: practiceCount,
		CorrectCount:  correctCount,
		Accuracy:      accuracy,
		StudyTime:     0, // TODO: 实现学习时长统计
		NewKnowledge:  0, // TODO: 统计新学知识点
	}, nil
}

// getWeeklyStatistics 获取本周统计
func (s *ReportService) getWeeklyStatistics(ctx context.Context, userID uint, date time.Time) (*dto.WeeklyStatistics, error) {
	// 获取本周一
	weekday := int(date.Weekday())
	if weekday == 0 {
		weekday = 7
	}
	startOfWeek := date.AddDate(0, 0, -(weekday - 1))
	startOfWeek = time.Date(startOfWeek.Year(), startOfWeek.Month(), startOfWeek.Day(), 0, 0, 0, 0, startOfWeek.Location())
	endOfWeek := startOfWeek.AddDate(0, 0, 7)

	records, err := s.recordRepo.FindByDateRange(ctx, userID, startOfWeek, endOfWeek)
	if err != nil {
		return nil, err
	}

	practiceCount := len(records)
	correctCount := 0
	studyDays := make(map[string]bool)

	for _, record := range records {
		if record.IsCorrect {
			correctCount++
		}
		dateKey := record.CreatedAt.Format("2006-01-02")
		studyDays[dateKey] = true
	}

	accuracy := 0.0
	if practiceCount > 0 {
		accuracy = float64(correctCount) / float64(practiceCount) * 100
	}

	dailyAverage := 0.0
	if len(studyDays) > 0 {
		dailyAverage = float64(practiceCount) / float64(len(studyDays))
	}

	return &dto.WeeklyStatistics{
		StartDate:     startOfWeek.Format("2006-01-02"),
		EndDate:       endOfWeek.Format("2006-01-02"),
		PracticeCount: practiceCount,
		CorrectCount:  correctCount,
		Accuracy:      accuracy,
		StudyDays:     len(studyDays),
		TotalTime:     0, // TODO
		DailyAverage:  dailyAverage,
	}, nil
}

// getMonthlyStatistics 获取本月统计
func (s *ReportService) getMonthlyStatistics(ctx context.Context, userID uint, date time.Time) (*dto.MonthlyStatistics, error) {
	startOfMonth := time.Date(date.Year(), date.Month(), 1, 0, 0, 0, 0, date.Location())
	endOfMonth := startOfMonth.AddDate(0, 1, 0)

	records, err := s.recordRepo.FindByDateRange(ctx, userID, startOfMonth, endOfMonth)
	if err != nil {
		return nil, err
	}

	practiceCount := len(records)
	correctCount := 0
	studyDays := make(map[string]bool)

	for _, record := range records {
		if record.IsCorrect {
			correctCount++
		}
		dateKey := record.CreatedAt.Format("2006-01-02")
		studyDays[dateKey] = true
	}

	accuracy := 0.0
	if practiceCount > 0 {
		accuracy = float64(correctCount) / float64(practiceCount) * 100
	}

	return &dto.MonthlyStatistics{
		Year:          date.Year(),
		Month:         int(date.Month()),
		PracticeCount: practiceCount,
		CorrectCount:  correctCount,
		Accuracy:      accuracy,
		StudyDays:     len(studyDays),
		TotalTime:     0, // TODO
		Improvement:   0, // TODO: 计算较上月提升
	}, nil
}

// getTotalStatistics 获取总计统计
func (s *ReportService) getTotalStatistics(ctx context.Context, userID uint) (*dto.TotalStatistics, error) {
	stats, err := s.recordRepo.GetStatistics(ctx, userID)
	if err != nil {
		return nil, err
	}

	totalPractice := stats["total_practice"].(int)
	totalCorrect := stats["total_correct"].(int)
	totalWrong := stats["total_wrong"].(int)
	accuracy := stats["accuracy"].(float64)

	// TODO: 实现连续学习天数统计
	longestStreak := 0
	currentStreak := 0

	return &dto.TotalStatistics{
		TotalPractice:  totalPractice,
		TotalCorrect:   totalCorrect,
		TotalWrong:     totalWrong,
		Accuracy:       accuracy,
		TotalStudyDays: 0, // TODO
		TotalStudyTime: 0, // TODO
		LongestStreak:  longestStreak,
		CurrentStreak:  currentStreak,
	}, nil
}

// getChapterProgressByGrade 获取章节进度
func (s *ReportService) getChapterProgressByGrade(ctx context.Context, userID uint, grade string) ([]dto.ChapterProgress, error) {
	// 获取章节列表
	chapters, err := s.chapterRepo.FindByGrade(ctx, grade)
	if err != nil {
		return nil, err
	}

	result := make([]dto.ChapterProgress, 0)

	for _, chapter := range chapters {
		// 获取章节统计
		stats, err := s.progressRepo.GetMasteryStatsByChapter(ctx, userID, chapter.ID)
		if err != nil {
			continue
		}

		totalKPs := stats["total_kps"].(int64)
		masteredKPs := stats["mastered_kps"].(int64)
		learningKPs := stats["learning_kps"].(int64)
		avgMastery := stats["avg_mastery"].(float64)

		learnedPoints := int(masteredKPs + learningKPs)
		completionRate := 0.0
		if totalKPs > 0 {
			completionRate = float64(learnedPoints) / float64(totalKPs) * 100
		}

		result = append(result, dto.ChapterProgress{
			ChapterID:      chapter.ID,
			ChapterName:    chapter.Name,
			TotalPoints:    int(totalKPs),
			LearnedPoints:  learnedPoints,
			MasteredPoints: int(masteredKPs),
			AverageMastery: avgMastery,
			CompletionRate: completionRate,
		})
	}

	return result, nil
}

// getRecentActivity 获取最近活动
func (s *ReportService) getRecentActivity(ctx context.Context, userID uint, days int) ([]dto.ActivityRecord, error) {
	startDate := time.Now().AddDate(0, 0, -days)
	records, err := s.recordRepo.FindByDateRange(ctx, userID, startDate, time.Now())
	if err != nil {
		return nil, err
	}

	// 按日期分组
	dailyMap := make(map[string]int)
	for _, record := range records {
		dateKey := record.CreatedAt.Format("2006-01-02")
		dailyMap[dateKey]++
	}

	activities := make([]dto.ActivityRecord, 0)
	for date, count := range dailyMap {
		activities = append(activities, dto.ActivityRecord{
			Date:        date,
			Type:        "practice",
			Description: fmt.Sprintf("完成 %d 道练习题", count),
			Count:       count,
		})
	}

	// 排序
	sort.Slice(activities, func(i, j int) bool {
		return activities[i].Date > activities[j].Date
	})

	return activities, nil
}

// getNextRecommendations 获取下一步推荐
func (s *ReportService) getNextRecommendations(ctx context.Context, userID uint, grade string) ([]dto.KnowledgeMastery, error) {
	// TODO: 实现推荐算法
	// 1. 找出薄弱知识点
	// 2. 找出未学习的知识点
	// 3. 基于学习路径推荐
	return []dto.KnowledgeMastery{}, nil
}

// calculateTrend 计算趋势
func (s *ReportService) calculateTrend(progress interface{}) string {
	// TODO: 基于历史数据计算趋势
	return "stable"
}

// findPeakHours 找出高峰时段
func (s *ReportService) findPeakHours(hourDistribution map[int]int, topN int) []int {
	type hourCount struct {
		hour  int
		count int
	}

	hours := make([]hourCount, 0)
	for hour, count := range hourDistribution {
		hours = append(hours, hourCount{hour, count})
	}

	sort.Slice(hours, func(i, j int) bool {
		return hours[i].count > hours[j].count
	})

	result := make([]int, 0)
	for i := 0; i < topN && i < len(hours); i++ {
		result = append(result, hours[i].hour)
	}

	return result
}

// calculateAccuracyTrend 计算正确率趋势
func (s *ReportService) calculateAccuracyTrend(records interface{}, startDate, endDate time.Time) []dto.AccuracyPoint {
	// TODO: 实现正确率趋势计算
	return []dto.AccuracyPoint{}
}
