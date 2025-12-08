<template>
  <div class="admin-assessments-page">
    <el-card class="filter-card" shadow="never">
      <el-form :model="searchForm" inline>
        <el-form-item label="评价对象">
          <el-select v-model="searchForm.target_type" placeholder="请选择" clearable>
            <el-option label="项目" value="project" />
            <el-option label="任务" value="task" />
            <el-option label="成果" value="output" />
            <el-option label="学生" value="student" />
          </el-select>
        </el-form-item>
        <el-form-item label="评价人角色">
          <el-select v-model="searchForm.assessor_role" placeholder="请选择" clearable>
            <el-option label="教师" value="teacher" />
            <el-option label="学生互评" value="student" />
            <el-option label="专家" value="expert" />
            <el-option label="自评" value="self" />
          </el-select>
        </el-form-item>
        <el-form-item label="评价类型">
          <el-select v-model="searchForm.assessment_type" placeholder="请选择" clearable>
            <el-option label="过程性评价" value="formative" />
            <el-option label="总结性评价" value="summative" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :icon="Search" @click="handleSearch">查询</el-button>
          <el-button :icon="Refresh" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>评价列表</span>
          <el-button type="primary" :icon="Plus" @click="handleCreate">新建评价</el-button>
        </div>
      </template>

      <el-table :data="assessments" style="width: 100%" v-loading="loading">
        <el-table-column type="expand">
          <template #default="{ row }">
            <div class="expand-content">
              <div class="expand-section">
                <h4>评价维度</h4>
                <el-table :data="row.dimensions" size="small">
                  <el-table-column prop="dimension" label="维度" width="120" />
                  <el-table-column prop="score" label="得分" width="80" />
                  <el-table-column prop="weight" label="权重" width="80">
                    <template #default="{ row: dim }">{{ (dim.weight * 100).toFixed(0) }}%</template>
                  </el-table-column>
                  <el-table-column prop="comment" label="评语" />
                </el-table>
              </div>
              <div v-if="row.strengths" class="expand-section">
                <h4>优点</h4>
                <p>{{ row.strengths }}</p>
              </div>
              <div v-if="row.improvements" class="expand-section">
                <h4>改进建议</h4>
                <p>{{ row.improvements }}</p>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="student_name" label="被评学生" width="120" />
        <el-table-column prop="assessor_name" label="评价人" width="120" />
        <el-table-column prop="assessor_role" label="评价角色" width="100">
          <template #default="{ row }">
            <el-tag :type="getRoleType(row.assessor_role)" size="small">
              {{ getRoleText(row.assessor_role) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="target_type" label="评价对象" width="100">
          <template #default="{ row }">
            {{ getTargetTypeText(row.target_type) }}
          </template>
        </el-table-column>
        <el-table-column prop="assessment_type" label="评价类型" width="100">
          <template #default="{ row }">
            <el-tag :type="row.assessment_type === 'formative' ? 'warning' : 'success'" size="small">
              {{ row.assessment_type === 'formative' ? '过程性' : '总结性' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="total_score" label="总分" width="100">
          <template #default="{ row }">
            <span class="score-text">{{ row.total_score }} / {{ row.max_score }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="is_public" label="公开" width="80">
          <template #default="{ row }">
            <el-tag :type="row.is_public ? 'success' : 'info'" size="small">
              {{ row.is_public ? '是' : '否' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="评价时间" width="160" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="handleView(row)">查看</el-button>
            <el-button size="small" type="primary" @click="handleEdit(row)">编辑</el-button>
            <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.size"
        :total="pagination.total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSearch"
        @current-change="handleSearch"
        class="pagination"
      />
    </el-card>

    <!-- 创建/编辑评价对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="800px"
      @close="handleDialogClose"
    >
      <el-form :model="formData" :rules="formRules" ref="formRef" label-width="120px">
        <el-form-item label="被评学生" prop="student_id">
          <el-select v-model="formData.student_id" placeholder="请选择学生" filterable>
            <el-option
              v-for="student in students"
              :key="student.id"
              :label="student.name"
              :value="student.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="评价对象" prop="target_type">
          <el-select v-model="formData.target_type" placeholder="请选择评价对象">
            <el-option label="项目" value="project" />
            <el-option label="任务" value="task" />
            <el-option label="成果" value="output" />
            <el-option label="学生" value="student" />
          </el-select>
        </el-form-item>
        <el-form-item label="评价类型" prop="assessment_type">
          <el-radio-group v-model="formData.assessment_type">
            <el-radio label="formative">过程性评价</el-radio>
            <el-radio label="summative">总结性评价</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="评价模板">
          <el-select v-model="selectedTemplate" placeholder="选择评价模板（可选）" @change="applyTemplate" clearable>
            <el-option
              v-for="template in templates"
              :key="template.uuid"
              :label="template.name"
              :value="template.uuid"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="评价维度" prop="dimensions">
          <el-button size="small" @click="addDimension" style="margin-bottom: 12px;">
            添加维度
          </el-button>
          <div v-for="(dim, index) in formData.dimensions" :key="index" class="dimension-item">
            <el-input v-model="dim.dimension" placeholder="维度名称" style="width: 150px;" />
            <el-input-number v-model="dim.score" :min="0" :max="100" style="width: 120px;" />
            <el-input-number v-model="dim.weight" :min="0" :max="1" :step="0.1" style="width: 120px;" />
            <el-input v-model="dim.comment" placeholder="评语" style="flex: 1;" />
            <el-button type="danger" :icon="Delete" circle size="small" @click="removeDimension(index)" />
          </div>
        </el-form-item>
        <el-form-item label="总分" prop="total_score">
          <el-input-number v-model="formData.total_score" :min="0" :max="formData.max_score" />
          <span style="margin-left: 12px;">/ {{ formData.max_score }}</span>
        </el-form-item>
        <el-form-item label="综合评语" prop="comments">
          <el-input v-model="formData.comments" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="优点">
          <el-input v-model="formData.strengths" type="textarea" :rows="2" />
        </el-form-item>
        <el-form-item label="改进建议">
          <el-input v-model="formData.improvements" type="textarea" :rows="2" />
        </el-form-item>
        <el-form-item label="是否公开">
          <el-switch v-model="formData.is_public" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Search,
  Refresh,
  Plus,
  Delete
} from '@element-plus/icons-vue'
import { getAssessments, createAssessment, deleteAssessment, getAssessmentTemplates } from '@/api/assessment'
import { getUserList } from '@/api/users'

const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const dialogTitle = ref('新建评价')
const formRef = ref(null)
const selectedTemplate = ref('')

const searchForm = reactive({
  target_type: '',
  assessor_role: '',
  assessment_type: ''
})

const pagination = reactive({
  page: 1,
  size: 10,
  total: 0
})

const assessments = ref([])
const students = ref([])
const templates = ref([])

const formData = reactive({
  student_id: '',
  target_type: '',
  assessment_type: 'formative',
  dimensions: [],
  total_score: 0,
  max_score: 100,
  comments: '',
  strengths: '',
  improvements: '',
  is_public: false
})

const formRules = {
  student_id: [{ required: true, message: '请选择被评学生', trigger: 'change' }],
  target_type: [{ required: true, message: '请选择评价对象', trigger: 'change' }],
  dimensions: [{ required: true, message: '请添加评价维度', trigger: 'change' }]
}

const getRoleType = (role) => {
  const types = {
    teacher: 'primary',
    student: 'success',
    expert: 'warning',
    self: 'info'
  }
  return types[role] || 'info'
}

const getRoleText = (role) => {
  const texts = {
    teacher: '教师',
    student: '学生互评',
    expert: '专家',
    self: '自评'
  }
  return texts[role] || role
}

const getTargetTypeText = (type) => {
  const texts = {
    project: '项目',
    task: '任务',
    output: '成果',
    student: '学生'
  }
  return texts[type] || type
}

const handleSearch = () => {
  loadAssessments()
}

const handleReset = () => {
  Object.keys(searchForm).forEach(key => {
    searchForm[key] = ''
  })
  handleSearch()
}

const handleCreate = () => {
  dialogTitle.value = '新建评价'
  resetForm()
  dialogVisible.value = true
}

const handleView = (row) => {
  ElMessage.info('查看详情功能开发中...')
}

const handleEdit = (row) => {
  dialogTitle.value = '编辑评价'
  Object.assign(formData, row)
  dialogVisible.value = true
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除这条评价吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await deleteAssessment(row.uuid)
    ElMessage.success('删除成功')
    handleSearch()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
      ElMessage.error(error.response?.data?.detail || '删除失败')
    }
  }
}

const addDimension = () => {
  formData.dimensions.push({
    dimension: '',
    score: 0,
    weight: 0.2,
    comment: ''
  })
}

const removeDimension = (index) => {
  formData.dimensions.splice(index, 1)
}

const applyTemplate = (templateUuid) => {
  if (!templateUuid) return
  const template = templates.value.find(t => t.uuid === templateUuid)
  if (template) {
    formData.dimensions = JSON.parse(JSON.stringify(template.dimensions))
  }
}

const handleSubmit = async () => {
  try {
    await formRef.value.validate()
    submitting.value = true
    
    // 计算总分
    formData.total_score = formData.dimensions.reduce((sum, dim) => {
      return sum + (dim.score * dim.weight)
    }, 0)
    
    await createAssessment(formData)
    ElMessage.success('保存成功')
    dialogVisible.value = false
    handleSearch()
  } catch (error) {
    console.error('提交失败:', error)
    ElMessage.error(error.response?.data?.detail || '提交失败')
  } finally {
    submitting.value = false
  }
}

const handleDialogClose = () => {
  formRef.value?.resetFields()
  resetForm()
}

const resetForm = () => {
  Object.assign(formData, {
    student_id: '',
    target_type: '',
    assessment_type: 'formative',
    dimensions: [],
    total_score: 0,
    max_score: 100,
    comments: '',
    strengths: '',
    improvements: '',
    is_public: false
  })
  selectedTemplate.value = ''
}

const loadAssessments = async () => {
  loading.value = true
  try {
    const response = await getAssessments({
      skip: (pagination.page - 1) * pagination.size,
      limit: pagination.size,
      target_type: searchForm.target_type || undefined,
      assessor_role: searchForm.assessor_role || undefined,
      assessment_type: searchForm.assessment_type || undefined
    })
    
    if (response && response.data) {
      assessments.value = response.data.items || []
      pagination.total = response.data.total || 0
    }
  } catch (error) {
    console.error('加载评价列表失败:', error)
    ElMessage.error(error.response?.data?.detail || '加载数据失败')
    assessments.value = []
    pagination.total = 0
  } finally {
    loading.value = false
  }
}

const loadStudents = async () => {
  try {
    const response = await getUserList({ role: 'student', page_size: 1000 })
    if (response) {
      students.value = response.items || response || []
    }
  } catch (error) {
    console.error('加载学生列表失败:', error)
    students.value = []
  }
}

const loadTemplates = async () => {
  try {
    const response = await getAssessmentTemplates()
    if (response && response.data) {
      templates.value = response.data.items || response.data || []
    }
  } catch (error) {
    console.error('加载评价模板失败:', error)
    templates.value = []
  }
}

onMounted(() => {
  loadAssessments()
  loadStudents()
  loadTemplates()
})
</script>

<style scoped>
.admin-assessments-page {
  padding: 0;
}

.filter-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.expand-content {
  padding: 20px;
  background: #f5f7fa;
}

.expand-section {
  margin-bottom: 20px;
}

.expand-section:last-child {
  margin-bottom: 0;
}

.expand-section h4 {
  margin: 0 0 12px 0;
  font-size: 14px;
  font-weight: 600;
  color: #303133;
}

.expand-section p {
  margin: 0;
  line-height: 1.6;
  color: #606266;
}

.score-text {
  font-weight: 600;
  color: #67c23a;
}

.pagination {
  margin-top: 20px;
  justify-content: flex-end;
}

.dimension-item {
  display: flex;
  gap: 12px;
  margin-bottom: 12px;
  align-items: center;
}
</style>
