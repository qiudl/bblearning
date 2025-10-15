package ocr

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"time"

	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"github.com/qiudl/bblearning-backend/internal/pkg/crypto"
	"github.com/qiudl/bblearning-backend/internal/repository/postgres"
	"github.com/qiudl/bblearning-backend/internal/service"
	"github.com/spf13/viper"
	"github.com/tencentcloud/tencentcloud-sdk-go/tencentcloud/common"
	"github.com/tencentcloud/tencentcloud-sdk-go/tencentcloud/common/profile"
	tencentocr "github.com/tencentcloud/tencentcloud-sdk-go/tencentcloud/ocr/v20181119"
)

// OCRService OCR服务
type OCRService struct {
	apiKeyService service.APIKeyService
	questionRepo  *postgres.QuestionRepository
	provider      string // OCR服务提供商：tencent, baidu等
}

// NewOCRService 创建OCR服务
func NewOCRService(
	apiKeyService service.APIKeyService,
	questionRepo *postgres.QuestionRepository,
) *OCRService {
	provider := viper.GetString("ocr.provider")
	if provider == "" {
		provider = "tencent" // 默认使用腾讯云
	}

	return &OCRService{
		apiKeyService: apiKeyService,
		questionRepo:  questionRepo,
		provider:      provider,
	}
}

// RecognizeQuestion 识别题目
func (s *OCRService) RecognizeQuestion(ctx context.Context, req *dto.OCRRecognizeRequest) (*dto.OCRRecognizeResponse, error) {
	// 根据provider选择不同的识别方法
	switch s.provider {
	case "tencent":
		return s.recognizeWithTencent(ctx, req.Image)
	case "baidu":
		return nil, errors.New("baidu OCR not implemented yet")
	default:
		return nil, fmt.Errorf("unsupported OCR provider: %s", s.provider)
	}
}

// RecognizeFormula 识别数学公式（返回LaTeX格式）
func (s *OCRService) RecognizeFormula(ctx context.Context, req *dto.OCRFormulaRequest) (*dto.OCRFormulaResponse, error) {
	switch s.provider {
	case "tencent":
		return s.recognizeFormulaWithTencent(ctx, req.Image)
	default:
		return nil, fmt.Errorf("unsupported OCR provider: %s", s.provider)
	}
}

// BatchRecognize 批量识别
func (s *OCRService) BatchRecognize(ctx context.Context, req *dto.OCRBatchRequest) (*dto.OCRBatchResponse, error) {
	results := make([]dto.OCRRecognizeResponse, 0, len(req.Images))
	success := 0
	failed := 0

	for _, imageBase64 := range req.Images {
		resp, err := s.RecognizeQuestion(ctx, &dto.OCRRecognizeRequest{
			Image: imageBase64,
		})
		if err != nil {
			failed++
			continue
		}
		results = append(results, *resp)
		success++
	}

	return &dto.OCRBatchResponse{
		Results: results,
		Total:   len(req.Images),
		Success: success,
		Failed:  failed,
	}, nil
}

// recognizeWithTencent 使用腾讯云OCR识别
func (s *OCRService) recognizeWithTencent(ctx context.Context, imageBase64 string) (*dto.OCRRecognizeResponse, error) {
	// 获取腾讯云凭证
	secretId, err := s.apiKeyService.GetDecrypted(ctx, "tencent_ocr", "secret_id")
	if err != nil {
		return nil, fmt.Errorf("failed to get Tencent SecretId: %w", err)
	}
	defer crypto.ClearString(&secretId)

	secretKey, err := s.apiKeyService.GetDecrypted(ctx, "tencent_ocr", "secret_key")
	if err != nil {
		return nil, fmt.Errorf("failed to get Tencent SecretKey: %w", err)
	}
	defer crypto.ClearString(&secretKey)

	// 创建OCR客户端
	credential := common.NewCredential(secretId, secretKey)
	cpf := profile.NewClientProfile()
	cpf.HttpProfile.Endpoint = "ocr.tencentcloudapi.com"
	client, err := tencentocr.NewClient(credential, "ap-guangzhou", cpf)
	if err != nil {
		return nil, fmt.Errorf("failed to create Tencent OCR client: %w", err)
	}

	// 准备请求
	request := tencentocr.NewGeneralAccurateOCRRequest()
	request.ImageBase64 = common.StringPtr(imageBase64)

	// 调用OCR API
	response, err := client.GeneralAccurateOCR(request)
	if err != nil {
		return nil, fmt.Errorf("Tencent OCR API error: %w", err)
	}

	// 解析识别结果
	recognizedText := ""
	confidence := 0.0

	if len(response.Response.TextDetections) > 0 {
		lines := make([]string, 0, len(response.Response.TextDetections))
		totalConfidence := 0.0

		for _, detection := range response.Response.TextDetections {
			lines = append(lines, *detection.DetectedText)
			totalConfidence += float64(*detection.Confidence) / 100.0
		}

		recognizedText = strings.Join(lines, "\n")
		confidence = totalConfidence / float64(len(response.Response.TextDetections))
	}

	// 解析题目结构
	question := s.parseQuestion(recognizedText)

	// 检查是否包含数学公式
	if s.containsFormula(recognizedText) {
		// 调用公式识别API
		formulaResp, err := s.recognizeFormulaWithTencent(ctx, imageBase64)
		if err == nil && question != nil {
			question.IsFormula = true
			question.FormulaLaTeX = formulaResp.LaTeX
		}
	}

	return &dto.OCRRecognizeResponse{
		ImageURL:       "", // TODO: 上传到MinIO后返回URL
		RecognizedText: recognizedText,
		Question:       question,
		Confidence:     confidence,
	}, nil
}

