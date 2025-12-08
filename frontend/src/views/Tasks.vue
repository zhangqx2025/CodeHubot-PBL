<template>
  <div class="tasks-page">
    <div class="page-header">
      <h1>任务列表</h1>
      <p>管理你的任务列表和进度</p>
    </div>

    <div class="filters">
      <el-select v-model="selectedProject" placeholder="筛选项目" clearable style="width: 180px">
        <el-option label="全部项目" value="" />
        <el-option v-for="project in uniqueProjects" :key="project" :label="project" :value="project" />
      </el-select>

      <el-select v-model="selectedMode" placeholder="任务模式" clearable style="width: 150px">
        <el-option label="全部" value="" />
        <el-option label="个人任务" value="individual" />
        <el-option label="小组任务" value="group" />
      </el-select>

      <el-select v-model="selectedStatus" placeholder="筛选状态" clearable style="width: 150px">
        <el-option label="全部" value="" />
        <el-option label="待开始" value="pending" />
        <el-option label="进行中" value="in-progress" />
        <el-option label="已完成" value="completed" />
      </el-select>
      
      <el-select v-model="selectedType" placeholder="筛选类型" clearable style="width: 150px">
        <el-option label="全部" value="" />
        <el-option label="分析类" value="analysis" />
        <el-option label="编程类" value="coding" />
        <el-option label="设计类" value="design" />
      </el-select>
      
      <el-input
        v-model="searchText"
        placeholder="搜索任务..."
        :prefix-icon="Search"
        style="width: 300px"
        clearable
      />
    </div>

    <div class="tasks-list" v-if="loading">
      <el-skeleton :rows="5" animated />
    </div>

    <div class="tasks-list" v-else-if="filteredTasks.length === 0">
      <el-empty description="暂无任务" />
    </div>

    <div class="tasks-list" v-else>
      <div 
        class="task-card" 
        v-for="task in filteredTasks" 
        :key="task.id"
      >
        <div class="task-header">
          <div class="task-title-section">
            <div class="task-project-badge">
              <el-tag size="small" effect="dark" type="primary">{{ task.projectName }}</el-tag>
            </div>
            <h3>{{ task.title }}</h3>
            
            <!-- 任务模式标记 -->
            <el-tag 
              v-if="task.isGroupTask" 
              type="warning" 
              effect="light" 
              size="small"
              class="mode-tag"
            >
              <el-icon><UserFilled /></el-icon> 小组任务
            </el-tag>
            <el-tag 
              v-else 
              type="info" 
              effect="plain" 
              size="small"
              class="mode-tag"
            >
              <el-icon><User /></el-icon> 个人任务
            </el-tag>

            <el-tag :type="getTaskTagType(task.status)" size="small">
              {{ getStatusText(task.status) }}
            </el-tag>
          </div>
          <div class="task-progress">
            <el-progress :percentage="task.progress" :status="getProgressStatus(task.status)" />
          </div>
        </div>
        
        <p class="task-description">{{ task.description }}</p>
        
        <div class="task-meta">
          <span class="meta-item">
            <el-icon><Clock /></el-icon>
            {{ task.estimatedTime }}
          </span>
          <span class="meta-item">
            <el-icon><Star /></el-icon>
            {{ task.difficulty }}
          </span>
          <span class="meta-item">
            <el-icon><Document /></el-icon>
            {{ task.type }}
          </span>
        </div>
        
        <!-- 小组提交状态提示 -->
        <div v-if="task.isGroupTask && task.submittedBy" class="group-submission-info">
          <el-alert
            :title="`同组乘员 ${task.submittedBy.name} 已于 ${task.submittedBy.time} 提交`"
            type="success"
            :closable="false"
            show-icon
          />
        </div>

        <div class="task-actions">
          <el-button 
            type="primary" 
            size="small"
            @click="goToTask(task.id)"
          >
            {{ task.status === 'completed' ? '查看详情' : '开始任务' }}
          </el-button>
          <el-button 
            size="small"
            @click="viewUnit(task.unitUuid || task.unitId)"
          >
            查看单元
          </el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Search, Clock, Star, Document, User, UserFilled } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { getMyCourses, getCourseDetail, getMyLearningProgress } from '@/api/student'

const router = useRouter()

const selectedStatus = ref('')
const selectedType = ref('')
const selectedMode = ref('')
const selectedProject = ref('')
const searchText = ref('')

const tasks = ref([])
const loading = ref(true)

