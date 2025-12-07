<template>
  <div class="admin-resources">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>资料管理</span>
          <div>
            <el-select v-model="selectedCourseId" placeholder="选择课程" style="width: 200px; margin-right: 10px;" @change="loadUnits">
              <el-option
                v-for="course in courses"
                :key="course.id"
                :label="course.title"
                :value="course.id"
              />
            </el-select>
            <el-select v-model="selectedUnitId" placeholder="选择单元" style="width: 200px; margin-right: 10px;" @change="loadResources" :disabled="!selectedCourseId">
              <el-option
                v-for="unit in units"
                :key="unit.id"
                :label="unit.title"
                :value="unit.id"
              />
            </el-select>
            <el-button type="primary" @click="handleCreate" :disabled="!selectedUnitId">创建资料</el-button>
          </div>
        </div>
      </template>

      <el-table :data="resources" v-loading="loading" stripe v-if="selectedUnitId">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="title" label="资料标题" />
        <el-table-column prop="type" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="getTypeType(row.type)">
              {{ getTypeText(row.type) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="url" label="URL/路径" />
        <el-table-column prop="order" label="顺序" width="100" />
        <el-table-column prop="created_at" label="创建时间" width="180" />
        <el-table-column label="操作" width="250" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="handleEdit(row)">编辑</el-button>
            <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      
      <el-empty v-else description="请先选择课程和单元" />
    </el-card>

    <!-- 创建/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="700px"
    >
      <el-form :model="formData" :rules="formRules" ref="formRef" label-width="100px">
        <el-form-item label="资料类型" prop="type">
          <el-select v-model="formData.type" placeholder="请选择资料类型" @change="handleTypeChange">
            <el-option label="视频" value="video" />
            <el-option label="文档" value="document" />
            <el-option label="链接" value="link" />
          </el-select>
        </el-form-item>
        <el-form-item label="资料标题" prop="title">
          <el-input v-model="formData.title" placeholder="请输入资料标题" />
        </el-form-item>
        <el-form-item label="资料描述" prop="description">
          <el-input
            v-model="formData.description"
            type="textarea"
            :rows="3"
            placeholder="请输入资料描述"
          />
        </el-form-item>
        <el-form-item v-if="formData.type === 'link'" label="链接URL" prop="url">
          <el-input v-model="formData.url" placeholder="请输入链接URL" />
        </el-form-item>
        <el-form-item v-if="formData.type === 'video'" label="视频ID" prop="video_id">
          <el-input v-model="formData.video_id" placeholder="请输入视频ID" />
        </el-form-item>
        <el-form-item v-if="formData.type === 'video'" label="视频封面" prop="video_cover_url">
          <el-input v-model="formData.video_cover_url" placeholder="请输入视频封面URL" />
        </el-form-item>
        <el-form-item v-if="formData.type === 'document'" label="文档内容" prop="content">
          <el-input
            v-model="formData.content"
            type="textarea"
            :rows="6"
            placeholder="请输入文档内容（Markdown格式）"
          />
        </el-form-item>
        <el-form-item v-if="formData.type === 'document' || formData.type === 'video'" label="上传文件">
          <el-upload
            :action="uploadUrl"
            :before-upload="beforeUpload"
            :on-success="handleUploadSuccess"
            :on-error="handleUploadError"
            :show-file-list="false"
          >
            <el-button type="primary">选择文件</el-button>
            <template #tip>
              <div class="el-upload__tip">
                支持 {{ formData.type === 'video' ? 'MP4, AVI, MOV' : 'PDF, DOC, DOCX, TXT, MD' }} 格式
              </div>
            </template>
          </el-upload>
        </el-form-item>
        <el-form-item label="顺序" prop="order">
          <el-input-number v-model="formData.order" :min="0" />
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
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getCourses } from '@/api/admin'
import { getUnits } from '@/api/admin'
import { getResources, createResource, updateResource, deleteResource, uploadResourceFile } from '@/api/admin'

const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const dialogTitle = ref('创建资料')
const formRef = ref(null)
const courses = ref([])
const units = ref([])
const resources = ref([])
const selectedCourseId = ref(null)
const selectedUnitId = ref(null)
const editingId = ref(null)

const formData = reactive({
  type: 'document',
  title: '',
  description: '',
  url: '',
  content: '',
  video_id: '',
  video_cover_url: '',
  order: 0
})

const formRules = {
  title: [{ required: true, message: '请输入资料标题', trigger: 'blur' }],
  type: [{ required: true, message: '请选择资料类型', trigger: 'change' }]
}

const uploadUrl = computed(() => {
  if (!selectedUnitId.value) return ''
  return `/api/v1/admin/resources/upload?unit_id=${selectedUnitId.value}&file_type=${formData.type}`
})

const getTypeType = (type) => {
  const types = {
    video: 'danger',
    document: 'success',
    link: 'info'
  }
  return types[type] || ''
}

const getTypeText = (type) => {
  const texts = {
    video: '视频',
    document: '文档',
    link: '链接'
  }
  return texts[type] || type
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
  if (!selectedCourseId.value) return
  
  try {
    const data = await getUnits(selectedCourseId.value)
    units.value = Array.isArray(data) ? data : []
    selectedUnitId.value = null
    resources.value = []
  } catch (error) {
    ElMessage.error('加载单元列表失败')
  }
}

const loadResources = async () => {
  if (!selectedUnitId.value) return
  
  loading.value = true
  try {
    const data = await getResources(selectedUnitId.value)
    resources.value = Array.isArray(data) ? data : []
  } catch (error) {
    ElMessage.error('加载资料列表失败')
  } finally {
    loading.value = false
  }
}

const handleTypeChange = () => {
  // 切换类型时清空相关字段
  formData.url = ''
  formData.content = ''
  formData.video_id = ''
  formData.video_cover_url = ''
}

const handleCreate = () => {
  editingId.value = null
  dialogTitle.value = '创建资料'
  Object.assign(formData, {
    type: 'document',
    title: '',
    description: '',
    url: '',
    content: '',
    video_id: '',
    video_cover_url: '',
    order: 0
  })
  dialogVisible.value = true
}

const handleEdit = (row) => {
  editingId.value = row.id
  dialogTitle.value = '编辑资料'
  Object.assign(formData, {
    type: row.type,
    title: row.title,
    description: row.description || '',
    url: row.url || '',
    content: row.content || '',
    video_id: row.video_id || '',
    video_cover_url: row.video_cover_url || '',
    order: row.order || 0
  })
  dialogVisible.value = true
}

const beforeUpload = (file) => {
  // 文件上传前的验证
  return true
}

const handleUploadSuccess = (response) => {
  if (response.data && response.data.url) {
    if (formData.type === 'document') {
      formData.url = response.data.url
    } else if (formData.type === 'video') {
      formData.url = response.data.url
    }
    ElMessage.success('文件上传成功')
  }
}

const handleUploadError = () => {
  ElMessage.error('文件上传失败')
}

const handleSubmit = async () => {
  if (!formRef.value) return
  
  try {
    const valid = await formRef.value.validate()
    if (!valid) return
    
    submitting.value = true
    
    const submitData = {
      ...formData,
      unit_id: selectedUnitId.value
    }
    
    if (editingId.value) {
      await updateResource(editingId.value, formData)
      ElMessage.success('资料更新成功')
    } else {
      await createResource(submitData)
      ElMessage.success('资料创建成功')
    }
    
    dialogVisible.value = false
    loadResources()
  } catch (error) {
    ElMessage.error(error.message || '操作失败')
  } finally {
    submitting.value = false
  }
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除该资料吗？', '提示', {
      type: 'warning'
    })
    
    await deleteResource(row.id)
    ElMessage.success('删除成功')
    loadResources()
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
.admin-resources {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
