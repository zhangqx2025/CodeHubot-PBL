<template>
  <div class="login-container">
    <div class="login-card">
      <div class="login-header">
        <h1>跨学科项目式学习平台</h1>
        <p>学生端 - 学号登录</p>
      </div>
      
      <el-form 
        ref="loginFormRef" 
        :model="loginData" 
        :rules="loginRules" 
        class="login-form"
        @submit.prevent="handleLogin"
      >
        <el-form-item prop="username">
          <el-input
            v-model="loginData.username"
            placeholder="请输入学号@学校代码 (如: 20240001@school001)"
            :prefix-icon="User"
            size="large"
            clearable
          />
        </el-form-item>
        
        <el-form-item prop="password">
          <el-input
            v-model="loginData.password"
            type="password"
            placeholder="请输入密码"
            :prefix-icon="Lock"
            size="large"
            show-password
            @keyup.enter="handleLogin"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button 
            type="primary" 
            size="large" 
            class="login-button"
            :loading="loading"
            @click="handleLogin"
          >
            {{ loading ? '登录中...' : '登录' }}
          </el-button>
        </el-form-item>
      </el-form>
      
      <div class="login-tips">
        <div class="demo-account">
          <p class="demo-title">演示账号</p>
          <p class="demo-info">学号: 20240001</p>
          <p class="demo-info">学校代码: DEMO_SCHOOL</p>
          <p class="demo-info">密码: 123456</p>
          <p class="demo-info">登录格式: 学号@学校代码</p>
          <el-button 
            type="text" 
            size="small" 
            @click="fillDemoAccount"
            class="demo-button"
          >
            一键填入演示账号
          </el-button>
        </div>
      </div>
      
      <div class="login-footer">
        <p>© 2025 跨学科项目式学习平台. All rights reserved.</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import { useAuthStore } from '@/store/auth'

const router = useRouter()
const authStore = useAuthStore()

const loading = ref(false)
const loginFormRef = ref(null)

const loginData = reactive({
  username: '',
  password: ''
})

const loginRules = {
  username: [
    { required: true, message: '请输入学号@学校代码', trigger: 'blur' },
    {
      pattern: /^[a-zA-Z0-9_]+@[a-zA-Z0-9_]+$/,
      message: '请输入正确的学号@学校代码格式',
      trigger: 'blur'
    }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于6位', trigger: 'blur' }
  ]
}

const handleLogin = async () => {
  if (!loginFormRef.value) return
  
  try {
    const valid = await loginFormRef.value.validate()
    if (!valid) return
    
    loading.value = true
    
    // 解析学号@学校代码格式
    const [studentId, schoolCode] = loginData.username.split('@')
    await authStore.studentLogin({
      student_id: studentId,
      school_code: schoolCode,
      password: loginData.password
    })
    
    ElMessage.success('登录成功！')
    await router.push('/')
    
  } catch (error) {
    console.error('登录失败:', error)
    
    let errorMessage = '登录失败，请重试！'
    
    if (error.message.includes('用户名或密码错误')) {
      errorMessage = '用户名或密码错误！'
    } else if (error.message.includes('网络')) {
      errorMessage = '网络连接失败，请检查网络设置！'
    }
    
    ElMessage.error(errorMessage)
  } finally {
    loading.value = false
  }
}

const fillDemoAccount = () => {
  loginData.username = '20240001@DEMO_SCHOOL'
  loginData.password = '123456'
  ElMessage.success('演示账号已自动填充！')
}

onMounted(() => {
  if (authStore.isLoggedIn) {
    router.push('/')
  }
})
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.login-card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  padding: 40px;
  width: 100%;
  max-width: 400px;
  text-align: center;
}

.login-header h1 {
  color: #333;
  font-size: 24px;
  font-weight: 600;
  margin: 0 0 8px 0;
}

.login-header p {
  color: #666;
  font-size: 16px;
  margin: 0 0 32px 0;
}

.login-form {
  text-align: left;
}

.login-button {
  width: 100%;
  height: 48px;
  font-size: 16px;
  font-weight: 500;
  border-radius: 8px;
}

.login-tips {
  margin-top: 20px;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
  border-left: 4px solid #409eff;
}

.login-tips p {
  margin: 0 0 8px 0;
  color: #666;
  font-size: 14px;
}

.demo-title {
  font-weight: 600;
  color: #333 !important;
  margin-bottom: 8px !important;
}

.demo-info {
  font-size: 12px !important;
  color: #666 !important;
}

.demo-button {
  color: #409eff;
  font-size: 12px;
  padding: 0;
  margin: 0;
}

.demo-button:hover {
  color: #66b1ff;
}

.login-footer {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid #eee;
}

.login-footer p {
  margin: 0;
  color: #999;
  font-size: 12px;
}

@media (max-width: 480px) {
  .login-card {
    padding: 24px;
    margin: 0 16px;
  }
  
  .login-header h1 {
    font-size: 20px;
  }
}
</style>

