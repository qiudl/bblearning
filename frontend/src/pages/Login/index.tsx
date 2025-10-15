import React, { useState } from 'react';
import { Form, Input, Button, Card, message, Tabs } from 'antd';
import { UserOutlined, LockOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { login, register } from '../../services/auth';
import { useAuthStore } from '../../store/auth';
import './index.css';

const LoginPage: React.FC = () => {
  const navigate = useNavigate();
  const setAuth = useAuthStore((state) => state.setAuth);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('login');

  // 登录
  const onLogin = async (values: any) => {
    setLoading(true);
    try {
      console.log('🔐 开始登录...', values);
      const result = await login({
        username: values.username,
        password: values.password,
      });

      console.log('✅ 登录API返回:', result);
      setAuth(result.user, result.access_token, result.refresh_token);
      console.log('✅ 状态已更新，准备跳转到 /learn');
      message.success('登录成功！');
      navigate('/learn');
      console.log('✅ navigate已调用');
    } catch (error: any) {
      console.error('❌ 登录失败:', error);
      message.error(error.response?.data?.message || '登录失败，请检查用户名和密码');
    } finally {
      setLoading(false);
    }
  };

  // 注册
  const onRegister = async (values: any) => {
    if (values.password !== values.confirmPassword) {
      message.error('两次输入的密码不一致');
      return;
    }

    setLoading(true);
    try {
      const result = await register({
        username: values.username,
        password: values.password,
        grade: values.grade,
      });

      setAuth(result.user, result.access_token, result.refresh_token);
      message.success('注册成功！');
      navigate('/learn');
    } catch (error: any) {
      message.error(error.response?.data?.message || '注册失败，请重试');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <Card className="login-card" title="BBLearning - 初中数学学习平台">
        <Tabs activeKey={activeTab} onChange={setActiveTab}>
          <Tabs.TabPane tab="登录" key="login">
            <Form
              name="login"
              onFinish={onLogin}
              autoComplete="off"
            >
              <Form.Item
                name="username"
                rules={[{ required: true, message: '请输入用户名' }]}
              >
                <Input
                  prefix={<UserOutlined />}
                  placeholder="用户名"
                  size="large"
                />
              </Form.Item>

              <Form.Item
                name="password"
                rules={[{ required: true, message: '请输入密码' }]}
              >
                <Input.Password
                  prefix={<LockOutlined />}
                  placeholder="密码"
                  size="large"
                />
              </Form.Item>

              <Form.Item>
                <Button
                  type="primary"
                  htmlType="submit"
                  loading={loading}
                  block
                  size="large"
                >
                  登录
                </Button>
              </Form.Item>
            </Form>
          </Tabs.TabPane>

          <Tabs.TabPane tab="注册" key="register">
            <Form
              name="register"
              onFinish={onRegister}
              autoComplete="off"
            >
              <Form.Item
                name="username"
                rules={[
                  { required: true, message: '请输入用户名' },
                  { min: 3, message: '用户名至少3个字符' },
                ]}
              >
                <Input
                  prefix={<UserOutlined />}
                  placeholder="用户名（至少3个字符）"
                  size="large"
                />
              </Form.Item>

              <Form.Item
                name="password"
                rules={[
                  { required: true, message: '请输入密码' },
                  { min: 6, message: '密码至少6个字符' },
                ]}
              >
                <Input.Password
                  prefix={<LockOutlined />}
                  placeholder="密码（至少6个字符）"
                  size="large"
                />
              </Form.Item>

              <Form.Item
                name="confirmPassword"
                rules={[
                  { required: true, message: '请确认密码' },
                ]}
              >
                <Input.Password
                  prefix={<LockOutlined />}
                  placeholder="确认密码"
                  size="large"
                />
              </Form.Item>

              <Form.Item
                name="grade"
                rules={[{ required: true, message: '请选择年级' }]}
              >
                <Input
                  placeholder="年级（如：7）"
                  size="large"
                />
              </Form.Item>

              <Form.Item>
                <Button
                  type="primary"
                  htmlType="submit"
                  loading={loading}
                  block
                  size="large"
                >
                  注册
                </Button>
              </Form.Item>
            </Form>
          </Tabs.TabPane>
        </Tabs>
      </Card>
    </div>
  );
};

export default LoginPage;
