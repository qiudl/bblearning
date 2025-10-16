import React, { useState, useEffect } from 'react';
import {
  Card,
  Form,
  Select,
  InputNumber,
  Button,
  Space,
  List,
  Tag,
  Typography,
  Divider,
  message,
  Spin,
  Empty,
  Tooltip,
  Alert,
  Modal,
} from 'antd';
import {
  ThunderboltOutlined,
  BulbOutlined,
  SaveOutlined,
  ReloadOutlined,
  CheckCircleOutlined,
} from '@ant-design/icons';
import aiGenerateService, { QuestionInfo } from '../../services/aiGenerate';
import quotaService, { QuotaInfo } from '../../services/quota';
import knowledgeService, { KnowledgePoint } from '../../services/knowledge';
import { handleApiError } from '../../utils/errorHandler';
import './index.css';

const { Title, Text, Paragraph } = Typography;
const { Option } = Select;

const AIGeneratePage: React.FC = () => {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [generatedQuestions, setGeneratedQuestions] = useState<QuestionInfo[]>([]);
  const [quotaInfo, setQuotaInfo] = useState<QuotaInfo | null>(null);
  const [knowledgePoints, setKnowledgePoints] = useState<KnowledgePoint[]>([]);
  const [savingIds, setSavingIds] = useState<Set<number>>(new Set());
  const [loadingKnowledge, setLoadingKnowledge] = useState(false);

  // 加载配额信息和知识点
  useEffect(() => {
    loadQuotaInfo();
    loadKnowledgePoints();
  }, []);

  const loadQuotaInfo = async () => {
    try {
      const quota = await quotaService.getMyQuota();
      setQuotaInfo(quota);
    } catch (error) {
      console.error('Failed to load quota:', error);
    }
  };

  const loadKnowledgePoints = async () => {
    setLoadingKnowledge(true);
    try {
      // 获取所有年级的知识点，或者可以根据当前用户年级过滤
      const points = await knowledgeService.getAllKnowledgePoints();
      setKnowledgePoints(points);
    } catch (error) {
      console.error('Failed to load knowledge points:', error);
      message.error('加载知识点失败');
    } finally {
      setLoadingKnowledge(false);
    }
  };

  // 生成题目
  const handleGenerate = async (values: any) => {
    setLoading(true);

    try {
      const response = await aiGenerateService.generateQuestions({
        knowledge_point_id: values.knowledge_point_id,
        difficulty: values.difficulty,
        type: values.type,
        count: values.count,
      });

      setGeneratedQuestions(response.questions);
      message.success(`成功生成 ${response.count} 道题目！`);

      // 刷新配额
      loadQuotaInfo();
    } catch (error) {
      handleApiError(error, {
        onQuotaInsufficient: () => {
          Modal.warning({
            title: '配额不足',
            content: '您的AI配额不足，无法生成题目。请联系管理员充值或等待配额重置。',
          });
        },
      });
    } finally {
      setLoading(false);
    }
  };

  // 保存单个题目
  const handleSaveQuestion = async (question: QuestionInfo, index: number) => {
    setSavingIds(prev => new Set(prev).add(index));

    try {
      await aiGenerateService.saveQuestion(question);
      message.success('题目已保存到题库');

      // 从列表中移除已保存的题目
      setGeneratedQuestions(prev => prev.filter((_, i) => i !== index));
    } catch (error) {
      handleApiError(error);
    } finally {
      setSavingIds(prev => {
        const newSet = new Set(prev);
        newSet.delete(index);
        return newSet;
      });
    }
  };

  // 批量保存所有题目
  const handleSaveAll = async () => {
    if (generatedQuestions.length === 0) {
      message.warning('没有可保存的题目');
      return;
    }

    Modal.confirm({
      title: '批量保存',
      content: `确定要将所有 ${generatedQuestions.length} 道题目保存到题库吗？`,
      onOk: async () => {
        setLoading(true);
        try {
          const result = await aiGenerateService.batchSaveQuestions(generatedQuestions);
          message.success(`成功保存 ${result.saved} 道题目${result.failed > 0 ? `，失败 ${result.failed} 道` : ''}`);
          setGeneratedQuestions([]);
        } catch (error) {
          handleApiError(error);
        } finally {
          setLoading(false);
        }
      },
    });
  };

  // 重新生成
  const handleRegenerate = () => {
    form.submit();
  };

  return (
    <div className="ai-generate-page">
      <Card
        title={
          <Space>
            <BulbOutlined />
            <span>AI智能生成题目</span>
          </Space>
        }
        extra={
          quotaInfo && (
            <Tooltip title={quotaService.getNextResetTime(quotaInfo)}>
              <Tag
                icon={<ThunderboltOutlined />}
                color={quotaInfo.total_available > 10 ? 'success' : quotaInfo.total_available > 0 ? 'warning' : 'error'}
              >
                可用配额: {quotaInfo.total_available}
              </Tag>
            </Tooltip>
          )
        }
      >
        <Alert
          message="AI智能生成"
          description="根据知识点、难度和题型，AI将为您生成高质量的练习题目。每次生成会消耗相应的AI配额。"
          type="info"
          showIcon
          style={{ marginBottom: 24 }}
        />

        <Form
          form={form}
          layout="vertical"
          onFinish={handleGenerate}
          initialValues={{
            difficulty: 'medium',
            type: 'choice',
            count: 5,
          }}
        >
          <Form.Item
            label="知识点"
            name="knowledge_point_id"
            rules={[{ required: true, message: '请选择知识点' }]}
          >
            <Select
              placeholder="请选择要生成题目的知识点"
              showSearch
              optionFilterProp="children"
              size="large"
              loading={loadingKnowledge}
              filterOption={(input, option) =>
                (option?.children as string)?.toLowerCase().includes(input.toLowerCase())
              }
            >
              {knowledgePoints.map((point: any) => (
                <Option key={point.id} value={point.id}>
                  {knowledgeService.formatKnowledgePointName(point)}
                </Option>
              ))}
            </Select>
          </Form.Item>

          <Space size="large" style={{ width: '100%' }}>
            <Form.Item
              label="难度"
              name="difficulty"
              rules={[{ required: true, message: '请选择难度' }]}
            >
              <Select style={{ width: 150 }} size="large">
                <Option value="basic">
                  <Tag color="success">基础</Tag>
                </Option>
                <Option value="medium">
                  <Tag color="warning">中等</Tag>
                </Option>
                <Option value="advanced">
                  <Tag color="error">困难</Tag>
                </Option>
              </Select>
            </Form.Item>

            <Form.Item
              label="题型"
              name="type"
              rules={[{ required: true, message: '请选择题型' }]}
            >
              <Select style={{ width: 150 }} size="large">
                <Option value="choice">📝 选择题</Option>
                <Option value="fill">✏️ 填空题</Option>
                <Option value="answer">📋 解答题</Option>
              </Select>
            </Form.Item>

            <Form.Item
              label="数量"
              name="count"
              rules={[
                { required: true, message: '请输入数量' },
                { type: 'number', min: 1, max: 10, message: '数量范围：1-10' },
              ]}
            >
              <InputNumber min={1} max={10} style={{ width: 120 }} size="large" />
            </Form.Item>
          </Space>

          <Form.Item>
            <Space>
              <Button
                type="primary"
                htmlType="submit"
                icon={<ThunderboltOutlined />}
                loading={loading}
                size="large"
                disabled={quotaInfo?.total_available === 0}
              >
                {loading ? '生成中...' : 'AI生成题目'}
              </Button>

              {generatedQuestions.length > 0 && (
                <>
                  <Button
                    icon={<ReloadOutlined />}
                    onClick={handleRegenerate}
                    disabled={loading}
                    size="large"
                  >
                    重新生成
                  </Button>

                  <Button
                    type="default"
                    icon={<SaveOutlined />}
                    onClick={handleSaveAll}
                    disabled={loading}
                    size="large"
                  >
                    全部保存到题库
                  </Button>
                </>
              )}
            </Space>
          </Form.Item>
        </Form>
      </Card>

      {/* 生成结果 */}
      {loading ? (
        <Card style={{ marginTop: 24, textAlign: 'center', padding: 48 }}>
          <Spin size="large" />
          <div style={{ marginTop: 16 }}>
            <Text type="secondary">AI正在生成题目，请稍候...</Text>
          </div>
        </Card>
      ) : generatedQuestions.length > 0 ? (
        <Card title="生成结果" style={{ marginTop: 24 }}>
          <List
            dataSource={generatedQuestions}
            renderItem={(question, index) => (
              <List.Item
                key={index}
                actions={[
                  <Button
                    type="primary"
                    icon={<SaveOutlined />}
                    onClick={() => handleSaveQuestion(question, index)}
                    loading={savingIds.has(index)}
                    size="small"
                  >
                    保存到题库
                  </Button>,
                ]}
              >
                <List.Item.Meta
                  title={
                    <Space>
                      <Text strong>题目 {index + 1}</Text>
                      <Tag color={aiGenerateService.getDifficultyColor(question.difficulty || 'medium')}>
                        {aiGenerateService.formatDifficulty(question.difficulty || 'medium')}
                      </Tag>
                      <Tag>{aiGenerateService.formatType(question.type)}</Tag>
                    </Space>
                  }
                  description={
                    <div style={{ marginTop: 8 }}>
                      <Paragraph style={{ fontSize: 16, marginBottom: 16 }}>
                        <Text strong>题目：</Text>
                        <br />
                        {question.content}
                      </Paragraph>

                      {question.options && question.options.length > 0 && (
                        <Paragraph>
                          <Text strong>选项：</Text>
                          <br />
                          {question.options.map((opt, i) => (
                            <div key={i} style={{ marginLeft: 16, marginTop: 4 }}>
                              {String.fromCharCode(65 + i)}. {opt}
                            </div>
                          ))}
                        </Paragraph>
                      )}

                      <Paragraph>
                        <Text strong>答案：</Text>
                        <Text type="success" style={{ marginLeft: 8 }}>
                          {question.answer}
                        </Text>
                      </Paragraph>

                      {question.explanation && (
                        <Paragraph>
                          <Text strong>解析：</Text>
                          <br />
                          <Text type="secondary">{question.explanation}</Text>
                        </Paragraph>
                      )}
                    </div>
                  }
                />
              </List.Item>
            )}
          />
        </Card>
      ) : null}
    </div>
  );
};

export default AIGeneratePage;
