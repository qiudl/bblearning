import React from 'react';
import { Card, Row, Col, Statistic, Progress, List, Tag } from 'antd';
import {
  ClockCircleOutlined,
  FireOutlined,
  CheckCircleOutlined,
  TrophyOutlined,
} from '@ant-design/icons';

const ProgressPage: React.FC = () => {
  const knowledgePointProgress = [
    { name: '三角形的边', masteryLevel: 85, color: '#52c41a' },
    { name: '三角形的角', masteryLevel: 90, color: '#52c41a' },
    { name: '幂的运算', masteryLevel: 75, color: '#1890ff' },
    { name: '提公因式法', masteryLevel: 70, color: '#1890ff' },
    { name: '全等三角形', masteryLevel: 60, color: '#faad14' },
    { name: '平方差公式', masteryLevel: 55, color: '#faad14' },
    { name: '十字相乘法', masteryLevel: 40, color: '#ff4d4f' },
  ];

  const weeklyReport = [
    { day: '周一', questions: 15, correctRate: 73 },
    { day: '周二', questions: 20, correctRate: 80 },
    { day: '周三', questions: 12, correctRate: 75 },
    { day: '周四', questions: 18, correctRate: 78 },
    { day: '周五', questions: 22, correctRate: 85 },
    { day: '周六', questions: 0, correctRate: 0 },
    { day: '周日', questions: 0, correctRate: 0 },
  ];

  return (
    <div>
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="今日学习时长"
              value={45}
              suffix="分钟"
              prefix={<ClockCircleOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="连续学习天数"
              value={7}
              suffix="天"
              prefix={<FireOutlined />}
              valueStyle={{ color: '#ff4d4f' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="本周练习题数"
              value={87}
              suffix="题"
              prefix={<CheckCircleOutlined />}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="总体正确率"
              value={76}
              suffix="%"
              prefix={<TrophyOutlined />}
              valueStyle={{ color: '#faad14' }}
            />
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col xs={24} lg={12}>
          <Card title="知识点掌握度" bordered={false}>
            <List
              dataSource={knowledgePointProgress}
              renderItem={(item) => (
                <List.Item>
                  <div style={{ width: '100%' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                      <span>{item.name}</span>
                      <span style={{ fontWeight: 500 }}>{item.masteryLevel}%</span>
                    </div>
                    <Progress
                      percent={item.masteryLevel}
                      strokeColor={item.color}
                      showInfo={false}
                    />
                  </div>
                </List.Item>
              )}
            />
          </Card>
        </Col>

        <Col xs={24} lg={12}>
          <Card title="本周学习情况" bordered={false}>
            <List
              dataSource={weeklyReport}
              renderItem={(item) => (
                <List.Item>
                  <List.Item.Meta
                    title={item.day}
                    description={
                      item.questions > 0 ? (
                        <div>
                          <Tag color="blue">{item.questions} 题</Tag>
                          <Tag color={item.correctRate >= 80 ? 'green' : item.correctRate >= 60 ? 'orange' : 'red'}>
                            正确率 {item.correctRate}%
                          </Tag>
                        </div>
                      ) : (
                        <span style={{ color: '#999' }}>未学习</span>
                      )
                    }
                  />
                </List.Item>
              )}
            />
          </Card>
        </Col>
      </Row>

      <Card title="薄弱知识点分析" style={{ marginTop: 16 }}>
        <List
          dataSource={[
            {
              name: '十字相乘法',
              correctRate: 40,
              recommendedPractice: 10,
              tip: '建议先复习基础的因式分解方法，再重点练习十字相乘法',
            },
            {
              name: '平方差公式',
              correctRate: 55,
              recommendedPractice: 8,
              tip: '掌握公式 (a+b)(a-b) = a²-b² 的推导过程，多做变式练习',
            },
            {
              name: '全等三角形',
              correctRate: 60,
              recommendedPractice: 6,
              tip: '重点掌握 SSS、SAS、ASA、AAS 四种判定方法的应用条件',
            },
          ]}
          renderItem={(item) => (
            <List.Item
              extra={
                <Tag color="red">推荐练习 {item.recommendedPractice} 题</Tag>
              }
            >
              <List.Item.Meta
                title={
                  <span>
                    {item.name}
                    <Tag color="orange" style={{ marginLeft: 8 }}>
                      正确率 {item.correctRate}%
                    </Tag>
                  </span>
                }
                description={
                  <div style={{ color: '#666', marginTop: 8 }}>
                    💡 {item.tip}
                  </div>
                }
              />
            </List.Item>
          )}
        />
      </Card>
    </div>
  );
};

export default ProgressPage;
