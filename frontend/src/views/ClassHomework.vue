<template>
  <div class="class-homework-container">
    <!-- 返回按钮 -->
    <div class="page-header">
      <el-button @click="goBack" text>
        <el-icon><ArrowLeft /></el-icon>
        返回班级详情
      </el-button>
    </div>

    <!-- 页面标题和操作 -->
    <el-card shadow="never" class="header-card">
      <div class="header-content">
        <div class="header-left">
          <h1 class="page-title">作业管理</h1>
          <p class="page-subtitle">{{ className }}</p>
        </div>
        <div class="header-right">
          <el-button type="primary" size="large" @click="createHomework">
            <el-icon><Plus /></el-icon>
            创建作业
          </el-button>
        </div>
      </div>
    </el-card>

    <!-- 统计卡片 -->
    <div class="stats-grid">
      <el-card shadow="hover" class="stat-card">
        <el-statistic title="总作业数" :value="homeworkStats.total" />
      </el-card>
      <el-card shadow="hover" class="stat-card">
        <el-statistic title="进行中" :value="homeworkStats.ongoing" />
      </el-card>
      <el-card shadow="hover" class="stat-card">
        <el-statistic title="已截止" :value="homeworkStats.ended" />
      </el-card>
      <el-card shadow="hover" class="stat-card">
        <el-statistic title="待批改" :value="homeworkStats.toReview" />
      </el-card>
    </div>

    <!-- 筛选和搜索 -->
    <el-card shadow="never" class="filter-card">
      <div class="filter-content">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索作业（标题、描述）"
          style="width: 300px"
          size="large"
          clearable
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        
        <div class="filter-right">
          <el-select v-model="filterStatus" placeholder="状态筛选" style="width: 150px" size="large" clearable>
            <el-option label="全部" value="" />
            <el-option label="未发布" value="draft" />
            <el-option label="进行中" value="ongoing" />
            <el-option label="已截止" value="ended" />
          </el-select>
        </div>
      </div>
    </el-card>

    <!-- 作业列表 -->
    <el-card shadow="never" class="table-card">
      <el-table 
        :data="filteredHomework" 
        v-loading="loading" 
        stripe
        style="width: 100%"
      >
        <el-table-column prop="title" label="作业标题" width="250" fixed="left">
          <template #default="{ row }">
            <div class="homework-title">
              <span>{{ row.title }}</span>
              <el-tag v-if="row.is_required" type="danger" size="small" style="margin-left: 8px">
                必做
              </el-tag>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusTagType(row.status)">
              {{ getStatusName(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="unit_name" label="所属单元" width="180" />
        <el-table-column label="提交情况" width="150">
          <template #default="{ row }">
            <span>{{ row.submitted_count }} / {{ row.total_count }}</span>
            <el-progress 
              :percentage="getSubmissionRate(row)" 
              :stroke-width="6"
              style="margin-top: 4px"
            />
          </template>
        </el-table-column>
        <el-table-column label="待批改" width="100">
          <template #default="{ row }">
            <el-badge :value="row.to_review_count" :max="99" v-if="row.to_review_count > 0">
              <el-button size="small" text>{{ row.to_review_count }}</el-button>
            </el-badge>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="start_time" label="开始时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.start_time) }}
          </template>
        </el-table-column>
        <el-table-column prop="deadline" label="截止时间" width="180">
          <template #default="{ row }">
            <span :class="getDeadlineClass(row.deadline)">
              {{ formatDateTime(row.deadline) }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="viewHomework(row)">
              <el-icon><View /></el-icon>
              查看
            </el-button>
            <el-button link type="primary" @click="editHomework(row)" v-if="row.status === 'draft'">
              <el-icon><Edit /></el-icon>
              编辑
            </el-button>
            <el-button link type="danger" @click="deleteHomework(row)" v-if="row.status === 'draft'">
              <el-icon><Delete /></el-icon>
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-empty 
        v-if="!loading && homeworkList.length === 0" 
        description="暂无作业"
        style="padding: 60px 0"
      >
        <el-button type="primary" @click="createHomework">创建第一个作业</el-button>
      </el-empty>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  ArrowLeft, Plus, Search, View, Edit, Delete
} from '@element-plus/icons-vue'
import { getClubClassDetail } from '@/api/club'
import dayjs from 'dayjs'
import request from '@/api/request'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const homeworkList = ref([])
const className = ref('')
const searchKeyword = ref('')
const filterStatus = ref('')
const homeworkStats = ref({
  total: 0,
  ongoing: 0,
  ended: 0,
  toReview: 0
})

// 计算属性
const filteredHomework = computed(() => {
  let result = homeworkList.value
  
  // 搜索过滤
  if (searchKeyword.value) {
    const keyword = searchKeyword.value.toLowerCase()
    result = result.filter(item => 
      item.title.toLowerCase().includes(keyword) || 
      (item.description && item.description.toLowerCase().includes(keyword))
    )
  }
  
  // 状态过滤
  if (filterStatus.value) {
    result = result.filter(item => item.status === filterStatus.value)
  }
  
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

// 加载作业列表
const loadHomework = async () => {
  loading.value = true
  try {
    const res = await request({
      url: `/admin/club/classes/${route.params.uuid}/homework`,
      method: 'get'
    })
    homeworkList.value = res.data.data || []
    
    // 计算统计数据
    homeworkStats.value = {
      total: homeworkList.value.length,
      ongoing: homeworkList.value.filter(item => item.status === 'ongoing').length,
      ended: homeworkList.value.filter(item => item.status === 'ended').length,
      toReview: homeworkList.value.reduce((sum, item) => sum + (item.to_review_count || 0), 0)
    }
  } catch (error) {
    ElMessage.error(error.message || '加载作业列表失败')
  } finally {
    loading.value = false
  }
}

// 创建作业
const createHomework = () => {
  ElMessage.info('创建作业功能开发中')
}

// 查看作业详情
const viewHomework = (homework) => {
  ElMessage.info(`查看作业"${homework.title}"的详情（功能开发中）`)
}

// 编辑作业
const editHomework = (homework) => {
  ElMessage.info(`编辑作业"${homework.title}"（功能开发中）`)
}

// 删除作业
const deleteHomework = async (homework) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除作业"${homework.title}"吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await request({
      url: `/admin/club/homework/${homework.id}`,
      method: 'delete'
    })
    ElMessage.success('作业已删除')
    loadHomework()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '删除失败')
    }
  }
}

// 工具方法
const getSubmissionRate = (homework) => {
  if (homework.total_count === 0) return 0
  return Math.round((homework.submitted_count / homework.total_count) * 100)
}

const getStatusName = (status) => {
  const map = {
    draft: '未发布',
    ongoing: '进行中',
    ended: '已截止'
  }
  return map[status] || status
}

const getStatusTagType = (status) => {
  const map = {
    draft: 'info',
    ongoing: 'success',
    ended: 'danger'
  }
  return map[status] || 'info'
}

const getDeadlineClass = (deadline) => {
  if (!deadline) return ''
  const now = dayjs()
  const deadlineDate = dayjs(deadline)
  const diffDays = deadlineDate.diff(now, 'day')
  
  if (diffDays < 0) return 'deadline-passed'
  if (diffDays <= 1) return 'deadline-soon'
  return ''
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
  loadHomework()
})
</script>

<style scoped lang="scss">
.class-homework-container {
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

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 24px;
  margin-bottom: 24px;
  
  .stat-card {
    border-radius: 12px;
    
    :deep(.el-statistic) {
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

.homework-title {
  display: flex;
  align-items: center;
}

.deadline-soon {
  color: #e6a23c;
  font-weight: 600;
}

.deadline-passed {
  color: #f56c6c;
  font-weight: 600;
}
</style>
