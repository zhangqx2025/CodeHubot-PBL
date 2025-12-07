// 管理员相关API
import axios from 'axios'
import { API_CONFIG, API_ENDPOINTS, createApiUrl, handleApiError } from './config'

// 创建axios实例
const httpClient = axios.create({
  baseURL: API_CONFIG.API_BASE,
  timeout: API_CONFIG.TIMEOUT,
  headers: API_CONFIG.DEFAULT_HEADERS
})

// 请求拦截器 - 添加管理员token
httpClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('admin_access_token')
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
    if (error.response?.status === 401) {
      // Token过期，清除本地存储并跳转到登录页
      localStorage.removeItem('admin_access_token')
      localStorage.removeItem('admin_info')
      window.location.href = '/admin/login'
    }
    return Promise.reject(error)
  }
)

/**
 * 管理员登录
 */
export const adminLogin = async (loginData) => {
  try {
    const response = await httpClient.post('/api/v1/admin/auth/login', loginData)
    return response
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取当前管理员信息
 */
export const getCurrentAdmin = async () => {
  try {
    const response = await httpClient.get('/api/v1/admin/auth/me')
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取课程列表
 */
export const getCourses = async (params = {}) => {
  try {
    const response = await httpClient.get('/api/v1/admin/courses', { params })
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 创建课程
 */
export const createCourse = async (courseData) => {
  try {
    const response = await httpClient.post('/api/v1/admin/courses', courseData)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 更新课程
 */
export const updateCourse = async (courseId, courseData) => {
  try {
    const response = await httpClient.put(`/api/v1/admin/courses/${courseId}`, courseData)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 删除课程
 */
export const deleteCourse = async (courseId) => {
  try {
    const response = await httpClient.delete(`/api/v1/admin/courses/${courseId}`)
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取学习单元列表
 */
export const getUnits = async (courseId) => {
  try {
    const response = await httpClient.get(`/api/v1/admin/units/course/${courseId}`)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 创建学习单元
 */
export const createUnit = async (unitData) => {
  try {
    const response = await httpClient.post('/api/v1/admin/units', unitData)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 更新学习单元
 */
export const updateUnit = async (unitId, unitData) => {
  try {
    const response = await httpClient.put(`/api/v1/admin/units/${unitId}`, unitData)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 删除学习单元
 */
export const deleteUnit = async (unitId) => {
  try {
    const response = await httpClient.delete(`/api/v1/admin/units/${unitId}`)
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取资料列表
 */
export const getResources = async (unitId) => {
  try {
    const response = await httpClient.get(`/api/v1/admin/resources/unit/${unitId}`)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 创建资料
 */
export const createResource = async (resourceData) => {
  try {
    const response = await httpClient.post('/api/v1/admin/resources', resourceData)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 上传资料文件
 */
export const uploadResourceFile = async (unitId, fileType, file) => {
  try {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('file_type', fileType)
    
    const response = await httpClient.post(
      `/api/v1/admin/resources/upload?unit_id=${unitId}`,
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      }
    )
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 更新资料
 */
export const updateResource = async (resourceId, resourceData) => {
  try {
    const response = await httpClient.put(`/api/v1/admin/resources/${resourceId}`, resourceData)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 删除资料
 */
export const deleteResource = async (resourceId) => {
  try {
    const response = await httpClient.delete(`/api/v1/admin/resources/${resourceId}`)
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}
