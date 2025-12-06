import axios from 'axios'
import { API_CONFIG, API_ENDPOINTS, handleApiError } from './config'

const httpClient = axios.create({
  baseURL: API_CONFIG.API_BASE,
  timeout: API_CONFIG.TIMEOUT,
  headers: API_CONFIG.DEFAULT_HEADERS
})

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

// 任务相关 API
export const getTasks = async (params) => {
  try {
    const response = await httpClient.get(API_ENDPOINTS.TASKS.LIST, { params })
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

export const getTaskDetail = async (id) => {
  try {
    const response = await httpClient.get(API_ENDPOINTS.TASKS.DETAIL(id))
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

export const updateTaskProgress = async (id, progressData) => {
  try {
    const response = await httpClient.post(API_ENDPOINTS.TASKS.PROGRESS(id), progressData)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

export const submitTask = async (id, submissionData) => {
  try {
    const response = await httpClient.post(API_ENDPOINTS.TASKS.SUBMIT(id), submissionData)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

