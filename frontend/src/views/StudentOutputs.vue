<template>
  <div class="student-outputs-container">
    <el-card class="header-card">
      <div class="page-header">
        <div>
          <h2>项目成果</h2>
          <p class="subtitle">查看和管理我的所有项目成果</p>
        </div>
        <el-button type="primary" :icon="Plus" @click="handleAddOutput">
          提交新成果
        </el-button>
      </div>
    </el-card>

    <!-- 筛选器 -->
    <el-card class="filter-card">
      <el-form :inline="true" :model="filters">
        <el-form-item label="成果类型">
          <el-select v-model="filters.outputType" placeholder="全部类型" clearable>
            <el-option label="全部" value="" />
            <el-option label="报告" value="report" />
            <el-option label="代码" value="code" />
            <el-option label="设计" value="design" />
            <el-option label="视频" value="video" />
            <el-option label="演示文稿" value="presentation" />
            <el-option label="模型" value="model" />
            <el-option label="数据集" value="dataset" />
            <el-option label="其他" value="other" />
          </el-select>
        </el-form-item>
        <el-form-item label="所属项目">
          <el-select v-model="filters.projectId" placeholder="全部项目" clearable>
            <el-option label="全部项目" value="" />
            <el-option
              v-for="project in projects"
              :key="project.id"
              :label="project.title"
              :value="project.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadOutputs">查询</el-button>
          <el-button @click="resetFilters">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 成果列表 -->
    <div class="outputs-grid">
      <el-card
        v-for="output in outputs"
        :key="output.id"
        class="output-card"
        shadow="hover"
      >
        <div class="output-thumbnail" @click="handleViewOutput(output)">
          <img v-if="output.thumbnail" :src="output.thumbnail" alt="成果缩略图" />
          <div v-else class="placeholder-thumbnail">
            <el-icon :size="60"><Document /></el-icon>
          </div>
          <div class="output-type-badge">
            {{ getOutputTypeLabel(output.output_type) }}
          </div>
        </div>
        
        <div class="output-content">
          <h3 class="output-title">{{ output.title }}</h3>
          <p class="output-description">{{ output.description }}</p>
          
          <div class="output-meta">
            <el-tag size="small">{{ output.project_name }}</el-tag>
            <span class="output-date">
              {{ formatDate(output.created_at) }}
            </span>
          </div>
          
          <div class="output-stats">
            <span>
              <el-icon><View /></el-icon>
              {{ output.view_count || 0 }}
            </span>
            <span>
              <el-icon><Star /></el-icon>
              {{ output.like_count || 0 }}
            </span>
          </div>
          
          <div class="output-actions">
            <el-button size="small" text @click="handleViewOutput(output)">
              查看详情
            </el-button>
            <el-button size="small" text type="primary" @click="handleEditOutput(output)">
              编辑
            </el-button>
            <el-button
              size="small"
              text
              type="danger"
              @click="handleDeleteOutput(output)"
            >
              删除
            </el-button>
          </div>
        </div>
      </el-card>
    </div>

    <!-- 空状态 -->
    <el-empty
      v-if="outputs.length === 0 && !loading"
      description="还没有提交任何成果"
    >
      <el-button type="primary" @click="handleAddOutput">提交第一个成果</el-button>
    </el-empty>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading-container">
      <el-skeleton :rows="6" animated />
    </div>

    <!-- 提交/编辑成果对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="800px"
      @close="handleDialogClose"
    >
      <el-form
        ref="outputFormRef"
        :model="outputForm"
        :rules="outputFormRules"
        label-width="100px"
      >
        <el-form-item label="成果标题" prop="title">
          <el-input v-model="outputForm.title" placeholder="请输入成果标题" />
        </el-form-item>
        
        <el-form-item label="成果类型" prop="output_type">
          <el-select v-model="outputForm.output_type" placeholder="选择成果类型">
            <el-option label="报告" value="report" />
            <el-option label="代码" value="code" />
            <el-option label="设计" value="design" />
            <el-option label="视频" value="video" />
            <el-option label="演示文稿" value="presentation" />
            <el-option label="模型" value="model" />
            <el-option label="数据集" value="dataset" />
            <el-option label="其他" value="other" />
          </el-select>
        </el-form-item>
        
        <el-form-item label="所属项目" prop="project_id">
          <el-select v-model="outputForm.project_id" placeholder="选择项目">
            <el-option
              v-for="project in projects"
              :key="project.id"
              :label="project.title"
              :value="project.id"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item label="成果说明" prop="description">
          <el-input
            v-model="outputForm.description"
            type="textarea"
            :rows="4"
            placeholder="请描述你的成果内容和特点"
          />
        </el-form-item>
        
        <el-form-item label="代码仓库">
          <el-input
            v-model="outputForm.repo_url"
            placeholder="如：https://github.com/username/repo"
          />
        </el-form-item>
        
        <el-form-item label="演示地址">
          <el-input
            v-model="outputForm.demo_url"
            placeholder="在线演示地址或视频链接"
          />
        </el-form-item>
        
        <el-form-item label="文件上传">
          <el-upload
            class="upload-demo"
            drag
            :action="uploadUrl"
            :headers="uploadHeaders"
            :on-success="handleUploadSuccess"
            :on-error="handleUploadError"
            multiple
          >
            <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
            <div class="el-upload__text">
              将文件拖到此处，或<em>点击上传</em>
            </div>
            <template #tip>
              <div class="el-upload__tip">
                支持上传文档、图片、视频等文件，单个文件不超过100MB
              </div>
            </template>
          </el-upload>
        </el-form-item>
        
        <el-form-item label="公开展示">
          <el-switch v-model="outputForm.is_public" />
          <span class="form-tip">开启后，其他同学可以查看你的成果</span>
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmitOutput" :loading="submitting">
          提交
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Plus,
  Document,
  View,
  Star,
  UploadFilled
} from '@element-plus/icons-vue'

