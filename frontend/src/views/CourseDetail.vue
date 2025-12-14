<template>
  <div class="course-detail" v-if="course">
    <!-- 课程头部 -->
    <div class="course-header">
      <el-button :icon="ArrowLeft" @click="goBack" class="back-btn">返回课程列表</el-button>
      
      <div class="header-content">
        <div class="header-info">
          <h1 class="course-title">{{ course.title }}</h1>
          <p class="course-description">{{ course.description }}</p>
          
          <div class="course-stats">
            <div class="stat-item">
              <el-icon><Clock /></el-icon>
              <span>{{ course.duration || '8周' }}</span>
            </div>
            <div class="stat-item">
              <el-icon><TrendCharts /></el-icon>
              <span>{{ getDifficultyText(course.difficulty) }}</span>
            </div>
            <div class="stat-item">
              <el-icon><Reading /></el-icon>
              <span>{{ course.units?.length || 0 }}个学习单元</span>
            </div>
          </div>
        </div>
        
        <div class="header-cover" v-if="course.cover_image">
          <img :src="course.cover_image" :alt="course.title" @error="handleImageError" />
        </div>
      </div>
    </div>

    <!-- 课程进度 -->
    <div class="course-progress-section">
      <h3>学习进度</h3>
      <el-progress 
        :percentage="overallProgress" 
        :stroke-width="12"
        :color="progressColor"
      >
        <template #default="{ percentage }">
          <span class="progress-label">{{ percentage }}%</span>
        </template>
      </el-progress>
      <div class="progress-text">
        已完成 {{ completedUnits }} / {{ totalUnits }} 个单元，总体进度 {{ overallProgress }}%
      </div>
    </div>

    <!-- 学习单元列表 -->
    <div class="units-section">
      <h3 class="section-title">
        <el-icon><Reading /></el-icon>
        学习单元
      </h3>
      
      <div class="units-timeline">
        <div 
          v-for="(unit, index) in course.units" 
          :key="unit.id"
          class="unit-item"
          :class="{ 
            'locked': unit.status === 'locked',
            'completed': unit.status === 'completed',
            'active': unit.status === 'available'
          }"
        >
          <!-- 时间线连接线 -->
          <div class="timeline-line" v-if="index < course.units.length - 1"></div>
          
          <!-- 单元图标 -->
          <div class="unit-icon">
            <el-icon v-if="unit.status === 'completed'"><CircleCheck /></el-icon>
            <el-icon v-else-if="unit.status === 'locked'"><Lock /></el-icon>
            <el-icon v-else><VideoPlay /></el-icon>
          </div>
          
          <!-- 单元内容 -->
          <div class="unit-content">
            <div class="unit-header">
              <h4 class="unit-title">
                <span class="unit-number">{{ index + 1 }}.</span>
                {{ unit.title }}
              </h4>
              <div class="unit-tags">
                <el-tag 
                  :type="getUnitStatusType(unit.status)" 
                  size="small"
                >
                  {{ getUnitStatusText(unit.status) }}
                </el-tag>
                <el-tag 
                  v-if="unit.open_from && !unit.is_open" 
                  type="warning" 
                  size="small"
                >
                  {{ formatOpenTime(unit.open_from) }}
                </el-tag>
              </div>
            </div>
            
            <p class="unit-description">{{ unit.description }}</p>
            
            <!-- 单元学习进度 - 分类统计 -->
            <div class="unit-progress-detail">
              <div class="progress-item" v-if="unit.video_count > 0">
                <span class="progress-icon">
                  <el-icon><VideoPlay /></el-icon>
                </span>
                <span class="progress-label">视频</span>
                <span class="progress-stats">{{ unit.completed_videos || 0 }}/{{ unit.video_count }}</span>
              </div>
              <div class="progress-item" v-if="unit.document_count > 0">
                <span class="progress-icon">
                  <el-icon><Document /></el-icon>
                </span>
                <span class="progress-label">文档</span>
                <span class="progress-stats">{{ unit.completed_documents || 0 }}/{{ unit.document_count }}</span>
              </div>
              <div class="progress-item" v-if="unit.tasks_count > 0">
                <span class="progress-icon">
                  <el-icon><Edit /></el-icon>
                </span>
                <span class="progress-label">作业</span>
                <span class="progress-stats">{{ unit.completed_tasks || 0 }}/{{ unit.tasks_count }}</span>
              </div>
            </div>
            
            <!-- 单元操作 -->
            <div class="unit-actions">
              <el-button 
                v-if="unit.status !== 'locked' && unit.is_open" 
                type="primary" 
                size="default"
                @click="gotoUnitLearning(unit.id, unit.uuid)"
              >
                {{ unit.status === 'completed' ? '回顾单元' : '开始学习' }}
              </el-button>
              <el-button 
                v-else-if="unit.status !== 'locked' && !unit.is_open" 
                disabled
                size="default"
              >
                <el-icon><Clock /></el-icon>
                {{ formatOpenTime(unit.open_from) }}
              </el-button>
              <el-button 
                v-else 
                disabled
                size="default"
              >
                <el-icon><Lock /></el-icon>
                尚未解锁
              </el-button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 课程项目 -->
    <div class="projects-section" v-if="course.projects && course.projects.length > 0">
      <h3 class="section-title">
        <el-icon><Notebook /></el-icon>
        实践项目
      </h3>
      
      <div class="projects-grid">
        <div 
          v-for="project in course.projects" 
          :key="project.id"
          class="project-card"
          @click="gotoProjectDetail(project.id)"
        >
          <div class="project-header">
            <h4>{{ project.title }}</h4>
            <el-tag :type="getProjectStatusType(project.status)" size="small">
              {{ getProjectStatusText(project.status) }}
            </el-tag>
          </div>
          <p class="project-description">{{ project.description }}</p>
          <div class="project-progress">
            <el-progress :percentage="project.progress" :show-text="false" />
            <span class="progress-text">{{ project.progress }}%</span>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- 加载状态 -->
  <el-skeleton v-else :loading="loading" :rows="5" animated />
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  ArrowLeft,
  Clock,
  TrendCharts,
  Reading,
  CircleCheck,
  Lock,
  VideoPlay,
  Document,
  Edit
} from '@element-plus/icons-vue'
import { getCourseDetail } from '@/api/student'

