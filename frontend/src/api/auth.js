// 认证相关API
import axios from 'axios'
import { API_CONFIG, API_ENDPOINTS, createApiUrl, handleApiError } from './config'

// 创建axios实例
const httpClient = axios.create({
  baseURL: API_CONFIG.API_BASE,
  timeout: API_CONFIG.TIMEOUT,
  headers: API_CONFIG.DEFAULT_HEADERS
})

// 请求拦截器
httpClient.interceptors.request.use(
  (config) => {
    // 从localStorage获取token
    const token = localStorage.getItem('access_token') || localStorage.getItem('student_access_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 响应拦截器
httpClient.interceptors.response.use(
  (response) => {
    return response
  },
  async (error) => {
    const originalRequest = error.config
    
    // 如果是401错误且不是刷新token的请求，尝试刷新token
    if (error.response?.status === 401 && !originalRequest._retry && !originalRequest.url.includes('/auth/refresh')) {
      originalRequest._retry = true
      
      try {
        const refreshToken = localStorage.getItem('refresh_token') || localStorage.getItem('student_refresh_token')
        if (refreshToken) {
          const response = await httpClient.post(API_ENDPOINTS.AUTH.STUDENT_REFRESH, {
            refresh_token: refreshToken
          })
          
          const { access_token, refresh_token: newRefreshToken } = response.data.data || response.data
          
          // 更新token
          localStorage.setItem('access_token', access_token)
          localStorage.setItem('student_access_token', access_token)
          if (newRefreshToken) {
            localStorage.setItem('refresh_token', newRefreshToken)
            localStorage.setItem('student_refresh_token', newRefreshToken)
          }
          
          // 重新发送原请求
          originalRequest.headers.Authorization = `Bearer ${access_token}`
          return httpClient(originalRequest)
        }
      } catch (refreshError) {
        // 刷新token失败，清除本地存储并跳转到登录页
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        localStorage.removeItem('student_access_token')
        localStorage.removeItem('student_refresh_token')
        localStorage.removeItem('user_info')
        localStorage.removeItem('student_user_info')
        window.location.href = '/login'
        return Promise.reject(refreshError)
      }
    }
    
    return Promise.reject(error)
  }
)

/**
 * 用户登录
 * @param {Object} loginData - 登录数据
 * @param {string} loginData.username - 用户名
 * @param {string} loginData.password - 密码
 * @param {string} [loginData.tenant_id] - 租户ID（可选）
 * @returns {Promise<Object>} 登录响应数据
 */
export const login = async (loginData) => {
  // 模拟登录成功
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        access_token: 'mock_access_token_' + Date.now(),
        refresh_token: 'mock_refresh_token_' + Date.now(),
        user: {
          id: 1,
          username: loginData.username,
          full_name: '模拟用户',
          role: 'student',
          avatar: ''
        },
        available_tenants: [
          { tenant_id: 'tenant_1', name: '默认租户' }
        ],
        current_tenant: { tenant_id: 'tenant_1', name: '默认租户' }
      })
    }, 500)
  })
  /* 
  try {
    const response = await httpClient.post(API_ENDPOINTS.AUTH.LOGIN, loginData)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
  */
}

/**
 * 学生学号登录 - 机构登录方式
 * @param {Object} loginData - 学号登录数据
 * @param {string} loginData.student_id - 学号
 * @param {string} loginData.school_code - 学校代码
 * @param {string} loginData.password - 密码
 * @param {boolean} [loginData.remember_me] - 是否记住登录状态
 * @returns {Promise<Object>} 登录响应数据
 */
export const studentLogin = async (loginData) => {
  try {
    // 发送机构登录请求：school_code + number + password
    const response = await httpClient.post(API_ENDPOINTS.AUTH.STUDENT_LOGIN, {
      school_code: loginData.school_code,
      number: loginData.student_id,
      password: loginData.password
    })
    
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 刷新访问令牌
 * @param {string} refreshToken - 刷新令牌
 * @returns {Promise<Object>} 新的令牌数据
 */
export const refreshToken = async (refreshToken) => {
  try {
    const response = await httpClient.post(API_ENDPOINTS.AUTH.STUDENT_REFRESH, {
      refresh_token: refreshToken
    })
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 用户登出
 * @param {string} token - 访问令牌
 * @returns {Promise<void>}
 */
export const logout = async (token) => {
  // 模拟登出成功
  return Promise.resolve()
  /*
  try {
    await httpClient.post(API_ENDPOINTS.AUTH.LOGOUT, {}, {
      headers: {
        Authorization: `Bearer ${token}`
      }
    })
  } catch (error) {
    // 登出失败不抛出错误，因为可能是token已过期
    console.warn('登出API调用失败:', error)
  }
  */
}

/**
 * 获取当前用户信息
 * @param {string} token - 访问令牌
 * @returns {Promise<Object>} 用户信息
 */
export const getCurrentUser = async (token) => {
  try {
    const response = await httpClient.get(API_ENDPOINTS.AUTH.STUDENT_ME, {
      headers: {
        Authorization: `Bearer ${token}`
      }
    })
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 切换租户
 * @param {string} tenantId - 租户ID
 * @returns {Promise<Object>} 切换结果
 */
export const switchTenant = async (tenantId) => {
  // 模拟切换成功
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        access_token: 'mock_tenant_token_' + Date.now(),
        refresh_token: 'mock_tenant_refresh_' + Date.now(),
        current_tenant: { tenant_id: tenantId, name: '切换后的租户' }
      })
    }, 400)
  })
  /*
  try {
    const response = await httpClient.post(API_ENDPOINTS.AUTH.SWITCH_TENANT, {
      tenant_id: tenantId
    })
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
  */
}
