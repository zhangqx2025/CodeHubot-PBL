<template>
  <div class="admin-dashboard">
    <el-container>
      <!-- 侧边栏 -->
      <el-aside width="250px" class="admin-sidebar">
        <div class="admin-logo">
          <h2>PBL管理后台</h2>
        </div>
        <el-menu
          :default-active="activeMenu"
          router
          class="admin-menu"
        >
          <el-menu-item index="/admin">
            <el-icon><HomeFilled /></el-icon>
            <span>概览</span>
          </el-menu-item>
          <el-menu-item index="/admin/courses">
            <el-icon><Document /></el-icon>
            <span>课程管理</span>
          </el-menu-item>
          <el-menu-item index="/admin/units">
            <el-icon><FolderOpened /></el-icon>
            <span>学习单元</span>
          </el-menu-item>
          <el-menu-item index="/admin/resources">
            <el-icon><Upload /></el-icon>
            <span>资料管理</span>
          </el-menu-item>
        </el-menu>
        <div class="admin-user">
          <el-dropdown @command="handleCommand">
            <span class="admin-user-info">
              <el-icon><User /></el-icon>
              {{ adminInfo?.full_name || adminInfo?.username || '管理员' }}
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-aside>

      <!-- 主内容区 -->
      <el-container>
        <el-header class="admin-header">
          <h3>{{ pageTitle }}</h3>
        </el-header>
        <el-main class="admin-main">
          <router-view />
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { HomeFilled, Document, FolderOpened, Upload, User } from '@element-plus/icons-vue'
import { getCurrentAdmin } from '@/api/admin'

const router = useRouter()
const route = useRoute()

const adminInfo = ref(null)
const activeMenu = computed(() => route.path)

const pageTitle = computed(() => {
  const titles = {
    '/admin': '概览',
    '/admin/courses': '课程管理',
    '/admin/units': '学习单元',
    '/admin/resources': '资料管理'
  }
  return titles[route.path] || '管理后台'
})

const handleCommand = (command) => {
  if (command === 'logout') {
    localStorage.removeItem('admin_access_token')
    localStorage.removeItem('admin_info')
    ElMessage.success('已退出登录')
    router.push('/admin/login')
  }
}

onMounted(async () => {
  try {
    const admin = await getCurrentAdmin()
    adminInfo.value = admin
  } catch (error) {
    console.error('获取管理员信息失败:', error)
  }
})
</script>

<style scoped>
.admin-dashboard {
  height: 100vh;
  overflow: hidden;
}

.admin-sidebar {
  background: #304156;
  color: white;
  height: 100vh;
  position: fixed;
  left: 0;
  top: 0;
  overflow-y: auto;
}

.admin-logo {
  padding: 20px;
  text-align: center;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.admin-logo h2 {
  margin: 0;
  color: white;
  font-size: 18px;
}

.admin-menu {
  border: none;
  background: #304156;
}

.admin-menu .el-menu-item {
  color: rgba(255, 255, 255, 0.7);
}

.admin-menu .el-menu-item:hover {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.admin-menu .el-menu-item.is-active {
  background: #409eff;
  color: white;
}

.admin-user {
  position: absolute;
  bottom: 20px;
  left: 0;
  right: 0;
  padding: 0 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding-top: 20px;
}

.admin-user-info {
  color: rgba(255, 255, 255, 0.7);
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
}

.admin-user-info:hover {
  color: white;
}

.admin-header {
  background: white;
  border-bottom: 1px solid #e4e7ed;
  display: flex;
  align-items: center;
  padding: 0 20px;
  margin-left: 250px;
}

.admin-header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 500;
}

.admin-main {
  margin-left: 250px;
  padding: 20px;
  background: #f5f7fa;
  min-height: calc(100vh - 60px);
}
</style>
