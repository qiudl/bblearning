package dto

import "time"

// LearningReportRequest 学习报告请求
type LearningReportRequest struct {
	StartDate string `form:"start_date"` // 开始日期 YYYY-MM-DD
	EndDate   string `form:"end_date"`   // 结束日期 YYYY-MM-DD
	Period    string `form:"period" binding:"omitempty,oneof=day week month"` // 统计周期
}

// LearningReportResponse 学习报告响应
type LearningReportResponse struct {
	Period           string                    `json:"period"`            // 统计周期
	StartDate        string                    `json:"start_date"`        // 开始日期
	EndDate          string                    `json:"end_date"`          // 结束日期
	Summary          *ReportSummary            `json:"summary"`           // 总体概况
	PracticeAnalysis *PracticeAnalysis         `json:"practice_analysis"` // 练习分析
	KnowledgeAnalysis *KnowledgeAnalysis       `json:"knowledge_analysis"` // 知识点分析
	ProgressCurve    []ProgressPoint           `json:"progress_curve"`    // 进度曲线
	Achievements     []Achievement             `json:"achievements"`      // 成就列表
}

// ReportSummary 报告概况
type ReportSummary struct {
	TotalStudyDays    int     `json:"total_study_days"`    // 总学习天数
	TotalStudyTime    int     `json:"total_study_time"`    // 总学习时长(分钟)
	TotalPractice     int     `json:"total_practice"`      // 总练习题数
	TotalCorrect      int     `json:"total_correct"`       // 总正确题数
	AverageAccuracy   float64 `json:"average_accuracy"`    // 平均正确率
	KnowledgePoints   int     `json:"knowledge_points"`    // 已学知识点数
	MasteredPoints    int     `json:"mastered_points"`     // 已掌握知识点数
	WeakPoints        int     `json:"weak_points"`         // 薄弱知识点数
	Rank              *int    `json:"rank,omitempty"`      // 排名(可选)
	BeatPercentage    *float64 `json:"beat_percentage,omitempty"` // 超越百分比(可选)
}

// PracticeAnalysis 练习分析
type PracticeAnalysis struct {
	DailyAverage      float64                `json:"daily_average"`      // 日均练习量
	PeakHours         []int                  `json:"peak_hours"`         // 高峰时段(小时)
	TypeDistribution  map[string]int         `json:"type_distribution"`  // 题型分布
	DifficultyDistribution map[string]int    `json:"difficulty_distribution"` // 难度分布
	AccuracyTrend     []AccuracyPoint        `json:"accuracy_trend"`     // 正确率趋势
	WeekdayDistribution map[string]int       `json:"weekday_distribution"` // 星期分布
}

// KnowledgeAnalysis 知识点分析
type KnowledgeAnalysis struct {
	MasteredPoints   []KnowledgeMastery     `json:"mastered_points"`   // 已掌握知识点
	LearningPoints   []KnowledgeMastery     `json:"learning_points"`   // 学习中知识点
	WeakPoints       []KnowledgeMastery     `json:"weak_points"`       // 薄弱知识点
	RecommendedPoints []KnowledgeMastery    `json:"recommended_points"` // 推荐学习
	ChapterProgress  []ChapterProgress      `json:"chapter_progress"`  // 章节进度
}

// KnowledgeMastery 知识点掌握情况
type KnowledgeMastery struct {
	KnowledgePointID   uint    `json:"knowledge_point_id"`
	KnowledgePointName string  `json:"knowledge_point_name"`
	ChapterName        string  `json:"chapter_name"`
	MasteryLevel       float64 `json:"mastery_level"`       // 掌握程度 0-100
	PracticeCount      int     `json:"practice_count"`      // 练习次数
	CorrectRate        float64 `json:"correct_rate"`        // 正确率
	LastPracticeTime   *string `json:"last_practice_time"`  // 最后练习时间
	Trend              string  `json:"trend"`               // 趋势: up/down/stable
}

// ChapterProgress 章节进度
type ChapterProgress struct {
	ChapterID        uint    `json:"chapter_id"`
	ChapterName      string  `json:"chapter_name"`
	TotalPoints      int     `json:"total_points"`        // 总知识点数
	LearnedPoints    int     `json:"learned_points"`      // 已学习知识点数
	MasteredPoints   int     `json:"mastered_points"`     // 已掌握知识点数
	AverageMastery   float64 `json:"average_mastery"`     // 平均掌握度
	CompletionRate   float64 `json:"completion_rate"`     // 完成率
}

