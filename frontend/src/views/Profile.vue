<template>
  <div class="profile-page">
    <div class="page-header">
      <h1>个人信息</h1>
      <p>管理你的个人资料和学习设置</p>
    </div>

    <div class="profile-content">
      <el-row :gutter="24">
        <el-col :span="8">
          <div class="profile-card">
            <div class="avatar-section">
              <el-avatar :size="120" :src="userInfo.avatar">
                {{ userInfo.name.charAt(0) }}
              </el-avatar>
              <el-button type="primary" size="small" style="margin-top: 16px">
                更换头像
              </el-button>
            </div>
            <div class="user-basic-info">
              <h2>{{ userInfo.name }}</h2>
              <p class="user-role">{{ userInfo.role }}</p>
              <p class="user-class">{{ userInfo.class }}</p>
            </div>
          </div>
        </el-col>
        
        <el-col :span="16">
          <el-tabs v-model="activeTab">
            <el-tab-pane label="基本信息" name="basic">
              <div class="form-section">
                <el-form :model="userInfo" label-width="120px">
                  <el-form-item label="姓名">
                    <el-input v-model="userInfo.name" />
                  </el-form-item>
                  <el-form-item label="学号">
                    <el-input v-model="userInfo.studentId" disabled />
                  </el-form-item>
                  <el-form-item label="班级">
                    <el-input v-model="userInfo.class" disabled />
                  </el-form-item>
                  <el-form-item label="邮箱">
                    <el-input v-model="userInfo.email" />
                  </el-form-item>
                  <el-form-item label="手机号">
                    <el-input v-model="userInfo.phone" />
                  </el-form-item>
                  <el-form-item>
                    <el-button type="primary" @click="saveBasicInfo">保存</el-button>
                  </el-form-item>
                </el-form>
              </div>
            </el-tab-pane>
            
            <el-tab-pane label="学习统计" name="stats">
              <div class="stats-section">
                <div class="stat-grid">
                  <div class="stat-item">
                    <div class="stat-value">{{ stats.completedProjects }}</div>
                    <div class="stat-label">已完成项目</div>
                  </div>
                  <div class="stat-item">
                    <div class="stat-value">{{ stats.completedTasks }}</div>
                    <div class="stat-label">完成任务</div>
                  </div>
                  <div class="stat-item">
                    <div class="stat-value">{{ stats.totalHours }}</div>
                    <div class="stat-label">学习时长(小时)</div>
                  </div>
                  <div class="stat-item">
                    <div class="stat-value">{{ stats.achievements }}</div>
                    <div class="stat-label">获得成就</div>
                  </div>
                </div>
              </div>
            </el-tab-pane>
            
            <el-tab-pane label="账号安全" name="security">
              <div class="security-section">
                <el-form label-width="120px">
                  <el-form-item label="当前密码">
                    <el-input type="password" v-model="passwordForm.currentPassword" />
                  </el-form-item>
                  <el-form-item label="新密码">
                    <el-input type="password" v-model="passwordForm.newPassword" />
                  </el-form-item>
                  <el-form-item label="确认新密码">
                    <el-input type="password" v-model="passwordForm.confirmPassword" />
                  </el-form-item>
                  <el-form-item>
                    <el-button type="primary" @click="changePassword">修改密码</el-button>
                  </el-form-item>
                </el-form>
              </div>
            </el-tab-pane>
          </el-tabs>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useAuthStore } from '@/store/auth'
import { ElMessage } from 'element-plus'

const authStore = useAuthStore()

const activeTab = ref('basic')

const userInfo = reactive({
  name: '学生用户',
  role: '学生',
  class: '2024级1班',
  studentId: '20240001',
  email: 'student@example.com',
  phone: '13800138000',
  avatar: ''
})

const stats = reactive({
  completedProjects: 3,
  completedTasks: 15,
  totalHours: 45,
  achievements: 8
})

const passwordForm = reactive({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const saveBasicInfo = () => {
  ElMessage.success('保存成功')
}

const changePassword = () => {
  if (passwordForm.newPassword !== passwordForm.confirmPassword) {
    ElMessage.error('两次输入的密码不一致')
    return
  }
  ElMessage.success('密码修改成功')
  passwordForm.currentPassword = ''
  passwordForm.newPassword = ''
  passwordForm.confirmPassword = ''
}

onMounted(() => {
  if (authStore.userInfo) {
    Object.assign(userInfo, {
      name: authStore.userName || authStore.userInfo.full_name || authStore.userInfo.username,
      studentId: authStore.userInfo.username || '',
      email: authStore.userInfo.email || '',
      class: authStore.userInfo.class_name || ''
    })
  }
})
</script>

<style scoped>
.profile-page {
  padding: 24px;
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 32px;
}

.page-header h1 {
  font-size: 32px;
  font-weight: 700;
  color: #1e293b;
  margin: 0 0 8px 0;
}

.page-header p {
  color: #64748b;
  font-size: 16px;
  margin: 0;
}

.profile-content {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.profile-card {
  text-align: center;
  padding: 24px;
  background: #f8fafc;
  border-radius: 12px;
}

.avatar-section {
  margin-bottom: 24px;
}

.user-basic-info h2 {
  font-size: 24px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 8px 0;
}

.user-role {
  font-size: 14px;
  color: #64748b;
  margin: 0 0 4px 0;
}

.user-class {
  font-size: 14px;
  color: #64748b;
  margin: 0;
}

.form-section,
.stats-section,
.security-section {
  padding: 24px 0;
}

.stat-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 24px;
}

.stat-item {
  text-align: center;
  padding: 24px;
  background: #f8fafc;
  border-radius: 8px;
}

.stat-value {
  font-size: 36px;
  font-weight: 700;
  color: #3b82f6;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 14px;
  color: #64748b;
}
</style>

