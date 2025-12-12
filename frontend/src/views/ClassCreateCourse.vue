<template>
  <div class="class-create-course-container">
    <!-- 返回按钮 -->
    <div class="page-header">
      <el-button @click="goBack" text>
        <el-icon><ArrowLeft /></el-icon>
        返回班级详情
      </el-button>
    </div>

    <!-- 页面标题 -->
    <el-card shadow="never" class="header-card">
      <div class="header-content">
        <div class="header-left">
          <h1 class="page-title">为班级创建课程</h1>
          <p class="page-subtitle">{{ className }}</p>
        </div>
      </div>
    </el-card>

    <!-- 创建表单 -->
    <el-card shadow="never" class="form-card" v-loading="loading">
      <el-form :model="courseForm" label-width="120px">
        <el-alert 
          title="提示" 
          type="info" 
          :closable="false"
          style="margin-bottom: 24px"
        >
          基于模板创建课程，将自动复制模板的单元、资源和任务，并可为班级成员自动选课
        </el-alert>
        
        <el-form-item label="课程模板" required>
          <el-select 
            v-model="courseForm.template_id" 
            placeholder="请选择课程模板" 
            style="width: 100%"
            size="large"
            @change="onTemplateChange"
            filterable
          >
            <el-option
              v-for="template in courseTemplates"
              :key="template.id"
              :label="template.title"
              :value="template.id"
            >
              <div style="display: flex; justify-content: space-between; align-items: center">
                <span>{{ template.title }}</span>
                <el-tag :type="getDifficultyTagType(template.difficulty)" size="small">
                  {{ getDifficultyName(template.difficulty) }}
                </el-tag>
              </div>
            </el-option>
          </el-select>
        </el-form-item>
        
        <el-form-item label="课程名称">
          <el-input 
            v-model="courseForm.title" 
            placeholder="默认为：班级名+模板名"
            size="large"
            maxlength="100"
            show-word-limit
          />
          <div class="form-tip">
            留空将自动使用 "{{ className }}{{ selectedTemplate?.name || '' }}" 作为课程名称
          </div>
        </el-form-item>
        
        <el-form-item label="自动选课">
          <el-switch 
            v-model="courseForm.auto_enroll" 
            active-text="自动为班级成员选课"
            size="large"
          />
          <div class="form-tip">
            开启后，班级所有成员将自动选上该课程
          </div>
        </el-form-item>
        
        <el-divider />
        
        <!-- 模板预览 -->
        <div v-if="selectedTemplate" class="template-preview">
          <h3 class="preview-title">模板信息预览</h3>
          
          <el-descriptions :column="2" border size="large">
            <el-descriptions-item label="模板名称">
              <strong>{{ selectedTemplate.name }}</strong>
            </el-descriptions-item>
            <el-descriptions-item label="难度等级">
              <el-tag :type="getDifficultyTagType(selectedTemplate.difficulty)">
                {{ getDifficultyName(selectedTemplate.difficulty) }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="预计时长">
              {{ selectedTemplate.duration || '-' }}
            </el-descriptions-item>
            <el-descriptions-item label="课程分类">
              {{ selectedTemplate.category || '-' }}
            </el-descriptions-item>
            <el-descriptions-item label="使用次数">
              {{ selectedTemplate.usage_count || 0 }}
            </el-descriptions-item>
            <el-descriptions-item label="创建时间">
              {{ formatDate(selectedTemplate.created_at) }}
            </el-descriptions-item>
            <el-descriptions-item label="模板描述" :span="2">
              {{ selectedTemplate.description || '暂无描述' }}
            </el-descriptions-item>
          </el-descriptions>
        </div>

        <el-form-item style="margin-top: 32px">
          <el-button 
            type="primary" 
            @click="submitCreateCourse" 
            :loading="creating"
            :disabled="!courseForm.template_id"
            size="large"
          >
            <el-icon><Check /></el-icon>
            创建课程
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
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  ArrowLeft, Check
} from '@element-plus/icons-vue'
import { getClubClassDetail, getCourseTemplates, createCourseFromTemplate } from '@/api/club'
import dayjs from 'dayjs'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const creating = ref(false)
const className = ref('')
const classId = ref(null)
const courseTemplates = ref([])

const courseForm = reactive({
  template_id: null,
  class_id: null,
  title: '',
  auto_enroll: true
})

// 计算属性
const selectedTemplate = computed(() => {
  if (!courseForm.template_id) return null
  return courseTemplates.value.find(t => t.id === courseForm.template_id)
})

// 加载班级信息和课程模板
const loadData = async () => {
  loading.value = true
  try {
    // 加载班级信息
    const classRes = await getClubClassDetail(route.params.uuid)
    className.value = classRes.data.data.name
    classId.value = classRes.data.data.id
    courseForm.class_id = classRes.data.data.id
    
    // 加载课程模板
    const templateRes = await getCourseTemplates()
    courseTemplates.value = templateRes.data.data || []
  } catch (error) {
    ElMessage.error(error.message || '加载数据失败')
  } finally {
    loading.value = false
  }
}

// 模板选择变化
const onTemplateChange = () => {
  if (selectedTemplate.value && !courseForm.title) {
    // 自动生成课程名称
    courseForm.title = `${className.value}${selectedTemplate.value.name}`
  }
}

// 提交创建课程
const submitCreateCourse = async () => {
  if (!courseForm.template_id) {
    ElMessage.warning('请选择课程模板')
    return
  }
  
  creating.value = true
  try {
    const res = await createCourseFromTemplate(courseForm)
    ElMessage.success({
      message: `课程创建成功！已为 ${res.data.enrolled_students || 0} 名学生选课`,
      duration: 3000
    })
    // 返回班级详情页
    router.push(`/admin/classes/${route.params.uuid}`)
  } catch (error) {
    ElMessage.error(error.message || '创建课程失败')
  } finally {
    creating.value = false
  }
}

// 工具方法
const getDifficultyName = (difficulty) => {
  const map = {
    beginner: '入门',
    intermediate: '中级',
    advanced: '高级'
  }
  return map[difficulty] || difficulty
}

const getDifficultyTagType = (difficulty) => {
  const map = {
    beginner: 'success',
    intermediate: 'warning',
    advanced: 'danger'
  }
  return map[difficulty] || 'info'
}

const formatDate = (dateStr) => {
  if (!dateStr) return '-'
  return dayjs(dateStr).format('YYYY-MM-DD')
}

const goBack = () => {
  router.push(`/admin/classes/${route.params.uuid}`)
}

onMounted(() => {
  loadData()
})
</script>

<style scoped lang="scss">
.class-create-course-container {
  padding: 24px;
  background: #f5f7fa;
  min-height: calc(100vh - 60px);
}

.page-header {
  margin-bottom: 24px;
}

.header-card {
  margin-bottom: 24px;
  border-radius: 12px;
  
  .header-content {
    .header-left {
      .page-title {
        margin: 0 0 8px 0;
        font-size: 24px;
        font-weight: 600;
        color: #303133;
      }
      
      .page-subtitle {
        margin: 0;
        font-size: 14px;
        color: #909399;
      }
    }
  }
}

.form-card {
  max-width: 900px;
  margin: 0 auto;
  border-radius: 12px;
  
  .form-tip {
    margin-top: 8px;
    font-size: 12px;
    color: #909399;
    line-height: 1.5;
  }
  
  .template-preview {
    margin-top: 24px;
    padding: 24px;
    background: #f5f7fa;
    border-radius: 8px;
    
    .preview-title {
      margin: 0 0 20px 0;
      font-size: 16px;
      font-weight: 600;
      color: #303133;
    }
  }
}
</style>
