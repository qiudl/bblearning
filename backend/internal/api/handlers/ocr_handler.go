package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/service/ocr"
)

// OCRHandler OCR处理器
type OCRHandler struct {
	ocrService *ocr.OCRService
}

// NewOCRHandler 创建OCR处理器
func NewOCRHandler(ocrService *ocr.OCRService) *OCRHandler {
	return &OCRHandler{
		ocrService: ocrService,
	}
}

// RecognizeQuestion 识别题目
// @Summary 识别题目
// @Description OCR识别图片中的题目内容
// @Tags OCR
// @Accept json
// @Produce json
// @Param request body dto.OCRRecognizeRequest true "识别请求"
// @Success 200 {object} response.Response{data=dto.OCRRecognizeResponse}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/ai/ocr [post]
func (h *OCRHandler) RecognizeQuestion(c *gin.Context) {
	var req dto.OCRRecognizeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	// 验证Base64图片
	if len(req.Image) == 0 {
		ErrorResponse(c, http.StatusBadRequest, 1000, "图片不能为空")
		return
	}

	// 调用OCR服务
	result, err := h.ocrService.RecognizeQuestion(c.Request.Context(), &req)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 4000, "OCR识别失败: "+err.Error())
		return
	}

	SuccessResponse(c, result)
}

// RecognizeFormula 识别数学公式
// @Summary 识别数学公式
// @Description OCR识别图片中的数学公式，返回LaTeX格式
// @Tags OCR
// @Accept json
// @Produce json
// @Param request body dto.OCRFormulaRequest true "公式识别请求"
// @Success 200 {object} response.Response{data=dto.OCRFormulaResponse}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/ai/ocr/formula [post]
func (h *OCRHandler) RecognizeFormula(c *gin.Context) {
	var req dto.OCRFormulaRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	result, err := h.ocrService.RecognizeFormula(c.Request.Context(), &req)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 4000, "公式识别失败: "+err.Error())
		return
	}

	SuccessResponse(c, result)
}

// BatchRecognize 批量识别
// @Summary 批量识别题目
// @Description 批量OCR识别多张图片
// @Tags OCR
// @Accept json
// @Produce json
// @Param request body dto.OCRBatchRequest true "批量识别请求"
// @Success 200 {object} response.Response{data=dto.OCRBatchResponse}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/ai/ocr/batch [post]
func (h *OCRHandler) BatchRecognize(c *gin.Context) {
	var req dto.OCRBatchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	result, err := h.ocrService.BatchRecognize(c.Request.Context(), &req)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 4000, "批量识别失败: "+err.Error())
		return
	}

	SuccessResponse(c, result)
}
