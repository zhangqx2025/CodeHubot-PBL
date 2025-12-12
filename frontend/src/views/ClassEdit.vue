<template>
  <div class="class-edit-container">
    <!-- 返回按钮 -->
    <div class="page-header">
      <el-button @click="goBack" text>
        <el-icon><ArrowLeft /></el-icon>
        返回班级详情
      </el-button>
    </div>

    <!-- 编辑表单 -->
    <el-card shadow="never" class="form-card">
      <template #header>
        <div class="card-header">
          <span>编辑班级信息</span>
        </div>
      </template>

      <el-form 
        :model="classForm" 
        :rules="classRules" 
        ref="classFormRef" 
        label-width="120px"
        v-loading="loading"
      >
        <el-form-item label="班级名称" prop="name">
          <el-input 
            v-model="classForm.name" 
            placeholder="例如：0501班、AI兴趣班" 
            maxlength="50"
            show-word-limit
            size="large"
          />
        </el-form-item>
        
        <el-form-item label="班级类型" prop="class_type">
          <el-select v-model="classForm.class_type" placeholder="请选择班级类型" size="large" style="width: 100%">
            <el-option label="社团班" value="club">
              <span style="display: flex; align-items: center">
                <el-icon style="margin-right: 8px"><Medal /></el-icon>
                社团班
              </span>
            </el-option>
            <el-option label="项目班" value="project">
              <span style="display: flex; align-items: center">
                <el-icon style="margin-right: 8px"><FolderOpened /></el-icon>
                项目班
              </span>
            </el-option>
            <el-option label="兴趣班" value="interest">
              <span style="display: flex; align-items: center">
                <el-icon style="margin-right: 8px"><Star /></el-icon>
                兴趣班
              </span>
            </el-option>
            <el-option label="竞赛班" value="competition">
              <span style="display: flex; align-items: center">
                <el-icon style="margin-right: 8px"><Trophy /></el-icon>
                竞赛班
              </span>
            </el-option>
          </el-select>
        </el-form-item>
        
        <el-form-item label="班级描述" prop="description">
          <el-input 
            v-model="classForm.description" 
            type="textarea" 
            :rows="6" 
            placeholder="请输入班级描述"
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
        
        <el-form-item label="最大人数" prop="max_students">
          <el-input-number 
            v-model="classForm.max_students" 
            :min="1" 
            :max="200" 
            size="large"
            style="width: 100%"
          />
          <div class="form-tip">
            当前已有 {{ currentMembers }} 名成员，最大人数不能小于当前成员数
          </div>
        </el-form-item>
        
        <el-form-item label="开放状态">
          <el-switch 
            v-model="classForm.is_open" 
            active-text="开放加入" 
            inactive-text="关闭加入"
            size="large"
          />
          <div class="form-tip">
            开启后，学生可以申请加入该班级
          </div>
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="submitForm" :loading="submitting" size="large">
            <el-icon><Check /></el-icon>
            保存修改
          </el-button>
          <el-button @click="goBack" size="large">
            取消
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  ArrowLeft, Check, Medal, FolderOpened, Star, Trophy
} from '@element-plus/icons-vue'
import { getClubClassDetail, updateClubClass } from '@/api/club'

const route = useRoute()
const router = useRouter()

const loading = ref(true)
const submitting = ref(false)
const currentMembers = ref(0)
const classFormRef = ref(null)

const classForm = reactive({
  name: '',
  class_type: 'club',
  description: '',
  max_students: 30,
  is_open: true
})

const classRules = {
  name: [
    { required: true, message: '请输入班级名称', trigger: 'blur' },
    { min: 2, max: 50, message: '长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  class_type: [
    { required: true, message: '请选择班级类型', trigger: 'change' }
  ],
  max_students: [
    { required: true, message: '请输入最大人数', trigger: 'blur' },
    { 
      validator: (rule, value, callback) => {
        if (value < currentMembers.value) {
          callback(new Error(`最大人数不能小于当前成员数 ${currentMembers.value}`))
        } else {
          callback()
        }
      }, 
      trigger: 'blur' 
    }
  ]
}

// 加载班级详情
const loadClassDetail = async () => {
  loading.value = true
  try {
    const uuid = route.params.uuid
    const res = await getClubClassDetail(uuid)
    const data = res.data.data
    
    Object.assign(classForm, {
      name: data.name,
      class_type: data.class_type,
      description: data.description,
      max_students: data.max_students,
      is_open: data.is_open
    })
    
    currentMembers.value = data.current_members || 0
  } catch (error) {
    ElMessage.error(error.message || '加载班级详情失败')
  } finally {
    loading.value = false
  }
}

// 提交表单
const submitForm = async () => {
  try {
    await classFormRef.value.validate()
  } catch {
    return
  }
  
  submitting.value = true
  try {
    await updateClubClass(route.params.uuid, classForm)
    ElMessage.success('班级信息更新成功')
    goBack()
  } catch (error) {
    ElMessage.error(error.message || '更新失败')
  } finally {
    submitting.value = false
  }
}

const goBack = () => {
  router.push(`/admin/classes/${route.params.uuid}`)
}

onMounted(() => {
  loadClassDetail()
})
</script>

<style scoped lang="scss">
.class-edit-container {
  padding: 24px;
  background: #f5f7fa;
  min-height: calc(100vh - 60px);
}

.page-header {
  margin-bottom: 24px;
}

.form-card {
  max-width: 800px;
  margin: 0 auto;
  border-radius: 12px;
  
  .card-header {
    font-size: 18px;
    font-weight: 600;
  }
  
  .form-tip {
    margin-top: 8px;
    font-size: 12px;
    color: #909399;
    line-height: 1.5;
  }
}
</style>
