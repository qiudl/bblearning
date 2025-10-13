import React, { useEffect } from 'react';
import { Card, Row, Col, Collapse, Button, Progress, Tag, Empty } from 'antd';
import { BookOutlined, PlayCircleOutlined, RightOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { Chapter, KnowledgePoint } from '../../types';
import { useAppStore } from '../../store';

const { Panel } = Collapse;

const LearnPage: React.FC = () => {
  const navigate = useNavigate();
  const { chapters, setChapters, setCurrentKnowledgePoint } = useAppStore();

  useEffect(() => {
    // 模拟加载章节数据
    setTimeout(() => {
      const mockChapters: Chapter[] = [
        {
          id: 1,
          name: '三角形',
          description: '学习三角形的基本性质和判定',
          order: 1,
          knowledgePoints: [
            {
              id: 1,
              chapterId: 1,
              name: '三角形的边',
              content: '三角形任意两边之和大于第三边',
              difficulty: 'basic',
              masteryLevel: 85,
            },
            {
              id: 2,
              chapterId: 1,
              name: '三角形的角',
              content: '三角形内角和为180度',
              difficulty: 'basic',
              masteryLevel: 90,
            },
            {
              id: 3,
              chapterId: 1,
              name: '全等三角形',
              content: '全等三角形的性质和判定',
              difficulty: 'medium',
              masteryLevel: 60,
            },
          ],
        },
        {
          id: 2,
          name: '整式的乘除',
          description: '学习整式的乘法和除法运算',
          order: 2,
          knowledgePoints: [
            {
              id: 4,
              chapterId: 2,
              name: '幂的运算',
              content: '同底数幂的乘法和除法',
              difficulty: 'basic',
              masteryLevel: 75,
            },
            {
              id: 5,
              chapterId: 2,
              name: '平方差公式',
              content: '(a+b)(a-b) = a²-b²',
              difficulty: 'medium',
              masteryLevel: 55,
            },
          ],
        },
        {
          id: 3,
          name: '因式分解',
          description: '学习因式分解的方法',
          order: 3,
          knowledgePoints: [
            {
              id: 6,
              chapterId: 3,
              name: '提公因式法',
              content: '提取公因式进行分解',
              difficulty: 'basic',
              masteryLevel: 70,
            },
            {
              id: 7,
              chapterId: 3,
              name: '十字相乘法',
              content: '利用十字相乘法分解二次三项式',
              difficulty: 'advanced',
              masteryLevel: 40,
            },
          ],
        },
      ];
      setChapters(mockChapters);
    }, 500);
  }, [setChapters]);

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'basic':
        return 'green';
      case 'medium':
        return 'orange';
      case 'advanced':
        return 'red';
      default:
        return 'default';
    }
  };

  const getDifficultyText = (difficulty: string) => {
    switch (difficulty) {
      case 'basic':
        return '基础';
      case 'medium':
        return '中等';
      case 'advanced':
        return '拔高';
      default:
        return '未知';
    }
  };

  const handleStartPractice = (kp: KnowledgePoint) => {
    setCurrentKnowledgePoint(kp);
    navigate('/practice', { state: { knowledgePointId: kp.id } });
  };

  return (
    <div>
      <Card 
        title={
          <span>
            <BookOutlined style={{ marginRight: 8 }} />
            知识点学习
          </span>
        }
        extra={<Tag color="blue">初二上学期</Tag>}
      >
        {chapters.length === 0 ? (
          <Empty description="暂无章节数据" />
        ) : (
          <Collapse
            accordion
            defaultActiveKey={['1']}
            expandIcon={({ isActive }) => <RightOutlined rotate={isActive ? 90 : 0} />}
          >
            {chapters.map((chapter) => (
              <Panel
                header={
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: '16px', fontWeight: 500 }}>
                      {chapter.name}
                    </span>
                    <span style={{ fontSize: '12px', color: '#999' }}>
                      {chapter.knowledgePoints?.length || 0} 个知识点
                    </span>
                  </div>
                }
                key={chapter.id.toString()}
              >
                <Row gutter={[16, 16]}>
                  {chapter.knowledgePoints?.map((kp) => (
                    <Col xs={24} sm={12} lg={8} key={kp.id}>
                      <Card
                        hoverable
                        size="small"
                        title={kp.name}
                        extra={
                          <Tag color={getDifficultyColor(kp.difficulty)}>
                            {getDifficultyText(kp.difficulty)}
                          </Tag>
                        }
                      >
                        <p style={{ color: '#666', fontSize: '14px', minHeight: 40 }}>
                          {kp.content}
                        </p>
                        
                        <div style={{ marginTop: 16 }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                            <span style={{ fontSize: '12px', color: '#999' }}>掌握度</span>
                            <span style={{ fontSize: '12px', fontWeight: 500 }}>
                              {kp.masteryLevel}%
                            </span>
                          </div>
                          <Progress 
                            percent={kp.masteryLevel} 
                            showInfo={false}
                            strokeColor={{
                              '0%': '#108ee9',
                              '100%': '#87d068',
                            }}
                          />
                        </div>

                        <div style={{ marginTop: 16, display: 'flex', gap: 8 }}>
                          {kp.videoUrl && (
                            <Button 
                              type="default" 
                              size="small" 
                              icon={<PlayCircleOutlined />}
                              onClick={() => window.open(kp.videoUrl)}
                            >
                              视频讲解
                            </Button>
                          )}
                          <Button 
                            type="primary" 
                            size="small"
                            onClick={() => handleStartPractice(kp)}
                          >
                            开始练习
                          </Button>
                        </div>
                      </Card>
                    </Col>
                  ))}
                </Row>
              </Panel>
            ))}
          </Collapse>
        )}
      </Card>
    </div>
  );
};

export default LearnPage;
