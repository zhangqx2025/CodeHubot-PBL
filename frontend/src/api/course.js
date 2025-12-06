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

// 课程和单元相关 API
export const getCourses = async (params) => {
  try {
    const response = await httpClient.get(API_ENDPOINTS.COURSES.LIST, { params })
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

export const getCourseDetail = async (id) => {
  try {
    const response = await httpClient.get(API_ENDPOINTS.COURSES.DETAIL(id))
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

export const getCourseUnits = async (courseId) => {
  try {
    const response = await httpClient.get(API_ENDPOINTS.COURSES.UNITS(courseId))
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

export const getUnitDetail = async (id) => {
  try {
    const response = await httpClient.get(API_ENDPOINTS.UNITS.DETAIL(id))
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

export const getUnitResources = async (id) => {
  try {
    const response = await httpClient.get(API_ENDPOINTS.UNITS.RESOURCES(id))
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