// ProgressPoint 进度点
type ProgressPoint struct {
	Date        string  `json:"date"`        // 日期
	PracticeCount int   `json:"practice_count"` // 练习数量
	CorrectCount  int   `json:"correct_count"`  // 正确数量
	Accuracy    float64 `json:"accuracy"`    // 正确率
	StudyTime   int     `json:"study_time"`  // 学习时长(分钟)
}

// AccuracyPoint 正确率点
type AccuracyPoint struct {
	Date     string  `json:"date"`
	Accuracy float64 `json:"accuracy"`
}

// Achievement 成就
type Achievement struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Icon        string    `json:"icon"`
	UnlockedAt  time.Time `json:"unlocked_at"`
	Category    string    `json:"category"` // practice/knowledge/streak/milestone
}

// WeakPointsResponse 薄弱点分析响应
type WeakPointsResponse struct {
	WeakPoints []KnowledgeMastery `json:"weak_points"`
	Total      int                `json:"total"`
}

// ProgressOverviewResponse 进度总览响应
type ProgressOverviewResponse struct {
	OverallProgress  float64           `json:"overall_progress"`   // 整体进度
	Grade            string            `json:"grade"`              // 年级
	ChapterProgress  []ChapterProgress `json:"chapter_progress"`   // 章节进度
	RecentActivity   []ActivityRecord  `json:"recent_activity"`    // 最近活动
	NextRecommendations []KnowledgeMastery `json:"next_recommendations"` // 下一步推荐
}

// ActivityRecord 活动记录
type ActivityRecord struct {
	Date        string `json:"date"`
	Type        string `json:"type"`        // practice/learn/review
	Description string `json:"description"`
	Count       int    `json:"count"`
}

// LearningStatisticsResponse 学习统计响应
type LearningStatisticsResponse struct {
	Daily   *DailyStatistics   `json:"daily"`   // 今日统计
	Weekly  *WeeklyStatistics  `json:"weekly"`  // 本周统计
	Monthly *MonthlyStatistics `json:"monthly"` // 本月统计
	Total   *TotalStatistics   `json:"total"`   // 总计统计
}

// DailyStatistics 今日统计
type DailyStatistics struct {
	Date          string  `json:"date"`
	PracticeCount int     `json:"practice_count"`
	CorrectCount  int     `json:"correct_count"`
	Accuracy      float64 `json:"accuracy"`
	StudyTime     int     `json:"study_time"` // 分钟
	NewKnowledge  int     `json:"new_knowledge"` // 新学知识点数
}

// WeeklyStatistics 本周统计
type WeeklyStatistics struct {
	StartDate     string  `json:"start_date"`
	EndDate       string  `json:"end_date"`
	PracticeCount int     `json:"practice_count"`
	CorrectCount  int     `json:"correct_count"`
	Accuracy      float64 `json:"accuracy"`
	StudyDays     int     `json:"study_days"`
	TotalTime     int     `json:"total_time"` // 分钟
	DailyAverage  float64 `json:"daily_average"` // 日均练习
}

// MonthlyStatistics 本月统计
type MonthlyStatistics struct {
	Year          int     `json:"year"`
	Month         int     `json:"month"`
	PracticeCount int     `json:"practice_count"`
	CorrectCount  int     `json:"correct_count"`
	Accuracy      float64 `json:"accuracy"`
	StudyDays     int     `json:"study_days"`
	TotalTime     int     `json:"total_time"`
	Improvement   float64 `json:"improvement"` // 较上月提升百分比
}

// TotalStatistics 总计统计
type TotalStatistics struct {
	TotalPractice   int     `json:"total_practice"`
	TotalCorrect    int     `json:"total_correct"`
	TotalWrong      int     `json:"total_wrong"`
	Accuracy        float64 `json:"accuracy"`
	TotalStudyDays  int     `json:"total_study_days"`
	TotalStudyTime  int     `json:"total_study_time"` // 分钟
	LongestStreak   int     `json:"longest_streak"`   // 最长连续学习天数
	CurrentStreak   int     `json:"current_streak"`   // 当前连续学习天数
}
