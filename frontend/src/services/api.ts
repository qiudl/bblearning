import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';
import { message } from 'antd';
import { API_CONFIG } from '../config/api';

// 创建 axios 实例
const apiClient: AxiosInstance = axios.create({
  baseURL: API_CONFIG.BASE_URL,
  timeout: API_CONFIG.TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 请求拦截器
apiClient.interceptors.request.use(
  (config) => {
    // 从 localStorage 获取 token
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 响应拦截器
apiClient.interceptors.response.use(
  (response) => {
    return response.data;
  },
  async (error) => {
    const originalRequest = error.config;

    // 如果是401错误且未重试过，尝试刷新token
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const refreshToken = localStorage.getItem('refresh_token');
        if (refreshToken) {
          const response = await axios.post(
            `${API_CONFIG.BASE_URL}/auth/refresh`,
            { refresh_token: refreshToken }
          );

          const { access_token, refresh_token: newRefreshToken } = response.data.data;
          localStorage.setItem('access_token', access_token);
          localStorage.setItem('refresh_token', newRefreshToken);

          originalRequest.headers.Authorization = `Bearer ${access_token}`;
          return apiClient(originalRequest);
        }
      } catch (refreshError) {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }

    // 处理其他错误
    if (error.response) {
      const { status, data } = error.response;

      switch (status) {
        case 401:
          message.error('未授权，请重新登录');
          localStorage.removeItem('access_token');
          localStorage.removeItem('refresh_token');
          window.location.href = '/login';
          break;
        case 403:
          message.error('没有权限访问');
          break;
        case 404:
          message.error('请求的资源不存在');
          break;
        case 500:
          message.error('服务器错误');
          break;
        default:
          message.error(data?.message || '请求失败');
      }
    } else if (error.request) {
      message.error('网络错误，请检查网络连接');
    } else {
      message.error('请求配置错误');
    }

    return Promise.reject(error);
  }
);

// 通用请求方法
export const request = {
  get: <T = any>(url: string, config?: AxiosRequestConfig) =>
    apiClient.get<any, T>(url, config),
  
  post: <T = any>(url: string, data?: any, config?: AxiosRequestConfig) =>
    apiClient.post<any, T>(url, data, config),
  
  put: <T = any>(url: string, data?: any, config?: AxiosRequestConfig) =>
    apiClient.put<any, T>(url, data, config),
  
  delete: <T = any>(url: string, config?: AxiosRequestConfig) =>
    apiClient.delete<any, T>(url, config),
  
  patch: <T = any>(url: string, data?: any, config?: AxiosRequestConfig) =>
    apiClient.patch<any, T>(url, data, config),
};

export default apiClient;
