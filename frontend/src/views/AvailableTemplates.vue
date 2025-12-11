<template>
  <div class="available-templates">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>可用课程模板库</span>
          <el-tag type="info" size="large">
            可用模板：{{ pagination.total }} 个
          </el-tag>
        </div>
      </template>

      <!-- 筛选条件 -->
      <el-form :inline="true" class="filter-form">
        <el-form-item label="搜索">
          <el-input 
            v-model="filters.search" 
            placeholder="模板名称" 
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
        <el-form-item label="类别">
          <el-select 
            v-model="filters.category" 
            placeholder="请选择类别" 
            clearable 
            style="width: 150px"
          >
            <el-option label="AI" value="AI" />
            <el-option label="编程" value="Programming" />
            <el-option label="机器人" value="Robot" />
            <el-option label="其他" value="Other" />
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

      <!-- 模板卡片列表 -->
      <el-row :gutter="20" v-loading="loading">
        <el-col 
          v-for="template in templates" 
          :key="template.id" 
          :xs="24" 
          :sm="12" 
          :md="8" 
          :lg="6"
          style="margin-bottom: 20px"
        >
          <el-card shadow="hover" class="template-card">
            <template #header>
              <div class="template-header">
                <span class="template-title">{{ template.title }}</span>
                <el-tag :type="getDifficultyType(template.difficulty)" size="small">
                  {{ getDifficultyText(template.difficulty) }}
                </el-tag>
              </div>
            </template>
            
            <div class="template-cover" v-if="template.cover_image">
              <el-image 
                :src="template.cover_image" 
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
            
            <div class="template-info">
              <p class="template-description">
                {{ template.description || '暂无描述' }}
              </p>
              
              <div class="template-meta">
                <div class="meta-item">
                  <el-icon><Clock /></el-icon>
                  <span>{{ template.duration || '待定' }}</span>
                </div>
                <div class="meta-item">
                  <el-icon><Document /></el-icon>
                  <span>v{{ template.version }}</span>
                </div>
              </div>
              
              <div class="template-permission" v-if="template.permission">
                <el-divider />
                <div class="permission-info">
                  <div class="permission-item">
                    <span class="label">已创建：</span>
                    <span class="value">
                      {{ template.permission.current_instances }}
                      <template v-if="template.permission.max_instances">
                        / {{ template.permission.max_instances }}
                      </template>
                      个实例
                    </span>
                  </div>
                  <div class="permission-item" v-if="template.permission.can_customize">
                    <el-tag type="success" size="small">允许自定义</el-tag>
                  </div>
                  <div class="permission-item" v-if="template.permission.valid_until">
                    <span class="label">有效至：</span>
                    <span class="value">{{ formatDate(template.permission.valid_until) }}</span>
                  </div>
                </div>
              </div>
            </div>
            
            <template #footer>
              <div class="template-actions">
                <el-button 
                  type="primary" 
                  size="small" 
                  @click="handleCreateCourse(template)"
                  :disabled="!template.permission?.can_create_instance"
                >
                  <el-icon><Plus /></el-icon>
                  创建课程
                </el-button>
                <el-button size="small" @click="handleViewDetails(template)">
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
        v-if="!loading && templates.length === 0" 
        description="暂无可用的课程模板"
      >
        <template #extra>
          <el-text type="info">
            请联系平台管理员开放课程模板
          </el-text>
        </template>
      </el-empty>

      <!-- 分页 -->
      <div class="pagination-container" v-if="templates.length > 0">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.page_size"
          :page-sizes="[12, 24, 48]"
          :total="pagination.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="loadTemplates"
          @current-change="loadTemplates"
        />
      </div>
    </el-card>

    <!-- 创建课程对话框 -->
    <el-dialog
      v-model="createDialogVisible"
      title="基于模板创建课程"
      width="600px"
      :close-on-click-modal="false"
    >
      <div v-if="currentTemplate">
        <el-alert
          :title="`模板：${currentTemplate.name}`"
          type="info"
          :closable="false"
          style="margin-bottom: 20px"
        />
        
        <el-form
          ref="courseFormRef"
          :model="courseForm"
          :rules="courseRules"
          label-width="100px"
        >
          <el-form-item label="课程名称" prop="title">
            <el-input 
              v-model="courseForm.title" 
              placeholder="请输入课程名称（默认使用模板名称）"
            />
          </el-form-item>
          
          <el-form-item label="课程描述">
            <el-input 
              v-model="courseForm.description" 
              type="textarea"
              :rows="3"
              placeholder="请输入课程描述（默认使用模板描述）"
            />
          </el-form-item>
          
          <el-form-item label="关联班级">
            <el-select 
              v-model="courseForm.class_id" 
              placeholder="请选择班级（可选）"
              clearable
              style="width: 100%"
            >
              <el-option 
                v-for="cls in classes" 
                :key="cls.id" 
                :label="cls.name" 
                :value="cls.id" 
              />
            </el-select>
            <el-text type="info" size="small">
              选择班级后，课程将自动分配给班级成员
            </el-text>
          </el-form-item>
        </el-form>
      </div>
      
      <template #footer>
        <el-button @click="createDialogVisible = false">取消</el-button>
        <el-button 
          type="primary" 
          @click="handleCreateSubmit" 
          :loading="submitting"
        >
          确定创建
        </el-button>
      </template>
    </el-dialog>

    <!-- 模板详情对话框 -->
    <el-dialog
      v-model="detailDialogVisible"
      title="课程模板详情"
      width="900px"
    >
      <div v-if="currentTemplate">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="模板名称">{{ currentTemplate.name }}</el-descriptions-item>
          <el-descriptions-item label="版本">v{{ currentTemplate.version }}</el-descriptions-item>
          <el-descriptions-item label="难度">
            <el-tag :type="getDifficultyType(currentTemplate.difficulty)" size="small">
              {{ getDifficultyText(currentTemplate.difficulty) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="类别">{{ currentTemplate.category || '-' }}</el-descriptions-item>
          <el-descriptions-item label="时长">{{ currentTemplate.duration || '-' }}</el-descriptions-item>
          <el-descriptions-item label="使用次数">{{ currentTemplate.usage_count || 0 }}</el-descriptions-item>
          
          <el-descriptions-item label="权限信息" :span="2">
            <div v-if="currentTemplate.permission">
              <el-tag type="success" size="small" v-if="currentTemplate.permission.can_customize">
                允许自定义
              </el-tag>
              <el-tag type="warning" size="small" v-else>
                不允许自定义
              </el-tag>
              <span style="margin-left: 10px">
                已创建实例：{{ currentTemplate.permission.current_instances }}
                <template v-if="currentTemplate.permission.max_instances">
                  / {{ currentTemplate.permission.max_instances }}
                </template>
              </span>
            </div>
          </el-descriptions-item>
          
          <el-descriptions-item label="模板描述" :span="2">
            {{ currentTemplate.description || '-' }}
          </el-descriptions-item>
          
          <el-descriptions-item label="备注说明" :span="2" v-if="currentTemplate.permission?.remarks">
            {{ currentTemplate.permission.remarks }}
          </el-descriptions-item>
        </el-descriptions>
      </div>
      <template #footer>
        <el-button @click="detailDialogVisible = false">关闭</el-button>
        <el-button 
          type="primary" 
          @click="() => { detailDialogVisible = false; handleCreateCourse(currentTemplate) }"
          :disabled="!currentTemplate?.permission?.can_create_instance"
        >
          创建课程
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Search, Refresh, Plus, View, Clock, Document, Picture } from '@element-plus/icons-vue'
import axios from 'axios'

const loading = ref(false)
const submitting = ref(false)
const createDialogVisible = ref(false)
const detailDialogVisible = ref(false)
const courseFormRef = ref(null)

const templates = ref([])
const classes = ref([])
const currentTemplate = ref(null)

const filters = reactive({
  search: '',
  difficulty: '',
  category: ''
})

const pagination = reactive({
  page: 1,
  page_size: 12,
  total: 0
})

const courseForm = reactive({
  title: '',
  description: '',
  class_id: null
})

const courseRules = {
  title: [{ required: true, message: '请输入课程名称', trigger: 'blur' }]
}

// API请求
const getAuthHeaders = () => {
  const token = localStorage.getItem('admin_access_token')
  return { Authorization: `Bearer ${token}` }
}

// 加载可用模板
const loadTemplates = async () => {
  try {
    loading.value = true
    const params = {
      page: pagination.page,
      page_size: pagination.page_size,
      ...(filters.search && { search: filters.search }),
      ...(filters.difficulty && { difficulty: filters.difficulty }),
      ...(filters.category && { category: filters.category })
    }
    
    const response = await axios.get('/api/v1/admin/available-templates', {
      params,
      headers: getAuthHeaders()
    })
    
    if (response.data && response.data.success) {
      templates.value = response.data.data.items || []
      pagination.total = response.data.data.total || 0
    }
  } catch (error) {
    console.error('加载模板失败:', error)
    ElMessage.error(error.response?.data?.message || '加载模板失败')
  } finally {
    loading.value = false
  }
}

// 加载班级列表
const loadClasses = async () => {
  try {
    const response = await axios.get('/api/v1/admin/classes-groups/classes', {
      params: { limit: 1000 },
      headers: getAuthHeaders()
    })
    
    if (response.data && response.data.success) {
      classes.value = response.data.data.items || []
    }
  } catch (error) {
    console.error('加载班级列表失败:', error)
  }
}

// 筛选处理
const handleFilter = () => {
  pagination.page = 1
  loadTemplates()
}

// 重置筛选
const resetFilters = () => {
  filters.search = ''
  filters.difficulty = ''
  filters.category = ''
  pagination.page = 1
  loadTemplates()
}

// 打开创建课程对话框
const handleCreateCourse = (template) => {
  if (!template.permission?.can_create_instance) {
    ElMessage.warning('已达到创建限制或模板不可用')
    return
  }
  
  currentTemplate.value = template
  courseForm.title = template.title
  courseForm.description = template.description
  courseForm.class_id = null
  createDialogVisible.value = true
}

// 提交创建课程
const handleCreateSubmit = async () => {
  if (!courseFormRef.value) return
  
  await courseFormRef.value.validate(async (valid) => {
    if (!valid) return
    
    try {
      submitting.value = true
      
      const response = await axios.post(
        `/api/v1/admin/available-templates/${currentTemplate.value.uuid}/create-course`,
        {
          title: courseForm.title,
          description: courseForm.description,
          class_id: courseForm.class_id
        },
        { headers: getAuthHeaders() }
      )
      
      if (response.data && response.data.success) {
        ElMessage.success('课程创建成功')
        createDialogVisible.value = false
        loadTemplates() // 刷新列表
      }
    } catch (error) {
      console.error('创建失败:', error)
      ElMessage.error(error.response?.data?.message || '创建失败')
    } finally {
      submitting.value = false
    }
  })
}

// 查看模板详情
const handleViewDetails = async (template) => {
  try {
    const response = await axios.get(
      `/api/v1/admin/available-templates/${template.uuid}`,
      { headers: getAuthHeaders() }
    )
    
    if (response.data && response.data.success) {
      currentTemplate.value = response.data.data
      detailDialogVisible.value = true
    }
  } catch (error) {
    console.error('加载详情失败:', error)
    ElMessage.error(error.response?.data?.message || '加载详情失败')
  }
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

// 格式化日期
const formatDate = (dateString) => {
  if (!dateString) return ''
  return new Date(dateString).toLocaleDateString('zh-CN')
}

// 初始化
onMounted(() => {
  loadTemplates()
  loadClasses()
})
</script>

<style scoped>
.available-templates {
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

.template-card {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.template-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.template-title {
  font-weight: 600;
  font-size: 16px;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  margin-right: 10px;
}

.template-info {
  flex: 1;
}

.template-description {
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

.template-meta {
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

.template-permission {
  margin-top: 10px;
}

.permission-info {
  font-size: 13px;
  color: #606266;
}

.permission-item {
  margin: 5px 0;
}

.permission-item .label {
  color: #909399;
}

.permission-item .value {
  font-weight: 500;
}

.template-actions {
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

.pagination-container {
  margin-top: 20px;
  display: flex;
  justify-content: center;
}
</style>