const router = useRouter()
const route = useRoute()

const loading = ref(false)
const course = ref(null)

// 计算属性
const totalUnits = computed(() => course.value?.units?.length || 0)

// 计算已完成的单元数（单元进度达到100%才算完成）
const completedUnits = computed(() => {
  if (!course.value?.units) return 0
  return course.value.units.filter(u => {
    // 如果有status字段且为completed，则认为已完成
    // 或者进度达到100%也认为已完成
    return u.status === 'completed' || u.progress >= 100
  }).length
})

// 计算总体学习进度（基于完成的单元数，而不是平均进度）
const overallProgress = computed(() => {
  if (!course.value?.units || course.value.units.length === 0) return 0
  
  // 进度 = 已完成单元数 / 总单元数 * 100
  return Math.round((completedUnits.value / totalUnits.value) * 100)
})

const progressColor = computed(() => {
  const percentage = overallProgress.value
  if (percentage < 30) return '#f56c6c'
  if (percentage < 70) return '#e6a23c'
  return '#67c23a'
})

// 方法
const loadCourseDetail = async () => {
  loading.value = true
  try {
    const courseId = route.params.courseId
    const data = await getCourseDetail(courseId)
    course.value = data
  } catch (error) {
    ElMessage.error('加载课程详情失败: ' + error.message)
    console.error('Load course detail error:', error)
  } finally {
    loading.value = false
  }
}

const getDifficultyText = (difficulty) => {
  const map = {
    'beginner': '入门级',
    'intermediate': '中级',
    'advanced': '高级'
  }
  return map[difficulty] || '入门级'
}

const getUnitStatusType = (status) => {
  const map = {
    'locked': 'info',
    'available': 'warning',
    'completed': 'success'
  }
  return map[status] || 'info'
}

const getUnitStatusText = (status) => {
  const map = {
    'locked': '未解锁',
    'available': '可学习',
    'completed': '已完成'
  }
  return map[status] || '未知'
}

const getProjectStatusType = (status) => {
  const map = {
    'planning': 'info',
    'in-progress': 'warning',
    'review': 'primary',
    'completed': 'success'
  }
  return map[status] || 'info'
}

const getProjectStatusText = (status) => {
  const map = {
    'planning': '计划中',
    'in-progress': '进行中',
    'review': '审核中',
    'completed': '已完成'
  }
  return map[status] || '未知'
}

// 格式化开放时间
const formatOpenTime = (timeStr) => {
  if (!timeStr) return ''
  const openTime = new Date(timeStr)
  const now = new Date()
  
  if (openTime > now) {
    // 未开放
    return `${openTime.toLocaleString('zh-CN', { 
      month: 'numeric', 
      day: 'numeric', 
      hour: '2-digit', 
      minute: '2-digit' 
    })} 开放`
  } else {
    // 已开放
    return '已开放'
  }
}

const handleImageError = (e) => {
  e.target.src = 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800'
}

const goBack = () => {
  router.push('/courses')
}

