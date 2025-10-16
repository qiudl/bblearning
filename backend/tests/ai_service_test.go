package tests

import (
	"testing"

	"github.com/qiudl/bblearning-backend/internal/service/ai"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestAIGenerateQuestion 测试AI生成题目
func TestAIGenerateQuestion(t *testing.T) {
	service := ai.NewAIService()

	tests := []struct {
		name           string
		knowledgePoint string
		difficulty     string
		questionType   string
		count          int
		expectError    bool
	}{
		{
			name:           "生成基础选择题",
			knowledgePoint: "一元一次方程",
			difficulty:     "basic",
			questionType:   "choice",
			count:          2,
			expectError:    false,
		},
		{
			name:           "生成中等难度填空题",
			knowledgePoint: "二次函数",
			difficulty:     "medium",
			questionType:   "fill",
			count:          3,
			expectError:    false,
		},
		{
			name:           "生成高难度解答题",
			knowledgePoint: "几何证明",
			difficulty:     "advanced",
			questionType:   "answer",
			count:          1,
			expectError:    false,
		},
		{
			name:           "无效的题目类型",
			knowledgePoint: "一元一次方程",
			difficulty:     "basic",
			questionType:   "invalid",
			count:          1,
			expectError:    true,
		},
		{
			name:           "题目数量过多",
			knowledgePoint: "一元一次方程",
			difficulty:     "basic",
			questionType:   "choice",
			count:          50,
			expectError:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := &ai.GenerateQuestionRequest{
				KnowledgePoint: tt.knowledgePoint,
				Difficulty:     tt.difficulty,
				Type:           tt.questionType,
				Count:          tt.count,
			}

			resp, err := service.GenerateQuestions(req)

			if tt.expectError {
				assert.Error(t, err)
			} else {
				require.NoError(t, err)
				assert.NotNil(t, resp)
				assert.Equal(t, tt.count, len(resp.Questions))

				// 验证每个题目的结构
				for _, q := range resp.Questions {
					assert.NotEmpty(t, q.Content)
					assert.NotEmpty(t, q.Answer)
					assert.Equal(t, tt.questionType, q.Type)
					assert.Equal(t, tt.difficulty, q.Difficulty)
				}
			}
		})
	}
}

// TestAIGradeAnswer 测试AI批改答案
func TestAIGradeAnswer(t *testing.T) {
	service := ai.NewAIService()

	tests := []struct {
		name            string
		questionContent string
		standardAnswer  string
		userAnswer      string
		expectCorrect   bool
		expectMinScore  int
	}{
		{
			name:            "完全正确的答案",
			questionContent: "计算: 2 + 3 = ?",
			standardAnswer:  "5",
			userAnswer:      "5",
			expectCorrect:   true,
			expectMinScore:  90,
		},
		{
			name:            "部分正确的答案",
			questionContent: "解方程: x + 2 = 5",
			standardAnswer:  "x = 3",
			userAnswer:      "x = 3，移项得：x = 5 - 2 = 3",
			expectCorrect:   true,
			expectMinScore:  70,
		},
		{
			name:            "完全错误的答案",
			questionContent: "计算: 2 + 3 = ?",
			standardAnswer:  "5",
			userAnswer:      "8",
			expectCorrect:   false,
			expectMinScore:  0,
		},
		{
			name:            "空答案",
			questionContent: "计算: 2 + 3 = ?",
			standardAnswer:  "5",
			userAnswer:      "",
			expectCorrect:   false,
			expectMinScore:  0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := &ai.GradeAnswerRequest{
				QuestionContent: tt.questionContent,
				StandardAnswer:  tt.standardAnswer,
				UserAnswer:      tt.userAnswer,
			}

			resp, err := service.GradeAnswer(req)

			require.NoError(t, err)
			assert.NotNil(t, resp)
			assert.Equal(t, tt.expectCorrect, resp.IsCorrect)
			assert.GreaterOrEqual(t, resp.Score, tt.expectMinScore)
			assert.LessOrEqual(t, resp.Score, 100)
			assert.NotEmpty(t, resp.Feedback)

			if !tt.expectCorrect && tt.userAnswer != "" {
				assert.NotEmpty(t, resp.Suggestion)
			}
		})
	}
}

// TestAIDiagnose 测试学习诊断
func TestAIDiagnose(t *testing.T) {
	service := ai.NewAIService()

	tests := []struct {
		name        string
		userID      uint
		expectLevel string
		minWeakPts  int
		minRecommend int
	}{
		{
			name:        "初级学习者诊断",
			userID:      1,
			expectLevel: "beginner",
			minWeakPts:  1,
			minRecommend: 2,
		},
		{
			name:        "中级学习者诊断",
			userID:      2,
			expectLevel: "intermediate",
			minWeakPts:  1,
			minRecommend: 2,
		},
		{
			name:        "高级学习者诊断",
			userID:      3,
			expectLevel: "advanced",
			minWeakPts:  0,
			minRecommend: 1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := &ai.DiagnoseRequest{
				UserID: tt.userID,
			}

			resp, err := service.Diagnose(req)

			require.NoError(t, err)
			assert.NotNil(t, resp)
			assert.NotEmpty(t, resp.OverallLevel)
			assert.GreaterOrEqual(t, len(resp.WeakPoints), tt.minWeakPts)
			assert.GreaterOrEqual(t, len(resp.Recommendations), tt.minRecommend)
			assert.NotEmpty(t, resp.NextSteps)

			// 验证薄弱点结构
			for _, wp := range resp.WeakPoints {
				assert.NotEmpty(t, wp.KnowledgePoint)
				assert.GreaterOrEqual(t, wp.MasteryLevel, 0.0)
				assert.LessOrEqual(t, wp.MasteryLevel, 1.0)
				assert.GreaterOrEqual(t, wp.ErrorRate, 0.0)
				assert.LessOrEqual(t, wp.ErrorRate, 1.0)
			}
		})
	}
}

// BenchmarkAIGenerateQuestion 性能测试：生成题目
func BenchmarkAIGenerateQuestion(b *testing.B) {
	service := ai.NewAIService()
	req := &ai.GenerateQuestionRequest{
		KnowledgePoint: "一元一次方程",
		Difficulty:     "basic",
		Type:           "choice",
		Count:          1,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = service.GenerateQuestions(req)
	}
}

// BenchmarkAIGradeAnswer 性能测试：批改答案
func BenchmarkAIGradeAnswer(b *testing.B) {
	service := ai.NewAIService()
	req := &ai.GradeAnswerRequest{
		QuestionContent: "计算: 2 + 3 = ?",
		StandardAnswer:  "5",
		UserAnswer:      "5",
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = service.GradeAnswer(req)
	}
}
