import axios from 'axios'
import { API_CONFIG, handleApiError } from './config'

// 创建axios实例
const request = axios.create({
  baseURL: API_CONFIG.API_BASE,
  timeout: API_CONFIG.TIMEOUT,
  headers: API_CONFIG.DEFAULT_HEADERS
})

// Token刷新状态管理
let isRefreshing = false
let refreshSubscribers = []

// 订阅token刷新
const subscribeTokenRefresh = (callback) => {
  refreshSubscribers.push(callback)
}

// 通知所有订阅者token已刷新
const onTokenRefreshed = (token) => {
  refreshSubscribers.forEach((callback) => callback(token))
  refreshSubscribers = []
}

// 检测用户类型
const getUserType = () => {
  // 根据当前路径判断用户类型
  const path = window.location.pathname
  if (path.startsWith('/admin')) {
    return 'admin'
  } else if (path.startsWith('/student') || localStorage.getItem('student_access_token')) {
    return 'student'
  }
  return 'student' // 默认为学生
}

// 获取token的键名
const getTokenKeys = (userType) => {
  if (userType === 'admin') {
    return {
      accessToken: 'admin_access_token',
      refreshToken: 'admin_refresh_token'
    }
  }
  return {
    accessToken: 'student_access_token',
    refreshToken: 'student_refresh_token'
  }
}

// 获取刷新token的端点
const getRefreshEndpoint = (userType) => {
  if (userType === 'admin') {
    return '/admin/auth/refresh'
  }
  return '/student/auth/refresh'
}

// 刷新token
const refreshAccessToken = async (userType) => {
  const tokenKeys = getTokenKeys(userType)
  const refreshToken = localStorage.getItem(tokenKeys.refreshToken)
  
  if (!refreshToken) {
    throw new Error('No refresh token available')
  }

  try {
    const response = await axios.post(
      `${API_CONFIG.API_BASE}${getRefreshEndpoint(userType)}`,
      { refresh_token: refreshToken },
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    )

    const data = response.data.data || response.data
    const { access_token, refresh_token: newRefreshToken } = data

    // 更新本地存储
    localStorage.setItem(tokenKeys.accessToken, access_token)
    if (newRefreshToken) {
      localStorage.setItem(tokenKeys.refreshToken, newRefreshToken)
    }

    return access_token
  } catch (error) {
    // 刷新失败，清除所有token
    clearAllTokens()
    throw error
  }
}

// 清除所有token
const clearAllTokens = () => {
  localStorage.removeItem('access_token')
  localStorage.removeItem('student_access_token')
  localStorage.removeItem('admin_access_token')
  localStorage.removeItem('refresh_token')
  localStorage.removeItem('student_refresh_token')
  localStorage.removeItem('admin_refresh_token')
  localStorage.removeItem('user_info')
  localStorage.removeItem('student_user_info')
  localStorage.removeItem('admin_user_info')
}

// 重定向到登录页
const redirectToLogin = () => {
  const path = window.location.pathname
  if (path.startsWith('/admin')) {
    window.location.href = '/admin/login'
  } else {
    window.location.href = '/login'
  }
}

// 请求拦截器 - 添加token
request.interceptors.request.use(
  (config) => {
    const userType = getUserType()
    const tokenKeys = getTokenKeys(userType)
    const token = localStorage.getItem(tokenKeys.accessToken) || 
                  localStorage.getItem('access_token')
    
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    console.error('请求错误:', error)
    return Promise.reject(error)
  }
)

// 响应拦截器 - 处理错误和自动刷新token
request.interceptors.response.use(
  (response) => {
    // 返回完整的响应对象，让调用方自己决定如何处理
    return response
  },
  async (error) => {
    const originalRequest = error.config

    // 401错误 - token过期或无效
    if (error.response && error.response.status === 401) {
      // 如果是刷新token的请求失败，直接跳转登录
      if (originalRequest.url.includes('/auth/refresh')) {
        console.error('刷新token失败，跳转到登录页')
        clearAllTokens()
        redirectToLogin()
        return Promise.reject(error)
      }

      // 如果已经重试过，不再重试
      if (originalRequest._retry) {
        console.error('重试失败，跳转到登录页')
        clearAllTokens()
        redirectToLogin()
        return Promise.reject(error)
      }

      // 标记为已重试
      originalRequest._retry = true

      // 如果正在刷新token，将请求加入队列
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          subscribeTokenRefresh((token) => {
            originalRequest.headers.Authorization = `Bearer ${token}`
            resolve(request(originalRequest))
          })
        })
      }

      // 开始刷新token
      isRefreshing = true

      try {
        const userType = getUserType()
        const newToken = await refreshAccessToken(userType)
        
        // 刷新成功，更新请求头
        originalRequest.headers.Authorization = `Bearer ${newToken}`
        
        // 通知所有等待的请求
        onTokenRefreshed(newToken)
        
        isRefreshing = false
        
        // 重试原请求
        return request(originalRequest)
      } catch (refreshError) {
        console.error('刷新token失败:', refreshError)
        isRefreshing = false
        clearAllTokens()
        redirectToLogin()
        return Promise.reject(refreshError)
      }
    }

    // 其他错误
    console.error('响应错误:', error)
    return Promise.reject(error)
  }
)

export default request