const loading = ref(false)
const dialogVisible = ref(false)
const submitting = ref(false)
const outputFormRef = ref(null)

const filters = reactive({
  outputType: '',
  projectId: ''
})

const outputs = ref([])
const projects = ref([])

const outputForm = reactive({
  title: '',
  output_type: '',
  project_id: '',
  description: '',
  repo_url: '',
  demo_url: '',
  file_url: '',
  is_public: false
})

const outputFormRules = {
  title: [{ required: true, message: '请输入成果标题', trigger: 'blur' }],
  output_type: [{ required: true, message: '请选择成果类型', trigger: 'change' }],
  project_id: [{ required: true, message: '请选择所属项目', trigger: 'change' }],
  description: [{ required: true, message: '请输入成果说明', trigger: 'blur' }]
}

const dialogTitle = computed(() => {
  return outputForm.id ? '编辑成果' : '提交新成果'
})

const uploadUrl = computed(() => {
  return `${import.meta.env.VITE_API_BASE_URL}/api/upload`
})

const uploadHeaders = computed(() => {
  const token = localStorage.getItem('access_token') || localStorage.getItem('student_access_token')
  return {
    Authorization: `Bearer ${token}`
  }
})

const getOutputTypeLabel = (type) => {
  const typeMap = {
    report: '报告',
    code: '代码',
    design: '设计',
    video: '视频',
    presentation: '演示文稿',
    model: '模型',
    dataset: '数据集',
    other: '其他'
  }
  return typeMap[type] || type
}

const formatDate = (date) => {
  if (!date) return ''
  return new Date(date).toLocaleDateString('zh-CN')
}

const loadOutputs = async () => {
  loading.value = true
  try {
    // TODO: 调用API获取成果列表
    await new Promise(resolve => setTimeout(resolve, 1000))
    outputs.value = []
    ElMessage.info('成果列表加载功能开发中...')
  } catch (error) {
    ElMessage.error('加载成果列表失败')
    console.error(error)
  } finally {
    loading.value = false
  }
}

