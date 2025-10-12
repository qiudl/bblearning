package dto

// QuestionListRequest 题目列表请求
type QuestionListRequest struct {
	KnowledgePointID *uint  `form:"knowledge_point_id"`
	Type             string `form:"type" binding:"omitempty,oneof=choice fill answer"`
	Difficulty       string `form:"difficulty" binding:"omitempty,oneof=basic medium advanced"`
	Page             int    `form:"page" binding:"min=1"`
	PageSize         int    `form:"page_size" binding:"min=1,max=100"`
}

// QuestionInfo 题目信息
type QuestionInfo struct {
	ID               uint     `json:"id"`
	KnowledgePointID uint     `json:"knowledge_point_id"`
	KnowledgePoint   string   `json:"knowledge_point_name,omitempty"`
	Type             string   `json:"type"`
	Content          string   `json:"content"`
	Options          []string `json:"options,omitempty"`
	Answer           string   `json:"answer,omitempty"` // 不返回给学生
	Explanation      string   `json:"explanation,omitempty"`
	Difficulty       string   `json:"difficulty"`
}

// QuestionListResponse 题目列表响应
type QuestionListResponse struct {
	Items []*QuestionInfo `json:"items"`
	Total int64           `json:"total"`
	Page  int             `json:"page"`
	Size  int             `json:"size"`
}

// GeneratePracticeRequest 生成练习请求
type GeneratePracticeRequest struct {
	KnowledgePointID uint   `json:"knowledge_point_id" binding:"required"`
	Count            int    `json:"count" binding:"required,min=1,max=50"`
	Difficulty       string `json:"difficulty" binding:"omitempty,oneof=basic medium advanced"`
	Type             string `json:"type" binding:"omitempty,oneof=choice fill answer"`
}

// GeneratePracticeResponse 生成练习响应
type GeneratePracticeResponse struct {
	Questions []*QuestionInfo `json:"questions"`
	Count     int             `json:"count"`
}

// SubmitAnswerRequest 提交答案请求
type SubmitAnswerRequest struct {
	QuestionID uint   `json:"question_id" binding:"required"`
	UserAnswer string `json:"user_answer" binding:"required"`
}

// SubmitAnswerResponse 提交答案响应
type SubmitAnswerResponse struct {
	QuestionID  uint   `json:"question_id"`
	UserAnswer  string `json:"user_answer"`
	IsCorrect   bool   `json:"is_correct"`
	Answer      string `json:"answer"`
	Explanation string `json:"explanation"`
	RecordID    uint   `json:"record_id"` // 练习记录ID
}

// BatchSubmitRequest 批量提交答案请求
type BatchSubmitRequest struct {
	Answers []SubmitAnswerRequest `json:"answers" binding:"required,dive"`
}

// BatchSubmitResponse 批量提交答案响应
type BatchSubmitResponse struct {
	Results      []*SubmitAnswerResponse `json:"results"`
	TotalCount   int                     `json:"total_count"`
	CorrectCount int                     `json:"correct_count"`
	Accuracy     float64                 `json:"accuracy"`
}

// PracticeRecordInfo 练习记录信息
type PracticeRecordInfo struct {
	ID         uint          `json:"id"`
	UserID     uint          `json:"user_id"`
	QuestionID uint          `json:"question_id"`
	Question   *QuestionInfo `json:"question,omitempty"`
	UserAnswer string        `json:"user_answer"`
	IsCorrect  bool          `json:"is_correct"`
	Timestamp  string        `json:"timestamp"`
}

// PracticeRecordListRequest 练习记录列表请求
type PracticeRecordListRequest struct {
	KnowledgePointID *uint  `form:"knowledge_point_id"`
	IsCorrect        *bool  `form:"is_correct"`
	StartDate        string `form:"start_date"`
	EndDate          string `form:"end_date"`
	Page             int    `form:"page" binding:"min=1"`
	PageSize         int    `form:"page_size" binding:"min=1,max=100"`
}

// PracticeRecordListResponse 练习记录列表响应
type PracticeRecordListResponse struct {
	Items []*PracticeRecordInfo `json:"items"`
	Total int64                 `json:"total"`
	Page  int                   `json:"page"`
	Size  int                   `json:"size"`
}

// PracticeStatistics 练习统计
type PracticeStatistics struct {
	TotalPractice   int     `json:"total_practice"`
	TotalCorrect    int     `json:"total_correct"`
	TotalWrong      int     `json:"total_wrong"`
	Accuracy        float64 `json:"accuracy"`
	TodayPractice   int     `json:"today_practice"`
	WeekPractice    int     `json:"week_practice"`
	LastPracticeAt  *string `json:"last_practice_at"`
	StrongPoints    []string `json:"strong_points,omitempty"`    // 擅长的知识点
	WeakPoints      []string `json:"weak_points,omitempty"`      // 薄弱的知识点
}

// WrongQuestionInfo 错题信息
type WrongQuestionInfo struct {
	ID            uint          `json:"id"`
	UserID        uint          `json:"user_id"`
	QuestionID    uint          `json:"question_id"`
	Question      *QuestionInfo `json:"question,omitempty"`
	WrongCount    int           `json:"wrong_count"`
	LastWrongTime string        `json:"last_wrong_time"`
	CreatedAt     string        `json:"created_at"`
}

// WrongQuestionListRequest 错题列表请求
type WrongQuestionListRequest struct {
	KnowledgePointID *uint  `form:"knowledge_point_id"`
	Difficulty       string `form:"difficulty" binding:"omitempty,oneof=basic medium advanced"`
	Page             int    `form:"page" binding:"min=1"`
	PageSize         int    `form:"page_size" binding:"min=1,max=100"`
}

// WrongQuestionListResponse 错题列表响应
type WrongQuestionListResponse struct {
	Items []*WrongQuestionInfo `json:"items"`
	Total int64                `json:"total"`
	Page  int                  `json:"page"`
	Size  int                  `json:"size"`
}

// ToQuestionInfo 将Question模型转换为QuestionInfo
func ToQuestionInfo(q interface{}, includeAnswer bool) *QuestionInfo {
	// TODO: 实现转换逻辑
	return nil
}

// ToPracticeRecordInfo 将PracticeRecord模型转换为PracticeRecordInfo
func ToPracticeRecordInfo(r interface{}) *PracticeRecordInfo {
	// TODO: 实现转换逻辑
	return nil
}

// ToWrongQuestionInfo 将WrongQuestion模型转换为WrongQuestionInfo
func ToWrongQuestionInfo(wq interface{}) *WrongQuestionInfo {
	// TODO: 实现转换逻辑
	return nil
}
