<template>
  <div class="unit-homework-container">
    <!-- 返回按钮 -->
    <div class="page-header">
      <el-button @click="goBack" text>
        <el-icon><ArrowLeft /></el-icon>
        返回作业管理
      </el-button>
    </div>

    <!-- 页面标题 -->
    <el-card shadow="never" class="header-card">
      <div class="header-content">
        <div class="header-left">
          <h1 class="page-title">{{ unitDetail?.unit.title }}</h1>
          <p class="page-subtitle">{{ className }} - 单元作业详情</p>
        </div>
        <div class="header-stats">
          <div class="stat-item">
            <div class="stat-label">作业数量</div>
            <div class="stat-value">{{ unitDetail?.tasks.length || 0 }}</div>
          </div>
          <div class="stat-item">
            <div class="stat-label">学生人数</div>
            <div class="stat-value">{{ unitDetail?.total_students || 0 }}</div>
          </div>
          <div class="stat-item">
            <div class="stat-label">总体进度</div>
            <div class="stat-value">{{ overallProgress }}%</div>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 单元信息 -->
    <el-card shadow="never" class="info-card">
      <template #header>
        <div class="card-header">
          <el-icon><InfoFilled /></el-icon>
          <span>单元信息</span>
        </div>
      </template>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="单元顺序">
          <el-tag type="info">第 {{ unitDetail?.unit.order }} 单元</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="作业数量">
          {{ unitDetail?.tasks.length || 0 }} 个
        </el-descriptions-item>
        <el-descriptions-item label="学生人数">
          {{ unitDetail?.total_students || 0 }} 人
        </el-descriptions-item>
        <el-descriptions-item label="完成情况">
          <span>{{ completedTasks }} / {{ totalTasks }} 已完成</span>
        </el-descriptions-item>
        <el-descriptions-item label="描述" :span="2">
          {{ unitDetail?.unit.description || '暂无描述' }}
        </el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- 作业列表 -->
    <el-card shadow="never" class="tasks-card">
      <template #header>
        <div class="card-header">
          <div>
            <el-icon><Document /></el-icon>
            <span>作业列表</span>
          </div>
        </div>
      </template>
      
      <div v-loading="loadingDetail">
        <el-table 
          :data="unitDetail?.tasks || []" 
          border
          stripe
          style="width: 100%"
        >
          <el-table-column prop="title" label="作业标题" min-width="300">
            <template #default="{ row }">
              <div class="task-title-cell">
                <span class="task-title-text">{{ row.title }}</span>
                <el-tag v-if="row.to_review_count > 0" type="danger" size="small" class="pending-badge">
                  待批改 {{ row.to_review_count }}
                </el-tag>
              </div>
            </template>
          </el-table-column>
          <el-table-column label="提交情况" width="250">
            <template #default="{ row }">
              <div class="submission-info">
                <div class="submission-text">
                  <span class="submitted">{{ row.submitted_count }}</span>
                  <span class="divider">/</span>
                  <span class="total">{{ row.total_count }}</span>
                  <span class="label">人提交</span>
                  <span class="percentage">({{ getSubmissionRate(row) }}%)</span>
                </div>
                <el-progress 
                  :percentage="getSubmissionRate(row)" 
                  :stroke-width="8"
                  :color="getProgressColor(getSubmissionRate(row))"
                  style="margin-top: 4px"
                />
              </div>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="140" align="center">
            <template #default="{ row }">
              <el-button type="primary" @click="gradeHomework(row)" size="default">
                <el-icon><Edit /></el-icon>
                批改作业
              </el-button>
            </template>
          </el-table-column>
        </el-table>

        <el-empty 
          v-if="!loadingDetail && (!unitDetail?.tasks || unitDetail.tasks.length === 0)" 
          description="该单元暂无作业"
          :image-size="120"
          style="padding: 80px 0"
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
  ArrowLeft, Edit, InfoFilled, Document
} from '@element-plus/icons-vue'
import { getClubClassDetail } from '@/api/club'
import request from '@/api/request'

const route = useRoute()
const router = useRouter()

const loadingDetail = ref(false)
const className = ref('')
const unitDetail = ref(null)

// 计算属性 - 总体进度
const overallProgress = computed(() => {
  if (!unitDetail.value?.tasks || unitDetail.value.tasks.length === 0) return 0
  const total = unitDetail.value.tasks.reduce((sum, task) => sum + task.total_count, 0)
  const submitted = unitDetail.value.tasks.reduce((sum, task) => sum + task.submitted_count, 0)
  return total > 0 ? Math.round((submitted / total) * 100) : 0
})

// 计算属性 - 完成的任务数
const completedTasks = computed(() => {
  if (!unitDetail.value?.tasks) return 0
  return unitDetail.value.tasks.filter(task => task.submitted_count === task.total_count).length
})

// 计算属性 - 总任务数
const totalTasks = computed(() => {
  return unitDetail.value?.tasks?.length || 0
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

// 加载单元详情
const loadUnitDetail = async () => {
  loadingDetail.value = true
  try {
    const res = await request({
      url: `/admin/club/classes/${route.params.uuid}/homework/units/${route.params.unitId}`,
      method: 'get'
    })
    unitDetail.value = res.data.data
  } catch (error) {
    ElMessage.error(error.message || '加载单元详情失败')
  } finally {
    loadingDetail.value = false
  }
}

// 批改作业 - 跳转到批改页面
const gradeHomework = (task) => {
  router.push(`/admin/classes/${route.params.uuid}/homework/units/${route.params.unitId}/tasks/${task.id}/grading`)
}

// 工具方法
const getSubmissionRate = (task) => {
  if (task.total_count === 0) return 0
  return Math.round((task.submitted_count / task.total_count) * 100)
}

const getProgressColor = (percentage) => {
  if (percentage >= 80) return '#67c23a'
  if (percentage >= 50) return '#e6a23c'
  return '#f56c6c'
}

const goBack = () => {
  router.push(`/admin/classes/${route.params.uuid}/homework`)
}

onMounted(async () => {
  await Promise.all([
    loadClassName(),
    loadUnitDetail()
  ])
})
</script>

<style scoped lang="scss">
.unit-homework-container {
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
        }
      }
    }
  }
}

.info-card, .tasks-card {
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
      gap: 12px;
    }
  }
}

.task-title-cell {
  display: flex;
  align-items: center;
  gap: 8px;
  
  .task-title-text {
    flex: 1;
    font-weight: 500;
  }
  
  .pending-badge {
    flex-shrink: 0;
  }
}

.submission-info {
  .submission-text {
    display: flex;
    align-items: center;
    gap: 4px;
    margin-bottom: 6px;
    
    .submitted {
      font-size: 16px;
      font-weight: 600;
      color: #409eff;
    }
    
    .divider {
      color: #dcdfe6;
    }
    
    .total {
      font-size: 14px;
      color: #909399;
    }
    
    .label {
      font-size: 12px;
      color: #909399;
      margin-left: 4px;
    }
    
    .percentage {
      font-size: 12px;
      color: #606266;
      margin-left: 4px;
    }
  }
}

</style>


