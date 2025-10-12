package dto

import "github.com/qiudl/bblearning-backend/internal/domain/models"

// ChapterListRequest 章节列表请求
type ChapterListRequest struct {
	Grade    string `form:"grade" binding:"omitempty,oneof=7 8 9"`
	Subject  string `form:"subject" binding:"omitempty"`
	Semester string `form:"semester" binding:"omitempty,oneof=first second"`
	Page     int    `form:"page" binding:"min=1"`
	PageSize int    `form:"page_size" binding:"min=1,max=100"`
}

// ChapterInfo 章节信息
type ChapterInfo struct {
	ID              uint   `json:"id"`
	Name            string `json:"name"`
	ChapterNumber   int    `json:"chapter_number"`
	Grade           string `json:"grade"`
	Subject         string `json:"subject"`
	Semester        string `json:"semester"`
	Description     string `json:"description"`
	DisplayOrder    int    `json:"display_order"`
	KnowledgePoints int    `json:"knowledge_points_count"` // 知识点数量
}

// ChapterListResponse 章节列表响应
type ChapterListResponse struct {
	Items []*ChapterInfo `json:"items"`
	Total int64          `json:"total"`
	Page  int            `json:"page"`
	Size  int            `json:"size"`
}

// ChapterDetailResponse 章节详情响应
type ChapterDetailResponse struct {
	*ChapterInfo
	KnowledgePoints []*KnowledgePointInfo `json:"knowledge_points"`
}

// KnowledgePointListRequest 知识点列表请求
type KnowledgePointListRequest struct {
	ChapterID  *uint  `form:"chapter_id"`
	Grade      string `form:"grade" binding:"omitempty,oneof=7 8 9"`
	Type       string `form:"type" binding:"omitempty,oneof=concept theorem formula skill"`
	Difficulty string `form:"difficulty" binding:"omitempty,oneof=basic medium advanced"`
	Page       int    `form:"page" binding:"min=1"`
	PageSize   int    `form:"page_size" binding:"min=1,max=100"`
}

// KnowledgePointInfo 知识点信息
type KnowledgePointInfo struct {
	ID             uint                    `json:"id"`
	ChapterID      uint                    `json:"chapter_id"`
	ChapterName    string                  `json:"chapter_name,omitempty"`
	ParentID       *uint                   `json:"parent_id"`
	Name           string                  `json:"name"`
	Type           string                  `json:"type"`
	Description    string                  `json:"description"`
	Content        string                  `json:"content,omitempty"`
	VideoURL       string                  `json:"video_url,omitempty"`
	Prerequisites  []uint                  `json:"prerequisites,omitempty"`
	Tags           []string                `json:"tags,omitempty"`
	Difficulty     string                  `json:"difficulty"`
	EstimatedHours float64                 `json:"estimated_hours"`
	DisplayOrder   int                     `json:"display_order"`
	Children       []*KnowledgePointInfo   `json:"children,omitempty"`
	MasteryLevel   *float64                `json:"mastery_level,omitempty"` // 用户掌握度
}

// KnowledgePointListResponse 知识点列表响应
type KnowledgePointListResponse struct {
	Items []*KnowledgePointInfo `json:"items"`
	Total int64                 `json:"total"`
	Page  int                   `json:"page"`
	Size  int                   `json:"size"`
}

// KnowledgeTreeRequest 知识树请求
type KnowledgeTreeRequest struct {
	Grade     string `form:"grade" binding:"required,oneof=7 8 9"`
	ChapterID *uint  `form:"chapter_id"`
}

// KnowledgeTreeResponse 知识树响应
type KnowledgeTreeResponse struct {
	Grade    string                  `json:"grade"`
	Chapters []*ChapterWithKnowledge `json:"chapters"`
}

// ChapterWithKnowledge 包含知识点的章节
type ChapterWithKnowledge struct {
	*ChapterInfo
	KnowledgePoints []*KnowledgePointInfo `json:"knowledge_points"`
}

// LearningProgressRequest 学习进度请求
type LearningProgressRequest struct {
	KnowledgePointID uint `json:"knowledge_point_id" binding:"required"`
	MasteryLevel     *float64 `json:"mastery_level" binding:"omitempty,min=0,max=100"`
}

// LearningProgressInfo 学习进度信息
type LearningProgressInfo struct {
	ID               uint    `json:"id"`
	UserID           uint    `json:"user_id"`
	KnowledgePointID uint    `json:"knowledge_point_id"`
	KnowledgePoint   *KnowledgePointInfo `json:"knowledge_point,omitempty"`
	MasteryLevel     float64 `json:"mastery_level"`
	PracticeCount    int     `json:"practice_count"`
	CorrectCount     int     `json:"correct_count"`
	LastPracticeAt   *string `json:"last_practice_at"`
}

// UserProgressListResponse 用户进度列表响应
type UserProgressListResponse struct {
	Items []*LearningProgressInfo `json:"items"`
	Total int64                   `json:"total"`
}

// ToChapterInfo 将Chapter模型转换为ChapterInfo
func ToChapterInfo(chapter *models.Chapter) *ChapterInfo {
	if chapter == nil {
		return nil
	}
	knowledgePointsCount := 0
	if chapter.KnowledgePoints != nil {
		knowledgePointsCount = len(chapter.KnowledgePoints)
	}
	return &ChapterInfo{
		ID:              chapter.ID,
		Name:            chapter.Name,
		ChapterNumber:   chapter.ChapterNumber,
		Grade:           chapter.Grade,
		Subject:         chapter.Subject,
		Semester:        chapter.Semester,
		Description:     chapter.Description,
		DisplayOrder:    chapter.DisplayOrder,
		KnowledgePoints: knowledgePointsCount,
	}
}

// ToKnowledgePointInfo 将KnowledgePoint模型转换为KnowledgePointInfo
func ToKnowledgePointInfo(kp *models.KnowledgePoint) *KnowledgePointInfo {
	if kp == nil {
		return nil
	}

	info := &KnowledgePointInfo{
		ID:             kp.ID,
		ChapterID:      kp.ChapterID,
		ParentID:       kp.ParentID,
		Name:           kp.Name,
		Type:           kp.Type,
		Description:    kp.Description,
		Content:        kp.Content,
		VideoURL:       kp.VideoURL,
		Difficulty:     kp.Difficulty,
		EstimatedHours: kp.EstimatedHours,
		DisplayOrder:   kp.DisplayOrder,
	}

	// 解析JSON字段 (Prerequisites和Tags)
	// TODO: 实现JSON解析

	return info
}
