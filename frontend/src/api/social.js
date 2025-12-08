import request from './request'

/**
 * 社会实践活动 API
 */

// 获取社会实践活动列表
export const getSocialActivities = (params) => {
  return request({
    url: '/pbl/social-activities',
    method: 'get',
    params
  })
}

// 获取活动详情
export const getSocialActivityDetail = (uuid) => {
  return request({
    url: `/pbl/social-activities/${uuid}`,
    method: 'get'
  })
}

// 创建活动
export const createSocialActivity = (data) => {
  return request({
    url: '/pbl/social-activities',
    method: 'post',
    data
  })
}

// 更新活动
export const updateSocialActivity = (uuid, data) => {
  return request({
    url: `/pbl/social-activities/${uuid}`,
    method: 'put',
    data
  })
}

// 删除活动
export const deleteSocialActivity = (uuid) => {
  return request({
    url: `/pbl/social-activities/${uuid}`,
    method: 'delete'
  })
}

// 报名参加活动
export const registerActivity = (uuid) => {
  return request({
    url: `/pbl/social-activities/${uuid}/register`,
    method: 'post'
  })
}

// 取消报名
export const cancelRegistration = (uuid) => {
  return request({
    url: `/pbl/social-activities/${uuid}/cancel`,
    method: 'post'
  })
}

// 提交活动反馈
export const submitActivityFeedback = (uuid, data) => {
  return request({
    url: `/pbl/social-activities/${uuid}/feedback`,
    method: 'post',
    data
  })
}

// 上传活动照片
export const uploadActivityPhotos = (uuid, formData, onUploadProgress) => {
  return request({
    url: `/pbl/social-activities/${uuid}/photos`,
    method: 'post',
    data: formData,
    headers: {
      'Content-Type': 'multipart/form-data'
    },
    onUploadProgress
  })
}

// 获取我的社会实践活动
export const getMySocialActivities = (params) => {
  return request({
    url: '/pbl/my-social-activities',
    method: 'get',
    params
  })
}
