import React, { useState } from 'react';
import {
  Card,
  Form,
  Input,
  Button,
  Space,
  Typography,
  Divider,
  message,
  Spin,
  Alert,
  Tag,
  Progress,
  List,
} from 'antd';
import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  ThunderboltOutlined,
  EditOutlined,
  BulbOutlined,
  TrophyOutlined,
} from '@ant-design/icons';
import aiGradeService, { AIGradeAnswerResponse } from '../../services/aiGrade';
import { handleApiError } from '../../utils/errorHandler';
import './index.css';

const { Title, Text, Paragraph } = Typography;
const { TextArea } = Input;

const AIGradePage: React.FC = () => {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [gradeResult, setGradeResult] = useState<AIGradeAnswerResponse | null>(null);

  // 提交批改
  const handleGrade = async (values: any) => {
    setLoading(true);
    setGradeResult(null);

    try {
      const response = await aiGradeService.gradeAnswer({
        question_id: values.question_id || 0,
        question_content: values.question_content,
        standard_answer: values.standard_answer,
        user_answer: values.user_answer,
      });

      setGradeResult(response);
      message.success('AI批改完成！');
    } catch (error) {
      handleApiError(error, {
        onQuotaInsufficient: () => {
          message.warning('AI配额不足，请稍后再试或联系管理员');
        },
      });
    } finally {
      setLoading(false);
    }
  };

  // 重新批改
  const handleReset = () => {
    setGradeResult(null);
    form.resetFields(['user_answer']);
  };

  return (
    <div className="ai-grade-page">
      <Card
        title={
          <Space>
            <EditOutlined />
            <span>AI智能批改</span>
          </Space>
        }
      >
        <Alert
          message="AI智能批改"
          description="提交您的答案，AI将为您提供详细的批改意见、评分和改进建议。"
          type="info"
          showIcon
          style={{ marginBottom: 24 }}
        />

        <Form
          form={form}
          layout="vertical"
          onFinish={handleGrade}
          initialValues={{
            question_id: 0,
          }}
        >
          <Form.Item
            label="题目内容"
            name="question_content"
            rules={[{ required: true, message: '请输入题目内容' }]}
          >
            <TextArea
              rows={4}
              placeholder="请输入题目内容..."
              disabled={loading}
            />
          </Form.Item>

          <Form.Item
            label="标准答案"
            name="standard_answer"
            rules={[{ required: true, message: '请输入标准答案' }]}
          >
            <TextArea
              rows={3}
              placeholder="请输入标准答案..."
              disabled={loading}
            />
          </Form.Item>

          <Form.Item
            label="您的答案"
            name="user_answer"
            rules={[{ required: true, message: '请输入您的答案' }]}
          >
            <TextArea
              rows={4}
              placeholder="请输入您的答案..."
              disabled={loading}
            />
          </Form.Item>

          <Form.Item hidden name="question_id">
            <Input type="hidden" />
          </Form.Item>

          <Form.Item>
            <Space>
              <Button
                type="primary"
                htmlType="submit"
                icon={<ThunderboltOutlined />}
                loading={loading}
                size="large"
              >
                {loading ? 'AI批改中...' : 'AI智能批改'}
              </Button>

              {gradeResult && (
                <Button
                  icon={<EditOutlined />}
                  onClick={handleReset}
                  size="large"
                >
                  重新作答
                </Button>
              )}
            </Space>
          </Form.Item>
        </Form>
      </Card>

      {/* 批改结果 */}
      {loading ? (
        <Card style={{ marginTop: 24, textAlign: 'center', padding: 48 }}>
          <Spin size="large" />
          <div style={{ marginTop: 16 }}>
            <Text type="secondary">AI正在认真批改您的答案，请稍候...</Text>
          </div>
        </Card>
      ) : gradeResult ? (
        <Card
          title={
            <Space>
              <TrophyOutlined />
              <span>批改结果</span>
            </Space>
          }
          style={{ marginTop: 24 }}
        >
          {/* 评分结果 */}
          <div className="grade-result-header">
            <div className="score-section">
              <div className="score-circle">
                <Progress
                  type="circle"
                  percent={gradeResult.score}
                  format={(percent) => (
                    <div className="score-content">
                      <div className="score-number">{percent}</div>
                      <div className="score-label">分</div>
                    </div>
                  )}
                  strokeColor={
                    gradeResult.score >= 90
                      ? '#52c41a'
                      : gradeResult.score >= 70
                      ? '#faad14'
                      : '#ff4d4f'
                  }
                  size={140}
                  strokeWidth={8}
                />
              </div>
              <div className="score-info">
                <Space direction="vertical" size="middle">
                  <div>
                    <Tag
                      icon={
                        gradeResult.is_correct ? (
                          <CheckCircleOutlined />
                        ) : (
                          <CloseCircleOutlined />
                        )
                      }
                      color={gradeResult.is_correct ? 'success' : 'error'}
                      style={{ fontSize: 16, padding: '6px 12px' }}
                    >
                      {gradeResult.is_correct ? '✓ 答案正确' : '✗ 答案错误'}
                    </Tag>
                  </div>
                  <div>
                    <Text strong style={{ fontSize: 16, marginRight: 8 }}>
                      等级：
                    </Text>
                    <Tag
                      color={aiGradeService.getScoreColor(gradeResult.score)}
                      style={{ fontSize: 14, padding: '4px 12px' }}
                    >
                      {aiGradeService.getScoreGrade(gradeResult.score)}
                    </Tag>
                  </div>
                </Space>
              </div>
            </div>
          </div>

          <Divider />

          {/* AI批改意见 */}
          <div className="feedback-section">
            <Title level={5}>
              <BulbOutlined /> AI批改意见
            </Title>
            <Paragraph className="feedback-content">
              {gradeResult.feedback}
            </Paragraph>
          </div>

          <Divider />

          {/* 改进建议 */}
          {gradeResult.suggestion && (
            <>
              <div className="suggestion-section">
                <Title level={5}>
                  <ThunderboltOutlined /> 改进建议
                </Title>
                <Paragraph className="suggestion-content">
                  {gradeResult.suggestion}
                </Paragraph>
              </div>
              <Divider />
            </>
          )}

          {/* 答题要点 */}
          {gradeResult.key_points && gradeResult.key_points.length > 0 && (
            <div className="keypoints-section">
              <Title level={5}>
                <CheckCircleOutlined /> 答题要点
              </Title>
              <List
                dataSource={gradeResult.key_points}
                renderItem={(point, index) => (
                  <List.Item>
                    <Space>
                      <Tag color="blue">{index + 1}</Tag>
                      <Text>{point}</Text>
                    </Space>
                  </List.Item>
                )}
              />
            </div>
          )}
        </Card>
      ) : null}
    </div>
  );
};

export default AIGradePage;
