import request from './request'

/**
 * 专家管理 API
 */

// 获取专家列表
export const getExperts = (params) => {
  return request({
    url: '/pbl/experts',
    method: 'get',
    params
  })
}

// 获取专家详情
export const getExpertDetail = (uuid) => {
  return request({
    url: `/pbl/experts/${uuid}`,
    method: 'get'
  })
}

// 创建专家
export const createExpert = (data) => {
  return request({
    url: '/pbl/experts',
    method: 'post',
    data
  })
}

// 更新专家信息
export const updateExpert = (uuid, data) => {
  return request({
    url: `/pbl/experts/${uuid}`,
    method: 'put',
    data
  })
}

// 删除专家
export const deleteExpert = (uuid) => {
  return request({
    url: `/pbl/experts/${uuid}`,
    method: 'delete'
  })
}

// 邀请专家评审
export const inviteExpertReview = (data) => {
  return request({
    url: '/pbl/expert-reviews/invite',
    method: 'post',
    data
  })
}

// 获取专家评审列表
export const getExpertReviews = (params) => {
  return request({
    url: '/pbl/expert-reviews',
    method: 'get',
    params
  })
}

// 提交专家评审
export const submitExpertReview = (data) => {
  return request({
    url: '/pbl/expert-reviews',
    method: 'post',
    data
  })
}
