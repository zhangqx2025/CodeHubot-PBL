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

    <div class="tasks-list">
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
            @click="viewUnit(task.unitId)"
          >
            查看单元
          </el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { Search, Clock, Star, Document, User, UserFilled } from '@element-plus/icons-vue'

const router = useRouter()

const selectedStatus = ref('')
const selectedType = ref('')
const selectedMode = ref('')
const selectedProject = ref('')
const searchText = ref('')

const tasks = ref([
  {
    id: 'task-1',
    title: '创建第一个智能体',
    projectName: '智能家居系统开发',
    description: '在平台上创建你的第一个AI智能体，熟悉基本操作流程',
    status: 'completed',
    progress: 100,
    estimatedTime: '30分钟',
    difficulty: '简单',
    type: '实践',
    unitId: 'unit-1',
    isGroupTask: false
  },
  {
    id: 'task-2',
    title: '优化提示词设计',
    projectName: '智能家居系统开发',
    description: '学习提示词工程，优化智能体的对话效果',
    status: 'completed',
    progress: 100,
    estimatedTime: '45分钟',
    difficulty: '中等',
    type: '分析',
    unitId: 'unit-2',
    isGroupTask: true,
    submittedBy: {
      name: '李明',
      time: '2023-12-06 14:30'
    }
  },
  {
    id: 'task-3',
    title: '构建知识库',
    projectName: '智能家居系统开发',
    description: '创建知识库并上传相关文档，实现RAG功能',
    status: 'in-progress', // 小组任务未完成状态
    progress: 45,
    estimatedTime: '60分钟',
    difficulty: '中等',
    type: '编程',
    unitId: 'unit-3',
    isGroupTask: true
  },
  {
    id: 'task-4',
    title: '环保主题调研',
    projectName: '校园环保卫士',
    description: '调研校园内的垃圾分类现状，收集数据并形成报告',
    status: 'pending',
    progress: 0,
    estimatedTime: '120分钟',
    difficulty: '简单',
    type: '调研',
    unitId: 'unit-env-1',
    isGroupTask: true
  }
])

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

const viewUnit = (unitId) => {
  router.push(`/unit/${unitId}`)
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
