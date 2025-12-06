/**
 * 认证状态管理
 */
import { defineStore } from 'pinia'
import { ref, computed, readonly } from 'vue'
import { studentLogin as studentLoginApi, logout as logoutApi, getCurrentUser, refreshToken as refreshTokenApi, switchTenant as switchTenantApi } from '@/api/auth'

export const useAuthStore = defineStore('auth', () => {
  // ==================== 状态定义 ====================
  
  /** @type {Ref<string>} 访问令牌 */
  const accessToken = ref(localStorage.getItem('student_access_token') || '')
  
  /** @type {Ref<string>} 刷新令牌 */
  const refreshToken = ref(localStorage.getItem('student_refresh_token') || '')
  
  /** @type {Ref<Object|null>} 用户信息对象 */
  const userInfo = ref(JSON.parse(localStorage.getItem('student_user_info') || 'null'))
  
  /** @type {Ref<Array>} 用户可访问的租户列表 */
  const availableTenants = ref(JSON.parse(localStorage.getItem('student_available_tenants') || '[]'))
  
  /** @type {Ref<string>} 当前激活的租户ID */
  const currentTenantId = ref(localStorage.getItem('student_current_tenant_id') || '')
  
  /** @type {Ref<Object|null>} 当前租户详细信息 */
  const currentTenant = ref(JSON.parse(localStorage.getItem('student_current_tenant') || 'null'))

  // ==================== 计算属性 ====================
  
  /** 用户是否已登录 */
  const isLoggedIn = computed(() => !!accessToken.value && !!userInfo.value)
  
  /** 用户显示名称 */
  const userName = computed(() => userInfo.value?.full_name || userInfo.value?.username || '')
  
  /** 用户角色 */
  const userRole = computed(() => userInfo.value?.role || '')
  
  /** 是否为多租户用户 */
  const isMultiTenant = computed(() => availableTenants.value.length > 1)
  
  /** 当前租户名称 */
  const currentTenantName = computed(() => currentTenant.value?.name || '')

  // ==================== 核心方法 ====================
  
  /**
   * 学生学号登录
   */
  const studentLogin = async (loginData) => {
    try {
      const response = await studentLoginApi(loginData)
      
      // 保存认证令牌
      accessToken.value = response.access_token
      refreshToken.value = response.refresh_token
      
      // 保存用户信息
      userInfo.value = response.user
      
      // 保存租户信息
      availableTenants.value = response.available_tenants || []
      currentTenant.value = response.current_tenant || null
      currentTenantId.value = response.current_tenant?.tenant_id || response.user?.current_tenant_id || ''

      // 持久化存储
      localStorage.setItem('access_token', accessToken.value)
      localStorage.setItem('student_access_token', accessToken.value)
      localStorage.setItem('student_refresh_token', refreshToken.value)
      localStorage.setItem('student_user_info', JSON.stringify(userInfo.value))
      localStorage.setItem('student_available_tenants', JSON.stringify(availableTenants.value))
      localStorage.setItem('student_current_tenant', JSON.stringify(currentTenant.value))
      localStorage.setItem('student_current_tenant_id', currentTenantId.value)
      
      return response
    } catch (error) {
      console.error('登录失败:', error)
      throw error
    }
  }

  /**
   * 切换租户
   */
  const switchTenant = async (tenantId) => {
    try {
      const response = await switchTenantApi(tenantId)
      
      // 更新令牌
      accessToken.value = response.access_token
      refreshToken.value = response.refresh_token
      
      // 更新当前租户信息
      currentTenant.value = response.current_tenant
      currentTenantId.value = tenantId
      
      if (userInfo.value) {
        userInfo.value.current_tenant_id = tenantId
      }
      
      // 持久化更新
      localStorage.setItem('student_access_token', accessToken.value)
      localStorage.setItem('student_refresh_token', refreshToken.value)
      localStorage.setItem('student_user_info', JSON.stringify(userInfo.value))
      localStorage.setItem('student_current_tenant', JSON.stringify(currentTenant.value))
      localStorage.setItem('student_current_tenant_id', currentTenantId.value)
      
      return response
    } catch (error) {
      console.error('租户切换失败:', error)
      throw error
    }
  }

  /**
   * 用户登出
   */
  const logout = async () => {
    try {
      if (accessToken.value) {
        await logoutApi(accessToken.value)
      }
    } catch (error) {
      console.error('登出API调用失败:', error)
    } finally {
      // 清除认证状态
      accessToken.value = ''
      refreshToken.value = ''
      userInfo.value = null
      availableTenants.value = []
      currentTenant.value = null
      currentTenantId.value = ''

      // 清除本地存储
      localStorage.removeItem('access_token')
      localStorage.removeItem('student_access_token')
      localStorage.removeItem('student_refresh_token')
      localStorage.removeItem('student_user_info')
      localStorage.removeItem('student_available_tenants')
      localStorage.removeItem('student_current_tenant')
      localStorage.removeItem('student_current_tenant_id')
    }
  }

  /**
   * 刷新令牌
   */
  const refreshAccessToken = async () => {
    try {
      if (!refreshToken.value) {
        throw new Error('没有刷新令牌')
      }

      const response = await refreshTokenApi(refreshToken.value)
      
      // 更新令牌
      accessToken.value = response.access_token
      if (response.refresh_token) {
        refreshToken.value = response.refresh_token
      }

      // 更新本地存储
      localStorage.setItem('student_access_token', accessToken.value)
      if (response.refresh_token) {
        localStorage.setItem('student_refresh_token', refreshToken.value)
      }

      return response
    } catch (error) {
      console.error('刷新令牌失败:', error)
      await logout()
      throw error
    }
  }

  /**
   * 获取当前用户信息
   */
  const fetchUserInfo = async () => {
    try {
      if (!accessToken.value) {
        throw new Error('没有访问令牌')
      }

      const response = await getCurrentUser(accessToken.value)
      
      // 更新用户信息
      userInfo.value = response
      localStorage.setItem('student_user_info', JSON.stringify(userInfo.value))

      return response
    } catch (error) {
      console.error('获取用户信息失败:', error)
      
      // 如果是401错误，尝试刷新令牌
      if (error.message.includes('401') || error.message.includes('Unauthorized')) {
        try {
          await refreshAccessToken()
          const response = await getCurrentUser(accessToken.value)
          userInfo.value = response
          localStorage.setItem('student_user_info', JSON.stringify(userInfo.value))
          return response
        } catch (refreshError) {
          console.error('刷新令牌后仍然失败:', refreshError)
          await logout()
          throw refreshError
        }
      }
      
      throw error
    }
  }

  /**
   * 设置Token（用于路由守卫）
   */
  const setToken = (token) => {
    accessToken.value = token
    localStorage.setItem('access_token', token)
    localStorage.setItem('student_access_token', token)
    
    if (userInfo.value) {
      // Token已设置，用户信息存在，认为已登录
    } else {
      // 尝试获取用户信息
      fetchUserInfo().catch(error => {
        console.error('设置Token后获取用户信息失败:', error)
      })
    }
  }

  /**
   * 初始化认证状态
   */
  const initializeAuth = () => {
    try {
      const storedAccessToken = localStorage.getItem('student_access_token')
      const storedRefreshToken = localStorage.getItem('student_refresh_token')
      
      if (storedAccessToken) {
        accessToken.value = storedAccessToken
      }
      if (storedRefreshToken) {
        refreshToken.value = storedRefreshToken
      }
      
      const storedUserInfo = localStorage.getItem('student_user_info')
      if (storedUserInfo) {
        try {
          userInfo.value = JSON.parse(storedUserInfo)
        } catch (error) {
          console.error('解析用户信息失败:', error)
          localStorage.removeItem('student_user_info')
        }
      }
      
      const storedAvailableTenants = localStorage.getItem('student_available_tenants')
      if (storedAvailableTenants) {
        try {
          availableTenants.value = JSON.parse(storedAvailableTenants)
        } catch (error) {
          console.error('解析可用租户失败:', error)
          localStorage.removeItem('student_available_tenants')
        }
      }
      
      const storedCurrentTenant = localStorage.getItem('student_current_tenant')
      if (storedCurrentTenant) {
        try {
          currentTenant.value = JSON.parse(storedCurrentTenant)
        } catch (error) {
          console.error('解析当前租户失败:', error)
          localStorage.removeItem('student_current_tenant')
        }
      }
      
      const storedCurrentTenantId = localStorage.getItem('student_current_tenant_id')
      if (storedCurrentTenantId) {
        currentTenantId.value = storedCurrentTenantId
      }
    } catch (error) {
      console.error('初始化认证状态失败:', error)
      logout()
    }
  }

  // ==================== 返回接口 ====================
  
  return {
    // 状态
    accessToken: readonly(accessToken),
    refreshToken: readonly(refreshToken),
    userInfo: readonly(userInfo),
    availableTenants: readonly(availableTenants),
    currentTenant: readonly(currentTenant),
    currentTenantId: readonly(currentTenantId),
    
    // 计算属性
    isLoggedIn,
    isMultiTenant,
    currentTenantName,
    userName,
    userRole,
    
    // 方法
    studentLogin,
    logout,
    setToken,
    switchTenant,
    refreshAccessToken,
    initializeAuth,
    fetchUserInfo
  }
})

