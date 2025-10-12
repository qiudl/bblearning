package ai

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"github.com/qiudl/bblearning-backend/internal/repository/postgres"
	openai "github.com/sashabaranov/go-openai"
	"github.com/spf13/viper"
)

// AIService AI服务
type AIService struct {
	client           *openai.Client
	kpRepo           *postgres.KnowledgePointRepository
	questionRepo     *postgres.QuestionRepository
	recordRepo       *postgres.PracticeRecordRepository
	progressRepo     *postgres.LearningProgressRepository
	conversationRepo *postgres.AIConversationRepository
}

// NewAIService 创建AI服务
func NewAIService(
	kpRepo *postgres.KnowledgePointRepository,
	questionRepo *postgres.QuestionRepository,
	recordRepo *postgres.PracticeRecordRepository,
	progressRepo *postgres.LearningProgressRepository,
	conversationRepo *postgres.AIConversationRepository,
) *AIService {
	apiKey := viper.GetString("openai.api_key")
	client := openai.NewClient(apiKey)

	return &AIService{
		client:           client,
		kpRepo:           kpRepo,
		questionRepo:     questionRepo,
		recordRepo:       recordRepo,
		progressRepo:     progressRepo,
		conversationRepo: conversationRepo,
	}
}

// GenerateQuestion AI生成题目
func (s *AIService) GenerateQuestion(ctx context.Context, req *dto.AIGenerateQuestionRequest) (*dto.AIGenerateQuestionResponse, error) {
	// 获取知识点信息
	kp, err := s.kpRepo.FindByID(ctx, req.KnowledgePointID)
	if err != nil {
		return nil, errors.New("knowledge point not found")
	}

	// 构建prompt
	prompt := s.buildGenerateQuestionPrompt(kp, req.Difficulty, req.Type, req.Count)

	// 调用OpenAI API
	resp, err := s.client.CreateChatCompletion(ctx, openai.ChatCompletionRequest{
		Model: viper.GetString("openai.model"),
		Messages: []openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleSystem,
				Content: "你是一位经验丰富的数学教师,擅长出题。请根据要求生成高质量的数学题目。",
			},
			{
				Role:    openai.ChatMessageRoleUser,
				Content: prompt,
			},
		},
		Temperature: 0.7,
	})

	if err != nil {
		return nil, fmt.Errorf("openai api error: %w", err)
	}

	// 解析AI返回的题目
	questions, err := s.parseGeneratedQuestions(resp.Choices[0].Message.Content, req.KnowledgePointID)
	if err != nil {
		return nil, fmt.Errorf("parse questions failed: %w", err)
	}

	return &dto.AIGenerateQuestionResponse{
		Questions: questions,
		Count:     len(questions),
	}, nil
}

// GradeAnswer AI批改答案
func (s *AIService) GradeAnswer(ctx context.Context, req *dto.AIGradeAnswerRequest) (*dto.AIGradeAnswerResponse, error) {
	// 构建prompt
	prompt := fmt.Sprintf(`请批改以下数学题答案:

题目: %s

标准答案: %s

学生答案: %s

请按以下JSON格式返回批改结果:
{
  "is_correct": true/false,
  "score": 0-100,
  "feedback": "批改意见",
  "suggestion": "改进建议",
  "key_points": ["要点1", "要点2"]
}`, req.QuestionContent, req.StandardAnswer, req.UserAnswer)

	// 调用OpenAI API
	resp, err := s.client.CreateChatCompletion(ctx, openai.ChatCompletionRequest{
		Model: viper.GetString("openai.model"),
		Messages: []openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleSystem,
				Content: "你是一位严谨的数学老师,擅长批改作业并给出建设性意见。",
			},
			{
				Role:    openai.ChatMessageRoleUser,
				Content: prompt,
			},
		},
		Temperature: 0.3,
	})

	if err != nil {
		return nil, fmt.Errorf("openai api error: %w", err)
	}

	// 解析批改结果
	var result dto.AIGradeAnswerResponse
	err = json.Unmarshal([]byte(resp.Choices[0].Message.Content), &result)
	if err != nil {
		return nil, fmt.Errorf("parse grade result failed: %w", err)
	}

	return &result, nil
}

