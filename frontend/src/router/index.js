import { createRouter, createWebHistory } from 'vue-router'
import Layout from '../views/Layout.vue'
import Login from '../views/Login.vue'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: {
      title: '学生登录 - 跨学科项目式学习平台',
      requiresAuth: false
    }
  },
  {
    path: '/',
    component: Layout,
    redirect: '/courses',
    children: [
      {
        path: 'courses',
        name: 'MyCourses',
        component: () => import('../views/MyCourses.vue'),
        meta: {
          title: '我的课程 - 跨学科项目式学习平台',
          requiresAuth: true
        }
      },
      {
        path: 'course/:courseId',
        name: 'CourseDetail',
        component: () => import('../views/CourseDetail.vue'),
        meta: {
          title: '课程详情 - 跨学科项目式学习平台',
          requiresAuth: true
        }
      },
      {
        path: 'projects',
        name: 'Projects',
        component: () => import('../views/Projects.vue'),
        meta: { 
          requiresAuth: true,
          title: '项目实践 - 跨学科项目式学习平台'
        }
      },
      {
        path: 'project/:id',
        name: 'ProjectDetail',
        component: () => import('../views/ProjectDetail.vue'),
        meta: { 
          requiresAuth: true, 
          title: '项目详情 - 跨学科项目式学习平台'
        }
      },
      {
        path: 'outputs',
        name: 'Outputs',
        component: () => import('../views/StudentOutputs.vue'),
        meta: { 
          requiresAuth: true, 
          title: '项目成果 - 跨学科项目式学习平台'
        }
      },
      {
        path: 'portfolio',
        name: 'Portfolio',
        component: () => import('../views/StudentPortfolio.vue'),
        meta: { 
          requiresAuth: true, 
          title: '学习档案 - 跨学科项目式学习平台'
        }
      },
      {
        path: 'tasks/:id?',
        name: 'Tasks',
        component: () => import('../views/Tasks.vue'),
        meta: { 
          requiresAuth: true, 
          title: '任务列表 - 跨学科项目式学习平台'
        }
      },
      {
        path: 'progress',
        name: 'Progress',
        component: () => import('../views/Progress.vue'),
        meta: { 
          requiresAuth: true, 
          title: '学习进度 - 跨学科项目式学习平台'
        }
      },
      {
        path: 'unit/:unitId',
        name: 'UnitLearning',
        component: () => import('../views/UnitLearning.vue'),
        meta: {
          title: '单元学习',
          requiresAuth: true,
          hideSidebar: true
        },
        props: true
      },
      {
        path: 'profile',
        name: 'Profile',
        component: () => import('../views/Profile.vue'),
        meta: {
          title: '个人中心 - 跨学科项目式学习平台',
          requiresAuth: true
        }
      }
    ]
  },
  {
    path: '/admin/login',
    name: 'AdminLogin',
    component: () => import('../views/AdminLogin.vue'),
    meta: {
      title: '机构管理员登录 - PBL系统管理后台',
      requiresAuth: false
    }
  },
  {
    path: '/platform-admin/login',
    name: 'PlatformAdminLogin',
    component: () => import('../views/PlatformAdminLogin.vue'),
    meta: {
      title: '平台管理员登录 - PBL系统管理后台',
      requiresAuth: false
    }
  },
  {
    path: '/admin',
    component: () => import('../views/AdminDashboard.vue'),
    redirect: '/admin',
    meta: {
      requiresAdminAuth: true
    },
    children: [
      {
        path: '',
        name: 'AdminHome',
        component: () => import('../views/AdminCourses.vue'),
        meta: {
          title: '概览 - PBL系统管理后台'
        }
      },
      {
        path: 'courses',
        name: 'AdminCourses',
        component: () => import('../views/AdminCourses.vue'),
        meta: {
          title: '课程管理 - PBL系统管理后台'
        }
      },
      {
        path: 'courses/:courseId',
        name: 'AdminCourseDetail',
        component: () => import('../views/AdminCourseDetail.vue'),
        meta: {
          title: '课程详情 - PBL系统管理后台'
        }
      },
      {
        path: 'schools',
        name: 'AdminSchools',
        component: () => import('../views/AdminSchools.vue'),
        meta: {
          title: '学校管理 - PBL系统管理后台'
        }
      },
      {
        path: 'school-courses',
        name: 'AdminSchoolCourses',
        component: () => import('../views/AdminSchoolCourses.vue'),
        meta: {
          title: '学校课程配置 - PBL系统管理后台'
        }
      },
      {
        path: 'school-course-library',
        name: 'SchoolCourseLibrary',
        component: () => import('../views/SchoolCourseLibrary.vue'),
        meta: {
          title: '学校课程库 - PBL系统管理后台'
        }
      },
      {
        path: 'course-templates',
        name: 'CourseTemplates',
        component: () => import('../views/CourseTemplates.vue'),
        meta: {
          title: '课程模板管理 - PBL系统管理后台'
        }
      },
      {
        path: 'course-templates/:uuid',
        name: 'CourseTemplateDetail',
        component: () => import('../views/CourseTemplateDetail.vue'),
        meta: {
          title: '课程模板详情 - PBL系统管理后台'
        }
      },
      {
        path: 'template-permissions',
        name: 'TemplatePermissions',
        component: () => import('../views/TemplatePermissions.vue'),
        meta: {
          title: '课程模板授权 - PBL系统管理后台'
        }
      },
      {
        path: 'template-library',
        redirect: '/admin/template-permissions',
        meta: {
          title: '模板库管理 - PBL系统管理后台'
        }
      },
      {
        path: 'available-templates',
        name: 'AvailableTemplates',
        component: () => import('../views/AvailableTemplates.vue'),
        meta: {
          title: '可用模板库 - PBL系统管理后台'
        }
      },
      {
        path: 'units',
        name: 'AdminUnits',
        component: () => import('../views/AdminUnits.vue'),
        meta: {
          title: '学习单元 - PBL系统管理后台'
        }
      },
      {
        path: 'resources',
        name: 'AdminResources',
        component: () => import('../views/AdminResources.vue'),
        meta: {
          title: '资料管理 - PBL系统管理后台'
        }
      },
      {
        path: 'video-permissions',
        name: 'AdminVideoPermissions',
        component: () => import('../views/AdminVideoPermissions.vue'),
        meta: {
          title: '视频权限管理 - PBL系统管理后台'
        }
      },
      {
        path: 'tasks',
        name: 'AdminTasks',
        component: () => import('../views/AdminTasks.vue'),
        meta: {
          title: '任务管理 - PBL系统管理后台'
        }
      },
      {
        path: 'projects',
        name: 'AdminProjects',
        component: () => import('../views/AdminProjects.vue'),
        meta: {
          title: '项目管理 - PBL系统管理后台'
        }
      },
      {
        path: 'users',
        name: 'AdminUsers',
        component: () => import('../views/AdminUsers.vue'),
        meta: {
          title: '用户管理 - PBL系统管理后台'
        }
      },
      {
        path: 'school-user-management',
        name: 'SchoolUserManagement',
        component: () => import('../views/SchoolUserManagement.vue'),
        meta: {
          title: '用户管理 - PBL系统管理后台'
        }
      },
      {
        path: 'classes',
        name: 'AdminClasses',
        component: () => import('../views/ClubClasses.vue'),
        meta: {
          title: '项目式课程管理 - PBL系统管理后台'
        }
      },
      {
        path: 'classes/:uuid',
        name: 'ClassDetail',
        component: () => import('../views/ClassDetail.vue'),
        meta: {
          title: '班级详情 - PBL系统管理后台'
        }
      },
      {
        path: 'classes/:uuid/edit',
        name: 'ClassEdit',
        component: () => import('../views/ClassEdit.vue'),
        meta: {
          title: '编辑班级 - PBL系统管理后台'
        }
      },
      {
        path: 'classes/:uuid/members',
        name: 'ClassMembers',
        component: () => import('../views/ClassMembers.vue'),
        meta: {
          title: '成员管理 - PBL系统管理后台'
        }
      },
      {
        path: 'classes/:uuid/courses',
        name: 'ClassCourses',
        component: () => import('../views/ClassCourses.vue'),
        meta: {
          title: '课程管理 - PBL系统管理后台'
        }
      },
      {
        path: 'classes/:uuid/groups',
        name: 'ClassGroups',
        component: () => import('../views/ClassGroups.vue'),
        meta: {
          title: '小组管理 - PBL系统管理后台'
        }
      },
      {
        path: 'classes/:uuid/create-course',
        name: 'ClassCreateCourse',
        component: () => import('../views/ClassCreateCourse.vue'),
        meta: {
          title: '创建课程 - PBL系统管理后台'
        }
      },
      {
        path: 'progress',
        name: 'AdminProgress',
        component: () => import('../views/AdminProgress.vue'),
        meta: {
          title: '学习进度 - PBL系统管理后台'
        }
      },
      {
        path: 'assessments',
        name: 'AdminAssessments',
        component: () => import('../views/AdminAssessments.vue'),
        meta: {
          title: '评价管理 - PBL系统管理后台'
        }
      },
      {
        path: 'assessment-templates',
        name: 'AdminAssessmentTemplates',
        component: () => import('../views/AdminAssessmentTemplates.vue'),
        meta: {
          title: '评价模板 - PBL系统管理后台'
        }
      },
      {
        path: 'outputs',
        name: 'AdminOutputs',
        component: () => import('../views/AdminOutputs.vue'),
        meta: {
          title: '成果管理 - PBL系统管理后台'
        }
      },
      {
        path: 'portfolios',
        name: 'AdminPortfolios',
        component: () => import('../views/AdminPortfolios.vue'),
        meta: {
          title: '学习档案 - PBL系统管理后台'
        }
      },
      {
        path: 'datasets',
        name: 'AdminDatasets',
        component: () => import('../views/AdminDatasets.vue'),
        meta: {
          title: '数据集管理 - PBL系统管理后台'
        }
      },
      {
        path: 'ethics-cases',
        name: 'AdminEthicsCases',
        component: () => import('../views/AdminEthicsCases.vue'),
        meta: {
          title: '伦理案例 - PBL系统管理后台'
        }
      },
      {
        path: 'ethics-activities',
        name: 'AdminEthicsActivities',
        component: () => import('../views/AdminEthicsActivities.vue'),
        meta: {
          title: '伦理活动 - PBL系统管理后台'
        }
      },
      {
        path: 'experts',
        name: 'AdminExperts',
        component: () => import('../views/AdminExperts.vue'),
        meta: {
          title: '专家管理 - PBL系统管理后台'
        }
      },
      {
        path: 'social-activities',
        name: 'AdminSocialActivities',
        component: () => import('../views/AdminSocialActivities.vue'),
        meta: {
          title: '社会活动 - PBL系统管理后台'
        }
      }
    ]
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/'
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else {
      return { top: 0 }
    }
  }
})