// 加载学生的所有任务
const loadTasks = async () => {
  try {
    loading.value = true
    
    // 获取我的课程列表
    const courses = await getMyCourses()
    
    // 获取我的学习进度概览
    const progressData = await getMyLearningProgress()
    const progressMap = {}
    progressData.forEach(item => {
      progressMap[item.course_id] = item
    })
    
    // 遍历每个课程，获取任务列表
    const allTasks = []
    
    for (const course of courses) {
      try {
        const courseDetail = await getCourseDetail(course.uuid || course.id)
        const courseProgress = progressMap[course.id] || {}
        
        // 遍历单元，提取任务
        if (courseDetail.units) {
          for (const unit of courseDetail.units) {
            if (unit.tasks && unit.tasks.length > 0) {
              unit.tasks.forEach(task => {
                allTasks.push({
                  id: task.id,
                  uuid: task.uuid,
                  title: task.title,
                  projectName: courseDetail.title,
                  description: task.description,
                  status: task.status || 'pending', // 从后端获取的任务状态
                  progress: task.progress || 0,
                  estimatedTime: task.estimated_time || '未知',
                  difficulty: getDifficultyText(task.difficulty),
                  type: getTaskTypeText(task.type),
                  unitId: unit.uuid || unit.id,
                  unitUuid: unit.uuid,
                  isGroupTask: task.is_group_task || false,
                  submittedBy: task.submitted_by || null
                })
              })
            }
          }
        }
      } catch (error) {
        console.error(`获取课程${course.id}详情失败:`, error)
      }
    }
    
    tasks.value = allTasks
    loading.value = false
  } catch (error) {
    console.error('加载任务列表失败:', error)
    ElMessage.error('加载任务列表失败')
    loading.value = false
    
    // 如果API失败，显示空列表而不是硬编码数据
    tasks.value = []
  }
}

// 难度文本转换
const getDifficultyText = (difficulty) => {
  const map = {
    'easy': '简单',
    'medium': '中等',
    'hard': '困难'
  }
  return map[difficulty] || difficulty
}

// 任务类型文本转换
const getTaskTypeText = (type) => {
  const map = {
    'analysis': '分析',
    'coding': '编程',
    'design': '设计',
    'deployment': '部署'
  }
  return map[type] || type
}

// 页面加载时获取任务
onMounted(() => {
  loadTasks()
})

const uniqueProjects = computed(() => {
  return [...new Set(tasks.value.map(t => t.projectName))]
})

const filteredTasks = computed(() => {
  return tasks.value.filter(task => {
    const matchProject = !selectedProject.value || task.projectName === selectedProject.value
    const matchStatus = !selectedStatus.value || task.status === selectedStatus.value
    const matchType = !selectedType.value || task.type === selectedType.value
    const matchMode = !selectedMode.value || (selectedMode.value === 'group' ? task.isGroupTask : !task.isGroupTask)
    const matchSearch = !searchText.value || 
      task.title.toLowerCase().includes(searchText.value.toLowerCase()) ||
      task.description.toLowerCase().includes(searchText.value.toLowerCase())
    
    return matchProject && matchStatus && matchType && matchMode && matchSearch
  })
})

const getStatusText = (status) => {
  const statusMap = {
    'pending': '待开始',
    'in-progress': '进行中',
    'completed': '已完成'
  }
  return statusMap[status] || status
}

const getTaskTagType = (status) => {
  const typeMap = {
    'completed': 'success',
    'in-progress': 'warning',
    'pending': 'info'
  }
  return typeMap[status] || 'info'
}

const getProgressStatus = (status) => {
  return status === 'completed' ? 'success' : null
}

const goToTask = (taskId) => {
  router.push(`/tasks/${taskId}`)
}

const viewUnit = (unitIdOrUuid) => {
  router.push(`/unit/${unitIdOrUuid}`)
}
</script>

<style scoped>
.tasks-page {
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

.filters {
  display: flex;
  gap: 16px;
  margin-bottom: 32px;
  flex-wrap: wrap;
}

.tasks-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.task-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: transform 0.2s, box-shadow 0.2s;
}

.task-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
}

.task-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}

.task-title-section {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
  flex-wrap: wrap;
}

.task-project-badge {
  flex-shrink: 0;
}

.task-title-section h3 {
  font-size: 20px;
  font-weight: 600;
  color: #1e293b;
  margin: 0;
}

.mode-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.task-progress {
  width: 200px;
}

.task-description {
  color: #64748b;
  font-size: 14px;
  line-height: 1.6;
  margin: 0 0 16px 0;
}

.task-meta {
  display: flex;
  gap: 24px;
  margin-bottom: 16px;
  font-size: 14px;
  color: #64748b;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 4px;
}

.group-submission-info {
  margin-bottom: 16px;
}

.task-actions {
  display: flex;
  gap: 12px;
}
</style>
