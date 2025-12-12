<template>
  <div class="class-progress-container">
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
          <h1 class="page-title">学习进度</h1>
          <p class="page-subtitle">{{ className }}</p>
        </div>
        <div class="header-right">
          <el-button type="primary" size="large" @click="exportProgress">
            <el-icon><Download /></el-icon>
            导出报表
          </el-button>
        </div>
      </div>
    </el-card>

    <!-- 整体进度统计 -->
    <el-card shadow="never" class="stats-card">
      <template #header>
        <div class="card-header">
          <span>整体进度统计</span>
        </div>
      </template>
      <div class="stats-grid">
        <div class="stat-item">
          <el-statistic title="平均完成率" :value="overallStats.avgCompletionRate" suffix="%" />
          <el-progress 
            :percentage="overallStats.avgCompletionRate" 
            :color="getProgressColor(overallStats.avgCompletionRate)"
            :stroke-width="8"
          />
        </div>
        <div class="stat-item">
          <el-statistic title="已完成学员" :value="overallStats.completedCount" />
          <div class="stat-detail">
            共 {{ overallStats.totalCount }} 人
          </div>
        </div>
        <div class="stat-item">
          <el-statistic title="平均学习时长" :value="overallStats.avgLearningHours" suffix="小时" />
        </div>
        <div class="stat-item">
          <el-statistic title="总提交作业数" :value="overallStats.totalSubmissions" />
        </div>
      </div>
    </el-card>

    <!-- 筛选和搜索 -->
    <el-card shadow="never" class="filter-card">
      <div class="filter-content">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索学员（姓名、学号）"
          style="width: 300px"
          size="large"
          clearable
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        
        <div class="filter-right">
          <el-select v-model="filterStatus" placeholder="进度筛选" style="width: 150px" size="large" clearable>
            <el-option label="全部" value="" />
            <el-option label="未开始" value="not_started" />
            <el-option label="进行中" value="in_progress" />
            <el-option label="已完成" value="completed" />
          </el-select>
          
          <el-select v-model="sortBy" placeholder="排序方式" style="width: 150px" size="large">
            <el-option label="按姓名" value="name" />
            <el-option label="按完成率" value="rate" />
            <el-option label="按学习时长" value="time" />
          </el-select>
        </div>
      </div>
    </el-card>

    <!-- 学员进度列表 -->
    <el-card shadow="never" class="table-card">
      <el-table 
        :data="filteredProgress" 
        v-loading="loading" 
        stripe
        style="width: 100%"
      >
        <el-table-column prop="name" label="姓名" width="150" fixed="left" />
        <el-table-column prop="student_number" label="学号" width="150" />
        <el-table-column label="完成率" width="200">
          <template #default="{ row }">
            <div class="progress-cell">
              <el-progress 
                :percentage="row.completion_rate" 
                :color="getProgressColor(row.completion_rate)"
              />
              <span class="progress-text">{{ row.completion_rate }}%</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="120">
          <template #default="{ row }">
            <el-tag :type="getStatusTagType(row.status)">
              {{ getStatusName(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="completed_units" label="已完成单元" width="120" />
        <el-table-column prop="total_units" label="总单元数" width="120" />
        <el-table-column prop="learning_hours" label="学习时长" width="120">
          <template #default="{ row }">
            {{ row.learning_hours }} 小时
          </template>
        </el-table-column>
        <el-table-column prop="submissions_count" label="提交作业数" width="120" />
        <el-table-column prop="last_active" label="最后活跃" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.last_active) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="viewStudentDetail(row)">
              <el-icon><View /></el-icon>
              查看详情
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-empty 
        v-if="!loading && progressList.length === 0" 
        description="暂无学习进度数据"
        style="padding: 60px 0"
      />
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  ArrowLeft, Download, Search, View
} from '@element-plus/icons-vue'
import { getClubClassDetail } from '@/api/club'
import dayjs from 'dayjs'
import request from '@/api/request'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const progressList = ref([])
const className = ref('')
const searchKeyword = ref('')
const filterStatus = ref('')
const sortBy = ref('name')
const overallStats = ref({
  avgCompletionRate: 0,
  completedCount: 0,
  totalCount: 0,
  avgLearningHours: 0,
  totalSubmissions: 0
})

// 计算属性
const filteredProgress = computed(() => {
  let result = progressList.value
  
  // 搜索过滤
  if (searchKeyword.value) {
    const keyword = searchKeyword.value.toLowerCase()
    result = result.filter(item => 
      item.name.toLowerCase().includes(keyword) || 
      item.student_number.includes(keyword)
    )
  }
  
  // 状态过滤
  if (filterStatus.value) {
    result = result.filter(item => item.status === filterStatus.value)
  }
  
  // 排序
  result = [...result].sort((a, b) => {
    switch (sortBy.value) {
      case 'name':
        return a.name.localeCompare(b.name)
      case 'rate':
        return b.completion_rate - a.completion_rate
      case 'time':
        return b.learning_hours - a.learning_hours
      default:
        return 0
    }
  })
  
  return result
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

// 加载学习进度
const loadProgress = async () => {
  loading.value = true
  try {
    const res = await request({
      url: `/admin/club/classes/${route.params.uuid}/progress`,
      method: 'get'
    })
    progressList.value = res.data.data || []
    
    // 计算整体统计
    if (progressList.value.length > 0) {
      overallStats.value = {
        avgCompletionRate: Math.round(
          progressList.value.reduce((sum, item) => sum + item.completion_rate, 0) / progressList.value.length
        ),
        completedCount: progressList.value.filter(item => item.status === 'completed').length,
        totalCount: progressList.value.length,
        avgLearningHours: Math.round(
          progressList.value.reduce((sum, item) => sum + item.learning_hours, 0) / progressList.value.length
        ),
        totalSubmissions: progressList.value.reduce((sum, item) => sum + item.submissions_count, 0)
      }
    }
  } catch (error) {
    ElMessage.error(error.message || '加载学习进度失败')
  } finally {
    loading.value = false
  }
}

// 导出进度报表
const exportProgress = async () => {
  try {
    ElMessage.success('导出功能开发中')
  } catch (error) {
    ElMessage.error(error.message || '导出失败')
  }
}

// 查看学员详情
const viewStudentDetail = (student) => {
  ElMessage.info(`查看学员 ${student.name} 的详细学习记录（功能开发中）`)
}

// 工具方法
const getProgressColor = (rate) => {
  if (rate >= 80) return '#67c23a'
  if (rate >= 60) return '#e6a23c'
  if (rate >= 40) return '#f56c6c'
  return '#909399'
}

const getStatusName = (status) => {
  const map = {
    not_started: '未开始',
    in_progress: '进行中',
    completed: '已完成'
  }
  return map[status] || status
}

const getStatusTagType = (status) => {
  const map = {
    not_started: 'info',
    in_progress: 'warning',
    completed: 'success'
  }
  return map[status] || 'info'
}

const formatDateTime = (dateStr) => {
  if (!dateStr) return '-'
  return dayjs(dateStr).format('YYYY-MM-DD HH:mm')
}

const goBack = () => {
  router.push(`/admin/classes/${route.params.uuid}`)
}

onMounted(() => {
  loadClassName()
  loadProgress()
})
</script>

<style scoped lang="scss">
.class-progress-container {
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

.stats-card {
  margin-bottom: 24px;
  border-radius: 12px;
  
  .card-header {
    font-size: 16px;
    font-weight: 600;
  }
  
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 24px;
    
    .stat-item {
      :deep(.el-statistic) {
        margin-bottom: 12px;
        
        .el-statistic__head {
          font-size: 14px;
          color: #909399;
          margin-bottom: 8px;
        }
        
        .el-statistic__content {
          font-size: 28px;
          font-weight: 600;
          color: #303133;
        }
      }
      
      .stat-detail {
        margin-top: 8px;
        font-size: 14px;
        color: #909399;
      }
    }
  }
}

.filter-card {
  margin-bottom: 24px;
  border-radius: 12px;
  
  .filter-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
    
    .filter-right {
      display: flex;
      gap: 12px;
    }
  }
}

.table-card {
  border-radius: 12px;
}

.progress-cell {
  display: flex;
  align-items: center;
  gap: 12px;
  
  .el-progress {
    flex: 1;
  }
  
  .progress-text {
    font-size: 14px;
    font-weight: 600;
    color: #303133;
    min-width: 45px;
  }
}
</style>
