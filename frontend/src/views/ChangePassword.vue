<template>
  <div class="change-password-container">
    <div class="change-password-card">
      <div class="password-header">
        <el-icon class="warning-icon" size="48"><WarningFilled /></el-icon>
        <h1>必须修改密码</h1>
        <p>您的密码已被管理员重置，为了账户安全，请立即修改密码</p>
      </div>
      
      <el-form 
        ref="passwordFormRef" 
        :model="passwordForm" 
        :rules="passwordRules" 
        class="password-form"
        @submit.prevent="handleChangePassword"
      >
        <el-form-item prop="currentPassword">
          <el-input
            v-model="passwordForm.currentPassword"
            type="password"
            placeholder="请输入当前密码"
            :prefix-icon="Lock"
            size="large"
            show-password
          />
        </el-form-item>
        
        <el-form-item prop="newPassword">
          <el-input
            v-model="passwordForm.newPassword"
            type="password"
            placeholder="请输入新密码（至少8位，含大小写字母、数字至少2种）"
            :prefix-icon="Lock"
            size="large"
            show-password
          />
        </el-form-item>
        
        <el-form-item prop="confirmPassword">
          <el-input
            v-model="passwordForm.confirmPassword"
            type="password"
            placeholder="请再次输入新密码"
            :prefix-icon="Lock"
            size="large"
            show-password
            @keyup.enter="handleChangePassword"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button 
            type="primary" 
            size="large" 
            class="change-button"
            :loading="loading"
            @click="handleChangePassword"
          >
            {{ loading ? '修改中...' : '确认修改' }}
          </el-button>
        </el-form-item>
      </el-form>
      
      <div class="password-tip">
        <el-alert type="info" :closable="false" show-icon>
          <template #default>
            <div>密码要求：</div>
            <ul style="margin: 8px 0 0 0; padding-left: 20px">
              <li>长度至少8位</li>
              <li>必须包含大写字母、小写字母、数字三种中的至少两种</li>
              <li>不能与当前密码相同</li>
            </ul>
          </template>
        </el-alert>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Lock, WarningFilled } from '@element-plus/icons-vue'
import { changePassword as changePasswordApi } from '@/api/student'
import { useAuthStore } from '@/store/auth'

const router = useRouter()
const authStore = useAuthStore()
const loading = ref(false)
const passwordFormRef = ref(null)

const passwordForm = reactive({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

// 验证密码强度
const validatePasswordStrength = (rule, value, callback) => {
  if (!value) {
    return callback(new Error('请输入新密码'))
  }
  
  if (value.length < 8) {
    return callback(new Error('新密码至少需要8位'))
  }
  
  const hasUpper = /[A-Z]/.test(value)
  const hasLower = /[a-z]/.test(value)
  const hasDigit = /\d/.test(value)
  
  const typeCount = [hasUpper, hasLower, hasDigit].filter(Boolean).length
  
  if (typeCount < 2) {
    return callback(new Error('密码必须包含大写字母、小写字母、数字三种中的至少两种'))
  }
  
  callback()
}

// 验证确认密码
const validateConfirmPassword = (rule, value, callback) => {
  if (!value) {
    return callback(new Error('请再次输入密码'))
  }
  
  if (value !== passwordForm.newPassword) {
    return callback(new Error('两次输入的密码不一致'))
  }
  
  callback()
}

const passwordRules = {
  currentPassword: [
    { required: true, message: '请输入当前密码', trigger: 'blur' }
  ],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { validator: validatePasswordStrength, trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请再次输入密码', trigger: 'blur' },
    { validator: validateConfirmPassword, trigger: 'blur' }
  ]
}

const handleChangePassword = async () => {
  if (!passwordFormRef.value) return
  
  try {
    const valid = await passwordFormRef.value.validate()
    if (!valid) return
    
    loading.value = true
    
    await changePasswordApi({
      current_password: passwordForm.currentPassword,
      new_password: passwordForm.newPassword
    })
    
    ElMessage.success('密码修改成功！正在跳转...')
    
    // 修改密码成功后，刷新用户信息并跳转到首页
    await authStore.fetchUserInfo()
    setTimeout(() => {
      router.push('/')
    }, 1000)
    
  } catch (error) {
    console.error('修改密码失败:', error)
    
    let errorMessage = '密码修改失败，请重试！'
    
    if (error.message.includes('当前密码错误')) {
      errorMessage = '当前密码错误！'
    } else if (error.message.includes('密码强度')) {
      errorMessage = error.message
    }
    
    ElMessage.error(errorMessage)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.change-password-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.change-password-card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  padding: 40px;
  width: 100%;
  max-width: 480px;
  text-align: center;
}

.password-header {
  margin-bottom: 32px;
}

.warning-icon {
  color: #f59e0b;
  margin-bottom: 16px;
}

.password-header h1 {
  color: #333;
  font-size: 24px;
  font-weight: 600;
  margin: 0 0 12px 0;
}

.password-header p {
  color: #666;
  font-size: 14px;
  margin: 0;
  line-height: 1.6;
}

.password-form {
  text-align: left;
}

.change-button {
  width: 100%;
  height: 48px;
  font-size: 16px;
  font-weight: 500;
  border-radius: 8px;
}

.password-tip {
  margin-top: 24px;
  text-align: left;
}

.password-tip :deep(.el-alert__content) {
  font-size: 13px;
  line-height: 1.6;
}

.password-tip ul {
  list-style-type: disc;
}

.password-tip li {
  margin-bottom: 4px;
}

@media (max-width: 480px) {
  .change-password-card {
    padding: 24px;
    margin: 0 16px;
  }
  
  .password-header h1 {
    font-size: 20px;
  }
}
</style>
