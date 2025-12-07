<template>
  <div class="admin-login-container">
    <div class="admin-login-card">
      <div class="admin-login-header">
        <h1>PBL系统管理后台</h1>
        <p>管理员登录</p>
      </div>
      
      <el-form 
        ref="loginFormRef" 
        :model="loginData" 
        :rules="loginRules" 
        class="admin-login-form"
        @submit.prevent="handleLogin"
      >
        <el-form-item prop="username">
          <el-input
            v-model="loginData.username"
            placeholder="请输入工号@学校代码 (如: T001@school001)"
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
            class="admin-login-button"
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
          <p class="demo-info">工号: T001</p>
          <p class="demo-info">学校代码: DEMO_SCHOOL</p>
          <p class="demo-info">密码: 123456</p>
          <p class="demo-info">登录格式: 工号@学校代码</p>
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
      
      <div class="admin-login-footer">
        <el-link type="primary" @click="goToStudentLogin">返回学生登录</el-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import { adminLogin } from '@/api/admin'

const router = useRouter()

const loading = ref(false)
const loginFormRef = ref(null)

const loginData = reactive({
  username: '',
  password: ''
})

const loginRules = {
  username: [
    { required: true, message: '请输入工号@学校代码', trigger: 'blur' },
    {
      pattern: /^[a-zA-Z0-9_]+@[a-zA-Z0-9_]+$/,
      message: '请输入正确的工号@学校代码格式',
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
    
    // 解析工号@学校代码格式
    const [teacherNumber, schoolCode] = loginData.username.split('@')
    
    const response = await adminLogin({
      school_code: schoolCode,
      number: teacherNumber,
      password: loginData.password
    })
    
    // 保存token和管理员信息
    if (response.data && response.data.data) {
      const { access_token, admin } = response.data.data
      localStorage.setItem('admin_access_token', access_token)
      localStorage.setItem('admin_info', JSON.stringify(admin))
    }
    
    ElMessage.success('登录成功！')
    await router.push('/admin')
    
  } catch (error) {
    console.error('登录失败:', error)
    
    let errorMessage = '登录失败，请重试！'
    
    if (error.response?.data?.message) {
      errorMessage = error.response.data.message
    } else if (error.message.includes('网络')) {
      errorMessage = '网络连接失败，请检查网络设置！'
    }
    
    ElMessage.error(errorMessage)
  } finally {
    loading.value = false
  }
}

const fillDemoAccount = () => {
  loginData.username = 'T001@DEMO_SCHOOL'
  loginData.password = '123456'
  ElMessage.success('演示账号已自动填充！')
}

const goToStudentLogin = () => {
  router.push('/login')
}
</script>

<style scoped>
.admin-login-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.admin-login-card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
  padding: 40px;
  width: 100%;
  max-width: 400px;
  text-align: center;
}

.admin-login-header h1 {
  color: #333;
  font-size: 24px;
  font-weight: 600;
  margin: 0 0 8px 0;
}

.admin-login-header p {
  color: #666;
  font-size: 16px;
  margin: 0 0 32px 0;
}

.admin-login-form {
  text-align: left;
}

.admin-login-button {
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
  border-left: 4px solid #667eea;
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
  color: #667eea;
  font-size: 12px;
  padding: 0;
  margin: 0;
}

.demo-button:hover {
  color: #764ba2;
}

.admin-login-footer {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid #eee;
  text-align: center;
}

@media (max-width: 480px) {
  .admin-login-card {
    padding: 24px;
    margin: 0 16px;
  }
  
  .admin-login-header h1 {
    font-size: 20px;
  }
}
</style>
