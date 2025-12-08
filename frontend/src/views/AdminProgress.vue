<template>
  <div class="admin-progress">
    <div class="toolbar">
      <el-form :inline="true">
        <el-form-item label="课程">
          <el-select 
            v-model="selectedCourseId" 
            placeholder="请选择课程"
            @change="loadProgress"
            style="width: 300px"
          >
            <el-option
              v-for="course in courses"
              :key="course.id"
              :label="course.title"
              :value="course.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button @click="loadProgress">刷新</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 进度统计卡片 -->
    <el-row :gutter="20" class="stats-cards" v-if="selectedCourseId">
      <el-col :span="6">
        <el-card>
          <div class="stat-item">
            <div class="stat-label">选课总人数</div>
            <div class="stat-value">{{ stats.totalStudents }}</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <div class="stat-item">
            <div class="stat-label">平均进度</div>
            <div class="stat-value">{{ stats.averageProgress }}%</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <div class="stat-item">
            <div class="stat-label">已完成人数</div>
            <div class="stat-value">{{ stats.completedStudents }}</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <div class="stat-item">
            <div class="stat-label">平均得分</div>
            <div class="stat-value">{{ stats.averageScore }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 学生进度列表 -->
    <el-table :data="progressList" border stripe v-loading="loading" v-if="selectedCourseId">
      <el-table-column prop="student_id" label="学生ID" width="100" />
      <el-table-column prop="student_name" label="学生姓名" width="150" />
      <el-table-column prop="student_number" label="学号" width="150" />
      <el-table-column label="课程进度" width="200">
        <template #default="{ row }">
          <el-progress :percentage="row.progress || 0" />
        </template>
      </el-table-column>
      <el-table-column prop="completed_units" label="已完成单元" width="120">
        <template #default="{ row }">
          {{ row.completed_units || 0 }} / {{ row.total_units || 0 }}
        </template>
      </el-table-column>
      <el-table-column prop="completed_tasks" label="已完成任务" width="120">
        <template #default="{ row }">
          {{ row.completed_tasks || 0 }} / {{ row.total_tasks || 0 }}
        </template>
      </el-table-column>
      <el-table-column prop="average_score" label="平均得分" width="100">
        <template #default="{ row }">
          {{ row.average_score || '-' }}
        </template>
      </el-table-column>
      <el-table-column prop="last_active_at" label="最后活跃" width="180">
        <template #default="{ row }">
          {{ formatDate(row.last_active_at) }}
        </template>
      </el-table-column>
      <el-table-column label="操作" width="150" fixed="right">
        <template #default="{ row }">
          <el-button link type="primary" @click="viewStudentDetail(row)">
            查看详情
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-empty v-else description="请先选择课程" />

    <!-- 学生详细进度对话框 -->
    <el-dialog 
      v-model="detailDialogVisible" 
      title="学生学习详情"
      width="900px"
    >
      <div v-loading="detailLoading">
        <h3>基本信息</h3>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="学生姓名">
            {{ studentDetail.student_name }}
          </el-descriptions-item>
          <el-descriptions-item label="学号">
            {{ studentDetail.student_number }}
          </el-descriptions-item>
          <el-descriptions-item label="课程进度">
            <el-progress :percentage="studentDetail.progress || 0" />
          </el-descriptions-item>
          <el-descriptions-item label="平均得分">
            {{ studentDetail.average_score || '-' }}
          </el-descriptions-item>
        </el-descriptions>

        <h3 style="margin-top: 20px">单元完成情况</h3>
        <el-table :data="studentDetail.units || []" border>
          <el-table-column prop="unit_title" label="单元名称" />
          <el-table-column label="状态" width="100">
            <template #default="{ row }">
              <el-tag :type="row.completed ? 'success' : 'info'">
                {{ row.completed ? '已完成' : '未完成' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="completed_at" label="完成时间" width="180">
            <template #default="{ row }">
              {{ formatDate(row.completed_at) }}
            </template>
          </el-table-column>
        </el-table>

        <h3 style="margin-top: 20px">任务完成情况</h3>
        <el-table :data="studentDetail.tasks || []" border>
          <el-table-column prop="task_title" label="任务名称" />
          <el-table-column label="状态" width="100">
            <template #default="{ row }">
              <el-tag :type="getStatusColor(row.status)">
                {{ getStatusLabel(row.status) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="score" label="得分" width="80" />
          <el-table-column prop="submitted_at" label="提交时间" width="180">
            <template #default="{ row }">
              {{ formatDate(row.submitted_at) }}
            </template>
          </el-table-column>
        </el-table>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { getCourses } from '@/api/admin'
import { 
  getCourseStudentProgress, 
  getStudentDetailProgress 
} from '@/api/progress'

const loading = ref(false)
const selectedCourseId = ref(null)
const courses = ref([])
const progressList = ref([])

// 统计信息
const stats = reactive({
  totalStudents: 0,
  averageProgress: 0,
  completedStudents: 0,
  averageScore: 0
})

// 学生详情
const detailDialogVisible = ref(false)
const detailLoading = ref(false)
const studentDetail = ref({})

// 格式化日期
const formatDate = (dateStr) => {
  if (!dateStr) return '-'
  const date = new Date(dateStr)
  return date.toLocaleString('zh-CN')
}

// 获取状态标签
const getStatusLabel = (status) => {
  const labels = {
    'pending': '待开始',
    'in-progress': '进行中',
    'blocked': '受阻',
    'review': '待审核',
    'completed': '已完成'
  }
  return labels[status] || status
}

const getStatusColor = (status) => {
  const colors = {
    'pending': 'info',
    'in-progress': 'primary',
    'blocked': 'warning',
    'review': 'warning',
    'completed': 'success'
  }
  return colors[status] || 'info'
}

// 加载课程列表
const loadCourses = async () => {
  try {
    const result = await getCourses()
    courses.value = result.items || result || []
  } catch (error) {
    ElMessage.error(error.message || '加载课程列表失败')
  }
}

// 加载进度数据
const loadProgress = async () => {
  if (!selectedCourseId.value) {
    progressList.value = []
    return
  }
  
  loading.value = true
  try {
    const result = await getCourseStudentProgress(selectedCourseId.value)
    progressList.value = result.students || []
    
    // 计算统计信息
    stats.totalStudents = progressList.value.length
    stats.averageProgress = Math.round(
      progressList.value.reduce((sum, item) => sum + (item.progress || 0), 0) / stats.totalStudents
    ) || 0
    stats.completedStudents = progressList.value.filter(item => item.progress >= 100).length
    stats.averageScore = Math.round(
      progressList.value.reduce((sum, item) => sum + (item.average_score || 0), 0) / stats.totalStudents
    ) || 0
  } catch (error) {
    ElMessage.error(error.message || '加载进度数据失败')
  } finally {
    loading.value = false
  }
}

// 查看学生详情
const viewStudentDetail = async (row) => {
  detailDialogVisible.value = true
  detailLoading.value = true
  
  try {
    studentDetail.value = await getStudentDetailProgress(row.student_id, selectedCourseId.value)
  } catch (error) {
    ElMessage.error(error.message || '加载学生详情失败')
  } finally {
    detailLoading.value = false
  }
}

onMounted(() => {
  loadCourses()
})
</script>

<style scoped>
.admin-progress {
  background: white;
  padding: 20px;
  border-radius: 4px;
}

.toolbar {
  margin-bottom: 20px;
}

.stats-cards {
  margin-bottom: 20px;
}

.stat-item {
  text-align: center;
}

.stat-label {
  color: #909399;
  font-size: 14px;
  margin-bottom: 8px;
}

.stat-value {
  color: #303133;
  font-size: 28px;
  font-weight: bold;
}

h3 {
  margin: 10px 0;
  font-size: 16px;
  font-weight: 600;
}
</style>
