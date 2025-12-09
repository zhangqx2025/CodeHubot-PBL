<template>
  <div class="student-layout">
    <!-- 顶部导航栏 -->
    <el-header class="header">
      <div class="header-left">
        <div class="logo">
          <el-icon size="24"><School /></el-icon>
          <h2>跨学科项目式学习平台</h2>
        </div>
      </div>
      
      <div class="header-center">
        <el-input
          v-model="searchText"
          placeholder="搜索项目、任务、资源..."
          :prefix-icon="Search"
          class="search-input"
          @keyup.enter="handleSearch"
        />
      </div>
      
      <div class="header-right">
        <!-- 通知 -->
        <el-badge :value="notificationCount" :hidden="notificationCount === 0">
          <el-button :icon="Bell" circle />
        </el-badge>
        
        <!-- 用户信息 -->
        <el-dropdown @command="handleUserCommand">
          <div class="user-info">
            <el-avatar :size="32" :src="userInfo.avatar">
              {{ userInfo.name.charAt(0) }}
            </el-avatar>
            <div class="user-details">
              <div class="user-name">{{ userInfo.name }}</div>
              <div class="user-role">学生</div>
            </div>
            <el-icon><ArrowDown /></el-icon>
          </div>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="profile">
                <el-icon><User /></el-icon>
                个人信息
              </el-dropdown-item>
              <el-dropdown-item command="settings">
                <el-icon><Setting /></el-icon>
                学习设置
              </el-dropdown-item>
              <el-dropdown-item command="help">
                <el-icon><QuestionFilled /></el-icon>
                帮助中心
              </el-dropdown-item>
              <el-dropdown-item command="logout" divided>
                <el-icon><SwitchButton /></el-icon>
                退出登录
              </el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
    </el-header>

    <!-- 主内容区 -->
    <el-container class="main-container">
      <!-- 侧边导航 -->
      <el-aside 
        v-if="!$route.meta.hideSidebar" 
        :width="isCollapsed ? '64px' : '250px'" 
        class="sidebar"
      >
        <div class="menu-toggle">
          <el-button 
            :icon="isCollapsed ? Expand : Fold" 
            @click="toggleSidebar"
            text
            class="toggle-btn"
          />
        </div>
        
        <el-menu
          :default-active="$route.path"
          class="sidebar-menu"
          router
          :collapse="isCollapsed"
          background-color="transparent"
          text-color="#374151"
          active-text-color="#3b82f6"
        >
          <el-menu-item index="/courses" class="menu-item">
            <el-icon><Reading /></el-icon>
            <template #title>我的课程</template>
          </el-menu-item>
          
          <el-menu-item index="/profile" class="menu-item">
            <el-icon><User /></el-icon>
            <template #title>个人中心</template>
          </el-menu-item>
        </el-menu>
      </el-aside>
      
      <!-- 主内容 -->
      <el-main class="main-content" :class="{ 'full-width': $route.meta.hideSidebar }">
        <router-view />
      </el-main>
    </el-container>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/store/auth'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  House,
  User,
  Folder,
  Document,
  School,
  Expand,
  Fold,
  Search,
  Bell,
  ArrowDown,
  Setting,
  QuestionFilled,
  SwitchButton,
  TrendCharts,
  Reading,
  Collection
} from '@element-plus/icons-vue'

const router = useRouter()
const authStore = useAuthStore()

const isCollapsed = ref(false)
const searchText = ref('')
const notificationCount = ref(3)

const userInfo = reactive({
  name: '学生用户',
  avatar: '',
  role: '学生'
})

const toggleSidebar = () => {
  isCollapsed.value = !isCollapsed.value
}

const handleSearch = () => {
  if (searchText.value.trim()) {
    ElMessage.info(`搜索: ${searchText.value}`)
  }
}

const handleUserCommand = async (command) => {
  switch (command) {
    case 'profile':
      router.push('/profile')
      break
    case 'settings':
      ElMessage.info('学习设置功能开发中...')
      break
    case 'help':
      ElMessage.info('帮助中心功能开发中...')
      break
    case 'logout':
      try {
        await ElMessageBox.confirm('确定要退出登录吗？', '提示', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        })
        
        await authStore.logout()
        ElMessage.success('已退出登录')
        router.push('/login')
      } catch {
        // 用户取消
      }
      break
  }
}

onMounted(() => {
  // 初始化认证状态
  authStore.initializeAuth()
  
  // 获取用户信息
  if (authStore.userInfo) {
    Object.assign(userInfo, {
      name: authStore.userName || authStore.userInfo.full_name || authStore.userInfo.username,
      avatar: authStore.userInfo.avatar || '',
      role: authStore.userRole || '学生'
    })
  }
})
</script>

<style scoped>
.student-layout {
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
}

.header {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  box-shadow: 0 2px 16px rgba(0, 0, 0, 0.04);
  position: relative;
  z-index: 100;
  height: 64px;
}

.header-left {
  flex: 1;
  min-width: 200px;
}

.logo {
  display: flex;
  align-items: center;
  gap: 12px;
  color: #1e293b;
}

.logo h2 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  background: linear-gradient(45deg, #3b82f6, #8b5cf6);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.header-center {
  flex: 1;
  display: flex;
  justify-content: center;
  max-width: 400px;
  margin: 0 24px;
}

.search-input {
  width: 100%;
  max-width: 300px;
}

:deep(.search-input .el-input__wrapper) {
  border-radius: 20px;
  background: rgba(0, 0, 0, 0.04);
  border: 1px solid transparent;
  transition: all 0.3s ease;
}

:deep(.search-input .el-input__wrapper:hover) {
  background: rgba(0, 0, 0, 0.06);
}

:deep(.search-input .el-input__wrapper.is-focus) {
  background: white;
  border-color: #3b82f6;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.1);
}

.header-right {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 16px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  padding: 8px 12px;
  border-radius: 8px;
  transition: background-color 0.3s;
}

.user-info:hover {
  background-color: rgba(0, 0, 0, 0.04);
}

.user-details {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.user-name {
  font-weight: 500;
  color: #1e293b;
  font-size: 14px;
  line-height: 1.2;
}

.user-role {
  font-size: 12px;
  color: #64748b;
  line-height: 1.2;
}

.main-container {
  flex: 1;
  overflow: hidden;
}

.sidebar {
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(10px);
  border-right: 1px solid rgba(0, 0, 0, 0.06);
  transition: width 0.3s ease;
  overflow: hidden;
}

.menu-toggle {
  padding: 16px;
  text-align: center;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.toggle-btn {
  color: #64748b !important;
  border: none !important;
  background: transparent !important;
}

.toggle-btn:hover {
  background: rgba(0, 0, 0, 0.04) !important;
  color: #374151 !important;
}

.sidebar-menu {
  border: none;
  height: calc(100vh - 128px);
  overflow-y: auto;
  background: transparent !important;
}

:deep(.menu-item) {
  margin: 4px 12px;
  border-radius: 8px;
  transition: all 0.3s ease;
}

:deep(.menu-item:hover) {
  background: rgba(59, 130, 246, 0.08) !important;
  transform: translateX(4px);
}

:deep(.menu-item.is-active) {
  background: rgba(59, 130, 246, 0.12) !important;
  color: #3b82f6 !important;
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.2);
}

.main-content {
  padding: 24px;
  overflow-y: auto;
  background: transparent;
}

.main-content.full-width {
  padding: 0;
}
</style>

