<template>
  <div class="admin-tasks">
    <!-- 课程选择 -->
    <div class="toolbar">
      <el-form :inline="true">
        <el-form-item label="课程">
          <el-select 
            v-model="selectedCourseId" 
            placeholder="请选择课程" 
            @change="onCourseChange"
            style="width: 300px"
          >
            <el-option
              v-for="course in courses"
              :key="course.uuid"
              :label="course.title"
              :value="course.uuid"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="学习单元" v-if="selectedCourseId">
          <el-select 
            v-model="selectedUnitId" 
            placeholder="请选择学习单元"
            @change="loadTasks"
            style="width: 300px"
          >
            <el-option
              v-for="unit in units"
              :key="unit.uuid"
              :label="unit.title"
              :value="unit.uuid"
            />
          </el-select>
        </el-form-item>
        <el-form-item v-if="selectedUnitId">
          <el-button type="primary" @click="showCreateDialog">
            <el-icon><Plus /></el-icon>
            创建任务
          </el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 任务列表 -->
    <el-table :data="tasks" border stripe v-loading="loading" v-if="selectedUnitId">
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="title" label="任务标题" min-width="200" />
      <el-table-column label="类型" width="100">
        <template #default="{ row }">
          <el-tag :type="getTaskTypeColor(row.type)">{{ getTaskTypeLabel(row.type) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="难度" width="100">
        <template #default="{ row }">
          <el-tag :type="getDifficultyColor(row.difficulty)">{{ getDifficultyLabel(row.difficulty) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="estimated_time" label="预估时间" width="120" />
      <el-table-column label="操作" width="300" fixed="right">
        <template #default="{ row }">
          <el-button link type="primary" @click="viewTaskProgress(row)">查看提交</el-button>
          <el-button link type="primary" @click="editTask(row)">编辑</el-button>
          <el-button link type="danger" @click="deleteTask(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-empty v-else description="请先选择课程和学习单元" />

    <!-- 创建/编辑任务对话框 -->
    <el-dialog 
      v-model="taskDialogVisible" 
      :title="isEditing ? '编辑任务' : '创建任务'"
      width="700px"
    >
      <el-form :model="taskForm" :rules="taskRules" ref="taskFormRef" label-width="100px">
        <el-form-item label="任务标题" prop="title">
          <el-input v-model="taskForm.title" />
        </el-form-item>
        <el-form-item label="任务描述" prop="description">
          <el-input v-model="taskForm.description" type="textarea" :rows="4" />
        </el-form-item>
        <el-form-item label="任务类型" prop="type">
          <el-select v-model="taskForm.type">
            <el-option label="分析任务" value="analysis" />
            <el-option label="编码任务" value="coding" />
            <el-option label="设计任务" value="design" />
            <el-option label="部署任务" value="deployment" />
          </el-select>
        </el-form-item>
        <el-form-item label="难度" prop="difficulty">
          <el-select v-model="taskForm.difficulty">
            <el-option label="简单" value="easy" />
            <el-option label="中等" value="medium" />
            <el-option label="困难" value="hard" />
          </el-select>
        </el-form-item>
        <el-form-item label="预估时间">
          <el-input v-model="taskForm.estimated_time" placeholder="例如：2小时" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="taskDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveTask">确定</el-button>
      </template>
    </el-dialog>

    <!-- 任务提交列表对话框 -->
    <el-dialog 
      v-model="progressDialogVisible" 
      title="学生提交列表"
      width="900px"
    >
      <el-table :data="progressList" border v-loading="progressLoading">
        <el-table-column prop="user_name" label="学生姓名" width="120" />
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusColor(row.status)">{{ getStatusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="progress" label="进度" width="100">
          <template #default="{ row }">{{ row.progress }}%</template>
        </el-table-column>
        <el-table-column prop="score" label="得分" width="80" />
        <el-table-column prop="feedback" label="反馈" min-width="150" show-overflow-tooltip />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button 
              link 
              type="primary" 
              @click="gradeSubmission(row)"
              :disabled="row.status !== 'review'"
            >
              评分
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-dialog>

    <!-- 评分对话框 -->
    <el-dialog v-model="gradeDialogVisible" title="评分" width="500px">
      <el-form :model="gradeForm" label-width="100px">
        <el-form-item label="得分" required>
          <el-input-number v-model="gradeForm.score" :min="0" :max="100" />
        </el-form-item>
        <el-form-item label="反馈">
          <el-input v-model="gradeForm.feedback" type="textarea" :rows="4" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="gradeDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitGrade">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { getCourses, getUnits } from '@/api/admin'
import {
  getTasks,
  createTask,
  updateTask,
  deleteTask as deleteTaskApi,
  getTaskProgressList,
  gradeTask
} from '@/api/admin'

const loading = ref(false)
const selectedCourseId = ref(null)
const selectedUnitId = ref(null)
const courses = ref([])
const units = ref([])
const tasks = ref([])

// 任务对话框
const taskDialogVisible = ref(false)
const isEditing = ref(false)
const taskFormRef = ref(null)
const taskForm = reactive({
  id: null,
  unit_id: null,
  title: '',
  description: '',
  type: 'analysis',
  difficulty: 'easy',
  estimated_time: ''
})

const taskRules = {
  title: [{ required: true, message: '请输入任务标题', trigger: 'blur' }],
  description: [{ required: true, message: '请输入任务描述', trigger: 'blur' }],
  type: [{ required: true, message: '请选择任务类型', trigger: 'change' }],
  difficulty: [{ required: true, message: '请选择难度', trigger: 'change' }]
}

// 进度对话框
const progressDialogVisible = ref(false)
const progressLoading = ref(false)
const progressList = ref([])
const currentTaskId = ref(null)

// 评分对话框
const gradeDialogVisible = ref(false)
const gradeForm = reactive({
  taskId: null,
  userId: null,
  score: 0,
  feedback: ''
})

// 获取任务类型标签
const getTaskTypeLabel = (type) => {
  const labels = {
    'analysis': '分析',
    'coding': '编码',
    'design': '设计',
    'deployment': '部署'
  }
  return labels[type] || type
}

const getTaskTypeColor = (type) => {
  const colors = {
    'analysis': 'primary',
    'coding': 'success',
    'design': 'warning',
    'deployment': 'danger'
  }
  return colors[type] || 'info'
}

// 获取难度标签
const getDifficultyLabel = (difficulty) => {
  const labels = {
    'easy': '简单',
    'medium': '中等',
    'hard': '困难'
  }
  return labels[difficulty] || difficulty
}

const getDifficultyColor = (difficulty) => {
  const colors = {
    'easy': 'success',
    'medium': 'warning',
    'hard': 'danger'
  }
  return colors[difficulty] || 'info'
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

// 课程变化时加载单元
const onCourseChange = async () => {
  selectedUnitId.value = null
  tasks.value = []
  
  if (!selectedCourseId.value) {
    units.value = []
    return
  }
  
  try {
    units.value = await getUnits(selectedCourseId.value)
  } catch (error) {
    console.error('加载学习单元失败:', error)
    ElMessage.error(error.message || '加载学习单元失败')
  }
}

// 加载任务列表
const loadTasks = async () => {
  if (!selectedUnitId.value) return
  
  loading.value = true
  try {
    tasks.value = await getTasks(selectedUnitId.value)
  } catch (error) {
    console.error('加载任务列表失败:', error)
    ElMessage.error(error.message || '加载任务列表失败')
  } finally {
    loading.value = false
  }
}

// 显示创建对话框
const showCreateDialog = () => {
  isEditing.value = false
  // 找到选中单元的数字ID
  const selectedUnit = units.value.find(u => u.uuid === selectedUnitId.value)
  Object.assign(taskForm, {
    id: null,
    unit_id: selectedUnit ? selectedUnit.id : null,
    title: '',
    description: '',
    type: 'analysis',
    difficulty: 'easy',
    estimated_time: ''
  })
  taskDialogVisible.value = true
}

// 编辑任务
const editTask = (row) => {
  isEditing.value = true
  Object.assign(taskForm, {
    uuid: row.uuid,
    unit_id: row.unit_id,
    title: row.title,
    description: row.description,
    type: row.type,
    difficulty: row.difficulty,
    estimated_time: row.estimated_time || ''
  })
  taskDialogVisible.value = true
}

// 保存任务
const saveTask = async () => {
  await taskFormRef.value.validate()
  
  try {
    if (isEditing.value) {
      await updateTask(taskForm.uuid, taskForm)
      ElMessage.success('任务更新成功')
    } else {
      await createTask(taskForm)
      ElMessage.success('任务创建成功')
    }
    taskDialogVisible.value = false
    loadTasks()
  } catch (error) {
    ElMessage.error(error.message || '操作失败')
  }
}

// 删除任务
const deleteTask = async (row) => {
  await ElMessageBox.confirm('确定要删除该任务吗？', '警告', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
  
  try {
    await deleteTaskApi(row.uuid)
    ElMessage.success('任务删除成功')
    loadTasks()
  } catch (error) {
    ElMessage.error(error.message || '任务删除失败')
  }
}

// 查看任务进度
const viewTaskProgress = async (row) => {
  currentTaskId.value = row.uuid
  progressLoading.value = true
  progressDialogVisible.value = true
  
  try {
    progressList.value = await getTaskProgressList(row.uuid)
  } catch (error) {
    ElMessage.error(error.message || '加载提交列表失败')
  } finally {
    progressLoading.value = false
  }
}

// 评分
const gradeSubmission = (row) => {
  Object.assign(gradeForm, {
    taskId: currentTaskId.value,
    userId: row.user_id,
    score: row.score || 0,
    feedback: row.feedback || ''
  })
  gradeDialogVisible.value = true
}

// 提交评分
const submitGrade = async () => {
  try {
    await gradeTask(gradeForm.taskId, gradeForm.userId, gradeForm.score, gradeForm.feedback)
    ElMessage.success('评分成功')
    gradeDialogVisible.value = false
    viewTaskProgress({ id: currentTaskId.value })
  } catch (error) {
    ElMessage.error(error.message || '评分失败')
  }
}

onMounted(() => {
  loadCourses()
})
</script>

<style scoped>
.admin-tasks {
  background: white;
  padding: 20px;
  border-radius: 4px;
}

.toolbar {
  margin-bottom: 20px;
}
</style>
