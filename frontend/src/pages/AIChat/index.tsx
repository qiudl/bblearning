import React, { useState, useRef, useEffect } from 'react';
import { Card, Input, Button, Avatar, Space, Upload, message } from 'antd';
import { SendOutlined, CameraOutlined, RobotOutlined, UserOutlined } from '@ant-design/icons';
import { ChatMessage } from '../../types';
import { aiService } from '../../services/ai';
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
  const [isStreaming, setIsStreaming] = useState(false); // 是否正在流式输出
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
    const currentInput = inputValue;
    setInputValue('');
    setLoading(true);

    // 创建一个临时的 AI 消息用于流式更新
    const aiMessageId = (Date.now() + 1).toString();
    const aiMessage: ChatMessage = {
      id: aiMessageId,
      role: 'assistant',
      content: '',
      timestamp: new Date().toISOString(),
    };
    setMessages((prev) => [...prev, aiMessage]);

    try {
      // 使用流式 API
      let accumulatedContent = '';
      setIsStreaming(true);

      aiService.chatStream(
        currentInput,
        undefined,
        // onChunk: 接收到内容块时更新消息
        (content: string) => {
          accumulatedContent += content;
          setMessages((prev) =>
            prev.map((msg) =>
              msg.id === aiMessageId
                ? { ...msg, content: accumulatedContent }
                : msg
            )
          );
        },
        // onDone: 流式输出完成
        (conversationId: number) => {
          setMessages((prev) =>
            prev.map((msg) =>
              msg.id === aiMessageId
                ? { ...msg, id: conversationId.toString() }
                : msg
            )
          );
          setIsStreaming(false);
          setLoading(false);
        },
        // onError: 发生错误
        (error: string) => {
          message.error(error || 'AI服务暂时不可用，请稍后再试');
          console.error('AI Chat Stream Error:', error);

          // 更新为错误提示消息
          setMessages((prev) =>
            prev.map((msg) =>
              msg.id === aiMessageId
                ? { ...msg, content: '抱歉，我现在无法回答。请稍后再试。' }
                : msg
            )
          );
          setIsStreaming(false);
          setLoading(false);
        }
      );
    } catch (error: any) {
      message.error(error.message || 'AI服务暂时不可用，请稍后再试');
      console.error('AI Chat Error:', error);

      // 更新为错误提示消息
      setMessages((prev) =>
        prev.map((msg) =>
          msg.id === aiMessageId
            ? { ...msg, content: '抱歉，我现在无法回答。请稍后再试。' }
            : msg
        )
      );
      setIsStreaming(false);
      setLoading(false);
    }
  };

  const handleUpload = async (file: File) => {
    message.info('图片上传成功，正在识别...');

    try {
      // 将图片转换为Base64
      const reader = new FileReader();
      reader.readAsDataURL(file);

      await new Promise<void>((resolve, reject) => {
        reader.onload = async () => {
          try {
            const base64 = reader.result as string;
            const userMessage: ChatMessage = {
              id: Date.now().toString(),
              role: 'user',
              content: '[图片]',
              timestamp: new Date().toISOString(),
              images: [base64],
            };
            setMessages((prev) => [...prev, userMessage]);

            setLoading(true);

            try {
              // 调用OCR API识别题目
              const response = await aiService.recognizeQuestion(base64);

              if (response.code === 0 && response.data) {
                // OCR识别成功，显示识别结果
                const recognizedText = response.data.recognized_text;
                const aiMessage: ChatMessage = {
                  id: (Date.now() + 1).toString(),
                  role: 'assistant',
                  content: `我识别到的题目是：\n\n${recognizedText}\n\n${
                    response.data.ai_solution
                      ? `\n答案：${response.data.ai_solution}`
                      : '请问需要我帮您解答这道题吗？'
                  }\n\n(识别置信度: ${Math.round(response.data.confidence * 100)}%)`,
                  timestamp: new Date().toISOString(),
                };
                setMessages((prev) => [...prev, aiMessage]);
                message.success('题目识别成功！');
              } else {
                throw new Error(response.message || 'OCR识别失败');
              }
            } catch (ocrError: any) {
              message.error(ocrError.message || 'OCR识别失败，请重试');
              const errorMessage: ChatMessage = {
                id: (Date.now() + 1).toString(),
                role: 'assistant',
                content: '抱歉，我无法识别这张图片。请确保图片清晰，或者直接输入您的问题。',
                timestamp: new Date().toISOString(),
              };
              setMessages((prev) => [...prev, errorMessage]);
            }

            setLoading(false);
            resolve();
          } catch (error) {
            reject(error);
          }
        };

        reader.onerror = () => reject(new Error('图片读取失败'));
      });
    } catch (error: any) {
      message.error(error.message || '图片上传失败');
      console.error('Upload Error:', error);
      setLoading(false);
    }

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
        {messages.map((msg, index) => {
          // 判断是否是正在流式输出的最后一条AI消息
          const isLastAIMessage = msg.role === 'assistant' && index === messages.length - 1;
          const shouldShowCursor = isStreaming && isLastAIMessage;

          return (
            <div
              key={msg.id}
              className={`message-item ${msg.role} message-fade-in`}
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
                  className={shouldShowCursor ? 'streaming-message' : ''}
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
          );
        })}
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
