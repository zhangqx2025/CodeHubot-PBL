<template>
  <div class="admin-class-progress">
    <div class="toolbar">
      <el-form :inline="true">
        <el-form-item label="班级">
          <el-select 
            v-model="selectedClassId" 
            placeholder="请选择班级"
            @change="loadClassProgress"
            style="width: 300px"
            filterable
          >
            <el-option
              v-for="cls in classes"
              :key="cls.class_id"
              :label="`${cls.class_name} (${cls.grade || ''})`"
              :value="cls.class_id"
            >
              <div style="display: flex; justify-content: space-between;">
                <span>{{ cls.class_name }}</span>
                <span style="color: #8492a6; font-size: 13px;">
                  {{ cls.student_count }}人
                </span>
              </div>
            </el-option>
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button @click="loadClassProgress" :disabled="!selectedClassId">
            刷新
          </el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 课程信息卡片 -->
    <div v-if="courseInfo && selectedClassId" class="course-info-card">
      <el-card>
        <div class="course-header">
          <img 
            v-if="courseInfo.cover_image" 
            :src="courseInfo.cover_image" 
            class="course-cover"
            alt="课程封面"
          />
          <div class="course-details">
            <h2>{{ courseInfo.course_title }}</h2>
            <p class="course-description">{{ courseInfo.description }}</p>
            <div class="course-meta">
              <el-tag size="small">{{ difficultyText(courseInfo.difficulty) }}</el-tag>
              <span class="meta-item">
                <el-icon><Document /></el-icon>
                {{ courseInfo.total_units }} 个单元
              </span>
              <span class="meta-item">
                <el-icon><EditPen /></el-icon>
                {{ courseInfo.total_tasks }} 个任务
              </span>
              <span class="meta-item">
                <el-icon><VideoPlay /></el-icon>
                {{ courseInfo.total_resources }} 个资源
              </span>
            </div>
          </div>
        </div>
      </el-card>
    </div>

    <!-- 班级统计卡片 -->
    <el-row :gutter="20" class="stats-cards" v-if="selectedClassId && classStats">
      <el-col :span="6">
        <el-card>
          <div class="stat-item">
            <div class="stat-icon" style="background: #409EFF;">
              <el-icon><User /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-label">班级总人数</div>
              <div class="stat-value">{{ classStats.total_students }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <div class="stat-item">
            <div class="stat-icon" style="background: #67C23A;">
              <el-icon><TrendCharts /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-label">平均进度</div>
              <div class="stat-value">{{ classStats.avg_progress }}%</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <div class="stat-item">
            <div class="stat-icon" style="background: #E6A23C;">
              <el-icon><CircleCheck /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-label">已完成</div>
              <div class="stat-value">{{ classStats.completed_students }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <div class="stat-item">
            <div class="stat-icon" style="background: #909399;">
              <el-icon><Loading /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-label">学习中</div>
              <div class="stat-value">{{ classStats.in_progress_students }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 学生进度列表 -->
    <el-card v-if="selectedClassId" class="students-table-card">
      <template #header>
        <div class="card-header">
          <span>学生学习进度</span>
          <el-button size="small" @click="exportProgress">
            <el-icon><Download /></el-icon>
            导出数据
          </el-button>
        </div>
      </template>
      <el-table 
        :data="studentsList" 
        border 
        stripe 
        v-loading="loading"
        :default-sort="{prop: 'progress', order: 'descending'}"
      >
        <el-table-column type="index" label="#" width="60" />
        <el-table-column prop="student_number" label="学号" width="120" />
        <el-table-column prop="student_name" label="学生姓名" width="120">
          <template #default="{ row }">
            <div class="student-info">
              <el-avatar :size="30" :src="row.avatar" v-if="row.avatar" />
              <el-avatar :size="30" v-else>{{ row.student_name.charAt(0) }}</el-avatar>
              <span class="student-name">{{ row.student_name }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="课程进度" width="200" sortable prop="progress">
          <template #default="{ row }">
            <el-progress 
              :percentage="row.progress || 0" 
              :color="progressColor(row.progress)"
            />
          </template>
        </el-table-column>
        <el-table-column prop="completed_tasks" label="完成任务" width="120" sortable>
          <template #default="{ row }">
            <span class="task-count">
              {{ row.completed_tasks }} / {{ row.total_tasks }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="watched_videos" label="观看视频" width="100" sortable>
          <template #default="{ row }">
            <el-tag size="small">{{ row.watched_videos }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="read_documents" label="阅读文档" width="100" sortable>
          <template #default="{ row }">
            <el-tag size="small" type="success">{{ row.read_documents }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="total_time_spent" label="学习时长" width="120" sortable>
          <template #default="{ row }">
            {{ formatTime(row.total_time_spent) }}
          </template>
        </el-table-column>
        <el-table-column prop="last_learning_time" label="最后学习" width="160" sortable>
          <template #default="{ row }">
            {{ formatDate(row.last_learning_time) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button 
              link 
              type="primary" 
              @click="viewStudentDetail(row)"
              size="small"
            >
              <el-icon><View /></el-icon>
              查看详情
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 学生详情对话框 -->
    <el-dialog 
      v-model="detailDialogVisible" 
      :title="`${currentStudent?.student_name} - 学习详情`"
      width="90%"
      top="5vh"
    >
      <div v-loading="detailLoading" class="student-detail">
        <div v-if="studentDetail">
          <!-- 单元进度列表 -->
          <div v-for="unit in studentDetail.units" :key="unit.unit_id" class="unit-section">
            <div class="unit-header">
              <h3>{{ unit.title }}</h3>
              <el-progress 
                :percentage="unit.completion" 
                :color="progressColor(unit.completion)"
                style="width: 200px"
              />
            </div>

            <!-- 资源进度 -->
            <div v-if="unit.resources && unit.resources.length > 0" class="resources-section">
              <h4>学习资源</h4>
              <el-table :data="unit.resources" size="small">
                <el-table-column prop="title" label="资源名称" />
                <el-table-column prop="type" label="类型" width="100">
                  <template #default="{ row }">
                    <el-tag size="small">{{ resourceTypeText(row.type) }}</el-tag>
                  </template>
                </el-table-column>
                <el-table-column label="完成状态" width="100">
                  <template #default="{ row }">
                    <el-tag 
                      :type="row.is_completed ? 'success' : 'info'" 
                      size="small"
                    >
                      {{ row.is_completed ? '已完成' : '未完成' }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column label="进度" width="180" v-if="row.type === 'video'">
                  <template #default="{ row }">
                    <span v-if="row.completion_rate !== undefined">
                      {{ row.completion_rate }}%
                    </span>
                    <span v-else>-</span>
                  </template>
                </el-table-column>
                <el-table-column prop="last_learning" label="最后学习" width="180">
                  <template #default="{ row }">
                    {{ formatDate(row.last_learning) }}
                  </template>
                </el-table-column>
              </el-table>
            </div>

            <!-- 任务进度 -->
            <div v-if="unit.tasks && unit.tasks.length > 0" class="tasks-section">
              <h4>学习任务</h4>
              <el-table :data="unit.tasks" size="small">
                <el-table-column prop="title" label="任务名称" />
                <el-table-column prop="type" label="类型" width="100">
                  <template #default="{ row }">
                    <el-tag size="small">{{ taskTypeText(row.type) }}</el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="difficulty" label="难度" width="80">
                  <template #default="{ row }">
                    <el-tag 
                      :type="difficultyTagType(row.difficulty)" 
                      size="small"
                    >
                      {{ difficultyText(row.difficulty) }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="status" label="状态" width="100">
                  <template #default="{ row }">
                    <el-tag 
                      :type="statusTagType(row.status)" 
                      size="small"
                    >
                      {{ statusText(row.status) }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="score" label="得分" width="80">
                  <template #default="{ row }">
                    {{ row.score || '-' }}
                  </template>
                </el-table-column>
                <el-table-column prop="updated_at" label="更新时间" width="180">
                  <template #default="{ row }">
                    {{ formatDate(row.updated_at) }}
                  </template>
                </el-table-column>
              </el-table>
            </div>
          </div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { 
  getAdminClasses, 
  getClassCourseProgress, 
  getStudentProgressDetail 
} from '@/api/classProgress'
import {
  Document,
  EditPen,
  VideoPlay,
  User,
  TrendCharts,
  CircleCheck,
  Loading,
  Download,
  View
} from '@element-plus/icons-vue'

// 数据
const classes = ref([])
const selectedClassId = ref(null)
const courseInfo = ref(null)
const classStats = ref(null)
const studentsList = ref([])
const loading = ref(false)

// 学生详情
const detailDialogVisible = ref(false)
const currentStudent = ref(null)
const studentDetail = ref(null)
const detailLoading = ref(false)

// 加载班级列表
const loadClasses = async () => {
  try {
    const res = await getAdminClasses()
    if (res.code === 0) {
      classes.value = res.data
      // 如果只有一个班级，自动选择
      if (classes.value.length === 1) {
        selectedClassId.value = classes.value[0].class_id
        await loadClassProgress()
      }
    }
  } catch (error) {
    console.error('加载班级列表失败:', error)
    ElMessage.error('加载班级列表失败')
  }
}

// 加载班级课程进度
const loadClassProgress = async () => {
  if (!selectedClassId.value) {
    return
  }
  
  loading.value = true
  try {
    const res = await getClassCourseProgress(selectedClassId.value)
    if (res.code === 0) {
      courseInfo.value = res.data.course
      classStats.value = res.data.class_statistics
      studentsList.value = res.data.students
    } else {
      ElMessage.error(res.message || '加载班级进度失败')
    }
  } catch (error) {
    console.error('加载班级进度失败:', error)
    ElMessage.error('加载班级进度失败')
  } finally {
    loading.value = false
  }
}

// 查看学生详情
const viewStudentDetail = async (student) => {
  currentStudent.value = student
  detailDialogVisible.value = true
  detailLoading.value = true
  
  try {
    const res = await getStudentProgressDetail(selectedClassId.value, student.student_id)
    if (res.code === 0) {
      studentDetail.value = res.data
    } else {
      ElMessage.error(res.message || '加载学生详情失败')
    }
  } catch (error) {
    console.error('加载学生详情失败:', error)
    ElMessage.error('加载学生详情失败')
  } finally {
    detailLoading.value = false
  }
}

// 导出进度数据
const exportProgress = () => {
  // TODO: 实现导出功能
  ElMessage.info('导出功能开发中...')
}

// 工具函数
const formatDate = (dateStr) => {
  if (!dateStr) return '-'
  const date = new Date(dateStr)
  return date.toLocaleString('zh-CN')
}

const formatTime = (seconds) => {
  if (!seconds) return '-'
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  if (hours > 0) {
    return `${hours}小时${minutes}分钟`
  }
  return `${minutes}分钟`
}

const progressColor = (progress) => {
  if (progress >= 100) return '#67C23A'
  if (progress >= 60) return '#409EFF'
  if (progress >= 30) return '#E6A23C'
  return '#F56C6C'
}

const difficultyText = (difficulty) => {
  const map = {
    'beginner': '初级',
    'intermediate': '中级',
    'advanced': '高级',
    'easy': '简单',
    'medium': '中等',
    'hard': '困难'
  }
  return map[difficulty] || difficulty
}

const difficultyTagType = (difficulty) => {
  const map = {
    'easy': 'success',
    'medium': 'warning',
    'hard': 'danger'
  }
  return map[difficulty] || 'info'
}

const resourceTypeText = (type) => {
  const map = {
    'video': '视频',
    'document': '文档',
    'link': '链接'
  }
  return map[type] || type
}

const taskTypeText = (type) => {
  const map = {
    'analysis': '分析',
    'coding': '编程',
    'design': '设计',
    'deployment': '部署'
  }
  return map[type] || type
}

const statusText = (status) => {
  const map = {
    'pending': '待开始',
    'in-progress': '进行中',
    'blocked': '受阻',
    'review': '待审核',
    'completed': '已完成'
  }
  return map[status] || status
}

const statusTagType = (status) => {
  const map = {
    'pending': 'info',
    'in-progress': 'primary',
    'blocked': 'warning',
    'review': 'warning',
    'completed': 'success'
  }
  return map[status] || 'info'
}

// 生命周期
onMounted(() => {
  loadClasses()
})
</script>

<style scoped>
.admin-class-progress {
  padding: 20px;
}

.toolbar {
  margin-bottom: 20px;
}

.course-info-card {
  margin-bottom: 20px;
}

.course-header {
  display: flex;
  gap: 20px;
}

.course-cover {
  width: 200px;
  height: 120px;
  object-fit: cover;
  border-radius: 8px;
}

.course-details h2 {
  margin: 0 0 10px 0;
  color: #303133;
}

.course-description {
  color: #606266;
  margin-bottom: 15px;
  line-height: 1.5;
}

.course-meta {
  display: flex;
  gap: 20px;
  align-items: center;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 5px;
  color: #909399;
  font-size: 14px;
}

.stats-cards {
  margin-bottom: 20px;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 15px;
}

.stat-icon {
  width: 50px;
  height: 50px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 24px;
}

.stat-content {
  flex: 1;
}

.stat-label {
  color: #909399;
  font-size: 14px;
  margin-bottom: 5px;
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #303133;
}

.students-table-card {
  margin-top: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.student-info {
  display: flex;
  align-items: center;
  gap: 10px;
}

.student-name {
  font-weight: 500;
}

.task-count {
  font-weight: 500;
}

/* 学生详情样式 */
.student-detail {
  max-height: 70vh;
  overflow-y: auto;
}

.unit-section {
  margin-bottom: 30px;
  padding: 20px;
  background: #f5f7fa;
  border-radius: 8px;
}

.unit-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 2px solid #dcdfe6;
}

.unit-header h3 {
  margin: 0;
  color: #303133;
}

.resources-section,
.tasks-section {
  margin-top: 20px;
  padding: 15px;
  background: white;
  border-radius: 8px;
}

.resources-section h4,
.tasks-section h4 {
  margin: 0 0 15px 0;
  color: #606266;
  font-size: 16px;
}
</style>
