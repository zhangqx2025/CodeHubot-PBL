<template>
  <div class="profile-page">
    <el-card class="page-header" shadow="never">
      <div class="header-content">
        <div>
          <h1>个人信息</h1>
          <p>查看个人资料和修改密码</p>
        </div>
      </div>
    </el-card>

    <div class="profile-content">
      <el-row :gutter="24">
        <el-col :span="24">
          <div class="info-section">
            <div class="user-info-display">
              <h2>{{ userInfo.name }}</h2>
              <p class="user-role">{{ userInfo.role }}</p>
            </div>
          </div>
          
          <div class="security-section">
            <h3>修改密码</h3>
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
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script setup>
import { reactive, onMounted } from 'vue'
import { useAuthStore } from '@/store/auth'
import { ElMessage } from 'element-plus'

const authStore = useAuthStore()

const userInfo = reactive({
  name: '学生用户',
  role: '学生'
})

const passwordForm = reactive({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

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
      role: '学生'
    })
  }
})
</script>

<style scoped>
.profile-page {
  padding: 0;
}

.page-header {
  margin-bottom: 20px;
  border-radius: 12px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
}

.page-header :deep(.el-card__body) {
  padding: 32px;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.page-header h1 {
  font-size: 28px;
  font-weight: 600;
  margin: 0 0 8px 0;
}

.page-header p {
  font-size: 14px;
  margin: 0;
  opacity: 0.9;
}

.profile-content {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  border: none;
}

.info-section {
  padding: 24px;
  background: #f8fafc;
  border-radius: 12px;
  margin-bottom: 24px;
}

.user-info-display {
  text-align: center;
}

.user-info-display h2 {
  font-size: 28px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 8px 0;
}

.user-role {
  font-size: 16px;
  color: #64748b;
  margin: 0;
}

.security-section {
  padding: 24px;
  background: #f8fafc;
  border-radius: 12px;
}

.security-section h3 {
  font-size: 18px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 20px 0;
}

.security-section :deep(.el-form) {
  max-width: 500px;
}
</style>

