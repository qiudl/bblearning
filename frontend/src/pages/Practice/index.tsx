import React, { useState } from 'react';
import { Card, Radio, Input, Button, Space, Alert, Result, Progress, Tag } from 'antd';
import { CheckCircleOutlined, CloseCircleOutlined, BulbOutlined } from '@ant-design/icons';
import { Question } from '../../types';

const { TextArea } = Input;

const PracticePage: React.FC = () => {
  const [currentQuestion] = useState<Question>({
    id: 1,
    knowledgePointId: 1,
    type: 'choice',
    content: '三角形的两边长分别为3和5，第三边的长度可能是（）',
    options: ['A. 1', 'B. 2', 'C. 6', 'D. 9'],
    answer: 'C',
    explanation: '根据三角形两边之和大于第三边，两边之差小于第三边的性质，第三边应满足：5-3 < x < 5+3，即 2 < x < 8，所以答案选C。',
    difficulty: 'medium',
  });

  const [userAnswer, setUserAnswer] = useState('');
  const [showResult, setShowResult] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);
  const [questionIndex, setQuestionIndex] = useState(1);
  const [totalQuestions] = useState(10);
  const [correctCount, setCorrectCount] = useState(0);

  const handleSubmit = () => {
    const correct = userAnswer.trim().toUpperCase() === currentQuestion.answer.toUpperCase();
    setIsCorrect(correct);
    setShowResult(true);
    if (correct) {
      setCorrectCount(correctCount + 1);
    }
  };

  const handleNext = () => {
    setShowResult(false);
    setUserAnswer('');
    setQuestionIndex(questionIndex + 1);
    // 这里应该加载下一题，现在暂时重置
  };

  const renderQuestionContent = () => {
    switch (currentQuestion.type) {
      case 'choice':
        return (
          <Radio.Group 
            onChange={(e) => setUserAnswer(e.target.value)} 
            value={userAnswer}
            disabled={showResult}
            style={{ width: '100%' }}
          >
            <Space direction="vertical" style={{ width: '100%' }}>
              {currentQuestion.options?.map((option) => (
                <Radio key={option} value={option.charAt(0)} style={{ fontSize: '16px', padding: '8px 0' }}>
                  {option}
                </Radio>
              ))}
            </Space>
          </Radio.Group>
        );
      case 'fill':
        return (
          <Input
            size="large"
            placeholder="请输入答案"
            value={userAnswer}
            onChange={(e) => setUserAnswer(e.target.value)}
            disabled={showResult}
          />
        );
      case 'answer':
        return (
          <TextArea
            rows={6}
            placeholder="请输入解题步骤"
            value={userAnswer}
            onChange={(e) => setUserAnswer(e.target.value)}
            disabled={showResult}
          />
        );
      default:
        return null;
    }
  };

  if (questionIndex > totalQuestions) {
    return (
      <Card>
        <Result
          status="success"
          title="练习完成！"
          subTitle={`共完成 ${totalQuestions} 题，正确 ${correctCount} 题，正确率 ${((correctCount/totalQuestions)*100).toFixed(0)}%`}
          extra={[
            <Button type="primary" key="retry">
              再来一组
            </Button>,
            <Button key="wrong">查看错题</Button>,
          ]}
        />
      </Card>
    );
  }

  return (
    <div>
      <Card 
        title="智能练习"
        extra={
          <Space>
            <Tag color="blue">三角形</Tag>
            <span>题目 {questionIndex}/{totalQuestions}</span>
          </Space>
        }
      >
        <Progress 
          percent={(questionIndex / totalQuestions) * 100} 
          showInfo={false}
          strokeColor="#1890ff"
          style={{ marginBottom: 24 }}
        />

        <Card 
          type="inner" 
          title={
            <Space>
              <span>第 {questionIndex} 题</span>
              <Tag color={
                currentQuestion.difficulty === 'basic' ? 'green' : 
                currentQuestion.difficulty === 'medium' ? 'orange' : 'red'
              }>
                {currentQuestion.difficulty === 'basic' ? '基础' : 
                 currentQuestion.difficulty === 'medium' ? '中等' : '拔高'}
              </Tag>
            </Space>
          }
        >
          <div style={{ fontSize: '16px', marginBottom: 24, lineHeight: 1.8 }}>
            {currentQuestion.content}
          </div>

          {renderQuestionContent()}

          {!showResult && (
            <div style={{ marginTop: 24 }}>
              <Button 
                type="primary" 
                size="large"
                onClick={handleSubmit}
                disabled={!userAnswer}
              >
                提交答案
              </Button>
            </div>
          )}

          {showResult && (
            <div style={{ marginTop: 24 }}>
              <Alert
                message={isCorrect ? '回答正确！' : '回答错误'}
                type={isCorrect ? 'success' : 'error'}
                icon={isCorrect ? <CheckCircleOutlined /> : <CloseCircleOutlined />}
                showIcon
                description={
                  <div>
                    <p><strong>正确答案：</strong>{currentQuestion.answer}</p>
                    <p><BulbOutlined style={{ marginRight: 8 }} /><strong>详细解析：</strong></p>
                    <p>{currentQuestion.explanation}</p>
                  </div>
                }
              />
              
              <div style={{ marginTop: 16 }}>
                <Button type="primary" size="large" onClick={handleNext}>
                  下一题
                </Button>
              </div>
            </div>
          )}
        </Card>

        <Card 
          type="inner" 
          title="答题统计" 
          style={{ marginTop: 16 }}
          bodyStyle={{ padding: '16px' }}
        >
          <Space size="large">
            <div>
              <div style={{ fontSize: '12px', color: '#999' }}>已答题</div>
              <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#1890ff' }}>
                {questionIndex - 1}
              </div>
            </div>
            <div>
              <div style={{ fontSize: '12px', color: '#999' }}>正确</div>
              <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#52c41a' }}>
                {correctCount}
              </div>
            </div>
            <div>
              <div style={{ fontSize: '12px', color: '#999' }}>错误</div>
              <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#f5222d' }}>
                {questionIndex - 1 - correctCount}
              </div>
            </div>
            <div>
              <div style={{ fontSize: '12px', color: '#999' }}>正确率</div>
              <div style={{ fontSize: '24px', fontWeight: 'bold' }}>
                {questionIndex > 1 ? ((correctCount/(questionIndex-1))*100).toFixed(0) : 0}%
              </div>
            </div>
          </Space>
        </Card>
      </Card>
    </div>
  );
};

export default PracticePage;
