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
          <!-- 个人信息展示 -->
          <div class="info-section">
            <h3 class="section-title">基本信息</h3>
            <el-descriptions :column="2" border>
              <el-descriptions-item label="姓名" label-class-name="desc-label">
                <span class="desc-value">{{ userInfo.realName || userInfo.name || '未设置' }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="学号" label-class-name="desc-label">
                <span class="desc-value">{{ userInfo.studentNumber || '未设置' }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="用户名" label-class-name="desc-label">
                <span class="desc-value">{{ userInfo.username || '未设置' }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="性别" label-class-name="desc-label">
                <span class="desc-value">{{ getGenderText(userInfo.gender) }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="所属学校" label-class-name="desc-label">
                <span class="desc-value">{{ userInfo.schoolName || '未设置' }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="角色" label-class-name="desc-label">
                <el-tag type="success">{{ userInfo.role }}</el-tag>
              </el-descriptions-item>
            </el-descriptions>
          </div>
          
          <!-- 修改密码 -->
          <div class="security-section">
            <h3 class="section-title">修改密码</h3>
            <el-form :model="passwordForm" label-width="120px">
              <el-form-item label="当前密码">
                <el-input 
                  type="password" 
                  v-model="passwordForm.currentPassword" 
                  placeholder="请输入当前密码"
                  show-password
                />
              </el-form-item>
              <el-form-item label="新密码">
                <el-input 
                  type="password" 
                  v-model="passwordForm.newPassword" 
                  placeholder="至少8位，含大小写字母、数字至少2种"
                  show-password
                />
              </el-form-item>
              <el-form-item label="确认新密码">
                <el-input 
                  type="password" 
                  v-model="passwordForm.confirmPassword" 
                  placeholder="请再次输入新密码"
                  show-password
                />
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="changePassword" :loading="passwordLoading">
                  修改密码
                </el-button>
                <el-button @click="resetPasswordForm">重置</el-button>
              </el-form-item>
            </el-form>
          </div>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref, onMounted } from 'vue'
import { useAuthStore } from '@/store/auth'
import { ElMessage } from 'element-plus'
import { changePassword as changePasswordApi } from '@/api/student'

const authStore = useAuthStore()
const passwordLoading = ref(false)

const userInfo = reactive({
  name: '',
  realName: '',
  username: '',
  studentNumber: '',
  gender: '',
  schoolName: '',
  role: '学生'
})

const passwordForm = reactive({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

// 性别文本转换
const getGenderText = (gender) => {
  const map = {
    'male': '男',
    'female': '女',
    'other': '其他'
  }
  return map[gender] || '未设置'
}

// 验证密码强度：至少8位，包含大写字母、小写字母、数字三种中的两种
const validatePasswordStrength = (password) => {
  if (password.length < 8) {
    return { valid: false, message: '新密码至少需要8位' }
  }
  
  const hasUpper = /[A-Z]/.test(password)
  const hasLower = /[a-z]/.test(password)
  const hasDigit = /\d/.test(password)
  
  const typeCount = [hasUpper, hasLower, hasDigit].filter(Boolean).length
  
  if (typeCount < 2) {
    return { valid: false, message: '密码必须包含大写字母、小写字母、数字三种中的至少两种' }
  }
  
  return { valid: true, message: '' }
}

// 修改密码
const changePassword = async () => {
  if (!passwordForm.currentPassword) {
    ElMessage.warning('请输入当前密码')
    return
  }
  if (!passwordForm.newPassword) {
    ElMessage.warning('请输入新密码')
    return
  }
  
  // 验证新密码强度
  const validation = validatePasswordStrength(passwordForm.newPassword)
  if (!validation.valid) {
    ElMessage.warning(validation.message)
    return
  }
  
  if (passwordForm.newPassword !== passwordForm.confirmPassword) {
    ElMessage.error('两次输入的密码不一致')
    return
  }
  
  passwordLoading.value = true
  
  try {
    await changePasswordApi({
      current_password: passwordForm.currentPassword,
      new_password: passwordForm.newPassword
    })
    ElMessage.success('密码修改成功')
    resetPasswordForm()
  } catch (error) {
    ElMessage.error(error.message || '密码修改失败')
  } finally {
    passwordLoading.value = false
  }
}

// 重置密码表单
const resetPasswordForm = () => {
  passwordForm.currentPassword = ''
  passwordForm.newPassword = ''
  passwordForm.confirmPassword = ''
}

onMounted(() => {
  if (authStore.userInfo) {
    Object.assign(userInfo, {
      name: authStore.userInfo.name || '',
      realName: authStore.userInfo.real_name || '',
      username: authStore.userInfo.username || '',
      studentNumber: authStore.userInfo.student_number || '',
      gender: authStore.userInfo.gender || '',
      schoolName: authStore.userInfo.school_name || '',
      role: authStore.userInfo.role === 'student' ? '学生' : authStore.userInfo.role || '学生'
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
  background: white;
  border-radius: 12px;
  margin-bottom: 24px;
  border: 1px solid #e5e7eb;
}

.section-title {
  font-size: 18px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 20px 0;
  padding-bottom: 12px;
  border-bottom: 2px solid #3b82f6;
}

.info-section :deep(.el-descriptions) {
  margin-top: 0;
}

.info-section :deep(.el-descriptions__label) {
  background: #f8fafc;
  font-weight: 600;
  color: #475569;
  width: 120px;
}

.info-section :deep(.el-descriptions__content) {
  background: white;
}

.desc-value {
  color: #1e293b;
  font-size: 14px;
}

.security-section {
  padding: 24px;
  background: white;
  border-radius: 12px;
  border: 1px solid #e5e7eb;
}

.security-section :deep(.el-form) {
  max-width: 600px;
}

.security-section :deep(.el-input) {
  max-width: 400px;
}
</style>

