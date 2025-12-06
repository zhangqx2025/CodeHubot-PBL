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
    redirect: '/',
    children: [
      {
        path: '',
        name: 'Dashboard',
        component: () => import('../views/Dashboard.vue'),
        meta: {
          title: '学习首页 - 跨学科项目式学习平台',
          requiresAuth: true
        }
      },
      {
        path: 'projects',
        name: 'Projects',
        component: () => import('../views/Projects.vue'),
        meta: { 
          requiresAuth: true,
          title: '项目列表'
        }
      },
      {
        path: 'project/:id',
        name: 'ProjectDetail',
        component: () => import('../views/ProjectDetail.vue'),
        meta: { requiresAuth: true, title: '项目详情' }
      },
      {
        path: 'tasks/:id?',
        name: 'Tasks',
        component: () => import('../views/Tasks.vue'),
        meta: { requiresAuth: true, title: '任务列表' }
      },
      {
        path: 'progress',
        name: 'Progress',
        component: () => import('../views/Progress.vue'),
        meta: { requiresAuth: true, title: '学习进度' }
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
          title: '个人信息',
          requiresAuth: true
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
    // 动态导入认证store以避免循环依赖
    const { useAuthStore } = await import('@/store/auth')
    const authStore = useAuthStore()
    
    // 设置页面标题
    if (to.meta.title) {
      document.title = to.meta.title
    } else {
      document.title = '跨学科项目式学习平台'
    }
    
    // 检查token是否存在且有效
    const token = localStorage.getItem('access_token') || localStorage.getItem('student_access_token')
    const isTokenValid = token && !isTokenExpired(token)
    
    // 如果访问需要认证的页面
    if (to.meta.requiresAuth !== false) {
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
    if (to.name === 'Login' && isTokenValid && authStore.isLoggedIn) {
      next('/')
      return
    }
    
    next()
  } catch (error) {
    console.error('路由守卫错误:', error)
    // 发生错误时，如果是需要认证的页面，跳转到登录页
    if (to.meta.requiresAuth !== false) {
      next('/login')
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

