import React from 'react';
import { Layout, Menu, Avatar, Dropdown, Space } from 'antd';
import {
  BookOutlined,
  EditOutlined,
  MessageOutlined,
  FileTextOutlined,
  BarChartOutlined,
  UserOutlined,
  LogoutOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
} from '@ant-design/icons';
import { useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuthStore } from '../../store/auth';
import { useAppStore } from '../../store';
import type { MenuProps } from 'antd';
import './MainLayout.css';

const { Header, Sider, Content } = Layout;

const MainLayout: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, clearAuth } = useAuthStore();
  const { sidebarCollapsed, toggleSidebar } = useAppStore();

  // 菜单项
  const menuItems: MenuProps['items'] = [
    {
      key: '/learn',
      icon: <BookOutlined />,
      label: '知识点学习',
      onClick: () => navigate('/learn'),
    },
    {
      key: '/practice',
      icon: <EditOutlined />,
      label: '智能练习',
      onClick: () => navigate('/practice'),
    },
    {
      key: '/ai-chat',
      icon: <MessageOutlined />,
      label: 'AI问答助手',
      onClick: () => navigate('/ai-chat'),
    },
    {
      key: '/wrong-questions',
      icon: <FileTextOutlined />,
      label: '错题本',
      onClick: () => navigate('/wrong-questions'),
    },
    {
      key: '/progress',
      icon: <BarChartOutlined />,
      label: '学习进度',
      onClick: () => navigate('/progress'),
    },
  ];

  // 用户菜单
  const userMenuItems: MenuProps['items'] = [
    {
      key: 'profile',
      icon: <UserOutlined />,
      label: '个人信息',
      onClick: () => navigate('/profile'),
    },
    {
      type: 'divider',
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: '退出登录',
      onClick: () => {
        clearAuth();
        navigate('/login');
      },
    },
  ];

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sider
        trigger={null}
        collapsible
        collapsed={sidebarCollapsed}
        style={{
          overflow: 'auto',
          height: '100vh',
          position: 'fixed',
          left: 0,
          top: 0,
          bottom: 0,
        }}
      >
        <div className="logo">
          <BookOutlined style={{ fontSize: '24px', color: '#fff' }} />
          {!sidebarCollapsed && <span style={{ marginLeft: '12px', color: '#fff', fontSize: '18px', fontWeight: 'bold' }}>Math智学</span>}
        </div>
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[location.pathname]}
          items={menuItems}
        />
      </Sider>
      <Layout style={{ marginLeft: sidebarCollapsed ? 80 : 200, transition: 'all 0.2s' }}>
        <Header style={{ background: '#fff', padding: '0 24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', boxShadow: '0 1px 4px rgba(0,21,41,.08)' }}>
          <div onClick={toggleSidebar} style={{ cursor: 'pointer', fontSize: '18px' }}>
            {sidebarCollapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
          </div>
          <Dropdown menu={{ items: userMenuItems }} placement="bottomRight">
            <Space style={{ cursor: 'pointer' }}>
              <Avatar icon={<UserOutlined />} src={user?.avatar} />
              <span>{user?.username || '用户'}</span>
            </Space>
          </Dropdown>
        </Header>
        <Content style={{ margin: '24px 16px', padding: 24, background: '#fff', minHeight: 280 }}>
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  );
};

export default MainLayout;
