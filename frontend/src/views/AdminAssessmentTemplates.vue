<template>
  <div class="admin-templates-page">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>评价模板</span>
          <el-button type="primary" :icon="Plus" @click="handleCreate">新建模板</el-button>
        </div>
      </template>

      <el-table :data="templates" style="width: 100%" v-loading="loading">
        <el-table-column prop="name" label="模板名称" width="200" />
        <el-table-column prop="applicable_to" label="适用对象" width="100">
          <template #default="{ row }">
            {{ getApplicableText(row.applicable_to) }}
          </template>
        </el-table-column>
        <el-table-column prop="grade_level" label="适用学段" width="120" />
        <el-table-column prop="description" label="模板描述" show-overflow-tooltip />
        <el-table-column prop="is_system" label="类型" width="80">
          <template #default="{ row }">
            <el-tag :type="row.is_system ? 'primary' : 'success'" size="small">
              {{ row.is_system ? '系统' : '自定义' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="usage_count" label="使用次数" width="100" />
        <el-table-column prop="is_active" label="状态" width="80">
          <template #default="{ row }">
            <el-switch v-model="row.is_active" @change="handleStatusChange(row)" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="handleView(row)">查看</el-button>
            <el-button size="small" type="primary" @click="handleEdit(row)" :disabled="row.is_system">编辑</el-button>
            <el-button size="small" type="danger" @click="handleDelete(row)" :disabled="row.is_system">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 创建/编辑模板对话框 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="900px">
      <el-form :model="formData" ref="formRef" label-width="120px">
        <el-form-item label="模板名称" prop="name" required>
          <el-input v-model="formData.name" placeholder="请输入模板名称" />
        </el-form-item>
        <el-form-item label="适用对象" prop="applicable_to" required>
          <el-select v-model="formData.applicable_to">
            <el-option label="项目" value="project" />
            <el-option label="任务" value="task" />
            <el-option label="成果" value="output" />
          </el-select>
        </el-form-item>
        <el-form-item label="适用学段" prop="grade_level">
          <el-select v-model="formData.grade_level">
            <el-option label="1-2年级" value="1-2年级" />
            <el-option label="3-4年级" value="3-4年级" />
            <el-option label="5-6年级" value="5-6年级" />
            <el-option label="7-9年级" value="7-9年级" />
            <el-option label="10-12年级" value="10-12年级" />
          </el-select>
        </el-form-item>
        <el-form-item label="模板描述">
          <el-input v-model="formData.description" type="textarea" :rows="2" />
        </el-form-item>
        <el-form-item label="评价维度" required>
          <el-button size="small" @click="addDimension" style="margin-bottom: 12px;">添加维度</el-button>
          <el-table :data="formData.dimensions" border>
            <el-table-column label="维度名称" width="150">
              <template #default="{ row }">
                <el-input v-model="row.name" placeholder="如：技术能力" />
              </template>
            </el-table-column>
            <el-table-column label="权重" width="120">
              <template #default="{ row }">
                <el-input-number v-model="row.weight" :min="0" :max="1" :step="0.05" />
              </template>
            </el-table-column>
            <el-table-column label="评分标准">
              <template #default="{ row }">
                <el-input v-model="row.criteria" placeholder="请描述评分标准" />
              </template>
            </el-table-column>
            <el-table-column label="评价等级" width="200">
              <template #default="{ row }">
                <el-select v-model="row.levels" multiple placeholder="选择等级">
                  <el-option label="优秀" value="优秀" />
                  <el-option label="良好" value="良好" />
                  <el-option label="合格" value="合格" />
                  <el-option label="需改进" value="需改进" />
                </el-select>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="80">
              <template #default="{ $index }">
                <el-button type="danger" :icon="Delete" circle size="small" @click="removeDimension($index)" />
              </template>
            </el-table-column>
          </el-table>
          <div class="weight-sum">权重总和：{{ calculateTotalWeight() }}</div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">保存</el-button>
      </template>
    </el-dialog>

    <!-- 查看模板对话框 -->
    <el-dialog v-model="viewDialogVisible" title="模板详情" width="800px">
      <div v-if="viewData" class="template-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="模板名称">{{ viewData.name }}</el-descriptions-item>
          <el-descriptions-item label="适用对象">{{ getApplicableText(viewData.applicable_to) }}</el-descriptions-item>
          <el-descriptions-item label="适用学段">{{ viewData.grade_level || '-' }}</el-descriptions-item>
          <el-descriptions-item label="使用次数">{{ viewData.usage_count }}</el-descriptions-item>
          <el-descriptions-item label="模板描述" :span="2">{{ viewData.description || '-' }}</el-descriptions-item>
        </el-descriptions>
        <h3 style="margin-top: 20px;">评价维度</h3>
        <el-table :data="viewData.dimensions" border>
          <el-table-column prop="name" label="维度名称" width="150" />
          <el-table-column prop="weight" label="权重" width="100">
            <template #default="{ row }">{{ (row.weight * 100).toFixed(0) }}%</template>
          </el-table-column>
          <el-table-column prop="criteria" label="评分标准" />
          <el-table-column prop="levels" label="评价等级" width="200">
            <template #default="{ row }">
              <el-tag v-for="level in row.levels" :key="level" size="small" style="margin-right: 4px;">
                {{ level }}
              </el-tag>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete } from '@element-plus/icons-vue'
import { getAssessmentTemplates, createAssessmentTemplate, updateAssessmentTemplate, deleteAssessmentTemplate } from '@/api/assessment'

const loading = ref(false)
const dialogVisible = ref(false)
const viewDialogVisible = ref(false)
const dialogTitle = ref('新建模板')
const formRef = ref(null)

const templates = ref([])
const viewData = ref(null)

const formData = reactive({
  name: '',
  applicable_to: 'project',
  grade_level: '',
  description: '',
  dimensions: []
})

const getApplicableText = (type) => {
  const texts = {
    project: '项目',
    task: '任务',
    output: '成果'
  }
  return texts[type] || type
}

const handleCreate = () => {
  dialogTitle.value = '新建模板'
  resetForm()
  dialogVisible.value = true
}

const handleView = (row) => {
  viewData.value = row
  viewDialogVisible.value = true
}

const handleEdit = (row) => {
  dialogTitle.value = '编辑模板'
  Object.assign(formData, JSON.parse(JSON.stringify(row)))
  dialogVisible.value = true
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除这个模板吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await deleteAssessmentTemplate(row.uuid)
    ElMessage.success('删除成功')
    loadTemplates()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
      ElMessage.error(error.response?.data?.detail || '删除失败')
    }
  }
}

