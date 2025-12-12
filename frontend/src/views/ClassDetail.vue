<template>
  <div class="class-detail-container">
    <!-- 返回按钮 -->
    <div class="page-header">
      <el-button @click="goBack" text>
        <el-icon><ArrowLeft /></el-icon>
        返回班级列表
      </el-button>
    </div>

    <!-- 加载中 -->
    <div v-if="loading" class="loading-container">
      <el-skeleton :rows="8" animated />
    </div>

    <!-- 班级详情 -->
    <div v-else-if="classInfo" class="detail-content">
      <!-- 班级头部卡片 -->
      <el-card class="header-card" shadow="never">
        <div class="header-content" :class="`type-${classInfo.class_type}`">
          <div class="header-left">
            <el-tag :type="getClassTypeTagType(classInfo.class_type)" size="large" effect="dark">
              {{ getClassTypeName(classInfo.class_type) }}
            </el-tag>
            <h1 class="class-name">{{ classInfo.name }}</h1>
            <p class="class-description">{{ classInfo.description || '暂无描述' }}</p>
          </div>
          <div class="header-right">
            <el-button type="primary" size="large" @click="editClass">
              <el-icon><Edit /></el-icon>
              编辑信息
            </el-button>
          </div>
        </div>
      </el-card>

      <!-- 统计卡片 -->
      <div class="stats-grid">
        <el-card shadow="hover" class="stat-card">
          <el-statistic title="成员人数" :value="classInfo.current_members">
            <template #suffix>
              / {{ classInfo.max_students }}
            </template>
          </el-statistic>
          <el-progress 
            :percentage="getClassFullnessPercentage(classInfo)" 
            :color="getProgressColor(getClassFullnessPercentage(classInfo))"
            :stroke-width="8"
            style="margin-top: 16px"
          />
        </el-card>

        <el-card shadow="hover" class="stat-card">
          <el-statistic title="课程数量" :value="classInfo.course_count" />
          <el-button type="primary" link style="margin-top: 16px" @click="viewCourses">
            查看课程 <el-icon><ArrowRight /></el-icon>
          </el-button>
        </el-card>

        <el-card shadow="hover" class="stat-card">
          <el-statistic title="小组数量" :value="groupCount" />
          <el-button type="primary" link style="margin-top: 16px" @click="viewGroups">
            查看小组 <el-icon><ArrowRight /></el-icon>
          </el-button>
        </el-card>

        <el-card shadow="hover" class="stat-card">
          <div class="stat-status">
            <span class="stat-label">班级状态</span>
            <el-tag 
              :type="classInfo.is_open ? 'success' : 'info'" 
              size="large"
              effect="plain"
            >
              {{ classInfo.is_open ? '开放加入' : '关闭加入' }}
            </el-tag>
          </div>
          <div class="stat-time">
            <el-icon><Clock /></el-icon>
            创建于 {{ formatDate(classInfo.created_at) }}
          </div>
        </el-card>
      </div>

      <!-- 快捷操作 -->
      <el-card shadow="never" class="actions-card">
        <template #header>
          <div class="card-header">
            <span>快捷操作</span>
          </div>
        </template>
        <div class="actions-grid">
          <el-button size="large" @click="viewMembers">
            <el-icon><UserFilled /></el-icon>
            成员管理
          </el-button>
          <el-button size="large" @click="viewCourses">
            <el-icon><Reading /></el-icon>
            课程管理
          </el-button>
          <el-button size="large" @click="viewGroups">
            <el-icon><Grid /></el-icon>
            小组管理
          </el-button>
          <el-button size="large" @click="createCourse">
            <el-icon><Plus /></el-icon>
            创建课程
          </el-button>
        </div>
      </el-card>

      <!-- 基本信息 -->
      <el-card shadow="never" class="info-card">
        <template #header>
          <div class="card-header">
            <span>基本信息</span>
          </div>
        </template>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="班级名称">{{ classInfo.name }}</el-descriptions-item>
          <el-descriptions-item label="班级类型">
            <el-tag :type="getClassTypeTagType(classInfo.class_type)">
              {{ getClassTypeName(classInfo.class_type) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="最大人数">{{ classInfo.max_students }}</el-descriptions-item>
          <el-descriptions-item label="当前人数">{{ classInfo.current_members }}</el-descriptions-item>
          <el-descriptions-item label="课程数量">{{ classInfo.course_count }}</el-descriptions-item>
          <el-descriptions-item label="班级状态">
            <el-tag :type="classInfo.is_open ? 'success' : 'info'">
              {{ classInfo.is_open ? '开放加入' : '关闭加入' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ formatDateTime(classInfo.created_at) }}</el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ formatDateTime(classInfo.updated_at) }}</el-descriptions-item>
          <el-descriptions-item label="班级描述" :span="2">
            {{ classInfo.description || '暂无描述' }}
          </el-descriptions-item>
        </el-descriptions>
      </el-card>
    </div>

    <!-- 错误提示 -->
    <el-empty v-else description="加载失败" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  ArrowLeft, ArrowRight, Edit, UserFilled, Reading, Grid, Plus, Clock
} from '@element-plus/icons-vue'
import { getClubClassDetail, getGroups } from '@/api/club'
import dayjs from 'dayjs'

