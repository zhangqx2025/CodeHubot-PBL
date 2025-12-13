<template>
  <div class="school-course-library">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>学校课程库</span>
          <el-tag type="info" size="large">
            可用课程：{{ courses.length }} 门
          </el-tag>
        </div>
      </template>

      <!-- 筛选条件 -->
      <el-form :inline="true" class="filter-form">
        <el-form-item label="搜索">
          <el-input 
            v-model="filters.search" 
            placeholder="课程名称" 
            clearable
            style="width: 250px"
            @keyup.enter="handleFilter"
          />
        </el-form-item>
        <el-form-item label="难度">
          <el-select 
            v-model="filters.difficulty" 
            placeholder="请选择难度" 
            clearable 
            style="width: 150px"
          >
            <el-option label="初级" value="beginner" />
            <el-option label="中级" value="intermediate" />
            <el-option label="高级" value="advanced" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleFilter">
            <el-icon><Search /></el-icon>
            查询
          </el-button>
          <el-button @click="resetFilters">
            <el-icon><Refresh /></el-icon>
            重置
          </el-button>
        </el-form-item>
      </el-form>

      <!-- 课程卡片列表 -->
      <el-row :gutter="20" v-loading="loading">
        <el-col 
          v-for="course in filteredCourses" 
          :key="course.id" 
          :xs="24" 
          :sm="12" 
          :md="8" 
          :lg="6"
          style="margin-bottom: 20px"
        >
          <el-card shadow="hover" class="course-card">
            <template #header>
              <div class="course-header">
                <span class="course-title">{{ course.title }}</span>
                <el-tag :type="getDifficultyType(course.difficulty)" size="small">
                  {{ getDifficultyText(course.difficulty) }}
                </el-tag>
              </div>
            </template>
            
            <div class="course-cover" v-if="course.cover_image">
              <el-image 
                :src="course.cover_image" 
                fit="cover"
                style="width: 100%; height: 150px"
              >
                <template #error>
                  <div class="image-slot">
                    <el-icon><Picture /></el-icon>
                  </div>
                </template>
              </el-image>
            </div>
            
            <div class="course-info">
              <p class="course-description">
                {{ course.description || '暂无描述' }}
              </p>
              
              <div class="course-meta">
                <div class="meta-item">
                  <el-icon><Clock /></el-icon>
                  <span>{{ course.duration || '待定' }}</span>
                </div>
                <div class="meta-item" v-if="course.school_course_info">
                  <el-icon><User /></el-icon>
                  <span>
                    {{ course.school_course_info.current_students || 0 }}
                    <template v-if="course.school_course_info.max_students">
                      / {{ course.school_course_info.max_students }}
                    </template>
                    人
                  </span>
                </div>
              </div>
              
              <div class="course-date" v-if="course.school_course_info">
                <el-text size="small" type="info">
                  <template v-if="course.school_course_info.start_date">
                    开始：{{ course.school_course_info.start_date }}
                  </template>
                  <template v-if="course.school_course_info.end_date">
                    <br/>结束：{{ course.school_course_info.end_date }}
                  </template>
                </el-text>
              </div>
            </div>
            
            <template #footer>
              <div class="course-actions">
                <el-button type="primary" size="small" @click="handleViewDetails(course)">
                  <el-icon><View /></el-icon>
                  查看详情
                </el-button>
              </div>
            </template>
          </el-card>
        </el-col>
      </el-row>

      <!-- 空状态 -->
      <el-empty 
        v-if="!loading && filteredCourses.length === 0" 
        description="暂无可用课程"
      />
    </el-card>

    <!-- 课程详情对话框 -->
    <el-dialog
      v-model="detailDialogVisible"
      title="课程详情"
      width="900px"
    >
      <div v-if="currentCourse">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="课程名称">{{ currentCourse.title }}</el-descriptions-item>
          <el-descriptions-item label="难度">
            <el-tag :type="getDifficultyType(currentCourse.difficulty)" size="small">
              {{ getDifficultyText(currentCourse.difficulty) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="时长">{{ currentCourse.duration || '-' }}</el-descriptions-item>
          <el-descriptions-item label="已选学生">
            {{ currentCourse.school_course_info?.current_students || 0 }}
            <template v-if="currentCourse.school_course_info?.max_students">
              / {{ currentCourse.school_course_info.max_students }}
            </template>
            人
          </el-descriptions-item>
          <el-descriptions-item label="开始日期">
            {{ currentCourse.school_course_info?.start_date || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="结束日期">
            {{ currentCourse.school_course_info?.end_date || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="分配时间" :span="2">
            {{ formatDateTime(currentCourse.school_course_info?.assigned_at) }}
          </el-descriptions-item>
          <el-descriptions-item label="课程描述" :span="2">
            {{ currentCourse.description || '-' }}
          </el-descriptions-item>
        </el-descriptions>
      </div>
      <template #footer>
        <el-button @click="detailDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Search, Refresh, View, Clock, User, Picture } from '@element-plus/icons-vue'
import axios from 'axios'

const loading = ref(false)
const detailDialogVisible = ref(false)

const courses = ref([])
const currentCourse = ref(null)

const filters = reactive({
  search: '',
  difficulty: ''
})

// API请求
const getAuthHeaders = () => {
  const token = localStorage.getItem('admin_access_token')
  return { Authorization: `Bearer ${token}` }
}

// 过滤课程
const filteredCourses = computed(() => {
  let result = courses.value
  
  if (filters.search) {
    result = result.filter(course => 
      course.title.toLowerCase().includes(filters.search.toLowerCase())
    )
  }
  
  if (filters.difficulty) {
    result = result.filter(course => course.difficulty === filters.difficulty)
  }
  
  return result
})

// 加载可用课程
const loadCourses = async () => {
  try {
    loading.value = true
    const response = await axios.get('/api/v1/admin/school-courses/available-courses', {
      headers: getAuthHeaders()
    })
    
    if (response.data && response.data.success) {
      courses.value = response.data.data || []
    }
  } catch (error) {
    console.error('加载课程失败:', error)
    ElMessage.error(error.response?.data?.message || '加载课程失败')
  } finally {
    loading.value = false
  }
}

// 查看课程详情
const handleViewDetails = (course) => {
  currentCourse.value = course
  detailDialogVisible.value = true
}

// 筛选处理
const handleFilter = () => {
  // 过滤已在 computed 中处理
}

// 重置筛选
const resetFilters = () => {
  filters.search = ''
  filters.difficulty = ''
}

// 获取难度类型
const getDifficultyType = (difficulty) => {
  const types = {
    beginner: 'success',
    intermediate: 'warning',
    advanced: 'danger'
  }
  return types[difficulty] || 'info'
}

// 获取难度文本
const getDifficultyText = (difficulty) => {
  const texts = {
    beginner: '初级',
    intermediate: '中级',
    advanced: '高级'
  }
  return texts[difficulty] || difficulty
}

// 格式化日期时间
const formatDateTime = (dateTime) => {
  if (!dateTime) return '-'
  return new Date(dateTime).toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 初始化
onMounted(() => {
  loadCourses()
})
</script>

<style scoped>
.school-course-library {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.filter-form {
  margin-bottom: 24px;
  padding: 20px;
  background: linear-gradient(135deg, #f5f7fa 0%, #ffffff 100%);
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.course-card {
  height: 100%;
  display: flex;
  flex-direction: column;
  border-radius: 16px;
  overflow: hidden;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1px solid #e4e7ed;
  background: #ffffff;
}

.course-card:hover {
  transform: translateY(-8px);
  box-shadow: 0 12px 24px rgba(103, 194, 58, 0.15);
  border-color: #67c23a;
}

.course-card :deep(.el-card__header) {
  background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
  padding: 16px 20px;
  border-bottom: none;
}

.course-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
}

.course-title {
  font-weight: 600;
  font-size: 16px;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  color: #ffffff;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.course-card :deep(.el-card__body) {
  padding: 0;
  flex: 1;
  display: flex;
  flex-direction: column;
}

.course-cover {
  position: relative;
  overflow: hidden;
}

.course-cover :deep(.el-image) {
  transition: transform 0.3s ease;
}

.course-card:hover .course-cover :deep(.el-image) {
  transform: scale(1.05);
}

.course-info {
  flex: 1;
  padding: 20px;
  display: flex;
  flex-direction: column;
}

.course-description {
  color: #606266;
  font-size: 14px;
  line-height: 1.6;
  margin: 0 0 16px 0;
  height: 66px;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
}

.course-meta {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  padding: 12px 16px;
  background: linear-gradient(135deg, #e8f5e9 0%, #f1f8e9 100%);
  border-radius: 10px;
  margin-bottom: 12px;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #606266;
  font-size: 13px;
  font-weight: 500;
}

.meta-item .el-icon {
  font-size: 16px;
  color: #67c23a;
}

.course-date {
  margin-top: auto;
  padding: 12px;
  background: linear-gradient(135deg, #fff9e6 0%, #fffbf0 100%);
  border-radius: 8px;
  border-left: 3px solid #ffc107;
}

.course-date .el-text {
  line-height: 1.6;
}

.course-card :deep(.el-card__footer) {
  padding: 16px 20px;
  background: linear-gradient(to top, #f8f9fa 0%, #ffffff 100%);
  border-top: 1px solid #f0f2f5;
}

.course-actions {
  display: flex;
  gap: 10px;
  justify-content: center;
}

.course-actions .el-button {
  flex: 1;
  border-radius: 8px;
  font-weight: 500;
  transition: all 0.3s ease;
}

.course-actions .el-button--primary {
  background: linear-gradient(135deg, #409eff 0%, #3a8ee6 100%);
  border: none;
}

.course-actions .el-button--primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(64, 158, 255, 0.4);
}

.image-slot {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #e8f5e9 0%, #f1f8e9 100%);
  color: #aed581;
  font-size: 48px;
}

/* 难度标签美化 */
.course-header :deep(.el-tag) {
  background: rgba(255, 255, 255, 0.25);
  border: 1px solid rgba(255, 255, 255, 0.4);
  color: #ffffff;
  font-weight: 600;
  padding: 4px 12px;
  border-radius: 20px;
  backdrop-filter: blur(10px);
}

/* 动画效果 */
@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.course-card {
  animation: fadeInUp 0.5s ease-out;
}

/* 为每个卡片添加交错动画 */
.course-card:nth-child(1) { animation-delay: 0.05s; }
.course-card:nth-child(2) { animation-delay: 0.1s; }
.course-card:nth-child(3) { animation-delay: 0.15s; }
.course-card:nth-child(4) { animation-delay: 0.2s; }
.course-card:nth-child(5) { animation-delay: 0.25s; }
.course-card:nth-child(6) { animation-delay: 0.3s; }
.course-card:nth-child(7) { animation-delay: 0.35s; }
.course-card:nth-child(8) { animation-delay: 0.4s; }

/* 响应式调整 */
@media (max-width: 768px) {
  .course-actions {
    flex-direction: column;
  }
  
  .course-actions .el-button {
    width: 100%;
  }
  
  .course-meta {
    flex-direction: column;
    gap: 8px;
  }
}
</style>
