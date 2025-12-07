// 学生端 API
import axios from 'axios'
import { API_CONFIG, handleApiError } from './config'

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
    // 统一处理响应数据
    return response.data.data !== undefined ? response.data.data : response.data
  },
  (error) => {
    const errorMessage = handleApiError(error)
    return Promise.reject(new Error(errorMessage))
  }
)

/**
 * 学生端 - 课程相关 API
 */

// 获取我的课程列表
export const getMyCourses = async (params = {}) => {
  try {
    const data = await httpClient.get('/student/courses', { params })
    return data
  } catch (error) {
    throw error
  }
}

// 获取课程详情（包含单元列表）
export const getCourseDetail = async (courseId) => {
  try {
    const data = await httpClient.get(`/student/courses/${courseId}`)
    return data
  } catch (error) {
    throw error
  }
}

// 获取课程的单元列表
export const getCourseUnits = async (courseId) => {
  try {
    const data = await httpClient.get(`/student/courses/${courseId}/units`)
    return data
  } catch (error) {
    throw error
  }
}

// 获取单元详情（包含资料和任务）
export const getUnitDetail = async (unitId) => {
  try {
    const data = await httpClient.get(`/student/units/${unitId}`)
    return data
  } catch (error) {
    throw error
  }
}

// 获取单元的学习资料列表
export const getUnitResources = async (unitId) => {
  try {
    const data = await httpClient.get(`/student/units/${unitId}/resources`)
    return data
  } catch (error) {
    throw error
  }
}

// 获取单元的任务列表
export const getUnitTasks = async (unitId) => {
  try {
    const data = await httpClient.get(`/student/units/${unitId}/tasks`)
    return data
  } catch (error) {
    throw error
  }
}

// 提交任务
export const submitTask = async (taskId, submitData) => {
  try {
    const data = await httpClient.post(`/student/tasks/${taskId}/submit`, submitData)
    return data
  } catch (error) {
    throw error
  }
}

// 获取任务进度
export const getTaskProgress = async (taskId) => {
  try {
    const data = await httpClient.get(`/student/tasks/${taskId}/progress`)
    return data
  } catch (error) {
    throw error
  }
}