const gotoUnitLearning = (unitId, unitUuid) => {
  // 优先使用uuid，如果没有uuid则使用id（向后兼容）
  const identifier = unitUuid || unitId
  router.push(`/unit/${identifier}`)
}

const gotoProjectDetail = (projectId) => {
  router.push(`/project/${projectId}`)
}

onMounted(() => {
  loadCourseDetail()
})
</script>

<style scoped>
.course-detail {
  width: 100%;
  margin: 0;
  padding: 24px;
}

.course-header {
  margin-bottom: 32px;
}

.back-btn {
  margin-bottom: 16px;
}

.header-content {
  display: grid;
  grid-template-columns: 1fr 300px;
  gap: 32px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 40px;
  border-radius: 16px;
  color: white;
}

.header-info {
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.course-title {
  font-size: 32px;
  font-weight: 700;
  margin: 0 0 16px 0;
  color: white;
}

.course-description {
  font-size: 16px;
  line-height: 1.6;
  margin: 0 0 24px 0;
  opacity: 0.95;
}

.course-stats {
  display: flex;
  flex-wrap: wrap;
  gap: 24px;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
}

.stat-item .el-icon {
  font-size: 18px;
}

.header-cover {
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

.header-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.course-progress-section {
  background: white;
  padding: 24px;
  border-radius: 12px;
  margin-bottom: 32px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.course-progress-section h3 {
  margin: 0 0 16px 0;
  font-size: 18px;
  color: #1e293b;
}

.progress-label {
  font-size: 14px;
  font-weight: 600;
}

.progress-text {
  margin-top: 8px;
  font-size: 14px;
  color: #64748b;
  text-align: right;
}

.units-section {
  background: white;
  padding: 24px;
  border-radius: 12px;
  margin-bottom: 32px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 24px 0;
  font-size: 20px;
  color: #1e293b;
}

.units-timeline {
  position: relative;
}

.unit-item {
  display: flex;
  gap: 20px;
  margin-bottom: 24px;
  position: relative;
  padding: 20px;
  border-radius: 12px;
  transition: all 0.3s ease;
}

.unit-item:hover {
  background: #f8fafc;
}

.unit-item.locked {
  opacity: 0.6;
}

.unit-item.completed .unit-icon {
  background: #10b981;
  color: white;
}

.unit-item.active .unit-icon {
  background: #3b82f6;
  color: white;
}

.timeline-line {
  position: absolute;
  left: 31px;
  top: 52px;
  width: 2px;
  height: calc(100% + 24px);
  background: #e5e7eb;
}

.unit-icon {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: #e5e7eb;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  flex-shrink: 0;
  z-index: 2;
  position: relative;
}

.unit-content {
  flex: 1;
}

.unit-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.unit-tags {
  display: flex;
  gap: 8px;
  align-items: center;
}

.unit-title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #1e293b;
  display: flex;
  align-items: center;
  gap: 8px;
}

.unit-number {
  color: #3b82f6;
  font-weight: 700;
}

.unit-description {
  color: #64748b;
  margin: 0 0 12px 0;
  line-height: 1.6;
}

.unit-meta {
  display: flex;
  gap: 16px;
  margin-bottom: 16px;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 13px;
  color: #64748b;
}

.unit-progress-detail {
  margin-bottom: 16px;
  padding: 12px;
  background: #f8fafc;
  border-radius: 8px;
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
}

.progress-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #64748b;
}

.progress-icon {
  display: flex;
  align-items: center;
  color: #3b82f6;
  font-size: 16px;
}

.progress-label {
  font-weight: 500;
  color: #475569;
}

.progress-stats {
  font-weight: 600;
  color: #1e293b;
}

.unit-actions {
  display: flex;
  gap: 12px;
}

.projects-section {
  background: white;
  padding: 24px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.projects-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.project-card {
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.project-card:hover {
  border-color: #3b82f6;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.1);
}

.project-header {
  display: flex;
  justify-content: space-between;
  align-items: start;
  margin-bottom: 12px;
}

.project-header h4 {
  margin: 0;
  font-size: 16px;
  color: #1e293b;
}

.project-description {
  font-size: 14px;
  color: #64748b;
  margin: 0 0 16px 0;
  line-height: 1.6;
}

.project-progress {
  display: flex;
  align-items: center;
  gap: 12px;
}

.project-progress .progress-text {
  font-size: 13px;
  color: #64748b;
  min-width: 40px;
  text-align: right;
}

@media (max-width: 768px) {
  .header-content {
    grid-template-columns: 1fr;
  }
  
  .header-cover {
    height: 200px;
  }
  
  .projects-grid {
    grid-template-columns: 1fr;
  }
}
</style>
