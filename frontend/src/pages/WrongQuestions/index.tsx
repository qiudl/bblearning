import React, { useState } from 'react';
import { Card, List, Tag, Button, Space, Empty, Tabs } from 'antd';
import { FileTextOutlined, RedoOutlined, DeleteOutlined } from '@ant-design/icons';
import { WrongQuestion } from '../../types';

const WrongQuestionsPage: React.FC = () => {
  const [wrongQuestions] = useState<WrongQuestion[]>([
    {
      id: 1,
      userId: 1,
      questionId: 1,
      wrongCount: 3,
      lastWrongTime: '2025-10-12T10:00:00Z',
      question: {
        id: 1,
        knowledgePointId: 1,
        type: 'choice',
        content: '三角形的两边长分别为3和5，第三边的长度可能是（）',
        options: ['A. 1', 'B. 2', 'C. 6', 'D. 9'],
        answer: 'C',
        explanation: '根据三角形两边之和大于第三边，两边之差小于第三边的性质...',
        difficulty: 'medium',
      },
    },
    {
      id: 2,
      userId: 1,
      questionId: 7,
      wrongCount: 2,
      lastWrongTime: '2025-10-11T15:30:00Z',
      question: {
        id: 7,
        knowledgePointId: 7,
        type: 'answer',
        content: '分解因式：x²-5x+6',
        answer: '(x-2)(x-3)',
        explanation: '使用十字相乘法分解...',
        difficulty: 'advanced',
      },
    },
  ]);

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

  const getTypeText = (type: string) => {
    switch (type) {
      case 'choice':
        return '选择题';
      case 'fill':
        return '填空题';
      case 'answer':
        return '解答题';
      default:
        return '未知';
    }
  };

  return (
    <div>
      <Card
        title={
          <Space>
            <FileTextOutlined />
            我的错题本
          </Space>
        }
        extra={
          <Space>
            <span style={{ fontSize: '12px', color: '#999' }}>共 {wrongQuestions.length} 道错题</span>
            <Button type="primary" icon={<RedoOutlined />}>
              重做全部
            </Button>
          </Space>
        }
      >
        <Tabs
          defaultActiveKey="all"
          items={[
            {
              key: 'all',
              label: '全部错题',
              children: (
                <List
                  dataSource={wrongQuestions}
                  renderItem={(item) => (
                    <List.Item
                      key={item.id}
                      actions={[
                        <Button type="link" icon={<RedoOutlined />}>
                          重做
                        </Button>,
                        <Button type="link" danger icon={<DeleteOutlined />}>
                          移除
                        </Button>,
                      ]}
                    >
                      <List.Item.Meta
                        title={
                          <Space>
                            <Tag color={getDifficultyColor(item.question?.difficulty || 'basic')}>
                              {item.question?.difficulty === 'basic' ? '基础' : 
                               item.question?.difficulty === 'medium' ? '中等' : '拔高'}
                            </Tag>
                            <Tag>{getTypeText(item.question?.type || '')}</Tag>
                            <span>{item.question?.content}</span>
                          </Space>
                        }
                        description={
                          <Space direction="vertical" style={{ width: '100%' }}>
                            <div>
                              <span style={{ color: '#999' }}>错误次数：</span>
                              <Tag color="red">{item.wrongCount} 次</Tag>
                              <span style={{ color: '#999', marginLeft: 16 }}>
                                最后错误时间：{new Date(item.lastWrongTime).toLocaleString()}
                              </span>
                            </div>
                            <div>
                              <span style={{ fontWeight: 500 }}>正确答案：</span>
                              <span style={{ color: '#52c41a' }}>{item.question?.answer}</span>
                            </div>
                          </Space>
                        }
                      />
                    </List.Item>
                  )}
                  locale={{ emptyText: <Empty description="暂无错题，继续加油！" /> }}
                />
              ),
            },
            {
              key: 'byChapter',
              label: '按章节',
              children: <Empty description="按章节分类功能开发中..." />,
            },
            {
              key: 'byDifficulty',
              label: '按难度',
              children: <Empty description="按难度分类功能开发中..." />,
            },
          ]}
        />
      </Card>
    </div>
  );
};

export default WrongQuestionsPage;
