<template>
  <div class="admin-school-courses">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>学校课程配置管理</span>
          <el-button type="primary" @click="handleAssignCourse">
            <el-icon><Plus /></el-icon>
            分配课程
          </el-button>
        </div>
      </template>

      <!-- 筛选条件 -->
      <el-form :inline="true" class="filter-form">
        <el-form-item label="学校">
          <el-select 
            v-model="filters.schoolId" 
            placeholder="请选择学校" 
            clearable 
            @change="handleFilter"
            style="width: 200px"
          >
            <el-option
              v-for="school in schools"
              :key="school.id"
              :label="school.school_name"
              :value="school.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select 
            v-model="filters.status" 
            placeholder="请选择状态" 
            clearable 
            @change="handleFilter"
            style="width: 150px"
          >
            <el-option label="启用" value="active" />
            <el-option label="停用" value="inactive" />
            <el-option label="归档" value="archived" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadSchoolCourses">
            <el-icon><Search /></el-icon>
            查询
          </el-button>
          <el-button @click="resetFilters">
            <el-icon><Refresh /></el-icon>
            重置
          </el-button>
        </el-form-item>
      </el-form>

      <!-- 数据表格 -->
      <el-table 
        :data="schoolCourses" 
        v-loading="loading" 
        stripe
        style="width: 100%"
      >
        <el-table-column prop="school_name" label="学校名称" width="200" />
        <el-table-column prop="course_title" label="课程名称" min-width="200" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="start_date" label="开始日期" width="120">
          <template #default="{ row }">
            {{ row.start_date || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="end_date" label="结束日期" width="120">
          <template #default="{ row }">
            {{ row.end_date || '-' }}
          </template>
        </el-table-column>
        <el-table-column label="学生数" width="120">
          <template #default="{ row }">
            {{ row.current_students || 0 }}
            <span v-if="row.max_students">/ {{ row.max_students }}</span>
            <span v-else>/ 无限制</span>
          </template>
        </el-table-column>
        <el-table-column prop="assigned_at" label="分配时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.assigned_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="handleEdit(row)">
              <el-icon><Edit /></el-icon>
              编辑
            </el-button>
            <el-button size="small" type="danger" @click="handleRemove(row)">
              <el-icon><Delete /></el-icon>
              移除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination-container">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="pagination.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handlePageChange"
        />
      </div>
    </el-card>

    <!-- 分配课程对话框 -->
    <el-dialog
      v-model="assignDialogVisible"
      title="分配课程给学校"
      width="600px"
      :close-on-click-modal="false"
    >
      <el-form :model="assignForm" :rules="assignRules" ref="assignFormRef" label-width="100px">
        <el-form-item label="学校" prop="school_id">
          <el-select 
            v-model="assignForm.school_id" 
            placeholder="请选择学校" 
            style="width: 100%"
            filterable
          >
            <el-option
              v-for="school in schools"
              :key="school.id"
              :label="school.school_name"
              :value="school.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="课程" prop="course_id">
          <el-select 
            v-model="assignForm.course_id" 
            placeholder="请选择课程" 
            style="width: 100%"
            filterable
          >
            <el-option
              v-for="course in courses"
              :key="course.id"
              :label="course.title"
              :value="course.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="assignForm.status" placeholder="请选择状态" style="width: 100%">
            <el-option label="启用" value="active" />
            <el-option label="停用" value="inactive" />
          </el-select>
        </el-form-item>
        <el-form-item label="开始日期">
          <el-date-picker
            v-model="assignForm.start_date"
            type="date"
            placeholder="选择开始日期"
            style="width: 100%"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
          />
        </el-form-item>
        <el-form-item label="结束日期">
          <el-date-picker
            v-model="assignForm.end_date"
            type="date"
            placeholder="选择结束日期"
            style="width: 100%"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
          />
        </el-form-item>
        <el-form-item label="学生数限制">
          <el-input-number 
            v-model="assignForm.max_students" 
            :min="0" 
            placeholder="0表示无限制"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="备注">
          <el-input
            v-model="assignForm.remarks"
            type="textarea"
            :rows="3"
            placeholder="请输入备注信息"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="assignDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleAssignSubmit" :loading="submitting">确定</el-button>
      </template>
    </el-dialog>

    <!-- 编辑对话框 -->
    <el-dialog
      v-model="editDialogVisible"
      title="编辑学校课程配置"
      width="600px"
      :close-on-click-modal="false"
    >
      <el-form :model="editForm" :rules="editRules" ref="editFormRef" label-width="100px">
        <el-form-item label="学校">
          <el-input v-model="editForm.school_name" disabled />
        </el-form-item>
        <el-form-item label="课程">
          <el-input v-model="editForm.course_title" disabled />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="editForm.status" placeholder="请选择状态" style="width: 100%">
            <el-option label="启用" value="active" />
            <el-option label="停用" value="inactive" />
            <el-option label="归档" value="archived" />
          </el-select>
        </el-form-item>
        <el-form-item label="开始日期">
          <el-date-picker
            v-model="editForm.start_date"
            type="date"
            placeholder="选择开始日期"
            style="width: 100%"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
          />
        </el-form-item>
        <el-form-item label="结束日期">
          <el-date-picker
            v-model="editForm.end_date"
            type="date"
            placeholder="选择结束日期"
            style="width: 100%"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
          />
        </el-form-item>
        <el-form-item label="学生数限制">
          <el-input-number 
            v-model="editForm.max_students" 
            :min="0" 
            placeholder="0表示无限制"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="当前学生数">
          <el-input v-model="editForm.current_students" disabled />
        </el-form-item>
        <el-form-item label="备注">
          <el-input
            v-model="editForm.remarks"
            type="textarea"
            :rows="3"
            placeholder="请输入备注信息"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleEditSubmit" :loading="submitting">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Search, Refresh, Edit, Delete } from '@element-plus/icons-vue'
import { 
  getAllSchoolCourses, 
  assignCourseToSchool, 
  updateSchoolCourse, 
  removeSchoolCourse,
  getSchools
} from '@/api/schoolCourses'
import { getCourses } from '@/api/admin'

const loading = ref(false)
const submitting = ref(false)
const assignDialogVisible = ref(false)
const editDialogVisible = ref(false)
const assignFormRef = ref(null)
const editFormRef = ref(null)

const schoolCourses = ref([])
const schools = ref([])
const courses = ref([])

const filters = reactive({
  schoolId: null,
  status: null
})

const pagination = reactive({
  page: 1,
  pageSize: 20,
  total: 0
})

const assignForm = reactive({
  school_id: null,
  course_id: null,
  status: 'active',
  start_date: null,
  end_date: null,
  max_students: null,
  remarks: ''
})

const editForm = reactive({
  uuid: '',
  school_name: '',
  course_title: '',
  status: 'active',
  start_date: null,
  end_date: null,
  max_students: null,
  current_students: 0,
  remarks: ''
})

const assignRules = {
  school_id: [{ required: true, message: '请选择学校', trigger: 'change' }],
  course_id: [{ required: true, message: '请选择课程', trigger: 'change' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }]
}

const editRules = {
  status: [{ required: true, message: '请选择状态', trigger: 'change' }]
}

// 加载学校课程数据
const loadSchoolCourses = async () => {
  try {
    loading.value = true
    const params = {
      skip: (pagination.page - 1) * pagination.pageSize,
      limit: pagination.pageSize
    }
    
    if (filters.schoolId) {
      params.school_id = filters.schoolId
    }
    if (filters.status) {
      params.status = filters.status
    }
    
    const response = await getAllSchoolCourses(params)
    
    if (response.data && response.data.code === 0) {
      const data = response.data.data || {}
      const items = data.items || []
      
      // 处理数据，将嵌套的 school 和 course 对象扁平化
      schoolCourses.value = items.map(item => ({
        ...item,
        school_name: item.school?.school_name || '-',
        course_title: item.course?.title || '-'
      }))
      
      pagination.total = data.total || 0
    }
  } catch (error) {
    console.error('加载学校课程数据失败:', error)
    ElMessage.error(error.response?.data?.message || '加载数据失败')
  } finally {
    loading.value = false
  }
}

// 加载学校列表
const loadSchools = async () => {
  try {
    const response = await getSchools()
    if (response.data && response.data.code === 0) {
      const data = response.data.data || {}
      schools.value = data.items || []
    }
  } catch (error) {
    console.error('加载学校列表失败:', error)
  }
}

// 加载课程列表
const loadCourses = async () => {
  try {
    // getCourses 返回的已经是处理过的数据（response.data.data）
    const data = await getCourses()
    // 检查数据格式，可能是数组或包含 items 的对象
    if (Array.isArray(data)) {
      courses.value = data
    } else if (data && data.items) {
      courses.value = data.items
    } else {
      courses.value = []
    }
  } catch (error) {
    console.error('加载课程列表失败:', error)
    courses.value = []
  }
}

// 打开分配课程对话框
const handleAssignCourse = () => {
  resetAssignForm()
  assignDialogVisible.value = true
}

// 重置分配表单
const resetAssignForm = () => {
  Object.assign(assignForm, {
    school_id: null,
    course_id: null,
    status: 'active',
    start_date: null,
    end_date: null,
    max_students: null,
    remarks: ''
  })
  assignFormRef.value?.resetFields()
}

// 提交分配
const handleAssignSubmit = async () => {
  if (!assignFormRef.value) return
  
  try {
    await assignFormRef.value.validate()
    
    submitting.value = true
    
    const data = {
      school_id: assignForm.school_id,
      course_id: assignForm.course_id,
      status: assignForm.status,
      start_date: assignForm.start_date || undefined,
      end_date: assignForm.end_date || undefined,
      max_students: assignForm.max_students || undefined,
      remarks: assignForm.remarks || undefined
    }
    
    const response = await assignCourseToSchool(data)
    
    if (response.data && response.data.code === 0) {
      ElMessage.success('分配成功！')
      assignDialogVisible.value = false
      loadSchoolCourses()
    }
  } catch (error) {
    if (error.errors) {
      // 表单验证错误
      return
    }
    console.error('分配课程失败:', error)
    ElMessage.error(error.response?.data?.message || '分配失败')
  } finally {
    submitting.value = false
  }
}

// 打开编辑对话框
const handleEdit = (row) => {
  Object.assign(editForm, {
    uuid: row.uuid,
    school_name: row.school_name,
    course_title: row.course_title,
    status: row.status,
    start_date: row.start_date,
    end_date: row.end_date,
    max_students: row.max_students,
    current_students: row.current_students || 0,
    remarks: row.remarks || ''
  })
  editDialogVisible.value = true
}

// 提交编辑
const handleEditSubmit = async () => {
  if (!editFormRef.value) return
  
  try {
    await editFormRef.value.validate()
    
    submitting.value = true
    
    const data = {
      status: editForm.status,
      start_date: editForm.start_date || undefined,
      end_date: editForm.end_date || undefined,
      max_students: editForm.max_students || undefined,
      remarks: editForm.remarks || undefined
    }
    
    const response = await updateSchoolCourse(editForm.uuid, data)
    
    if (response.data && response.data.code === 0) {
      ElMessage.success('更新成功！')
      editDialogVisible.value = false
      loadSchoolCourses()
    }
  } catch (error) {
    if (error.errors) {
      return
    }
    console.error('更新失败:', error)
    ElMessage.error(error.response?.data?.message || '更新失败')
  } finally {
    submitting.value = false
  }
}

// 移除课程分配
const handleRemove = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要移除学校"${row.school_name}"对课程"${row.course_title}"的访问权限吗？`,
      '确认移除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    loading.value = true
    const response = await removeSchoolCourse(row.uuid)
    
    if (response.data && response.data.code === 0) {
      ElMessage.success('移除成功！')
      loadSchoolCourses()
    }
  } catch (error) {
    if (error === 'cancel') {
      return
    }
    console.error('移除失败:', error)
    ElMessage.error(error.response?.data?.message || '移除失败')
  } finally {
    loading.value = false
  }
}

// 筛选处理
const handleFilter = () => {
  pagination.page = 1
  loadSchoolCourses()
}

// 重置筛选
const resetFilters = () => {
  filters.schoolId = null
  filters.status = null
  pagination.page = 1
  loadSchoolCourses()
}

// 分页处理
const handleSizeChange = (size) => {
  pagination.pageSize = size
  pagination.page = 1
  loadSchoolCourses()
}

const handlePageChange = (page) => {
  pagination.page = page
  loadSchoolCourses()
}

// 状态相关方法
const getStatusType = (status) => {
  const types = {
    active: 'success',
    inactive: 'warning',
    archived: 'info'
  }
  return types[status] || 'info'
}

const getStatusText = (status) => {
  const texts = {
    active: '启用',
    inactive: '停用',
    archived: '归档'
  }
  return texts[status] || status
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
  loadSchoolCourses()
  loadSchools()
  loadCourses()
})
</script>

<style scoped>
.admin-school-courses {
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

.pagination-container {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}
</style>
