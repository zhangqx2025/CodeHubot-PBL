// 管理员相关API
import request from './request'
import { API_ENDPOINTS, createApiUrl, handleApiError } from './config'

/**
 * 平台管理员登录（用户名+密码）
 */
export const platformAdminLogin = async (loginData) => {
  try {
    const response = await request.post('/admin/auth/platform-login', loginData)
    return response
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 机构管理员登录（学校代码+工号+密码）
 */
export const adminLogin = async (loginData) => {
  try {
    const response = await request.post('/admin/auth/login', loginData)
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
    const response = await request.get('/admin/auth/me')
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
    const response = await request.get('/admin/courses', { params })
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取课程完整详情（包括所有单元、资料和任务）
 */
export const getCourseFullDetail = async (courseId) => {
  try {
    const response = await request.get(`/admin/courses/${courseId}/full-detail`)
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
    const response = await request.post('/admin/courses', courseData)
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
    const response = await request.put(`/admin/courses/${courseId}`, courseData)
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
    const response = await request.delete(`/admin/courses/${courseId}`)
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取学习单元列表
 */
export const getUnits = async (courseUuid) => {
  try {
    const response = await request.get(`/admin/units/course/${courseUuid}`)
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
    const response = await request.post('/admin/units', unitData)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 更新学习单元
 */
export const updateUnit = async (unitUuid, unitData) => {
  try {
    const response = await request.put(`/admin/units/${unitUuid}`, unitData)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 删除学习单元
 */
export const deleteUnit = async (unitUuid) => {
  try {
    const response = await request.delete(`/admin/units/${unitUuid}`)
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
    const response = await request.get(`/admin/resources/unit/${unitId}`)
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
    const response = await request.post('/admin/resources', resourceData)
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
    
    const response = await request.post(
      `/admin/resources/upload?unit_id=${unitId}`,
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
    const response = await request.put(`/admin/resources/${resourceId}`, resourceData)
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
    const response = await request.delete(`/admin/resources/${resourceId}`)
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取单元的任务列表
 */
export const getTasks = async (unitId) => {
  try {
    const response = await request.get(`/admin/tasks/unit/${unitId}`)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 创建任务
 */
export const createTask = async (taskData) => {
  try {
    const response = await request.post('/admin/tasks', taskData)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取任务详情
 */
export const getTaskDetail = async (taskId) => {
  try {
    const response = await request.get(`/admin/tasks/${taskId}`)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 更新任务
 */
export const updateTask = async (taskId, taskData) => {
  try {
    const response = await request.put(`/admin/tasks/${taskId}`, taskData)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 删除任务
 */
export const deleteTask = async (taskId) => {
  try {
    const response = await request.delete(`/admin/tasks/${taskId}`)
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取任务的学生提交列表
 */
export const getTaskProgressList = async (taskId) => {
  try {
    const response = await request.get(`/admin/tasks/${taskId}/progress`)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 教师评分任务
 */
export const gradeTask = async (taskId, userId, score, feedback) => {
  try {
    const response = await request.post(`/admin/tasks/${taskId}/grade`, null, {
      params: {
        user_id: userId,
        score: score,
        feedback: feedback
      }
    })
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取成果列表
 */
export const getOutputs = async (params = {}) => {
  try {
    const response = await request.get('/admin/outputs', { params })
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取成果详情
 */
export const getOutputDetail = async (uuid) => {
  try {
    const response = await request.get(`/admin/outputs/${uuid}`)
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 更新成果公开状态
 */
export const updateOutputStatus = async (uuid, isPublic) => {
  try {
    const response = await request.put(`/admin/outputs/${uuid}/status`, {
      is_public: isPublic
    })
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 评审成果
 */
export const reviewOutput = async (uuid, data) => {
  try {
    const response = await request.post(`/admin/outputs/${uuid}/review`, data)
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 删除成果
 */
export const deleteOutput = async (uuid) => {
  try {
    const response = await request.delete(`/admin/outputs/${uuid}`)
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取成果统计数据
 */
export const getOutputStatistics = async () => {
  try {
    const response = await request.get('/admin/outputs/statistics/overview')
    return response.data.data || response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}
