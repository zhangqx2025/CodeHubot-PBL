<template>
  <div class="available-template-detail">
    <el-page-header @back="handleBack" :icon="ArrowLeft">
      <template #content>
        <div class="page-header-content">
          <h2>{{ templateData?.title || '课程模板详情' }}</h2>
          <el-tag v-if="templateData" :type="getDifficultyType(templateData.difficulty)" size="large">
            {{ getDifficultyText(templateData.difficulty) }}
          </el-tag>
        </div>
      </template>
    </el-page-header>

    <div v-loading="loading" class="template-detail-container">
      <div v-if="templateData" class="template-detail">
        <!-- 基本信息 -->
        <el-card class="detail-section">
          <template #header>
            <div class="section-header">
              <el-icon><InfoFilled /></el-icon>
              <span>基本信息</span>
            </div>
          </template>
          <el-descriptions :column="2" border>
            <el-descriptions-item label="模板名称">{{ templateData.title }}</el-descriptions-item>
            <el-descriptions-item label="版本">v{{ templateData.version }}</el-descriptions-item>
            <el-descriptions-item label="难度">
              <el-tag :type="getDifficultyType(templateData.difficulty)" size="small">
                {{ getDifficultyText(templateData.difficulty) }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="类别">{{ templateData.category || '-' }}</el-descriptions-item>
            <el-descriptions-item label="时长">{{ templateData.duration || '-' }}</el-descriptions-item>
            <el-descriptions-item label="使用次数">{{ templateData.usage_count || 0 }}</el-descriptions-item>
            
            <el-descriptions-item label="权限信息" :span="2">
              <div v-if="templateData.permission">
                <el-tag type="success" size="small" v-if="templateData.permission.can_customize">
                  允许自定义
                </el-tag>
                <el-tag type="warning" size="small" v-else>
                  不允许自定义
                </el-tag>
                <span style="margin-left: 10px">
                  已创建实例：{{ templateData.permission.current_instances }}
                  <template v-if="templateData.permission.max_instances">
                    / {{ templateData.permission.max_instances }}
                  </template>
                </span>
              </div>
            </el-descriptions-item>
            
            <el-descriptions-item label="模板描述" :span="2">
              {{ templateData.description || '-' }}
            </el-descriptions-item>
            
            <el-descriptions-item label="备注说明" :span="2" v-if="templateData.permission?.remarks">
              {{ templateData.permission.remarks }}
            </el-descriptions-item>
          </el-descriptions>
        </el-card>

        <!-- 单元、资源和任务清单 -->
        <el-card class="detail-section" v-if="templateData.units && templateData.units.length > 0">
          <template #header>
            <div class="section-header">
              <el-icon><List /></el-icon>
              <span>课程内容（共 {{ templateData.units.length }} 个单元）</span>
            </div>
          </template>
          
          <el-collapse v-model="activeUnits">
            <el-collapse-item 
              v-for="(unit, index) in templateData.units" 
              :key="unit.id"
              :name="unit.id"
            >
              <template #title>
                <div class="unit-title">
                  <el-tag type="primary" size="small">单元 {{ index + 1 }}</el-tag>
                  <span style="margin-left: 10px; font-weight: 600">{{ unit.title }}</span>
                  <el-text type="info" size="small" style="margin-left: 10px" v-if="unit.recommended_duration">
                    <el-icon><Clock /></el-icon>
                    {{ unit.recommended_duration }}
                  </el-text>
                </div>
              </template>
              
              <div class="unit-content">
                <!-- 单元描述 -->
                <div v-if="unit.description" class="unit-description">
                  <strong>单元描述：</strong>{{ unit.description }}
                </div>

                <!-- 学习目标 -->
                <div v-if="unit.learning_objectives && unit.learning_objectives.length > 0" class="unit-objectives">
                  <strong>学习目标：</strong>
                  <ul>
                    <li v-for="(objective, idx) in unit.learning_objectives" :key="idx">
                      {{ objective }}
                    </li>
                  </ul>
                </div>

                <!-- 关键概念 -->
                <div v-if="unit.key_concepts && unit.key_concepts.length > 0" class="unit-concepts">
                  <strong>关键概念：</strong>
                  <el-tag 
                    v-for="(concept, idx) in unit.key_concepts" 
                    :key="idx"
                    size="small"
                    style="margin-right: 8px; margin-bottom: 8px"
                  >
                    {{ concept }}
                  </el-tag>
                </div>

                <!-- 资源列表 -->
                <div v-if="unit.resources && unit.resources.length > 0" class="resources-section">
                  <el-divider content-position="left">
                    <el-icon><FolderOpened /></el-icon>
                    学习资源（{{ unit.resources.length }}）
                  </el-divider>
                  <el-table :data="unit.resources" border stripe>
                    <el-table-column type="index" label="#" width="50" />
                    <el-table-column label="类型" width="100">
                      <template #default="{ row }">
                        <el-tag :type="getResourceTypeTag(row.type)" size="small">
                          {{ getResourceTypeText(row.type) }}
                        </el-tag>
                      </template>
                    </el-table-column>
                    <el-table-column prop="title" label="标题" min-width="200" />
                    <el-table-column prop="description" label="描述" min-width="250" show-overflow-tooltip />
                    <el-table-column label="时长" width="100">
                      <template #default="{ row }">
                        {{ row.duration ? `${row.duration}分钟` : '-' }}
                      </template>
                    </el-table-column>
                    <el-table-column label="预览" width="80" align="center">
                      <template #default="{ row }">
                        <el-icon v-if="row.is_preview_allowed" color="#67C23A"><Check /></el-icon>
                        <el-icon v-else color="#F56C6C"><Close /></el-icon>
                      </template>
                    </el-table-column>
                  </el-table>
                </div>

                <!-- 任务列表 -->
                <div v-if="unit.tasks && unit.tasks.length > 0" class="tasks-section">
                  <el-divider content-position="left">
                    <el-icon><EditPen /></el-icon>
                    学习任务（{{ unit.tasks.length }}）
                  </el-divider>
                  <el-space direction="vertical" fill style="width: 100%">
                    <el-card 
                      v-for="(task, taskIdx) in unit.tasks" 
                      :key="task.id"
                      class="task-card"
                      shadow="hover"
                    >
                      <template #header>
                        <div class="task-header">
                          <div>
                            <el-tag type="primary" size="small">任务 {{ taskIdx + 1 }}</el-tag>
                            <span style="margin-left: 10px; font-weight: 600">{{ task.title }}</span>
                          </div>
                          <div>
                            <el-tag :type="getTaskDifficultyType(task.difficulty)" size="small">
                              {{ getTaskDifficultyText(task.difficulty) }}
                            </el-tag>
                            <el-tag type="info" size="small" style="margin-left: 5px">
                              {{ getTaskTypeText(task.type) }}
                            </el-tag>
                            <el-text type="info" size="small" style="margin-left: 10px" v-if="task.estimated_time">
                              <el-icon><Clock /></el-icon>
                              {{ task.estimated_time }}
                            </el-text>
                          </div>
                        </div>
                      </template>
                      
                      <div class="task-content">
                        <div v-if="task.description" class="task-description">
                          {{ task.description }}
                        </div>

                        <el-row :gutter="20" style="margin-top: 15px">
                          <el-col :span="12" v-if="task.requirements && task.requirements.length > 0">
                            <div class="task-detail-item">
                              <strong><el-icon><Document /></el-icon> 任务要求：</strong>
                              <ul>
                                <li v-for="(req, idx) in task.requirements" :key="idx">{{ req }}</li>
                              </ul>
                            </div>
                          </el-col>
                          
                          <el-col :span="12" v-if="task.deliverables && task.deliverables.length > 0">
                            <div class="task-detail-item">
                              <strong><el-icon><Box /></el-icon> 交付物：</strong>
                              <ul>
                                <li v-for="(del, idx) in task.deliverables" :key="idx">{{ del }}</li>
                              </ul>
                            </div>
                          </el-col>
                        </el-row>

                        <div v-if="task.evaluation_criteria && task.evaluation_criteria.length > 0" class="task-detail-item">
                          <strong><el-icon><Medal /></el-icon> 评价标准：</strong>
                          <ul>
                            <li v-for="(criteria, idx) in task.evaluation_criteria" :key="idx">{{ criteria }}</li>
                          </ul>
                        </div>

                        <div v-if="task.hints && task.hints.length > 0" class="task-detail-item">
                          <el-alert type="success" :closable="false">
                            <template #title>
                              <strong><el-icon><Promotion /></el-icon> 提示：</strong>
                            </template>
                            <ul style="margin: 5px 0 0 0; padding-left: 20px">
                              <li v-for="(hint, idx) in task.hints" :key="idx">{{ hint }}</li>
                            </ul>
                          </el-alert>
                        </div>
                      </div>
                    </el-card>
                  </el-space>
                </div>
              </div>
            </el-collapse-item>
          </el-collapse>
        </el-card>

        <!-- 无单元提示 -->
        <el-card class="detail-section" v-else>
          <el-empty description="该模板暂无单元内容" />
        </el-card>
      </div>

      <!-- 空状态 -->
      <el-empty v-else-if="!loading" description="模板数据加载失败" />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { 
  ArrowLeft, InfoFilled, List, FolderOpened, EditPen, Check, Close,
  Clock, Document, Box, Medal, Promotion
} from '@element-plus/icons-vue'
import axios from 'axios'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const templateData = ref(null)
const activeUnits = ref([])

// API请求
const getAuthHeaders = () => {
  const token = localStorage.getItem('admin_access_token')
  return { Authorization: `Bearer ${token}` }
}

// 返回列表
const handleBack = () => {
  router.push('/admin/available-templates')
}

// 加载模板详情
const loadTemplateDetail = async () => {
  try {
    loading.value = true
    const templateUuid = route.params.uuid
    
    const response = await axios.get(
      `/api/v1/admin/available-templates/${templateUuid}`,
      { headers: getAuthHeaders() }
    )
    
    if (response.data && response.data.success) {
      templateData.value = response.data.data
      // 默认展开所有单元
      if (templateData.value.units && templateData.value.units.length > 0) {
        activeUnits.value = templateData.value.units.map(unit => unit.id)
      }
    }
  } catch (error) {
    console.error('加载详情失败:', error)
    ElMessage.error(error.response?.data?.message || '加载详情失败')
  } finally {
    loading.value = false
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

// 获取资源类型标签
const getResourceTypeTag = (type) => {
  const tags = {
    video: 'success',
    document: 'primary',
    link: 'info',
    interactive: 'warning',
    quiz: 'danger'
  }
  return tags[type] || 'info'
}

// 获取资源类型文本
const getResourceTypeText = (type) => {
  const texts = {
    video: '视频',
    document: '文档',
    link: '链接',
    interactive: '互动',
    quiz: '测验'
  }
  return texts[type] || type
}

// 获取任务难度类型
const getTaskDifficultyType = (difficulty) => {
  const types = {
    easy: 'success',
    medium: 'warning',
    hard: 'danger'
  }
  return types[difficulty] || 'info'
}

// 获取任务难度文本
const getTaskDifficultyText = (difficulty) => {
  const texts = {
    easy: '简单',
    medium: '中等',
    hard: '困难'
  }
  return texts[difficulty] || difficulty
}

// 获取任务类型文本
const getTaskTypeText = (type) => {
  const texts = {
    analysis: '分析',
    coding: '编程',
    design: '设计',
    deployment: '部署',
    research: '研究',
    presentation: '展示'
  }
  return texts[type] || type
}

// 初始化
onMounted(() => {
  loadTemplateDetail()
})
</script>

<style scoped>
.available-template-detail {
  padding: 0;
}

.el-page-header {
  margin-bottom: 20px;
  padding: 20px;
  background: white;
  border-radius: 4px;
}

.page-header-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.page-header-content h2 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}

.template-detail-container {
  min-height: 400px;
}

.template-detail {
  width: 100%;
}

.detail-section {
  margin-bottom: 20px;
  border-radius: 12px;
}

.detail-section:last-child {
  margin-bottom: 0;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  font-size: 16px;
  color: #303133;
}

.section-header .el-icon {
  font-size: 18px;
  color: #409eff;
}

.unit-title {
  display: flex;
  align-items: center;
  width: 100%;
  font-size: 15px;
}

.unit-content {
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.unit-description {
  margin-bottom: 16px;
  padding: 12px;
  background: #fff;
  border-radius: 8px;
  line-height: 1.6;
  color: #606266;
}

.unit-objectives,
.unit-concepts {
  margin-bottom: 16px;
  padding: 12px;
  background: #fff;
  border-radius: 8px;
}

.unit-objectives ul {
  margin: 8px 0 0 0;
  padding-left: 24px;
  color: #606266;
  line-height: 1.8;
}

.unit-objectives li {
  margin-bottom: 6px;
}

.unit-concepts {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}

.resources-section,
.tasks-section {
  margin-top: 20px;
}

.resources-section :deep(.el-divider__text),
.tasks-section :deep(.el-divider__text) {
  font-weight: 600;
  color: #303133;
  display: flex;
  align-items: center;
  gap: 6px;
}

.task-card {
  border-radius: 10px;
  border: 1px solid #e4e7ed;
  transition: all 0.3s ease;
}

.task-card:hover {
  border-color: #409eff;
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.15);
}

.task-card :deep(.el-card__header) {
  background: linear-gradient(135deg, #f5f7fa 0%, #ffffff 100%);
  padding: 14px 18px;
}

.task-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
}

.task-content {
  color: #606266;
}

.task-description {
  padding: 12px;
  background: #f8f9fa;
  border-radius: 8px;
  line-height: 1.6;
  margin-bottom: 10px;
}

.task-detail-item {
  margin-top: 15px;
  padding: 12px;
  background: #ffffff;
  border-radius: 8px;
  border-left: 3px solid #409eff;
}

.task-detail-item strong {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #303133;
  margin-bottom: 8px;
}

.task-detail-item ul {
  margin: 8px 0 0 0;
  padding-left: 24px;
  line-height: 1.8;
}

.task-detail-item li {
  margin-bottom: 6px;
}

.task-detail-item .el-alert {
  border-radius: 8px;
}

/* 响应式 */
@media (max-width: 768px) {
  .page-header-content {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
}
</style>