const route = useRoute()
const router = useRouter()

const loading = ref(true)
const classInfo = ref(null)
const groupCount = ref(0)

// 加载班级详情
const loadClassDetail = async () => {
  loading.value = true
  try {
    const uuid = route.params.uuid
    const res = await getClubClassDetail(uuid)
    classInfo.value = res.data.data
    
    // 加载小组数量
    const groupRes = await getGroups({ class_id: classInfo.value.id })
    groupCount.value = groupRes.data.data?.length || 0
  } catch (error) {
    ElMessage.error(error.message || '加载班级详情失败')
  } finally {
    loading.value = false
  }
}

// 工具方法
const getClassTypeName = (type) => {
  const map = {
    club: '社团班',
    project: '项目班',
    interest: '兴趣班',
    competition: '竞赛班',
    regular: '普通班'
  }
  return map[type] || type
}

const getClassTypeTagType = (type) => {
  const map = {
    club: 'primary',
    project: 'success',
    interest: 'warning',
    competition: 'danger',
    regular: 'info'
  }
  return map[type] || 'info'
}

const getClassFullnessPercentage = (cls) => {
  if (cls.max_students === 0) return 0
  return Math.round((cls.current_members / cls.max_students) * 100)
}

const getProgressColor = (percentage) => {
  if (percentage < 50) return '#67c23a'
  if (percentage < 80) return '#e6a23c'
  return '#f56c6c'
}

const formatDate = (dateStr) => {
  if (!dateStr) return '-'
  return dayjs(dateStr).format('YYYY-MM-DD')
}

const formatDateTime = (dateStr) => {
  if (!dateStr) return '-'
  return dayjs(dateStr).format('YYYY-MM-DD HH:mm:ss')
}

// 操作方法
const goBack = () => {
  router.push('/admin/classes')
}

const editClass = () => {
  router.push(`/admin/classes/${route.params.uuid}/edit`)
}

const viewMembers = () => {
  router.push(`/admin/classes/${route.params.uuid}/members`)
}

const viewCourses = () => {
  router.push(`/admin/classes/${route.params.uuid}/courses`)
}

const viewGroups = () => {
  router.push(`/admin/classes/${route.params.uuid}/groups`)
}

const createCourse = () => {
  router.push(`/admin/classes/${route.params.uuid}/create-course`)
}

onMounted(() => {
  loadClassDetail()
})
</script>

<style scoped lang="scss">
.class-detail-container {
  padding: 24px;
  background: #f5f7fa;
  min-height: calc(100vh - 60px);
}

.page-header {
  margin-bottom: 24px;
}

.loading-container {
  background: white;
  padding: 24px;
  border-radius: 12px;
}

.detail-content {
  .header-card {
    margin-bottom: 24px;
    border-radius: 12px;
    border: none;
    
    :deep(.el-card__body) {
      padding: 0;
    }
  }
  
  .header-content {
    padding: 32px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 12px;
    color: white;
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    
    &.type-club {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    
    &.type-project {
      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
    }
    
    &.type-interest {
      background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
    }
    
    &.type-competition {
      background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
    }
    
    .header-left {
      flex: 1;
      
      .el-tag {
        margin-bottom: 16px;
      }
      
      .class-name {
        margin: 0 0 16px 0;
        font-size: 32px;
        font-weight: 600;
      }
      
      .class-description {
        margin: 0;
        font-size: 16px;
        opacity: 0.9;
        line-height: 1.6;
      }
    }
  }
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
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
        font-size: 32px;
        font-weight: 600;
        color: #303133;
      }
    }
    
    .stat-status {
      display: flex;
      flex-direction: column;
      gap: 12px;
      
      .stat-label {
        font-size: 14px;
        color: #909399;
      }
    }
    
    .stat-time {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-top: 16px;
      padding-top: 16px;
      border-top: 1px solid #f0f0f0;
      font-size: 14px;
      color: #606266;
    }
  }
}

.actions-card {
  margin-bottom: 24px;
  border-radius: 12px;
  
  .card-header {
    font-size: 16px;
    font-weight: 600;
  }
  
  .actions-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 16px;
    
    .el-button {
      height: 56px;
      font-size: 16px;
      
      .el-icon {
        font-size: 20px;
      }
    }
  }
}

.info-card {
  border-radius: 12px;
  
  .card-header {
    font-size: 16px;
    font-weight: 600;
  }
}
</style>
