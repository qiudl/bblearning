import React, { Component, ErrorInfo, ReactNode } from 'react';
import { Result, Button } from 'antd';
import { logReactError } from '../../utils/errorMonitor';
import './index.css';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
  errorInfo?: ErrorInfo;
}

/**
 * React错误边界组件
 * 捕获子组件树中的JavaScript错误，记录错误并显示降级UI
 */
class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      hasError: false,
    };
  }

  static getDerivedStateFromError(error: Error): State {
    return {
      hasError: true,
      error,
    };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    // 记录错误到监控系统
    logReactError(error, errorInfo);

    // 更新状态
    this.setState({
      error,
      errorInfo,
    });

    // 打印到控制台
    console.error('[ErrorBoundary] Component error:', error, errorInfo);
  }

  handleReset = (): void => {
    this.setState({
      hasError: false,
      error: undefined,
      errorInfo: undefined,
    });
  };

  render(): ReactNode {
    const { hasError, error } = this.state;
    const { children, fallback } = this.props;

    if (hasError) {
      // 如果提供了自定义降级UI，使用自定义UI
      if (fallback) {
        return fallback;
      }

      // 默认降级UI
      return (
        <div className="error-boundary">
          <Result
            status="error"
            title="页面出错了"
            subTitle={
              process.env.NODE_ENV === 'development'
                ? error?.message
                : '抱歉，页面遇到了一些问题，请稍后重试。'
            }
            extra={[
              <Button type="primary" key="refresh" onClick={this.handleReset}>
                刷新页面
              </Button>,
              <Button
                key="back"
                onClick={() => (window.location.href = '/')}
              >
                返回首页
              </Button>,
            ]}
          />

          {process.env.NODE_ENV === 'development' && (
            <div className="error-details">
              <h3>错误详情（仅开发环境显示）：</h3>
              <pre>{error?.stack}</pre>
              {this.state.errorInfo && (
                <>
                  <h3>组件栈：</h3>
                  <pre>{this.state.errorInfo.componentStack}</pre>
                </>
              )}
            </div>
          )}
        </div>
      );
    }

    return children;
  }
}

export default ErrorBoundary;