const handleStatusChange = async (row) => {
  try {
    await updateAssessmentTemplate(row.uuid, { is_active: row.is_active })
    ElMessage.success('状态更新成功')
  } catch (error) {
    console.error('状态更新失败:', error)
    row.is_active = !row.is_active
    ElMessage.error(error.response?.data?.detail || '状态更新失败')
  }
}

const addDimension = () => {
  formData.dimensions.push({
    name: '',
    weight: 0.2,
    criteria: '',
    levels: ['优秀', '良好', '合格', '需改进']
  })
}

const removeDimension = (index) => {
  formData.dimensions.splice(index, 1)
}

const calculateTotalWeight = () => {
  const total = formData.dimensions.reduce((sum, dim) => sum + (dim.weight || 0), 0)
  return total.toFixed(2)
}

const handleSubmit = async () => {
  try {
    const totalWeight = parseFloat(calculateTotalWeight())
    if (Math.abs(totalWeight - 1) > 0.01) {
      ElMessage.warning('权重总和必须等于1')
      return
    }
    
    if (formData.uuid) {
      // 编辑
      await updateAssessmentTemplate(formData.uuid, formData)
    } else {
      // 新建
      await createAssessmentTemplate(formData)
    }
    
    ElMessage.success('保存成功')
    dialogVisible.value = false
    loadTemplates()
  } catch (error) {
    console.error('保存失败:', error)
    ElMessage.error(error.response?.data?.detail || '保存失败')
  }
}

const resetForm = () => {
  Object.assign(formData, {
    name: '',
    applicable_to: 'project',
    grade_level: '',
    description: '',
    dimensions: []
  })
}

const loadTemplates = async () => {
  loading.value = true
  try {
    const response = await getAssessmentTemplates()
    if (response && response.data) {
      templates.value = response.data.items || response.data || []
    }
  } catch (error) {
    console.error('加载模板列表失败:', error)
    ElMessage.error(error.response?.data?.detail || '加载数据失败')
    templates.value = []
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadTemplates()
})
</script>

<style scoped>
.admin-templates-page {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.weight-sum {
  margin-top: 12px;
  font-size: 14px;
  font-weight: 600;
  color: #409eff;
}

.template-detail {
  padding: 20px;
}
</style>
