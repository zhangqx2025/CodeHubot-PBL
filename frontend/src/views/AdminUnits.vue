<template>
  <div class="admin-units">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>学习单元管理</span>
          <div>
            <el-select v-model="selectedCourseUuid" placeholder="选择课程" style="width: 200px; margin-right: 10px;" @change="loadUnits">
              <el-option
                v-for="course in courses"
                :key="course.uuid"
                :label="course.title"
                :value="course.uuid"
              />
            </el-select>
            <el-button type="primary" @click="handleCreate" :disabled="!selectedCourseUuid">创建单元</el-button>
          </div>
        </div>
      </template>

      <el-table :data="units" v-loading="loading" stripe v-if="selectedCourseUuid">
        <el-table-column prop="uuid" label="UUID" width="180" />
        <el-table-column prop="title" label="单元标题" />
        <el-table-column prop="order" label="顺序" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="handleEdit(row)">编辑</el-button>
            <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      
      <el-empty v-else description="请先选择课程" />
    </el-card>

    <!-- 创建/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="600px"
    >
      <el-form :model="formData" :rules="formRules" ref="formRef" label-width="100px">
        <el-form-item label="单元标题" prop="title">
          <el-input v-model="formData.title" placeholder="请输入单元标题" />
        </el-form-item>
        <el-form-item label="单元描述" prop="description">
          <el-input
            v-model="formData.description"
            type="textarea"
            :rows="4"
            placeholder="请输入单元描述"
          />
        </el-form-item>
        <el-form-item label="顺序" prop="order">
          <el-input-number v-model="formData.order" :min="0" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="formData.status" placeholder="请选择状态">
            <el-option label="锁定" value="locked" />
            <el-option label="可用" value="available" />
            <el-option label="已完成" value="completed" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getCourses } from '@/api/admin'
import { getUnits, createUnit, updateUnit, deleteUnit } from '@/api/admin'

const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const dialogTitle = ref('创建学习单元')
const formRef = ref(null)
const courses = ref([])
const units = ref([])
const selectedCourseUuid = ref(null)
const editingUuid = ref(null)

const formData = reactive({
  title: '',
  description: '',
  order: 0,
  status: 'locked'
})

const formRules = {
  title: [{ required: true, message: '请输入单元标题', trigger: 'blur' }]
}

const getStatusType = (status) => {
  const types = {
    locked: 'info',
    available: 'success',
    completed: 'warning'
  }
  return types[status] || ''
}

const getStatusText = (status) => {
  const texts = {
    locked: '锁定',
    available: '可用',
    completed: '已完成'
  }
  return texts[status] || status
}

const loadCourses = async () => {
  try {
    const data = await getCourses()
    courses.value = Array.isArray(data) ? data : []
  } catch (error) {
    ElMessage.error('加载课程列表失败')
  }
}

const loadUnits = async () => {
  if (!selectedCourseUuid.value) return
  
  loading.value = true
  try {
    const data = await getUnits(selectedCourseUuid.value)
    units.value = Array.isArray(data) ? data : []
  } catch (error) {
    ElMessage.error('加载单元列表失败')
  } finally {
    loading.value = false
  }
}

const handleCreate = () => {
  editingUuid.value = null
  dialogTitle.value = '创建学习单元'
  Object.assign(formData, {
    title: '',
    description: '',
    order: 0,
    status: 'locked'
  })
  dialogVisible.value = true
}

const handleEdit = (row) => {
  editingUuid.value = row.uuid
  dialogTitle.value = '编辑学习单元'
  Object.assign(formData, {
    title: row.title,
    description: row.description || '',
    order: row.order || 0,
    status: row.status || 'locked'
  })
  dialogVisible.value = true
}

const handleSubmit = async () => {
  if (!formRef.value) return
  
  try {
    const valid = await formRef.value.validate()
    if (!valid) return
    
    submitting.value = true
    
    const submitData = {
      ...formData,
      course_uuid: selectedCourseUuid.value
    }
    
    if (editingUuid.value) {
      await updateUnit(editingUuid.value, formData)
      ElMessage.success('单元更新成功')
    } else {
      await createUnit(submitData)
      ElMessage.success('单元创建成功')
    }
    
    dialogVisible.value = false
    loadUnits()
  } catch (error) {
    ElMessage.error(error.message || '操作失败')
  } finally {
    submitting.value = false
  }
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除该学习单元吗？', '提示', {
      type: 'warning'
    })
    
    await deleteUnit(row.uuid)
    ElMessage.success('删除成功')
    loadUnits()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

onMounted(() => {
  loadCourses()
})
</script>

<style scoped>
.admin-units {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
