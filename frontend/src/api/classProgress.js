import request from './request'

// 获取管理员可见的班级列表
export function getAdminClasses() {
  return request({
    url: '/api/v1/admin/class-progress/classes',
    method: 'get'
  })
}

// 获取班级课程学习进度
export function getClassCourseProgress(classId) {
  return request({
    url: `/api/v1/admin/class-progress/class/${classId}/course-progress`,
    method: 'get'
  })
}

// 获取学生详细学习进度
export function getStudentProgressDetail(classId, studentId) {
  return request({
    url: `/api/v1/admin/class-progress/class/${classId}/student/${studentId}/detail`,
    method: 'get'
  })
}
