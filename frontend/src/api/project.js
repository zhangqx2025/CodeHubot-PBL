import axios from 'axios'
import { API_CONFIG, API_ENDPOINTS, handleApiError } from './config'

const httpClient = axios.create({
  baseURL: API_CONFIG.API_BASE,
  timeout: API_CONFIG.TIMEOUT,
  headers: API_CONFIG.DEFAULT_HEADERS
})

// 请求拦截器（同 auth.js，建议提取公共 request.js）
httpClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token') || localStorage.getItem('student_access_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// 项目相关 API
export const getProjects = async (params) => {
  try {
    const response = await httpClient.get(API_ENDPOINTS.PROJECTS.LIST, { params })
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

export const getProjectDetail = async (id) => {
  try {
    const response = await httpClient.get(API_ENDPOINTS.PROJECTS.DETAIL(id))
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

export const getProjectTasks = async (id) => {
  try {
    const response = await httpClient.get(API_ENDPOINTS.PROJECTS.TASKS(id))
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

export const getProjectProgress = async (id) => {
  try {
    const response = await httpClient.get(API_ENDPOINTS.PROJECTS.PROGRESS(id))
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

