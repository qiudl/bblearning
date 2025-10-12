import React, { useState, useRef, useEffect } from 'react';
import { Card, Input, Button, Avatar, Space, Upload, message } from 'antd';
import { SendOutlined, CameraOutlined, RobotOutlined, UserOutlined } from '@ant-design/icons';
import { ChatMessage } from '../../types';
import './index.css';

const { TextArea } = Input;

const AIChatPage: React.FC = () => {
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: '1',
      role: 'assistant',
      content: '你好！我是你的数学学习助手。有什么数学问题可以问我哦！你可以拍照上传题目，或者直接输入问题。',
      timestamp: new Date().toISOString(),
    },
  ]);
  const [inputValue, setInputValue] = useState('');
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async () => {
    if (!inputValue.trim()) return;

    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      role: 'user',
      content: inputValue,
      timestamp: new Date().toISOString(),
    };

    setMessages([...messages, userMessage]);
    setInputValue('');
    setLoading(true);

    // 模拟AI回复
    setTimeout(() => {
      const aiMessage: ChatMessage = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: '让我来帮你理解这个问题。首先，你能告诉我这道题涉及哪个知识点吗？比如是三角形、因式分解还是其他？这样我能更好地引导你思考。',
        timestamp: new Date().toISOString(),
      };
      setMessages((prev) => [...prev, aiMessage]);
      setLoading(false);
    }, 1000);
  };

  const handleUpload = (file: File) => {
    message.success('图片上传成功，正在识别...');
    
    // 模拟OCR识别
    setTimeout(() => {
      const userMessage: ChatMessage = {
        id: Date.now().toString(),
        role: 'user',
        content: '已识别题目：证明三角形ABC中，如果AB=AC，则∠B=∠C',
        timestamp: new Date().toISOString(),
        images: [URL.createObjectURL(file)],
      };
      setMessages((prev) => [...prev, userMessage]);

      setTimeout(() => {
        const aiMessage: ChatMessage = {
          id: (Date.now() + 1).toString(),
          role: 'assistant',
          content: '这是一道关于等腰三角形性质的证明题。让我引导你思考：\n\n1. 题目给出的条件是什么？\n2. 等腰三角形有什么特殊性质？\n3. 你觉得应该用哪种方法来证明？\n\n提示：可以考虑作辅助线，比如从A点向BC作垂线。',
          timestamp: new Date().toISOString(),
        };
        setMessages((prev) => [...prev, aiMessage]);
      }, 1500);
    }, 1000);

    return false;
  };

  return (
    <Card 
      title={
        <Space>
          <RobotOutlined />
          AI问答助手
        </Space>
      }
      extra={<span style={{ fontSize: '12px', color: '#999' }}>今日剩余提问次数：7/10</span>}
      bodyStyle={{ height: 'calc(100vh - 280px)', display: 'flex', flexDirection: 'column' }}
    >
      <div className="chat-messages" style={{ flex: 1, overflowY: 'auto', marginBottom: 16 }}>
        {messages.map((msg) => (
          <div
            key={msg.id}
            className={`message-item ${msg.role}`}
            style={{
              display: 'flex',
              marginBottom: 16,
              flexDirection: msg.role === 'user' ? 'row-reverse' : 'row',
            }}
          >
            <Avatar
              icon={msg.role === 'user' ? <UserOutlined /> : <RobotOutlined />}
              style={{
                backgroundColor: msg.role === 'user' ? '#1890ff' : '#52c41a',
                flexShrink: 0,
              }}
            />
            <div
              style={{
                maxWidth: '70%',
                marginLeft: msg.role === 'user' ? 0 : 12,
                marginRight: msg.role === 'user' ? 12 : 0,
              }}
            >
              <div
                style={{
                  padding: '12px 16px',
                  borderRadius: 8,
                  backgroundColor: msg.role === 'user' ? '#1890ff' : '#f0f0f0',
                  color: msg.role === 'user' ? '#fff' : '#000',
                  whiteSpace: 'pre-wrap',
                  wordBreak: 'break-word',
                }}
              >
                {msg.images && msg.images.length > 0 && (
                  <div style={{ marginBottom: 8 }}>
                    {msg.images.map((img, idx) => (
                      <img
                        key={idx}
                        src={img}
                        alt="uploaded"
                        style={{ maxWidth: '100%', borderRadius: 4 }}
                      />
                    ))}
                  </div>
                )}
                {msg.content}
              </div>
              <div
                style={{
                  fontSize: '12px',
                  color: '#999',
                  marginTop: 4,
                  textAlign: msg.role === 'user' ? 'right' : 'left',
                }}
              >
                {new Date(msg.timestamp).toLocaleTimeString()}
              </div>
            </div>
          </div>
        ))}
        {loading && (
          <div className="message-item assistant" style={{ display: 'flex' }}>
            <Avatar icon={<RobotOutlined />} style={{ backgroundColor: '#52c41a' }} />
            <div style={{ marginLeft: 12 }}>
              <div
                style={{
                  padding: '12px 16px',
                  borderRadius: 8,
                  backgroundColor: '#f0f0f0',
                }}
              >
                <span className="typing-indicator">AI正在思考...</span>
              </div>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      <div style={{ borderTop: '1px solid #f0f0f0', paddingTop: 16 }}>
        <Space.Compact style={{ width: '100%' }}>
          <Upload
            accept="image/*"
            beforeUpload={handleUpload}
            showUploadList={false}
          >
            <Button icon={<CameraOutlined />}>拍照提问</Button>
          </Upload>
          <TextArea
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onPressEnter={(e) => {
              if (!e.shiftKey) {
                e.preventDefault();
                handleSend();
              }
            }}
            placeholder="输入你的问题（Shift+Enter换行）"
            autoSize={{ minRows: 1, maxRows: 4 }}
            style={{ flex: 1 }}
          />
          <Button
            type="primary"
            icon={<SendOutlined />}
            onClick={handleSend}
            loading={loading}
            disabled={!inputValue.trim()}
          >
            发送
          </Button>
        </Space.Compact>
      </div>
    </Card>
  );
};

export default AIChatPage;