const loadProjects = async () => {
  try {
    // TODO: 调用API获取项目列表
    projects.value = []
  } catch (error) {
    console.error('加载项目列表失败:', error)
  }
}

const resetFilters = () => {
  filters.outputType = ''
  filters.projectId = ''
  loadOutputs()
}

const handleAddOutput = () => {
  Object.keys(outputForm).forEach(key => {
    if (key === 'is_public') {
      outputForm[key] = false
    } else {
      outputForm[key] = ''
    }
  })
  delete outputForm.id
  dialogVisible.value = true
}

const handleViewOutput = (output) => {
  ElMessage.info('查看成果详情功能开发中...')
}

const handleEditOutput = (output) => {
  Object.assign(outputForm, output)
  dialogVisible.value = true
}

const handleDeleteOutput = async (output) => {
  try {
    await ElMessageBox.confirm(
      '确定要删除这个成果吗？删除后无法恢复。',
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    // TODO: 调用API删除成果
    ElMessage.success('删除成功')
    loadOutputs()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

const handleSubmitOutput = async () => {
  if (!outputFormRef.value) return
  
  await outputFormRef.value.validate(async (valid) => {
    if (valid) {
      submitting.value = true
      try {
        // TODO: 调用API提交成果
        await new Promise(resolve => setTimeout(resolve, 1000))
        ElMessage.success(outputForm.id ? '更新成功' : '提交成功')
        dialogVisible.value = false
        loadOutputs()
      } catch (error) {
        ElMessage.error('提交失败')
        console.error(error)
      } finally {
        submitting.value = false
      }
    }
  })
}

const handleDialogClose = () => {
  if (outputFormRef.value) {
    outputFormRef.value.resetFields()
  }
}

const handleUploadSuccess = (response) => {
  if (response.code === 200) {
    outputForm.file_url = response.data.url
    ElMessage.success('文件上传成功')
  } else {
    ElMessage.error(response.message || '文件上传失败')
  }
}

const handleUploadError = () => {
  ElMessage.error('文件上传失败')
}

onMounted(() => {
  loadOutputs()
  loadProjects()
})
</script>

<style scoped>
.student-outputs-container {
  padding: 20px;
}

.header-card {
  margin-bottom: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.page-header h2 {
  margin: 0 0 8px 0;
  font-size: 24px;
  color: #1e293b;
}

.subtitle {
  margin: 0;
  color: #64748b;
  font-size: 14px;
}

.filter-card {
  margin-bottom: 20px;
}

.outputs-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 20px;
  margin-bottom: 20px;
}

.output-card {
  cursor: pointer;
  transition: all 0.3s;
}

.output-card:hover {
  transform: translateY(-4px);
}

.output-thumbnail {
  width: 100%;
  height: 180px;
  position: relative;
  overflow: hidden;
  border-radius: 8px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  margin-bottom: 16px;
}

.output-thumbnail img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.placeholder-thumbnail {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  opacity: 0.8;
}

.output-type-badge {
  position: absolute;
  top: 12px;
  right: 12px;
  background: rgba(255, 255, 255, 0.95);
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;
  color: #1e293b;
}

.output-content {
  padding: 0 4px;
}

.output-title {
  margin: 0 0 8px 0;
  font-size: 16px;
  font-weight: 600;
  color: #1e293b;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.output-description {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #64748b;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.output-meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  font-size: 12px;
  color: #94a3b8;
}

.output-stats {
  display: flex;
  gap: 16px;
  margin-bottom: 12px;
  font-size: 14px;
  color: #64748b;
}

.output-stats span {
  display: flex;
  align-items: center;
  gap: 4px;
}

.output-actions {
  display: flex;
  gap: 8px;
  padding-top: 12px;
  border-top: 1px solid #e2e8f0;
}

.loading-container {
  padding: 20px;
}

.form-tip {
  margin-left: 12px;
  font-size: 12px;
  color: #64748b;
}

:deep(.el-upload-dragger) {
  padding: 40px;
}
</style>
