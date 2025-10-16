package models

import (
	"time"

	"gorm.io/gorm"
)

// User 用户模型
type User struct {
	ID          uint           `gorm:"primarykey" json:"id"`
	Username    string         `gorm:"uniqueIndex;size:50;not null" json:"username"`
	Password    string         `gorm:"size:255;not null" json:"-"`
	Nickname    string         `gorm:"size:50" json:"nickname"`
	PhoneNumber string         `gorm:"size:20" json:"phoneNumber"`
	Email       string         `gorm:"size:100" json:"email"`
	Grade       string         `gorm:"size:20" json:"grade"`
	Avatar      string         `gorm:"size:500" json:"avatar"`
	Role        string         `gorm:"size:20;default:student" json:"role"` // student, teacher, admin
	Status      string         `gorm:"size:20;default:active" json:"status"` // active, inactive, banned
	LastLoginAt *time.Time     `json:"lastLoginAt"`
	CreatedAt   time.Time      `json:"createdAt"`
	UpdatedAt   time.Time      `json:"updatedAt"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
}

// Chapter 章节模型
type Chapter struct {
	ID              uint             `gorm:"primarykey" json:"id"`
	Name            string           `gorm:"size:100;not null" json:"name"`
	ChapterNumber   int              `gorm:"not null" json:"chapterNumber"`
	Grade           string           `gorm:"size:20;not null" json:"grade"`       // 7, 8, 9
	Subject         string           `gorm:"size:20;not null" json:"subject"`     // math
	Semester        string           `gorm:"size:20;not null" json:"semester"`    // first, second
	Description     string           `gorm:"type:text" json:"description"`
	DisplayOrder    int              `gorm:"default:0" json:"displayOrder"`
	CreatedAt       time.Time        `json:"createdAt"`
	UpdatedAt       time.Time        `json:"updatedAt"`
	DeletedAt       gorm.DeletedAt   `gorm:"index" json:"-"`
	KnowledgePoints []KnowledgePoint `gorm:"foreignKey:ChapterID" json:"knowledgePoints,omitempty"`
}

// KnowledgePoint 知识点模型
type KnowledgePoint struct {
	ID              uint           `gorm:"primarykey" json:"id"`
	ChapterID       uint           `gorm:"not null;index" json:"chapterId"`
	ParentID        *uint          `gorm:"index" json:"parentId"`          // 支持知识点层级关系
	Name            string         `gorm:"size:200;not null" json:"name"`
	Type            string         `gorm:"size:20" json:"type"`            // concept, theorem, formula, skill
	Description     string         `gorm:"type:text" json:"description"`
	Content         string         `gorm:"type:text" json:"content"`
	VideoURL        string         `gorm:"size:500" json:"videoUrl"`
	Prerequisites   string         `gorm:"type:text" json:"prerequisites"` // JSON数组,前置知识点ID列表
	Tags            string         `gorm:"type:text" json:"tags"`          // JSON数组,标签
	Difficulty      string         `gorm:"size:20;default:medium" json:"difficulty"` // basic, medium, advanced
	EstimatedHours  float64        `gorm:"type:decimal(5,2)" json:"estimatedHours"`
	DisplayOrder    int            `gorm:"default:0" json:"displayOrder"`
	CreatedAt       time.Time      `json:"createdAt"`
	UpdatedAt       time.Time      `json:"updatedAt"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`
}

// Question 题目模型
type Question struct {
	ID               uint      `gorm:"primarykey" json:"id"`
	KnowledgePointID uint      `gorm:"not null;index" json:"knowledgePointId"`
	Type             string    `gorm:"size:20;not null" json:"type"` // choice, fill, answer
	Content          string    `gorm:"type:text;not null" json:"content"`
	Options          string    `gorm:"type:text" json:"options"` // JSON array for choice questions
	Answer           string    `gorm:"type:text;not null" json:"answer"`
	Explanation      string    `gorm:"type:text" json:"explanation"`
	Difficulty       string    `gorm:"size:20" json:"difficulty"` // basic, medium, advanced
	CreatedAt        time.Time `json:"createdAt"`
	UpdatedAt        time.Time `json:"updatedAt"`
}

// PracticeRecord 练习记录模型
type PracticeRecord struct {
	ID         uint           `gorm:"primarykey" json:"id"`
	UserID     uint           `gorm:"not null;index" json:"userId"`
	QuestionID uint           `gorm:"not null;index" json:"questionId"`
	UserAnswer string         `gorm:"type:text" json:"userAnswer"`
	IsCorrect  bool           `json:"isCorrect"`
	TimeSpent  int            `gorm:"default:0" json:"timeSpent"` // 做题用时(秒)
	CreatedAt  time.Time      `json:"createdAt"`
	UpdatedAt  time.Time      `json:"updatedAt"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`
	Question   *Question      `gorm:"foreignKey:QuestionID" json:"question,omitempty"`
}

// WrongQuestion 错题模型
type WrongQuestion struct {
	ID            uint      `gorm:"primarykey" json:"id"`
	UserID        uint      `gorm:"not null;index:idx_user_question,unique" json:"userId"`
	QuestionID    uint      `gorm:"not null;index:idx_user_question,unique" json:"questionId"`
	WrongCount    int       `gorm:"default:1" json:"wrongCount"`
	LastWrongTime time.Time `json:"lastWrongTime"`
	CreatedAt     time.Time `json:"createdAt"`
	Question      *Question `gorm:"foreignKey:QuestionID" json:"question,omitempty"`
}

// LearningProgress 学习进度模型
type LearningProgress struct {
	ID               uint           `gorm:"primarykey" json:"id"`
	UserID           uint           `gorm:"not null;index:idx_user_kp,unique" json:"userId"`
	KnowledgePointID uint           `gorm:"not null;index:idx_user_kp,unique" json:"knowledgePointId"`
	MasteryLevel     float64        `gorm:"type:decimal(5,2);default:0.00" json:"masteryLevel"` // 0.00-100.00
	PracticeCount    int            `gorm:"default:0" json:"practiceCount"`
	CorrectCount     int            `gorm:"default:0" json:"correctCount"`
	LastPracticeAt   *time.Time     `json:"lastPracticeAt"`
	CreatedAt        time.Time      `json:"createdAt"`
	UpdatedAt        time.Time      `json:"updatedAt"`
	DeletedAt        gorm.DeletedAt `gorm:"index" json:"-"`
}

// AIConversation AI对话记录模型
type AIConversation struct {
	ID         uint           `gorm:"primarykey" json:"id"`
	UserID     uint           `gorm:"not null;index" json:"userId"`
	QuestionID *uint          `gorm:"index" json:"questionId"` // 关联题目(可选)
	Role       string         `gorm:"size:20;not null" json:"role"` // user, assistant, system
	Content    string         `gorm:"type:text;not null" json:"content"`
	ImageURLs  []string       `gorm:"type:text[];default:ARRAY[]::TEXT[]" json:"imageUrls"` // MinIO存储的图片URL列表
	Metadata   string         `gorm:"type:jsonb" json:"metadata"` // 额外信息(token数、模型等)
	CreatedAt  time.Time      `json:"createdAt"`
	UpdatedAt  time.Time      `json:"updatedAt"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`
}

// DailyGoal 每日学习目标模型
type DailyGoal struct {
	ID                 uint           `gorm:"primarykey" json:"id"`
	UserID             uint           `gorm:"not null;index:idx_user_date,unique" json:"userId"`
	Date               time.Time      `gorm:"type:date;not null;index:idx_user_date,unique" json:"date"`
	TargetMinutes      int            `gorm:"default:30" json:"targetMinutes"`      // 目标学习时长(分钟)
	ActualMinutes      int            `gorm:"default:0" json:"actualMinutes"`       // 实际学习时长
	TargetQuestions    int            `gorm:"default:10" json:"targetQuestions"`    // 目标题目数
	CompletedQuestions int            `gorm:"default:0" json:"completedQuestions"`  // 完成题目数
	TargetKnowledgePoints int         `gorm:"default:2" json:"targetKnowledgePoints"` // 目标知识点数
	CompletedKnowledgePoints int      `gorm:"default:0" json:"completedKnowledgePoints"` // 完成知识点数
	IsCompleted        bool           `gorm:"default:false" json:"isCompleted"`     // 目标是否完成
	CreatedAt          time.Time      `json:"createdAt"`
	UpdatedAt          time.Time      `json:"updatedAt"`
	DeletedAt          gorm.DeletedAt `gorm:"index" json:"-"`
}

// LearningStatistics 学习统计模型
type LearningStatistics struct {
	ID                    uint           `gorm:"primarykey" json:"id"`
	UserID                uint           `gorm:"not null;index:idx_user_date,unique" json:"userId"`
	Date                  time.Time      `gorm:"type:date;not null;index:idx_user_date,unique" json:"date"`
	StudyMinutes          int            `gorm:"default:0" json:"studyMinutes"`          // 学习时长(分钟)
	PracticeCount         int            `gorm:"default:0" json:"practiceCount"`         // 练习题目数
	CorrectCount          int            `gorm:"default:0" json:"correctCount"`          // 正确题目数
	WrongCount            int            `gorm:"default:0" json:"wrongCount"`            // 错误题目数
	NewKnowledgePoints    int            `gorm:"default:0" json:"newKnowledgePoints"`    // 新学知识点数
	ReviewKnowledgePoints int            `gorm:"default:0" json:"reviewKnowledgePoints"` // 复习知识点数
	AccuracyRate          float64        `gorm:"type:decimal(5,2);default:0.00" json:"accuracyRate"` // 正确率
	AverageTimePerQuestion float64       `gorm:"type:decimal(8,2);default:0.00" json:"averageTimePerQuestion"` // 平均做题时间(秒)
	CreatedAt             time.Time      `json:"createdAt"`
	UpdatedAt             time.Time      `json:"updatedAt"`
	DeletedAt             gorm.DeletedAt `gorm:"index" json:"-"`
}