// Chat AI对话
func (s *AIService) Chat(ctx context.Context, userID uint, req *dto.AIChatRequest) (*dto.AIChatResponse, error) {
	// 获取历史对话
	conversations, err := s.conversationRepo.FindRecentByUserID(ctx, userID, 10)
	if err != nil {
		conversations = []*models.AIConversation{}
	}

	// 构建对话历史
	messages := []openai.ChatCompletionMessage{
		{
			Role:    openai.ChatMessageRoleSystem,
			Content: "你是一位耐心的数学辅导老师,擅长用简单易懂的方式解释数学概念。",
		},
	}

	for _, conv := range conversations {
		messages = append(messages, openai.ChatCompletionMessage{
			Role:    conv.Role,
			Content: conv.Content,
		})
	}

	messages = append(messages, openai.ChatCompletionMessage{
		Role:    openai.ChatMessageRoleUser,
		Content: req.Message,
	})

	// 调用OpenAI API
	resp, err := s.client.CreateChatCompletion(ctx, openai.ChatCompletionRequest{
		Model:       viper.GetString("openai.model"),
		Messages:    messages,
		Temperature: 0.7,
	})

	if err != nil {
		return nil, fmt.Errorf("openai api error: %w", err)
	}

	reply := resp.Choices[0].Message.Content

	// 保存对话记录
	userConv := &models.AIConversation{
		UserID:     userID,
		QuestionID: req.QuestionID,
		Role:       openai.ChatMessageRoleUser,
		Content:    req.Message,
	}
	_ = s.conversationRepo.Create(ctx, userConv)

	assistantConv := &models.AIConversation{
		UserID:     userID,
		QuestionID: req.QuestionID,
		Role:       openai.ChatMessageRoleAssistant,
		Content:    reply,
	}
	_ = s.conversationRepo.Create(ctx, assistantConv)

	return &dto.AIChatResponse{
		Reply:          reply,
		ConversationID: assistantConv.ID,
	}, nil
}

// Diagnose AI学习诊断
func (s *AIService) Diagnose(ctx context.Context, userID uint, req *dto.AIDiagnoseRequest) (*dto.AIDiagnoseResponse, error) {
	// 获取用户学习数据
	progresses, _, err := s.progressRepo.FindByUserID(ctx, userID, 100, 0)
	if err != nil {
		return nil, fmt.Errorf("get user progress failed: %w", err)
	}

	// 获取练习统计
	stats, err := s.recordRepo.GetStatistics(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get statistics failed: %w", err)
	}

	// 获取知识点正确率
	kpAccuracy, err := s.recordRepo.GetKnowledgePointAccuracy(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get kp accuracy failed: %w", err)
	}

	// 构建诊断prompt
	prompt := s.buildDiagnosePrompt(progresses, stats, kpAccuracy)

	// 调用OpenAI API
	resp, err := s.client.CreateChatCompletion(ctx, openai.ChatCompletionRequest{
		Model: viper.GetString("openai.model"),
		Messages: []openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleSystem,
				Content: "你是一位资深的数学教育专家,擅长分析学生的学习情况并给出个性化建议。",
			},
			{
				Role:    openai.ChatMessageRoleUser,
				Content: prompt,
			},
		},
		Temperature: 0.5,
	})

	if err != nil {
		return nil, fmt.Errorf("openai api error: %w", err)
	}

	// 解析诊断结果
	var result dto.AIDiagnoseResponse
	err = json.Unmarshal([]byte(resp.Choices[0].Message.Content), &result)
	if err != nil {
		return nil, fmt.Errorf("parse diagnose result failed: %w", err)
	}

	return &result, nil
}

// Explain AI解题讲解
func (s *AIService) Explain(ctx context.Context, req *dto.AIExplainRequest) (*dto.AIExplainResponse, error) {
	// 获取题目
	question, err := s.questionRepo.FindByID(ctx, req.QuestionID)
	if err != nil {
		return nil, errors.New("question not found")
	}

	// 构建prompt
	prompt := fmt.Sprintf(`请详细讲解以下数学题:

题目: %s
答案: %s
`, question.Content, question.Answer)

	if req.UserAnswer != "" {
		prompt += fmt.Sprintf("\n学生答案: %s", req.UserAnswer)
	}

	prompt += `

请按以下JSON格式返回:
{
  "explanation": "详细讲解",
  "steps": ["步骤1", "步骤2"],
  "key_concepts": ["概念1", "概念2"]
}`

	// 调用OpenAI API
	resp, err := s.client.CreateChatCompletion(ctx, openai.ChatCompletionRequest{
		Model: viper.GetString("openai.model"),
		Messages: []openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleSystem,
				Content: "你是一位耐心的数学老师,擅长用清晰的步骤讲解数学题目。",
			},
			{
				Role:    openai.ChatMessageRoleUser,
				Content: prompt,
			},
		},
		Temperature: 0.5,
	})

	if err != nil {
		return nil, fmt.Errorf("openai api error: %w", err)
	}

	// 解析讲解结果
	var result dto.AIExplainResponse
	err = json.Unmarshal([]byte(resp.Choices[0].Message.Content), &result)
	if err != nil {
		return nil, fmt.Errorf("parse explain result failed: %w", err)
	}

	return &result, nil
}

