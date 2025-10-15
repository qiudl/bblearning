import axios from './api';

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  password: string;
  grade?: string;
}

export interface AuthResponse {
  access_token: string;
  refresh_token: string;
  user: {
    id: number;
    username: string;
    grade?: string;
    avatar?: string;
  };
}

// 登录
export const login = async (data: LoginRequest): Promise<AuthResponse> => {
  const response = await axios.post('/auth/login', data);
  // 响应拦截器已经返回了 response.data，所以这里直接访问 .data
  return response.data;
};

// 注册
export const register = async (data: RegisterRequest): Promise<AuthResponse> => {
  const response = await axios.post('/auth/register', data);
  return response.data;
};

// 获取当前用户
export const getCurrentUser = async () => {
  const response = await axios.get('/users/me');
  return response.data;
};

// 退出登录
export const logout = async () => {
  const response = await axios.post('/auth/logout');
  return response;
};
