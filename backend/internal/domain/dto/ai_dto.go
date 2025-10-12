package dto

// AIGenerateQuestionRequest AI生成题目请求
type AIGenerateQuestionRequest struct {
	KnowledgePointID uint   `json:"knowledge_point_id" binding:"required"`
	Difficulty       string `json:"difficulty" binding:"required,oneof=basic medium advanced"`
	Type             string `json:"type" binding:"required,oneof=choice fill answer"`
	Count            int    `json:"count" binding:"required,min=1,max=10"`
}

// AIGenerateQuestionResponse AI生成题目响应
type AIGenerateQuestionResponse struct {
	Questions []*QuestionInfo `json:"questions"`
	Count     int             `json:"count"`
}

// AIGradeAnswerRequest AI批改答案请求
type AIGradeAnswerRequest struct {
	QuestionID     uint   `json:"question_id" binding:"required"`
	QuestionContent string `json:"question_content" binding:"required"`
	StandardAnswer string `json:"standard_answer" binding:"required"`
	UserAnswer     string `json:"user_answer" binding:"required"`
}

// AIGradeAnswerResponse AI批改答案响应
type AIGradeAnswerResponse struct {
	IsCorrect   bool    `json:"is_correct"`
	Score       float64 `json:"score"`        // 0-100分
	Feedback    string  `json:"feedback"`     // AI批改意见
	Suggestion  string  `json:"suggestion"`   // 改进建议
	KeyPoints   []string `json:"key_points"`  // 答题要点
}

// AIChatRequest AI对话请求
type AIChatRequest struct {
	Message    string `json:"message" binding:"required"`
	QuestionID *uint  `json:"question_id"` // 可选,关联具体题目
}

// AIChatResponse AI对话响应
type AIChatResponse struct {
	Reply          string `json:"reply"`
	ConversationID uint   `json:"conversation_id"`
}

// AIDiagnoseRequest AI学习诊断请求
type AIDiagnoseRequest struct {
	KnowledgePointID *uint `json:"knowledge_point_id"` // 可选,诊断特定知识点
}

// AIDiagnoseResponse AI学习诊断响应
type AIDiagnoseResponse struct {
	OverallLevel    string              `json:"overall_level"`    // 整体水平: beginner/intermediate/advanced
	WeakPoints      []WeakPointAnalysis `json:"weak_points"`      // 薄弱知识点
	Recommendations []string            `json:"recommendations"`  // 学习建议
	NextSteps       []string            `json:"next_steps"`       // 下一步行动
}

// WeakPointAnalysis 薄弱点分析
type WeakPointAnalysis struct {
	KnowledgePointID uint    `json:"knowledge_point_id"`
	KnowledgePoint   string  `json:"knowledge_point"`
	MasteryLevel     float64 `json:"mastery_level"`
	ErrorRate        float64 `json:"error_rate"`
	CommonMistakes   []string `json:"common_mistakes"`
	PracticeSuggestion string `json:"practice_suggestion"`
}

// AIExplainRequest AI解题讲解请求
type AIExplainRequest struct {
	QuestionID uint   `json:"question_id" binding:"required"`
	UserAnswer string `json:"user_answer"` // 可选,用户的答案
}

// AIExplainResponse AI解题讲解响应
type AIExplainResponse struct {
	Explanation    string   `json:"explanation"`     // 详细讲解
	Steps          []string `json:"steps"`           // 解题步骤
	KeyConcepts    []string `json:"key_concepts"`    // 关键概念
	SimilarQuestions []uint `json:"similar_questions"` // 相似题目ID
}
