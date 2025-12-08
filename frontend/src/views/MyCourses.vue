<template>
  <div class="my-courses">
    <!-- 页面标题 -->
    <div class="page-header">
      <h1>我的课程</h1>
      <p class="subtitle">开始你的学习之旅，探索项目式学习的乐趣</p>
    </div>

    <!-- 课程筛选 -->
    <div class="course-filters">
      <el-radio-group v-model="filterStatus" @change="loadCourses">
        <el-radio-button label="all">全部课程</el-radio-button>
        <el-radio-button label="in-progress">进行中</el-radio-button>
        <el-radio-button label="completed">已完成</el-radio-button>
      </el-radio-group>
      
      <el-input
        v-model="searchQuery"
        placeholder="搜索课程..."
        :prefix-icon="Search"
        class="search-input"
        clearable
        @input="handleSearch"
      />
    </div>

    <!-- 加载状态 -->
    <el-skeleton :loading="loading" :rows="3" animated>
      <!-- 课程列表 -->
      <div v-if="filteredCourses.length > 0" class="courses-grid">
        <div 
          v-for="course in filteredCourses" 
          :key="course.id"
          class="course-card"
          @click="gotoCourseDetail(course.uuid)"
        >
          <!-- 课程封面 -->
          <div class="course-cover">
            <img 
              :src="course.cover_image || '/default-course-cover.jpg'" 
              :alt="course.title"
              @error="handleImageError"
            />
            <div class="course-difficulty" :class="`difficulty-${course.difficulty}`">
              {{ getDifficultyText(course.difficulty) }}
            </div>
            <div class="course-progress-overlay">
              <el-progress 
                type="circle" 
                :percentage="course.progress" 
                :width="60"
                :stroke-width="4"
              />
            </div>
          </div>

          <!-- 课程信息 -->
          <div class="course-info">
            <h3 class="course-title">{{ course.title }}</h3>
            <p class="course-description">{{ course.description }}</p>
            
            <div class="course-meta">
              <div class="meta-item">
                <el-icon><Clock /></el-icon>
                <span>{{ course.duration || '8周' }}</span>
              </div>
              <div class="meta-item">
                <el-icon><Reading /></el-icon>
                <span>{{ course.total_units }}个单元</span>
              </div>
              <div class="meta-item">
                <el-icon><Check /></el-icon>
                <span>已完成{{ course.completed_units }}个</span>
              </div>
            </div>

            <!-- 进度条 -->
            <div class="course-progress-bar">
              <el-progress 
                :percentage="course.progress" 
                :show-text="false"
                :stroke-width="6"
              />
              <span class="progress-text">学习进度 {{ course.progress }}%</span>
            </div>
          </div>

          <!-- 课程操作 -->
          <div class="course-actions">
            <el-button 
              type="primary" 
              size="default"
              @click.stop="gotoCourseDetail(course.uuid)"
            >
              {{ course.progress > 0 ? '继续学习' : '开始学习' }}
            </el-button>
          </div>
        </div>
      </div>

      <!-- 空状态 -->
      <el-empty 
        v-else
        description="暂无课程"
        :image-size="200"
      >
        <template #image>
          <el-icon :size="100" color="#909399">
            <Reading />
          </el-icon>
        </template>
      </el-empty>
    </el-skeleton>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Search, Clock, Reading, Check } from '@element-plus/icons-vue'
import { getMyCourses } from '@/api/student'

const router = useRouter()

// 状态管理
const loading = ref(false)
const courses = ref([])
const filterStatus = ref('all')
const searchQuery = ref('')

// 计算属性
const filteredCourses = computed(() => {
  let result = courses.value

  // 状态筛选
  if (filterStatus.value !== 'all') {
    if (filterStatus.value === 'in-progress') {
      result = result.filter(c => c.progress > 0 && c.progress < 100)
    } else if (filterStatus.value === 'completed') {
      result = result.filter(c => c.progress === 100)
    }
  }

  // 搜索筛选
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(c => 
      c.title.toLowerCase().includes(query) || 
      (c.description && c.description.toLowerCase().includes(query))
    )
  }

  return result
})

// 方法
const loadCourses = async () => {
  loading.value = true
  try {
    const data = await getMyCourses()
    courses.value = data.items || []
  } catch (error) {
    ElMessage.error('加载课程列表失败: ' + error.message)
    console.error('Load courses error:', error)
  } finally {
    loading.value = false
  }
}

const getDifficultyText = (difficulty) => {
  const map = {
    'beginner': '入门',
    'intermediate': '中级',
    'advanced': '高级'
  }
  return map[difficulty] || '入门'
}

const handleImageError = (e) => {
  e.target.src = 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800'
}

const handleSearch = () => {
  // 搜索会通过 computed 自动触发
}

const gotoCourseDetail = (courseId) => {
  router.push(`/course/${courseId}`)
}

onMounted(() => {
  loadCourses()
})
</script>

<style scoped>
.my-courses {
  padding: 24px;
  max-width: 1400px;
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

.subtitle {
  font-size: 16px;
  color: #64748b;
  margin: 0;
}

.course-filters {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  gap: 16px;
}

.search-input {
  width: 300px;
}

.courses-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 24px;
}

.course-card {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.3s ease;
  cursor: pointer;
  display: flex;
  flex-direction: column;
}

.course-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12);
}

.course-cover {
  position: relative;
  width: 100%;
  height: 200px;
  overflow: hidden;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.course-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.course-card:hover .course-cover img {
  transform: scale(1.05);
}

.course-difficulty {
  position: absolute;
  top: 12px;
  left: 12px;
  padding: 4px 12px;
  border-radius: 16px;
  font-size: 12px;
  font-weight: 500;
  background: rgba(255, 255, 255, 0.9);
  color: #334155;
}

.difficulty-beginner {
  background: rgba(16, 185, 129, 0.9);
  color: white;
}

.difficulty-intermediate {
  background: rgba(245, 158, 11, 0.9);
  color: white;
}

.difficulty-advanced {
  background: rgba(239, 68, 68, 0.9);
  color: white;
}

.course-progress-overlay {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  opacity: 0;
  transition: opacity 0.3s ease;
}

.course-card:hover .course-progress-overlay {
  opacity: 1;
}

.course-info {
  padding: 20px;
  flex: 1;
}

.course-title {
  font-size: 18px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 12px 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.course-description {
  font-size: 14px;
  color: #64748b;
  line-height: 1.6;
  margin: 0 0 16px 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.course-meta {
  display: flex;
  gap: 16px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 13px;
  color: #64748b;
}

.meta-item .el-icon {
  font-size: 16px;
}

.course-progress-bar {
  margin-top: 12px;
}

.progress-text {
  display: block;
  font-size: 12px;
  color: #64748b;
  margin-top: 8px;
}

.course-actions {
  padding: 16px 20px;
  border-top: 1px solid #f1f5f9;
  background: #f8fafc;
}

.course-actions .el-button {
  width: 100%;
}

@media (max-width: 768px) {
  .courses-grid {
    grid-template-columns: 1fr;
  }

  .course-filters {
    flex-direction: column;
    align-items: stretch;
  }

  .search-input {
    width: 100%;
  }
}
</style>
