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

    <!-- 视图切换和筛选 -->
    <el-card shadow="never" class="filter-card">
      <div class="filter-content">
        <div class="filter-left">
          <el-radio-group v-model="viewMode" size="large" @change="handleViewModeChange">
            <el-radio-button value="student">按学员查看</el-radio-button>
            <el-radio-button value="unit">按单元查看</el-radio-button>
          </el-radio-group>
          
          <el-select 
            v-if="viewMode === 'unit'" 
            v-model="selectedUnitId" 
            placeholder="选择学习单元" 
            style="width: 250px; margin-left: 16px" 
            size="large"
            @change="loadUnitDetail"
          >
            <el-option 
              v-for="unit in unitList" 
              :key="unit.id" 
              :label="`${unit.title} (${unit.completed_count}/${unit.total_students}人完成)`" 
              :value="unit.id" 
            />
          </el-select>
        </div>
        
        <div class="filter-right">
          <el-input
            v-model="searchKeyword"
            placeholder="搜索学员（姓名、学号）"
            style="width: 250px"
            size="large"
            clearable
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
          
          <el-select 
            v-if="viewMode === 'student'"
            v-model="filterStatus" 
            placeholder="进度筛选" 
            style="width: 150px" 
            size="large" 
            clearable
          >
            <el-option label="全部" value="" />
            <el-option label="未开始" value="not_started" />
            <el-option label="进行中" value="in_progress" />
            <el-option label="已完成" value="completed" />
          </el-select>
          
          <el-select v-model="sortBy" placeholder="排序方式" style="width: 150px" size="large">
            <el-option label="按姓名" value="name" />
            <el-option label="按完成率" value="rate" />
            <el-option v-if="viewMode === 'student'" label="按学习时长" value="time" />
          </el-select>
        </div>
      </div>
    </el-card>

    <!-- 按学员查看 -->
    <el-card v-if="viewMode === 'student'" shadow="never" class="table-card">
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

    <!-- 按单元查看 -->
    <el-card v-if="viewMode === 'unit'" shadow="never" class="table-card">
      <!-- 单元概览 -->
      <div v-if="!selectedUnitId" class="units-grid">
        <div 
          v-for="unit in unitList" 
          :key="unit.id" 
          class="unit-card"
          @click="selectUnit(unit.id)"
        >
          <div class="unit-header">
            <h3>{{ unit.title }}</h3>
            <el-tag>{{ unit.task_count }} 个任务</el-tag>
          </div>
          <div class="unit-description">
            {{ unit.description || '暂无描述' }}
          </div>
          <div class="unit-stats">
            <div class="stat-item">
              <span class="label">完成人数</span>
              <span class="value">{{ unit.completed_count }}/{{ unit.total_students }}</span>
            </div>
            <div class="stat-item">
              <span class="label">完成率</span>
              <el-progress 
                :percentage="unit.completion_rate" 
                :color="getProgressColor(unit.completion_rate)"
                :stroke-width="8"
              />
            </div>
          </div>
        </div>
        <el-empty 
          v-if="unitList.length === 0" 
          description="暂无学习单元"
          style="padding: 60px 0; grid-column: 1 / -1;"
        />
      </div>

      <!-- 单元详情 -->
      <div v-if="selectedUnitId && unitDetail">
        <div class="unit-detail-header">
          <div class="unit-info">
            <h2>{{ unitDetail.unit.title }}</h2>
            <p>{{ unitDetail.unit.description || '暂无描述' }}</p>
            <div class="task-tags">
              <el-tag 
                v-for="task in unitDetail.tasks" 
                :key="task.id" 
                :type="task.is_required ? 'danger' : ''"
                style="margin-right: 8px"
              >
                {{ task.title }}
                <span v-if="task.is_required">(必做)</span>
              </el-tag>
            </div>
          </div>
        </div>

        <el-table 
          :data="filteredUnitProgress" 
          v-loading="loadingUnitDetail" 
          stripe
          style="width: 100%; margin-top: 24px"
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
          <el-table-column prop="completed_tasks" label="已完成任务" width="120">
            <template #default="{ row }">
              {{ row.completed_tasks }}/{{ row.total_tasks }}
            </template>
          </el-table-column>
          <el-table-column prop="avg_score" label="平均分" width="120">
            <template #default="{ row }">
              {{ row.avg_score !== null ? row.avg_score : '-' }}
            </template>
          </el-table-column>
          <el-table-column label="任务完成情况" min-width="400">
            <template #default="{ row }">
              <div class="task-progress-tags">
                <el-tooltip 
                  v-for="taskProgress in row.task_progress" 
                  :key="taskProgress.task_id"
                  :content="`${taskProgress.task_title}: ${getTaskStatusName(taskProgress.status)}${taskProgress.score !== null ? ' - ' + taskProgress.score + '分' : ''}`"
                  placement="top"
                >
                  <el-tag 
                    :type="getTaskProgressTagType(taskProgress.status)"
                    size="small"
                    style="margin-right: 4px; margin-bottom: 4px"
                  >
                    {{ taskProgress.task_title.substring(0, 10) }}{{ taskProgress.task_title.length > 10 ? '...' : '' }}
                  </el-tag>
                </el-tooltip>
              </div>
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
          v-if="!loadingUnitDetail && (!unitDetail.students || unitDetail.students.length === 0)" 
          description="暂无学生数据"
          style="padding: 60px 0"
        />
      </div>
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
const loadingUnitDetail = ref(false)
const progressList = ref([])
const className = ref('')
const searchKeyword = ref('')
const filterStatus = ref('')
const sortBy = ref('name')
const viewMode = ref('student') // student: 按学员, unit: 按单元
const unitList = ref([])
const studentUnitProgress = ref([])
const selectedUnitId = ref(null)
const unitDetail = ref(null)
const overallStats = ref({
  avgCompletionRate: 0,
  completedCount: 0,
  totalCount: 0,
  avgLearningHours: 0,
  totalSubmissions: 0
})

