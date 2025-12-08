<template>
  <div class="admin-enrollments">
    <div class="toolbar">
      <el-form :inline="true">
        <el-form-item label="课程">
          <el-select 
            v-model="selectedCourseId" 
            placeholder="请选择课程"
            @change="loadCourseStudents"
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
        <el-form-item v-if="selectedCourseId">
          <el-button type="primary" @click="showBatchEnrollDialog">
            <el-icon><Plus /></el-icon>
            批量选课
          </el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 选课学生列表 -->
    <el-table :data="students" border stripe v-loading="loading" v-if="selectedCourseId">
      <el-table-column prop="user_id" label="学生ID" width="100" />
      <el-table-column prop="user_name" label="学生姓名" width="150" />
      <el-table-column prop="student_number" label="学号" width="150" />
      <el-table-column prop="enrolled_at" label="选课时间" width="180">
        <template #default="{ row }">
          {{ formatDate(row.enrolled_at) }}
        </template>
      </el-table-column>
      <el-table-column label="学习进度" width="150">
        <template #default="{ row }">
          <el-progress :percentage="row.progress || 0" />
        </template>
      </el-table-column>
      <el-table-column label="操作" width="150" fixed="right">
        <template #default="{ row }">
          <el-button link type="danger" @click="unenrollStudent(row)">取消选课</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-empty v-else description="请先选择课程" />

    <!-- 批量选课对话框 -->
    <el-dialog v-model="batchEnrollDialogVisible" title="批量选课" width="500px">
      <el-form label-width="100px">
        <el-form-item label="学生ID" required>
          <el-input
            v-model="studentIds"
            type="textarea"
            :rows="10"
            placeholder="请输入学生ID，每行一个"
          />
        </el-form-item>
        <el-form-item>
          <el-alert
            title="提示"
            type="info"
            :closable="false"
            show-icon
          >
            每行输入一个学生ID，系统将为这些学生批量选课
          </el-alert>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="batchEnrollDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitBatchEnroll" :loading="enrolling">
          确定
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { getCourses } from '@/api/admin'
import { getCourseStudents, batchEnrollStudents } from '@/api/enrollments'

const loading = ref(false)
const selectedCourseId = ref(null)
const courses = ref([])
const students = ref([])

// 批量选课
const batchEnrollDialogVisible = ref(false)
const studentIds = ref('')
const enrolling = ref(false)

// 格式化日期
const formatDate = (dateStr) => {
  if (!dateStr) return '-'
  const date = new Date(dateStr)
  return date.toLocaleString('zh-CN')
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

// 加载课程学生列表
const loadCourseStudents = async () => {
  if (!selectedCourseId.value) {
    students.value = []
    return
  }
  
  loading.value = true
  try {
    students.value = await getCourseStudents(selectedCourseId.value)
  } catch (error) {
    ElMessage.error(error.message || '加载学生列表失败')
  } finally {
    loading.value = false
  }
}

// 显示批量选课对话框
const showBatchEnrollDialog = () => {
  studentIds.value = ''
  batchEnrollDialogVisible.value = true
}

// 提交批量选课
const submitBatchEnroll = async () => {
  const ids = studentIds.value
    .split('\n')
    .map(id => parseInt(id.trim()))
    .filter(id => !isNaN(id))
  
  if (ids.length === 0) {
    ElMessage.warning('请输入有效的学生ID')
    return
  }
  
  enrolling.value = true
  try {
    await batchEnrollStudents(selectedCourseId.value, ids)
    ElMessage.success(`成功为 ${ids.length} 名学生选课`)
    batchEnrollDialogVisible.value = false
    loadCourseStudents()
  } catch (error) {
    ElMessage.error(error.message || '批量选课失败')
  } finally {
    enrolling.value = false
  }
}

// 取消选课
const unenrollStudent = async (row) => {
  await ElMessageBox.confirm('确定要取消该学生的选课吗？', '警告', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
  
  ElMessage.warning('取消选课功能待实现')
}

onMounted(() => {
  loadCourses()
})
</script>

<style scoped>
.admin-enrollments {
  background: white;
  padding: 20px;
  border-radius: 4px;
}

.toolbar {
  margin-bottom: 20px;
}
</style>