// 路由守卫
router.beforeEach(async (to, from, next) => {
  try {
    // 设置页面标题
    if (to.meta.title) {
      document.title = to.meta.title
    } else {
      document.title = '跨学科项目式学习平台'
    }
    
    // 管理员路由检查
    if (to.meta.requiresAdminAuth) {
      const adminToken = localStorage.getItem('admin_access_token')
      const isAdminTokenValid = adminToken && !isTokenExpired(adminToken)
      
      if (!isAdminTokenValid) {
        localStorage.removeItem('admin_access_token')
        localStorage.removeItem('admin_info')
        next('/admin/login')
        return
      }
      
      // 如果已登录且访问管理员登录页，跳转到管理后台
      if ((to.name === 'AdminLogin' || to.name === 'PlatformAdminLogin') && isAdminTokenValid) {
        next('/admin')
        return
      }
      
      next()
      return
    }
    
    // 学生路由检查
    if (to.meta.requiresAuth !== false) {
      // 动态导入认证store以避免循环依赖
      const { useAuthStore } = await import('@/store/auth')
      const authStore = useAuthStore()
      
      // 检查token是否存在且有效
      const token = localStorage.getItem('access_token') || localStorage.getItem('student_access_token')
      const isTokenValid = token && !isTokenExpired(token)
      
      if (!isTokenValid) {
        // 清除无效token
        localStorage.removeItem('access_token')
        localStorage.removeItem('student_access_token')
        localStorage.removeItem('refresh_token')
        localStorage.removeItem('student_refresh_token')
        
        // 重置认证状态
        authStore.logout()
        
        next('/login')
        return
      }
      
      // Token有效，更新认证状态
      if (!authStore.isLoggedIn) {
        authStore.setToken(token)
      }
    }
    
    // 如果已登录且访问登录页，跳转到首页
    if (to.name === 'Login') {
      const token = localStorage.getItem('access_token') || localStorage.getItem('student_access_token')
      const isTokenValid = token && !isTokenExpired(token)
      if (isTokenValid) {
        next('/')
        return
      }
    }
    
    // 如果已登录且访问管理员登录页，跳转到管理后台
    if (to.name === 'AdminLogin' || to.name === 'PlatformAdminLogin') {
      const adminToken = localStorage.getItem('admin_access_token')
      const isAdminTokenValid = adminToken && !isTokenExpired(adminToken)
      if (isAdminTokenValid) {
        next('/admin')
        return
      }
    }
    
    next()
  } catch (error) {
    console.error('路由守卫错误:', error)
    // 发生错误时，如果是需要认证的页面，跳转到登录页
    if (to.meta.requiresAuth !== false || to.meta.requiresAdminAuth) {
      if (to.meta.requiresAdminAuth) {
        next('/admin/login')
      } else {
        next('/login')
      }
    } else {
      next()
    }
  }
})

// Token过期检查函数
function isTokenExpired(token) {
  try {
    if (!token) return true
    
    // 如果是 Mock Token，直接认为未过期
    if (token.startsWith('mock_')) {
      return false
    }
    
    // 简单的JWT token过期检查
    const parts = token.split('.')
    if (parts.length !== 3) {
      return true
    }
    
    const payload = JSON.parse(atob(parts[1]))
    const currentTime = Math.floor(Date.now() / 1000)
    
    return payload.exp < currentTime
  } catch (error) {
    console.error('Token解析错误:', error)
    return true
  }
}

export default router