// 计算属性 - 按学员查看的过滤列表
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

// 计算属性 - 按单元查看的过滤列表
const filteredUnitProgress = computed(() => {
  if (!unitDetail.value || !unitDetail.value.students) {
    return []
  }
  
  let result = unitDetail.value.students
  
  // 搜索过滤
  if (searchKeyword.value) {
    const keyword = searchKeyword.value.toLowerCase()
    result = result.filter(item => 
      item.name.toLowerCase().includes(keyword) || 
      item.student_number.includes(keyword)
    )
  }
  
  // 排序
  result = [...result].sort((a, b) => {
    switch (sortBy.value) {
      case 'name':
        return a.name.localeCompare(b.name)
      case 'rate':
        return b.completion_rate - a.completion_rate
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

// 加载学习进度（按学员）
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

// 加载单元进度（按单元）
const loadUnitProgress = async () => {
  loading.value = true
  try {
    const res = await request({
      url: `/admin/club/classes/${route.params.uuid}/progress/units`,
      method: 'get'
    })
    unitList.value = res.data.data.units || []
    studentUnitProgress.value = res.data.data.students || []
    
    // 计算整体统计（基于单元数据）
    if (studentUnitProgress.value.length > 0 && unitList.value.length > 0) {
      let totalCompletionRate = 0
      let completedCount = 0
      
      studentUnitProgress.value.forEach(student => {
        const unitProgress = student.unit_progress || []
        const completedUnits = unitProgress.filter(up => up.is_completed).length
        const totalUnits = unitProgress.length
        
        if (totalUnits > 0) {
          const rate = (completedUnits / totalUnits) * 100
          totalCompletionRate += rate
          
          if (rate === 100) {
            completedCount++
          }
        }
      })
      
      overallStats.value = {
        avgCompletionRate: Math.round(totalCompletionRate / studentUnitProgress.value.length),
        completedCount: completedCount,
        totalCount: studentUnitProgress.value.length,
        avgLearningHours: 0,  // 按单元查看时不显示学习时长
        totalSubmissions: 0   // 按单元查看时不显示提交数
      }
    }
  } catch (error) {
    ElMessage.error(error.message || '加载单元进度失败')
  } finally {
    loading.value = false
  }
}

// 加载单元详情
const loadUnitDetail = async () => {
  if (!selectedUnitId.value) return
  
  loadingUnitDetail.value = true
  try {
    const res = await request({
      url: `/admin/club/classes/${route.params.uuid}/progress/units/${selectedUnitId.value}`,
      method: 'get'
    })
    unitDetail.value = res.data.data
  } catch (error) {
    ElMessage.error(error.message || '加载单元详情失败')
  } finally {
    loadingUnitDetail.value = false
  }
}

// 选择单元
const selectUnit = (unitId) => {
  selectedUnitId.value = unitId
  loadUnitDetail()
}

// 切换视图模式
const handleViewModeChange = () => {
  selectedUnitId.value = null
  unitDetail.value = null
  searchKeyword.value = ''
  filterStatus.value = ''
  sortBy.value = 'name'
  
  if (viewMode.value === 'student') {
    loadProgress()
  } else {
    loadUnitProgress()
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

const getTaskStatusName = (status) => {
  const map = {
    not_started: '未开始',
    in_progress: '进行中',
    review: '待批改',
    completed: '已完成'
  }
  return map[status] || status
}

const getTaskProgressTagType = (status) => {
  const map = {
    not_started: 'info',
    in_progress: 'warning',
    review: '',
    completed: 'success'
  }
  return map[status] || 'info'
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
    
    .filter-left {
      display: flex;
      align-items: center;
    }
    
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

// 单元视图样式
.units-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 20px;
  padding: 20px 0;
}

.unit-card {
  border: 1px solid #e4e7ed;
  border-radius: 12px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:hover {
    border-color: #409eff;
    box-shadow: 0 2px 12px 0 rgba(64, 158, 255, 0.2);
    transform: translateY(-2px);
  }
  
  .unit-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 12px;
    
    h3 {
      margin: 0;
      font-size: 18px;
      font-weight: 600;
      color: #303133;
      flex: 1;
      margin-right: 12px;
    }
  }
  
  .unit-description {
    font-size: 14px;
    color: #606266;
    margin-bottom: 16px;
    line-height: 1.6;
    min-height: 44px;
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
  }
  
  .unit-stats {
    display: flex;
    gap: 24px;
    
    .stat-item {
      flex: 1;
      
      .label {
        display: block;
        font-size: 12px;
        color: #909399;
        margin-bottom: 8px;
      }
      
      .value {
        display: block;
        font-size: 16px;
        font-weight: 600;
        color: #303133;
      }
    }
  }
}

.unit-detail-header {
  padding: 24px;
  background: #f5f7fa;
  border-radius: 12px;
  margin-bottom: 24px;
  
  .unit-info {
    h2 {
      margin: 0 0 12px 0;
      font-size: 22px;
      font-weight: 600;
      color: #303133;
    }
    
    p {
      margin: 0 0 16px 0;
      font-size: 14px;
      color: #606266;
      line-height: 1.6;
    }
  }
  
  .task-tags {
    margin-top: 16px;
  }
}

.task-progress-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}
</style>
