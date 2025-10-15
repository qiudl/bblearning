package dto

// OCRRecognizeRequest OCR识别请求
type OCRRecognizeRequest struct {
	Image string `json:"image" binding:"required"` // Base64编码的图片
}

// OCRRecognizeResponse OCR识别响应
type OCRRecognizeResponse struct {
	ImageURL        string   `json:"image_url"`         // 图片URL（存储后）
	RecognizedText  string   `json:"recognized_text"`   // 识别的文本
	Question        *QuestionOCR `json:"question,omitempty"` // 解析的题目信息
	AISolution      string   `json:"ai_solution,omitempty"` // AI解答（可选）
	Confidence      float64  `json:"confidence"`        // 识别置信度 0-1
}

// QuestionOCR OCR识别的题目信息
type QuestionOCR struct {
	Content     string   `json:"content"`      // 题目内容
	Type        string   `json:"type"`         // 题目类型: choice/fill/answer
	Options     []string `json:"options"`      // 选项（选择题）
	IsFormula   bool     `json:"is_formula"`   // 是否包含数学公式
	FormulaLaTeX string  `json:"formula_latex"` // LaTeX格式的数学公式
}

// OCRFormulaRequest LaTeX公式识别请求
type OCRFormulaRequest struct {
	Image string `json:"image" binding:"required"` // Base64编码的公式图片
}

// OCRFormulaResponse LaTeX公式识别响应
type OCRFormulaResponse struct {
	LaTeX      string  `json:"latex"`       // LaTeX格式
	Confidence float64 `json:"confidence"`  // 识别置信度
	Rendered   string  `json:"rendered"`    // 渲染预览（可选）
}

// OCRBatchRequest 批量OCR识别请求
type OCRBatchRequest struct {
	Images []string `json:"images" binding:"required,min=1,max=10"` // 多张图片
}

// OCRBatchResponse 批量OCR识别响应
type OCRBatchResponse struct {
	Results []OCRRecognizeResponse `json:"results"`
	Total   int                    `json:"total"`
	Success int                    `json:"success"`
	Failed  int                    `json:"failed"`
}
