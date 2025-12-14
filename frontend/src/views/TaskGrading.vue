<template>
  <div class="task-grading-container">
    <!-- 返回按钮 -->
    <div class="page-header">
      <el-button @click="goBack" text>
        <el-icon><ArrowLeft /></el-icon>
        返回单元作业
      </el-button>
    </div>

    <!-- 页面标题 -->
    <el-card shadow="never" class="header-card">
      <div class="header-content">
        <div class="header-left">
          <h1 class="page-title">{{ taskDetail?.title }}</h1>
          <p class="page-subtitle">{{ className }} - {{ unitTitle }} - 作业批改</p>
        </div>
        <div class="header-stats">
          <div class="stat-item">
            <div class="stat-label">总人数</div>
            <div class="stat-value">{{ submissions.length }}</div>
          </div>
          <div class="stat-item">
            <div class="stat-label">已提交</div>
            <div class="stat-value submitted">{{ submittedCount }}</div>
          </div>
          <div class="stat-item">
            <div class="stat-label">待批改</div>
            <div class="stat-value pending">{{ toReviewCount }}</div>
          </div>
          <div class="stat-item">
            <div class="stat-label">已批改</div>
            <div class="stat-value completed">{{ completedCount }}</div>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 作业信息 -->
    <el-card shadow="never" class="info-card">
      <template #header>
        <div class="card-header">
          <el-icon><InfoFilled /></el-icon>
          <span>作业信息</span>
        </div>
      </template>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="作业标题" :span="2">
          {{ taskDetail?.title }}
        </el-descriptions-item>
        <el-descriptions-item label="作业描述" :span="2">
          <div class="task-description">
            {{ taskDetail?.description || '暂无描述' }}
          </div>
        </el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- 学生提交列表 -->
    <el-card shadow="never" class="submissions-card">
      <template #header>
        <div class="card-header">
          <div>
            <el-icon><User /></el-icon>
            <span>学生提交列表</span>
          </div>
          <div class="header-actions">
            <el-select v-model="filterStatus" placeholder="筛选状态" style="width: 150px" clearable size="default">
              <el-option label="全部" value="" />
              <el-option label="未提交" value="pending" />
              <el-option label="已提交" value="review" />
              <el-option label="已批改" value="completed" />
            </el-select>
            <el-select v-model="filterGrade" placeholder="筛选等级" style="width: 150px" clearable size="default">
              <el-option label="全部等级" value="" />
              <el-option label="优秀" value="excellent" />
              <el-option label="良好" value="good" />
              <el-option label="及格" value="pass" />
              <el-option label="不及格" value="fail" />
            </el-select>
            <span class="filter-tip">
              找到 {{ filteredSubmissions.length }} 名学生
            </span>
          </div>
        </div>
      </template>
      
      <div v-loading="loading">
        <el-table 
          :data="filteredSubmissions" 
          border
          stripe
          style="width: 100%"
          :max-height="650"
        >
          <el-table-column prop="student_number" label="学号" width="150" sortable fixed="left" />
          <el-table-column prop="student_name" label="姓名" width="120" sortable fixed="left" />
          <el-table-column label="状态" width="100" align="center">
            <template #default="{ row }">
              <el-tag :type="getSubmissionStatusType(row.status)">
                {{ getSubmissionStatusName(row.status) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="等级" width="100" align="center">
            <template #default="{ row }">
              <el-tag v-if="row.grade" :type="getGradeTagType(row.grade)">
                {{ getGradeName(row.grade) }}
              </el-tag>
              <span v-else>-</span>
            </template>
          </el-table-column>
          <el-table-column prop="score" label="分数" width="100" sortable align="center">
            <template #default="{ row }">
              {{ row.score !== null ? row.score : '-' }}
            </template>
          </el-table-column>
          <el-table-column prop="feedback" label="评语" min-width="200" show-overflow-tooltip />
          <el-table-column prop="submitted_at" label="提交时间" width="180">
            <template #default="{ row }">
              {{ formatDateTime(row.submitted_at) }}
            </template>
          </el-table-column>
          <el-table-column prop="graded_at" label="批改时间" width="180">
            <template #default="{ row }">
              {{ formatDateTime(row.graded_at) }}
            </template>
          </el-table-column>
          <el-table-column label="操作" width="200" fixed="right" align="center">
            <template #default="{ row }">
              <el-button 
                link 
                type="primary" 
                @click="openGradeDialog(row)"
                v-if="row.submission_id"
              >
                <el-icon><Edit /></el-icon>
                {{ row.graded_at ? '重新批改' : '批改' }}
              </el-button>
              <el-button 
                link 
                type="info" 
                @click="viewSubmission(row)"
                v-if="row.submission"
              >
                <el-icon><View /></el-icon>
                查看提交
              </el-button>
            </template>
          </el-table-column>
        </el-table>

        <el-empty 
          v-if="!loading && submissions.length === 0" 
          description="暂无学生提交"
          :image-size="120"
          style="padding: 80px 0"
        />
      </div>
    </el-card>

    <!-- 批改对话框 -->
    <el-dialog
      v-model="gradeDialogVisible"
      title="批改作业"
      width="700px"
      :close-on-click-modal="false"
    >
      <el-form :model="gradeForm" label-width="100px">
        <el-form-item label="学生">
          <el-input :value="currentSubmission?.student_name + ' (' + currentSubmission?.student_number + ')'" disabled />
        </el-form-item>
        
        <el-form-item label="等级" required>
          <el-radio-group v-model="gradeForm.grade" @change="onGradeChange">
            <el-radio value="excellent">
              <el-tag type="success" size="large">优秀</el-tag>
            </el-radio>
            <el-radio value="good">
              <el-tag type="success" effect="plain" size="large">良好</el-tag>
            </el-radio>
            <el-radio value="pass">
              <el-tag type="warning" size="large">及格</el-tag>
            </el-radio>
            <el-radio value="fail">
              <el-tag type="danger" size="large">不及格</el-tag>
            </el-radio>
          </el-radio-group>
        </el-form-item>
        
        <el-form-item label="分数">
          <el-input-number 
            v-model="gradeForm.score" 
            :min="0" 
            :max="100" 
            placeholder="0-100"
            style="width: 200px"
          />
          <span style="margin-left: 12px; color: #909399;">分（可选）</span>
        </el-form-item>
        
        <el-form-item label="评语模板">
          <el-select 
            v-model="selectedTemplate" 
            placeholder="选择评语模板" 
            style="width: 100%"
            clearable
            @change="onTemplateChange"
          >
            <el-option
              v-for="template in filteredTemplates"
              :key="template.id"
              :label="template.title"
              :value="template.id"
            >
              <div style="display: flex; justify-content: space-between;">
                <span>{{ template.title }}</span>
                <el-tag :type="getCategoryTagType(template.category)" size="small">
                  {{ template.category }}
                </el-tag>
              </div>
            </el-option>
          </el-select>
          <div class="form-tip">提示：选择模板后，评语会自动填充，你也可以自行修改</div>
        </el-form-item>
        
        <el-form-item label="评语" required>
          <el-input 
            v-model="gradeForm.feedback" 
            type="textarea" 
            :rows="5"
            placeholder="请输入评语"
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="gradeDialogVisible = false" size="large">取消</el-button>
        <el-button type="primary" @click="submitGrade" :loading="submittingGrade" size="large">
          提交批改
        </el-button>
      </template>
    </el-dialog>

    <!-- 查看提交对话框 -->
    <el-dialog
      v-model="viewSubmissionDialogVisible"
      title="查看提交内容"
      width="800px"
    >
      <div class="submission-content">
        <pre>{{ JSON.stringify(currentSubmission?.submission, null, 2) }}</pre>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  ArrowLeft, Edit, View, InfoFilled, User
} from '@element-plus/icons-vue'
import { getClubClassDetail } from '@/api/club'
import request from '@/api/request'
import dayjs from 'dayjs'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const className = ref('')
const unitTitle = ref('')
const taskDetail = ref(null)
const submissions = ref([])
const filterStatus = ref('')
const filterGrade = ref('')
const gradeDialogVisible = ref(false)
const viewSubmissionDialogVisible = ref(false)
const currentSubmission = ref(null)
const submittingGrade = ref(false)
const feedbackTemplates = ref([])
const selectedTemplate = ref(null)

const gradeForm = ref({
  grade: '',
  score: null,
  feedback: ''
})

// 计算属性 - 过滤后的提交列表
const filteredSubmissions = computed(() => {
  if (!submissions.value) return []
  let list = submissions.value
  
  if (filterStatus.value) {
    list = list.filter(s => s.status === filterStatus.value)
  }
  
  if (filterGrade.value) {
    list = list.filter(s => s.grade === filterGrade.value)
  }
  
  return list
})

// 计算属性 - 根据等级过滤模板
const filteredTemplates = computed(() => {
  if (!gradeForm.value.grade) return feedbackTemplates.value
  
  const gradeMap = {
    'excellent': '优秀',
    'good': '良好',
    'pass': '及格',
    'fail': '不及格'
  }
  
  const category = gradeMap[gradeForm.value.grade]
  return feedbackTemplates.value.filter(t => t.category === category)
})

// 计算属性 - 已提交数量
const submittedCount = computed(() => {
  return submissions.value.filter(s => s.status === 'review' || s.status === 'completed').length
})

// 计算属性 - 待批改数量
const toReviewCount = computed(() => {
  return submissions.value.filter(s => s.status === 'review').length
})

// 计算属性 - 已批改数量
const completedCount = computed(() => {
  return submissions.value.filter(s => s.status === 'completed').length
})

// 加载班级名称
const loadClassName = async () => {
  try {
    const res = await getClubClassDetail(route.params.uuid)
    className.value = res.data.data.name
  } catch (error) {
    console.error('加载班级名称失败:', error)
  }
}

// 加载单元标题
const loadUnitTitle = async () => {
  try {
    const res = await request({
      url: `/admin/club/classes/${route.params.uuid}/homework/units/${route.params.unitId}`,
      method: 'get'
    })
    unitTitle.value = res.data.data.unit.title
  } catch (error) {
    console.error('加载单元标题失败:', error)
  }
}

// 加载作业提交列表
const loadTaskSubmissions = async () => {
  loading.value = true
  try {
    const res = await request({
      url: `/admin/club/classes/${route.params.uuid}/homework/tasks/${route.params.taskId}/submissions`,
      method: 'get'
    })
    taskDetail.value = res.data.data.task
    submissions.value = res.data.data.submissions || []
  } catch (error) {
    ElMessage.error(error.message || '加载提交列表失败')
  } finally {
    loading.value = false
  }
}

// 加载评语模板
const loadFeedbackTemplates = async () => {
  try {
    const res = await request({
      url: '/admin/feedback-templates',
      method: 'get'
    })
    feedbackTemplates.value = res.data.data || []
  } catch (error) {
    console.error('加载评语模板失败:', error)
  }
}

// 打开批改对话框
const openGradeDialog = (submission) => {
  currentSubmission.value = submission
  gradeForm.value = {
    grade: submission.grade || '',
    score: submission.score,
    feedback: submission.feedback || ''
  }
  selectedTemplate.value = null
  gradeDialogVisible.value = true
}

// 等级变化时，重置模板选择
const onGradeChange = () => {
  selectedTemplate.value = null
}

// 模板变化时，填充评语
const onTemplateChange = (templateId) => {
  if (!templateId) return
  const template = feedbackTemplates.value.find(t => t.id === templateId)
  if (template) {
    gradeForm.value.feedback = template.content
  }
}

// 提交批改
const submitGrade = async () => {
  if (!gradeForm.value.grade) {
    ElMessage.warning('请选择等级')
    return
  }
  if (!gradeForm.value.feedback) {
    ElMessage.warning('请输入评语')
    return
  }
  
  submittingGrade.value = true
  try {
    await request({
      url: `/admin/club/classes/${route.params.uuid}/homework/submissions/${currentSubmission.value.submission_id}/review`,
      method: 'put',
      data: {
        grade: gradeForm.value.grade,
        score: gradeForm.value.score,
        feedback: gradeForm.value.feedback,
        status: 'completed'
      }
    })
    ElMessage.success('批改成功')
    gradeDialogVisible.value = false
    loadTaskSubmissions() // 刷新列表
  } catch (error) {
    ElMessage.error(error.message || '批改失败')
  } finally {
    submittingGrade.value = false
  }
}

// 查看提交内容
const viewSubmission = (submission) => {
  currentSubmission.value = submission
  viewSubmissionDialogVisible.value = true
}

// 工具方法
const getSubmissionStatusName = (status) => {
  const map = {
    pending: '未提交',
    'in-progress': '进行中',
    review: '已提交',
    completed: '已批改'
  }
  return map[status] || status
}

const getSubmissionStatusType = (status) => {
  const map = {
    pending: 'info',
    'in-progress': 'warning',
    review: '',
    completed: 'success'
  }
  return map[status] || 'info'
}

const getGradeName = (grade) => {
  const map = {
    excellent: '优秀',
    good: '良好',
    pass: '及格',
    fail: '不及格'
  }
  return map[grade] || grade
}

const getGradeTagType = (grade) => {
  const map = {
    excellent: 'success',
    good: 'success',
    pass: 'warning',
    fail: 'danger'
  }
  return map[grade] || 'info'
}

const getCategoryTagType = (category) => {
  const map = {
    '优秀': 'success',
    '良好': 'success',
    '及格': 'warning',
    '不及格': 'danger'
  }
  return map[category] || 'info'
}

const formatDateTime = (dateStr) => {
  if (!dateStr) return '-'
  return dayjs(dateStr).format('YYYY-MM-DD HH:mm')
}

const goBack = () => {
  router.push(`/admin/classes/${route.params.uuid}/homework/units/${route.params.unitId}`)
}

onMounted(async () => {
  await Promise.all([
    loadClassName(),
    loadUnitTitle(),
    loadTaskSubmissions(),
    loadFeedbackTemplates()
  ])
})
</script>

<style scoped lang="scss">
.task-grading-container {
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
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    
    .header-left {
      flex: 1;
      
      .page-title {
        margin: 0 0 8px 0;
        font-size: 26px;
        font-weight: 600;
        color: #303133;
      }
      
      .page-subtitle {
        margin: 0;
        font-size: 14px;
        color: #909399;
      }
    }
    
    .header-stats {
      display: flex;
      gap: 40px;
      
      .stat-item {
        text-align: center;
        
        .stat-label {
          font-size: 14px;
          color: #909399;
          margin-bottom: 8px;
        }
        
        .stat-value {
          font-size: 28px;
          font-weight: 600;
          color: #409eff;
          
          &.submitted {
            color: #67c23a;
          }
          
          &.pending {
            color: #e6a23c;
          }
          
          &.completed {
            color: #409eff;
          }
        }
      }
    }
  }
}

.info-card, .submissions-card {
  margin-bottom: 24px;
  border-radius: 12px;
  
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 16px;
    font-weight: 600;
    
    > div:first-child {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    
    .header-actions {
      display: flex;
      align-items: center;
      gap: 12px;
      
      .filter-tip {
        font-size: 14px;
        color: #909399;
      }
    }
  }
}

.task-description {
  line-height: 1.6;
  white-space: pre-wrap;
  color: #606266;
}

.submission-content {
  padding: 16px;
  background: #f5f7fa;
  border-radius: 8px;
  max-height: 500px;
  overflow-y: auto;
  
  pre {
    margin: 0;
    font-family: 'Courier New', monospace;
    font-size: 13px;
    line-height: 1.5;
    white-space: pre-wrap;
    word-wrap: break-word;
  }
}

.form-tip {
  margin-top: 8px;
  font-size: 12px;
  color: #909399;
  line-height: 1.5;
}

:deep(.el-radio) {
  margin-right: 20px;
  margin-bottom: 12px;
}
</style>