// buildGenerateQuestionPrompt 构建生成题目的prompt
func (s *AIService) buildGenerateQuestionPrompt(kp *models.KnowledgePoint, difficulty, qType string, count int) string {
	return fmt.Sprintf(`请为以下知识点生成%d道%s难度的%s题:

知识点: %s
描述: %s
难度: %s
题型: %s

要求:
1. 题目质量高,符合知识点要求
2. 难度适中,符合指定难度
3. 返回JSON格式: [{"content":"题目","options":["A","B","C","D"],"answer":"C","explanation":"解析"}]
4. 选择题包含options数组,填空题和解答题options为空数组
`, count, difficulty, qType, kp.Name, kp.Description, difficulty, qType)
}

// buildDiagnosePrompt 构建诊断prompt
func (s *AIService) buildDiagnosePrompt(progresses []*models.LearningProgress, stats map[string]interface{}, kpAccuracy []map[string]interface{}) string {
	prompt := fmt.Sprintf(`请分析以下学生的学习数据并给出诊断:

整体统计:
- 总练习: %d题
- 总正确: %d题
- 正确率: %.2f%%

知识点掌握情况:
`, stats["total_practice"], stats["total_correct"], stats["accuracy"])

	for i, kp := range kpAccuracy {
		if i >= 10 {
			break
		}
		prompt += fmt.Sprintf("- 知识点ID %d: 正确率 %.2f%%\n",
			kp["knowledge_point_id"], kp["accuracy"])
	}

	prompt += `

请按以下JSON格式返回诊断结果:
{
  "overall_level": "beginner/intermediate/advanced",
  "weak_points": [{"knowledge_point_id":1,"knowledge_point":"名称","mastery_level":60,"error_rate":40,"common_mistakes":["错误1"],"practice_suggestion":"建议"}],
  "recommendations": ["建议1","建议2"],
  "next_steps": ["步骤1","步骤2"]
}`

	return prompt
}

// parseGeneratedQuestions 解析AI生成的题目
func (s *AIService) parseGeneratedQuestions(content string, kpID uint) ([]*dto.QuestionInfo, error) {
	var rawQuestions []struct {
		Content     string   `json:"content"`
		Options     []string `json:"options"`
		Answer      string   `json:"answer"`
		Explanation string   `json:"explanation"`
	}

	err := json.Unmarshal([]byte(content), &rawQuestions)
	if err != nil {
		return nil, err
	}

	questions := make([]*dto.QuestionInfo, 0, len(rawQuestions))
	for _, rq := range rawQuestions {
		// 保存到数据库
		question := &models.Question{
			KnowledgePointID: kpID,
			Type:             s.inferQuestionType(rq.Options),
			Content:          rq.Content,
			Options:          s.serializeOptions(rq.Options),
			Answer:           rq.Answer,
			Explanation:      rq.Explanation,
			Difficulty:       "medium",
			CreatedAt:        time.Now(),
			UpdatedAt:        time.Now(),
		}

		_ = s.questionRepo.Create(context.Background(), question)

		questions = append(questions, &dto.QuestionInfo{
			ID:               question.ID,
			KnowledgePointID: kpID,
			Type:             question.Type,
			Content:          rq.Content,
			Options:          rq.Options,
			Answer:           rq.Answer,
			Explanation:      rq.Explanation,
		})
	}

	return questions, nil
}

// inferQuestionType 推断题型
func (s *AIService) inferQuestionType(options []string) string {
	if len(options) > 0 {
		return "choice"
	}
	return "answer"
}

// serializeOptions 序列化选项为JSON
func (s *AIService) serializeOptions(options []string) string {
	if len(options) == 0 {
		return ""
	}
	data, _ := json.Marshal(options)
	return string(data)
}
