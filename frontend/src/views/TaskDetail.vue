<template>
  <div class="task-detail" v-loading="loading">
    <el-page-header @back="$router.back()" class="page-header">
      <template #content>
        <span class="page-title">任务详情</span>
      </template>
    </el-page-header>

    <div class="content" v-if="task">
      <!-- 任务信息 -->
      <el-card class="task-info">
        <template #header>
          <div class="card-header">
            <span>{{ task.title }}</span>
            <el-tag :type="getDifficultyColor(task.difficulty)">
              {{ getDifficultyLabel(task.difficulty) }}
            </el-tag>
          </div>
        </template>
        
        <el-descriptions :column="2" border>
          <el-descriptions-item label="任务类型">
            <el-tag :type="getTaskTypeColor(task.type)">
              {{ getTaskTypeLabel(task.type) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="预估时间">
            {{ task.estimated_time || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="当前状态" :span="2">
            <el-tag :type="getStatusColor(taskProgress.status)">
              {{ getStatusLabel(taskProgress.status) }}
            </el-tag>
          </el-descriptions-item>
        </el-descriptions>

        <div class="task-description">
          <h3>任务描述</h3>
          <div class="description-content">{{ task.description }}</div>
        </div>

        <div class="task-requirements" v-if="task.requirements">
          <h3>任务要求</h3>
          <div class="requirements-content">
            <pre>{{ JSON.stringify(task.requirements, null, 2) }}</pre>
          </div>
        </div>
      </el-card>

      <!-- 进度信息 -->
      <el-card class="progress-card">
        <template #header>
          <span>完成进度</span>
        </template>
        
        <el-progress :percentage="taskProgress.progress || 0" :status="getProgressStatus()" />
        
        <div class="progress-actions">
          <el-button-group>
            <el-button @click="updateProgress(25)">25%</el-button>
            <el-button @click="updateProgress(50)">50%</el-button>
            <el-button @click="updateProgress(75)">75%</el-button>
            <el-button @click="updateProgress(100)">100%</el-button>
          </el-button-group>
        </div>
      </el-card>

      <!-- 提交作业 -->
      <el-card class="submission-card">
        <template #header>
          <span>{{ taskProgress.status === 'review' ? '重新提交作业' : taskProgress.status === 'completed' ? '重新提交作业（将覆盖原有评分）' : '提交作业' }}</span>
        </template>
        
        <el-form :model="submissionForm" label-width="100px">
          <el-form-item label="提交内容">
            <el-input
              v-model="submissionForm.content"
              type="textarea"
              :rows="12"
              placeholder="请输入作业内容"
              class="fixed-textarea"
            />
          </el-form-item>
          <el-form-item label="附件链接">
            <el-input
              v-model="submissionForm.attachment_url"
              placeholder="可选：作业文件链接（如代码仓库、文档等）"
            />
          </el-form-item>
          <el-form-item>
            <el-button 
              type="primary" 
              @click="handleSubmit"
              :loading="submitting"
            >
              {{ taskProgress.status === 'review' ? '重新提交' : taskProgress.status === 'completed' ? '重新提交' : '提交作业' }}
            </el-button>
            <el-button 
              @click="handleSaveDraft"
            >
              保存草稿
            </el-button>
          </el-form-item>
        </el-form>
      </el-card>

      <!-- 评分与反馈 -->
      <el-card class="feedback-card" v-if="taskProgress.score !== null || taskProgress.feedback">
        <template #header>
          <span>评分与反馈</span>
        </template>
        
        <el-descriptions :column="1" border>
          <el-descriptions-item label="得分">
            <el-tag type="success" size="large">{{ taskProgress.score }} 分</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="评分时间">
            {{ formatDate(taskProgress.graded_at) }}
          </el-descriptions-item>
          <el-descriptions-item label="教师反馈">
            <div class="feedback-content">{{ taskProgress.feedback || '暂无反馈' }}</div>
          </el-descriptions-item>
        </el-descriptions>
      </el-card>

      <!-- 提交历史 -->
      <el-card class="history-card" v-if="taskProgress.submission">
        <template #header>
          <span>提交历史</span>
        </template>
        
        <el-timeline>
          <el-timeline-item :timestamp="formatDate(taskProgress.updated_at)" placement="top">
            <el-card>
              <h4>最近提交</h4>
              <p>{{ taskProgress.submission?.content || '无内容' }}</p>
              <p v-if="taskProgress.submission?.attachment_url">
                附件：<el-link :href="taskProgress.submission?.attachment_url" target="_blank">查看</el-link>
              </p>
            </el-card>
          </el-timeline-item>
        </el-timeline>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { getTaskDetail, submitTask, updateTaskProgress } from '@/api/task'

const route = useRoute()
const loading = ref(false)
const submitting = ref(false)
const task = ref(null)
const taskProgress = ref({})

const submissionForm = reactive({
  content: '',
  attachment_url: ''
})

// 获取任务类型标签
const getTaskTypeLabel = (type) => {
  const labels = {
    'analysis': '分析',
    'coding': '编码',
    'design': '设计',
    'deployment': '部署'
  }
  return labels[type] || type
}

const getTaskTypeColor = (type) => {
  const colors = {
    'analysis': 'primary',
    'coding': 'success',
    'design': 'warning',
    'deployment': 'danger'
  }
  return colors[type] || 'info'
}

// 获取难度标签
const getDifficultyLabel = (difficulty) => {
  const labels = {
    'easy': '简单',
    'medium': '中等',
    'hard': '困难'
  }
  return labels[difficulty] || difficulty
}

const getDifficultyColor = (difficulty) => {
  const colors = {
    'easy': 'success',
    'medium': 'warning',
    'hard': 'danger'
  }
  return colors[difficulty] || 'info'
}

// 获取状态标签
const getStatusLabel = (status) => {
  const labels = {
    'pending': '待开始',
    'in-progress': '进行中',
    'blocked': '受阻',
    'review': '待审核',
    'completed': '已完成'
  }
  return labels[status] || status
}

const getStatusColor = (status) => {
  const colors = {
    'pending': 'info',
    'in-progress': 'primary',
    'blocked': 'warning',
    'review': 'warning',
    'completed': 'success'
  }
  return colors[status] || 'info'
}

// 获取进度状态
const getProgressStatus = () => {
  if (taskProgress.value.progress >= 100) return 'success'
  if (taskProgress.value.progress >= 50) return undefined
  return undefined
}

// 格式化日期
const formatDate = (dateStr) => {
  if (!dateStr) return '-'
  const date = new Date(dateStr)
  return date.toLocaleString('zh-CN')
}

// 加载任务详情
const loadTaskDetail = async () => {
  loading.value = true
  try {
    const taskUuid = route.params.uuid
    const result = await getTaskDetail(taskUuid)
    
    console.log('=== 加载任务详情 ===')
    console.log('完整返回数据:', result)
    console.log('任务进度数据:', result.progress)
    console.log('submission字段:', result.progress?.submission)
    
    task.value = result
    taskProgress.value = result.progress || {}
    
    // 始终填充之前提交的内容到表单（如果存在）
    if (taskProgress.value.submission) {
      console.log('找到submission数据，开始填充表单')
      console.log('content:', taskProgress.value.submission.content)
      console.log('attachment_url:', taskProgress.value.submission.attachment_url)
      
      submissionForm.content = taskProgress.value.submission.content || ''
      submissionForm.attachment_url = taskProgress.value.submission.attachment_url || ''
      
      console.log('表单填充完成:', submissionForm)
    } else {
      console.log('未找到submission数据，清空表单')
      // 如果没有提交记录，确保表单为空
      submissionForm.content = ''
      submissionForm.attachment_url = ''
    }
  } catch (error) {
    console.error('加载任务详情失败:', error)
    ElMessage.error(error.message || '加载任务详情失败')
  } finally {
    loading.value = false
  }
}

// 更新进度
const updateProgress = async (progress) => {
  try {
    await updateTaskProgress(task.value.uuid, progress)
    taskProgress.value.progress = progress
    ElMessage.success('进度更新成功')
  } catch (error) {
    ElMessage.error(error.message || '进度更新失败')
  }
}

// 保存草稿
const handleSaveDraft = () => {
  ElMessage.info('草稿已保存到本地')
}

// 提交作业
const handleSubmit = async () => {
  if (!submissionForm.content.trim()) {
    ElMessage.warning('请输入提交内容')
    return
  }
  
  submitting.value = true
  try {
    await submitTask(task.value.uuid, {
      content: submissionForm.content,
      attachment_url: submissionForm.attachment_url
    })
    
    ElMessage.success('作业提交成功！等待教师评分')
    loadTaskDetail()
  } catch (error) {
    ElMessage.error(error.message || '提交失败')
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  loadTaskDetail()
})
</script>

<style scoped>
.task-detail {
  background: #f5f7fa;
  min-height: calc(100vh - 60px);
  padding: 20px;
}

.page-header {
  background: white;
  padding: 20px;
  margin-bottom: 20px;
  border-radius: 4px;
}

.page-title {
  font-size: 18px;
  font-weight: 600;
}

.content {
  max-width: 1200px;
  margin: 0 auto;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.task-info,
.progress-card,
.submission-card,
.feedback-card,
.history-card {
  margin-bottom: 20px;
}

.task-description,
.task-requirements {
  margin-top: 20px;
}

.task-description h3,
.task-requirements h3 {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 10px;
}

.description-content {
  color: #606266;
  line-height: 1.8;
}

.requirements-content pre {
  background: #f5f7fa;
  padding: 15px;
  border-radius: 4px;
  overflow-x: auto;
  color: #303133;
}

.progress-actions {
  margin-top: 20px;
  text-align: center;
}

.feedback-content {
  color: #606266;
  line-height: 1.8;
  white-space: pre-wrap;
}

/* 固定textarea大小，禁用拖拽 */
.fixed-textarea :deep(textarea) {
  resize: none !important;
  min-height: 280px;
  max-height: 280px;
  overflow-y: auto;
}
</style>