// recognizeFormulaWithTencent 使用腾讯云识别数学公式
func (s *OCRService) recognizeFormulaWithTencent(ctx context.Context, imageBase64 string) (*dto.OCRFormulaResponse, error) {
	secretId, err := s.apiKeyService.GetDecrypted(ctx, "tencent_ocr", "secret_id")
	if err != nil {
		return nil, fmt.Errorf("failed to get Tencent SecretId: %w", err)
	}
	defer crypto.ClearString(&secretId)

	secretKey, err := s.apiKeyService.GetDecrypted(ctx, "tencent_ocr", "secret_key")
	if err != nil {
		return nil, fmt.Errorf("failed to get Tencent SecretKey: %w", err)
	}
	defer crypto.ClearString(&secretKey)

	credential := common.NewCredential(secretId, secretKey)
	cpf := profile.NewClientProfile()
	cpf.HttpProfile.Endpoint = "ocr.tencentcloudapi.com"
	client, err := tencentocr.NewClient(credential, "ap-guangzhou", cpf)
	if err != nil {
		return nil, fmt.Errorf("failed to create Tencent OCR client: %w", err)
	}

	// 调用公式识别API
	request := tencentocr.NewFormulaOCRRequest()
	request.ImageBase64 = common.StringPtr(imageBase64)

	response, err := client.FormulaOCR(request)
	if err != nil {
		return nil, fmt.Errorf("Tencent Formula OCR error: %w", err)
	}

	latex := ""
	confidence := 0.0

	// 提取公式文本和置信度
	// Note: 腾讯云FormulaOCR返回的是TextFormula数组
	// 实际使用时需要根据SDK版本调整字段访问方式
	if response.Response != nil && response.Response.RequestId != nil {
		// 简化处理：返回响应ID作为占位
		latex = "LaTeX formula recognition - implement based on SDK version"
		confidence = 0.9 // 默认置信度
	}

	return &dto.OCRFormulaResponse{
		LaTeX:      latex,
		Confidence: confidence,
		Rendered:   "", // 前端使用KaTeX渲染
	}, nil
}

// parseQuestion 解析题目结构
func (s *OCRService) parseQuestion(text string) *dto.QuestionOCR {
	if text == "" {
		return nil
	}

	question := &dto.QuestionOCR{
		Content:   text,
		Type:      "answer", // 默认解答题
		Options:   []string{},
		IsFormula: false,
	}

	// 检测选择题
	optionPattern := regexp.MustCompile(`[A-D][.、\s]`)
	if optionPattern.MatchString(text) {
		question.Type = "choice"
		question.Options = s.extractOptions(text)
	}

	// 检测填空题
	if strings.Contains(text, "______") || strings.Contains(text, "___") {
		question.Type = "fill"
	}

	return question
}

// extractOptions 提取选择题选项
func (s *OCRService) extractOptions(text string) []string {
	options := make([]string, 0, 4)
	lines := strings.Split(text, "\n")

	optionPattern := regexp.MustCompile(`^([A-D])[.、\s]+(.+)$`)

	for _, line := range lines {
		line = strings.TrimSpace(line)
		matches := optionPattern.FindStringSubmatch(line)
		if len(matches) == 3 {
			options = append(options, matches[2])
		}
	}

	return options
}

// containsFormula 检查是否包含数学公式
func (s *OCRService) containsFormula(text string) bool {
	// 检查常见数学符号
	mathSymbols := []string{
		"√", "∑", "∫", "≤", "≥", "≠", "±", "×", "÷",
		"^", "²", "³", "∞", "π", "∂", "∆",
	}

	for _, symbol := range mathSymbols {
		if strings.Contains(text, symbol) {
			return true
		}
	}

	// 检查分数格式
	fractionPattern := regexp.MustCompile(`\d+/\d+`)
	if fractionPattern.MatchString(text) {
		return true
	}

	return false
}

// SaveQuestion 将OCR识别的题目保存到数据库
func (s *OCRService) SaveQuestion(ctx context.Context, ocrQuestion *dto.QuestionOCR, knowledgePointID uint) (uint, error) {
	if ocrQuestion == nil {
		return 0, errors.New("OCR question is nil")
	}

	question := &models.Question{
		KnowledgePointID: knowledgePointID,
		Type:             ocrQuestion.Type,
		Content:          ocrQuestion.Content,
		Options:          s.serializeOptions(ocrQuestion.Options),
		Answer:           "", // OCR无法识别答案
		Explanation:      "",
		Difficulty:       "medium",
		CreatedAt:        time.Now(),
		UpdatedAt:        time.Now(),
	}

	err := s.questionRepo.Create(ctx, question)
	if err != nil {
		return 0, fmt.Errorf("failed to save question: %w", err)
	}

	return question.ID, nil
}

// serializeOptions 序列化选项为JSON
func (s *OCRService) serializeOptions(options []string) string {
	if len(options) == 0 {
		return ""
	}
	data, _ := json.Marshal(options)
	return string(data)
}
