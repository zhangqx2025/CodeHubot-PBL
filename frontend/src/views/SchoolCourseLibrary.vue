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
                <el-button type="primary" size="small" @click="handleAssignStudents(course)">
                  <el-icon><Plus /></el-icon>
                  分配学生
                </el-button>
                <el-button size="small" @click="handleViewDetails(course)">
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

    <!-- 分配学生对话框 -->
    <el-dialog
      v-model="assignDialogVisible"
      title="为学生分配课程"
      width="800px"
      :close-on-click-modal="false"
    >
      <div v-if="currentCourse">
        <el-alert
          :title="`课程：${currentCourse.title}`"
          type="info"
          :closable="false"
          style="margin-bottom: 20px"
        />
        
        <!-- 学生选择表格 -->
        <el-table
          ref="studentTableRef"
          :data="students"
          v-loading="loadingStudents"
          @selection-change="handleSelectionChange"
          max-height="400"
        >
          <el-table-column type="selection" width="55" />
          <el-table-column prop="name" label="姓名" width="120" />
          <el-table-column prop="student_number" label="学号" width="150" />
          <el-table-column prop="class_name" label="班级" width="150" />
          <el-table-column label="状态" width="100">
            <template #default="{ row }">
              <el-tag v-if="row.enrolled" type="success" size="small">已选课</el-tag>
              <el-tag v-else type="info" size="small">未选课</el-tag>
            </template>
          </el-table-column>
        </el-table>
        
        <div style="margin-top: 10px; color: #909399; font-size: 14px">
          已选择 {{ selectedStudents.length }} 名学生
        </div>
      </div>
      
      <template #footer>
        <el-button @click="assignDialogVisible = false">取消</el-button>
        <el-button 
          type="primary" 
          @click="handleAssignSubmit" 
          :loading="submitting"
          :disabled="selectedStudents.length === 0"
        >
          确定分配
        </el-button>
      </template>
    </el-dialog>

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
import { Search, Refresh, Plus, View, Clock, User, Picture } from '@element-plus/icons-vue'
import axios from 'axios'

const loading = ref(false)
const loadingStudents = ref(false)
const submitting = ref(false)
const assignDialogVisible = ref(false)
const detailDialogVisible = ref(false)
const studentTableRef = ref(null)

const courses = ref([])
const students = ref([])
const selectedStudents = ref([])
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

// 加载学生列表
const loadStudents = async (courseId) => {
  try {
    loadingStudents.value = true
    // 获取学校所有学生
    const response = await axios.get('/api/v1/admin/users/list', {
      params: {
        role: 'student',
        limit: 1000
      },
      headers: getAuthHeaders()
    })
    
    if (response.data && response.data.success) {
      students.value = response.data.data.items || []
      
      // 标记已选课的学生
      const enrolledResponse = await axios.get(`/api/v1/admin/enrollments/course/${courseId}/students`, {
        headers: getAuthHeaders()
      })
      
      if (enrolledResponse.data && enrolledResponse.data.success) {
        const enrolledIds = enrolledResponse.data.data.map(e => e.student_id)
        students.value = students.value.map(student => ({
          ...student,
          enrolled: enrolledIds.includes(student.id)
        }))
      }
    }
  } catch (error) {
    console.error('加载学生列表失败:', error)
    ElMessage.error(error.response?.data?.message || '加载学生列表失败')
  } finally {
    loadingStudents.value = false
  }
}

// 打开分配学生对话框
const handleAssignStudents = async (course) => {
  currentCourse.value = course
  assignDialogVisible.value = true
  await loadStudents(course.id)
}

// 处理学生选择
const handleSelectionChange = (selection) => {
  selectedStudents.value = selection
}

// 提交学生分配
const handleAssignSubmit = async () => {
  if (selectedStudents.value.length === 0) {
    ElMessage.warning('请至少选择一名学生')
    return
  }
  
  try {
    submitting.value = true
    
    const studentIds = selectedStudents.value
      .filter(s => !s.enrolled) // 过滤掉已选课的学生
      .map(s => s.id)
    
    if (studentIds.length === 0) {
      ElMessage.warning('选择的学生都已经选课')
      return
    }
    
    const response = await axios.post(
      `/api/v1/admin/enrollments/course/${currentCourse.value.id}/batch-enroll`,
      { student_ids: studentIds },
      { headers: getAuthHeaders() }
    )
    
    if (response.data && response.data.success) {
      ElMessage.success(`成功为 ${studentIds.length} 名学生分配课程`)
      assignDialogVisible.value = false
      loadCourses() // 刷新课程列表
    }
  } catch (error) {
    console.error('分配失败:', error)
    ElMessage.error(error.response?.data?.message || '分配失败')
  } finally {
    submitting.value = false
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
}

.filter-form {
  margin-bottom: 20px;
}

.course-card {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.course-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.course-title {
  font-weight: 600;
  font-size: 16px;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  margin-right: 10px;
}

.course-info {
  flex: 1;
}

.course-description {
  color: #606266;
  font-size: 14px;
  line-height: 1.5;
  margin: 10px 0;
  height: 60px;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
}

.course-meta {
  display: flex;
  justify-content: space-between;
  margin: 10px 0;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 5px;
  color: #909399;
  font-size: 14px;
}

.course-date {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid #EBEEF5;
}

.course-actions {
  display: flex;
  gap: 10px;
  justify-content: center;
}

.image-slot {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  height: 100%;
  background-color: #f5f7fa;
  color: #909399;
  font-size: 30px;
}
</style>
