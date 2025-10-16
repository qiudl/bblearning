import React, { useState, useEffect } from 'react';
import {
  Card,
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
  Empty,
  Row,
  Col,
  Statistic,
} from 'antd';
import {
  ThunderboltOutlined,
  TrophyOutlined,
  BulbOutlined,
  WarningOutlined,
  RocketOutlined,
  CheckCircleOutlined,
} from '@ant-design/icons';
import aiDiagnoseService, { AIDiagnoseResponse, WeakPointAnalysis } from '../../services/aiDiagnose';
import { handleApiError } from '../../utils/errorHandler';
import './index.css';

const { Title, Text, Paragraph } = Typography;

const AIDiagnosePage: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [diagnoseResult, setDiagnoseResult] = useState<AIDiagnoseResponse | null>(null);

  // 生成诊断报告
  const handleDiagnose = async () => {
    setLoading(true);
    setDiagnoseResult(null);

    try {
      const response = await aiDiagnoseService.diagnose();
      setDiagnoseResult(response);
      message.success('学习诊断完成！');
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

  // 页面加载时自动诊断
  useEffect(() => {
    handleDiagnose();
  }, []);

  // 渲染薄弱点卡片
  const renderWeakPointCard = (weakPoint: WeakPointAnalysis, index: number) => {
    const masteryPercent = weakPoint.mastery_level * 100;
    const errorPercent = weakPoint.error_rate * 100;

    return (
      <Card
        key={index}
        className="weak-point-card"
        style={{ marginBottom: 16 }}
        hoverable
      >
        <div className="weak-point-header">
          <Space>
            <Tag color="volcano">薄弱点 {index + 1}</Tag>
            <Title level={5} style={{ margin: 0 }}>
              {weakPoint.knowledge_point}
            </Title>
          </Space>
        </div>

        <Row gutter={16} style={{ marginTop: 16 }}>
          <Col span={12}>
            <div className="mastery-progress">
              <Text strong>掌握度</Text>
              <Progress
                percent={Number(masteryPercent.toFixed(1))}
                strokeColor={aiDiagnoseService.getMasteryColor(weakPoint.mastery_level)}
                status="active"
              />
              <Text type="secondary">
                {aiDiagnoseService.getMasteryGrade(weakPoint.mastery_level)}
              </Text>
            </div>
          </Col>
          <Col span={12}>
            <div className="error-progress">
              <Text strong>错误率</Text>
              <Progress
                percent={Number(errorPercent.toFixed(1))}
                strokeColor="#ff4d4f"
                status="exception"
              />
              <Tag color={aiDiagnoseService.getErrorRateColor(weakPoint.error_rate)}>
                {aiDiagnoseService.formatPercentage(weakPoint.error_rate)}
              </Tag>
            </div>
          </Col>
        </Row>

        {weakPoint.common_mistakes && weakPoint.common_mistakes.length > 0 && (
          <div className="common-mistakes" style={{ marginTop: 16 }}>
            <Text strong>
              <WarningOutlined /> 常见错误：
            </Text>
            <List
              size="small"
              dataSource={weakPoint.common_mistakes}
              renderItem={(mistake, idx) => (
                <List.Item style={{ padding: '8px 0', border: 'none' }}>
                  <Space>
                    <Tag color="red">{idx + 1}</Tag>
                    <Text>{mistake}</Text>
                  </Space>
                </List.Item>
              )}
            />
          </div>
        )}
      </Card>
    );
  };

  return (
    <div className="ai-diagnose-page">
      <Card
        title={
          <Space>
            <TrophyOutlined />
            <span>AI学习诊断</span>
          </Space>
        }
        extra={
          <Button
            type="primary"
            icon={<ThunderboltOutlined />}
            onClick={handleDiagnose}
            loading={loading}
          >
            重新诊断
          </Button>
        }
      >
        <Alert
          message="智能学习诊断"
          description="AI将分析您的学习数据，找出薄弱知识点，并提供针对性的学习建议。"
          type="info"
          showIcon
          style={{ marginBottom: 24 }}
        />
      </Card>

      {/* 诊断结果 */}
      {loading ? (
        <Card style={{ marginTop: 24, textAlign: 'center', padding: 48 }}>
          <Spin size="large" />
          <div style={{ marginTop: 16 }}>
            <Text type="secondary">AI正在分析您的学习数据，请稍候...</Text>
          </div>
        </Card>
      ) : diagnoseResult ? (
        <>
          {/* 整体水平 */}
          <Card title="整体水平评估" style={{ marginTop: 24 }}>
            <div className="overall-level">
              <Statistic
                title="您的水平"
                value={aiDiagnoseService.formatOverallLevel(diagnoseResult.overall_level).text}
                prefix={<TrophyOutlined />}
                valueStyle={{
                  color:
                    diagnoseResult.overall_level === 'advanced'
                      ? '#52c41a'
                      : diagnoseResult.overall_level === 'intermediate'
                      ? '#1890ff'
                      : '#8c8c8c',
                }}
              />
            </div>
          </Card>

          {/* 薄弱知识点 */}
          <Card
            title={
              <Space>
                <WarningOutlined />
                <span>薄弱知识点分析</span>
              </Space>
            }
            style={{ marginTop: 24 }}
          >
            {diagnoseResult.weak_points && diagnoseResult.weak_points.length > 0 ? (
              <>
                <Alert
                  message={`发现 ${diagnoseResult.weak_points.length} 个薄弱知识点`}
                  description="建议优先学习以下知识点，提升整体水平。"
                  type="warning"
                  showIcon
                  style={{ marginBottom: 16 }}
                />
                {aiDiagnoseService.sortWeakPoints(diagnoseResult.weak_points).map((weakPoint, index) =>
                  renderWeakPointCard(weakPoint, index)
                )}
              </>
            ) : (
              <Empty description="暂无薄弱知识点，继续保持！" />
            )}
          </Card>

          {/* 学习建议 */}
          {diagnoseResult.recommendations && diagnoseResult.recommendations.length > 0 && (
            <Card
              title={
                <Space>
                  <BulbOutlined />
                  <span>学习建议</span>
                </Space>
              }
              style={{ marginTop: 24 }}
            >
              <List
                dataSource={diagnoseResult.recommendations}
                renderItem={(recommendation, index) => (
                  <List.Item>
                    <Space align="start">
                      <CheckCircleOutlined style={{ color: '#52c41a', fontSize: 16, marginTop: 4 }} />
                      <div>
                        <Text strong>建议 {index + 1}：</Text>
                        <Paragraph style={{ margin: '4px 0 0 0' }}>{recommendation}</Paragraph>
                      </div>
                    </Space>
                  </List.Item>
                )}
              />
            </Card>
          )}

          {/* 下一步行动 */}
          {diagnoseResult.next_steps && diagnoseResult.next_steps.length > 0 && (
            <Card
              title={
                <Space>
                  <RocketOutlined />
                  <span>下一步行动</span>
                </Space>
              }
              style={{ marginTop: 24 }}
            >
              <List
                dataSource={diagnoseResult.next_steps}
                renderItem={(step, index) => (
                  <List.Item>
                    <Space>
                      <Tag color="blue" style={{ minWidth: 28, textAlign: 'center' }}>
                        {index + 1}
                      </Tag>
                      <Text>{step}</Text>
                    </Space>
                  </List.Item>
                )}
              />
            </Card>
          )}
        </>
      ) : (
        <Card style={{ marginTop: 24 }}>
          <Empty description="暂无诊断数据，请点击"生成诊断报告"按钮" />
        </Card>
      )}
    </div>
  );
};

export default AIDiagnosePage;
