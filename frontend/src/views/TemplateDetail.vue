<template>
  <div class="template-detail" v-loading="loading">
    <div v-if="template">
      <!-- 模板头部 -->
      <div class="template-header">
        <el-button :icon="ArrowLeft" @click="goBack" class="back-btn">返回模板库</el-button>
        
        <div class="header-content">
          <div class="header-info">
            <h1 class="template-title">{{ template.title }}</h1>
            <p class="template-description">{{ template.description || '暂无描述' }}</p>
            
            <div class="template-stats">
              <div class="stat-item">
                <el-icon><Clock /></el-icon>
                <span>{{ template.duration || '待定' }}</span>
              </div>
              <div class="stat-item">
                <el-icon><TrendCharts /></el-icon>
                <span>{{ getDifficultyText(template.difficulty) }}</span>
              </div>
              <div class="stat-item">
                <el-icon><FolderOpened /></el-icon>
                <span>{{ template.category || '未分类' }}</span>
              </div>
              <div class="stat-item">
                <el-icon><Reading /></el-icon>
                <span>{{ template.units?.length || 0 }}个学习单元</span>
              </div>
            </div>

            <!-- 权限信息 -->
            <div class="permission-info" v-if="template.permission">
              <el-tag type="success" size="default" v-if="template.permission.can_customize">
                <el-icon><EditPen /></el-icon>
                允许自定义
              </el-tag>
              <el-tag type="warning" size="default" v-else>
                <el-icon><Lock /></el-icon>
                不允许自定义
              </el-tag>
              <span class="instance-count">
                已创建实例：{{ template.permission.current_instances }}
                <template v-if="template.permission.max_instances">
                  / {{ template.permission.max_instances }}
                </template>
              </span>
            </div>
          </div>
          
          <div class="header-cover" v-if="template.cover_image">
            <el-image 
              :src="template.cover_image" 
              fit="cover"
              style="width: 100%; height: 100%; border-radius: 12px;"
            >
              <template #error>
                <div class="image-slot">
                  <el-icon><Picture /></el-icon>
                </div>
              </template>
            </el-image>
          </div>
        </div>
      </div>

      <!-- 学习单元列表 -->
      <div class="units-section">
        <h3 class="section-title">
          <el-icon><Reading /></el-icon>
          学习单元
        </h3>
        
        <el-empty 
          v-if="!template.units || template.units.length === 0" 
          description="该模板暂无学习单元"
        />

        <div class="units-list" v-else>
          <el-collapse v-model="activeUnits" accordion>
            <el-collapse-item 
              v-for="(unit, index) in template.units" 
              :key="unit.id"
              :name="unit.id"
            >
              <template #title>
                <div class="unit-header">
                  <span class="unit-number">单元 {{ index + 1 }}</span>
                  <span class="unit-title">{{ unit.title }}</span>
                  <div class="unit-meta">
                    <el-tag size="small" v-if="unit.resources_count">
                      <el-icon><Document /></el-icon>
                      {{ unit.resources_count }} 个资源
                    </el-tag>
                    <el-tag size="small" type="warning" v-if="unit.tasks_count">
                      <el-icon><Tickets /></el-icon>
                      {{ unit.tasks_count }} 个任务
                    </el-tag>
                  </div>
                </div>
              </template>
              
              <div class="unit-content">
                <p class="unit-description" v-if="unit.description">{{ unit.description }}</p>
                
                <!-- 单元资源 -->
                <div class="unit-resources" v-if="unit.resources && unit.resources.length > 0">
                  <h4 class="subsection-title">
                    <el-icon><Document /></el-icon>
                    学习资源
                  </h4>
                  <div class="resources-list">
                    <div 
                      v-for="resource in unit.resources" 
                      :key="resource.id"
                      class="resource-item"
                    >
                      <div class="resource-icon">
                        <el-icon v-if="resource.resource_type === 'video'"><VideoPlay /></el-icon>
                        <el-icon v-else-if="resource.resource_type === 'document'"><Document /></el-icon>
                        <el-icon v-else-if="resource.resource_type === 'link'"><Link /></el-icon>
                        <el-icon v-else><Files /></el-icon>
                      </div>
                      <div class="resource-info">
                        <div class="resource-title">{{ resource.title }}</div>
                        <div class="resource-meta">
                          <el-tag size="small">{{ getResourceTypeText(resource.resource_type) }}</el-tag>
                          <span class="resource-desc" v-if="resource.description">
                            {{ resource.description }}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- 单元任务 -->
                <div class="unit-tasks" v-if="unit.tasks && unit.tasks.length > 0">
                  <h4 class="subsection-title">
                    <el-icon><Tickets /></el-icon>
                    学习任务
                  </h4>
                  <div class="tasks-list">
                    <div 
                      v-for="(task, taskIndex) in unit.tasks" 
                      :key="task.id"
                      class="task-item"
                    >
                      <div class="task-number">{{ taskIndex + 1 }}</div>
                      <div class="task-info">
                        <div class="task-header">
                          <span class="task-title">{{ task.title }}</span>
                          <el-tag 
                            size="small" 
                            :type="getTaskTypeTag(task.task_type)"
                          >
                            {{ getTaskTypeText(task.task_type) }}
                          </el-tag>
                        </div>
                        <div class="task-description" v-if="task.description">
                          {{ task.description }}
                        </div>
                        <div class="task-requirements" v-if="task.requirements">
                          <div class="requirements-label">任务要求：</div>
                          <div class="requirements-content" v-html="formatRequirements(task.requirements)"></div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- 空状态 -->
                <el-empty 
                  v-if="(!unit.resources || unit.resources.length === 0) && (!unit.tasks || unit.tasks.length === 0)"
                  description="该单元暂无内容"
                  :image-size="80"
                />
              </div>
            </el-collapse-item>
          </el-collapse>
        </div>
      </div>
    </div>

    <!-- 空状态 -->
    <el-empty 
      v-else-if="!loading" 
      description="未找到模板信息"
    >
      <el-button type="primary" @click="goBack">返回模板库</el-button>
    </el-empty>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { 
  ArrowLeft, Clock, TrendCharts, FolderOpened, Reading, 
  Document, Tickets, VideoPlay, Link, Files, Picture,
  EditPen, Lock
} from '@element-plus/icons-vue'
import axios from 'axios'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const template = ref(null)
const activeUnits = ref([])

// API请求头
const getAuthHeaders = () => {
  const token = localStorage.getItem('admin_access_token')
  return { Authorization: `Bearer ${token}` }
}

// 加载模板详情
const loadTemplateDetail = async () => {
  try {
    loading.value = true
    const uuid = route.params.uuid
    
    const response = await axios.get(
      `/api/v1/admin/available-templates/${uuid}`,
      { headers: getAuthHeaders() }
    )
    
    if (response.data && response.data.success) {
      template.value = response.data.data
      // 自动展开第一个单元
      if (template.value.units && template.value.units.length > 0) {
        activeUnits.value = [template.value.units[0].id]
      }
    }
  } catch (error) {
    console.error('加载模板详情失败:', error)
    ElMessage.error(error.response?.data?.message || '加载模板详情失败')
  } finally {
    loading.value = false
  }
}

// 返回
const goBack = () => {
  router.push('/admin/available-templates')
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

// 获取资源类型文本
const getResourceTypeText = (type) => {
  const texts = {
    video: '视频',
    document: '文档',
    link: '链接',
    file: '文件'
  }
  return texts[type] || type
}

// 获取任务类型文本
const getTaskTypeText = (type) => {
  const texts = {
    analysis: '分析任务',
    coding: '编程任务',
    design: '设计任务',
    deployment: '部署任务',
    research: '研究任务',
    presentation: '展示任务'
  }
  return texts[type] || type
}

// 获取任务类型标签颜色
const getTaskTypeTag = (type) => {
  const tags = {
    analysis: 'info',
    coding: 'success',
    design: 'primary',
    deployment: 'warning',
    research: '',
    presentation: 'danger'
  }
  return tags[type] || ''
}

// 格式化任务要求
const formatRequirements = (requirements) => {
  if (!requirements) return ''
  
  // 如果是数组，转换为列表
  if (Array.isArray(requirements)) {
    return '<ul>' + requirements.map(item => `<li>${item}</li>`).join('') + '</ul>'
  }
  
  // 如果是对象，转换为键值对
  if (typeof requirements === 'object') {
    return Object.entries(requirements)
      .map(([key, value]) => `<strong>${key}:</strong> ${value}`)
      .join('<br>')
  }
  
  // 如果是字符串，将换行符转换为 <br>
  if (typeof requirements === 'string') {
    return requirements.replace(/\n/g, '<br>')
  }
  
  return String(requirements)
}

// 初始化
onMounted(() => {
  loadTemplateDetail()
})
</script>

<style scoped>
.template-detail {
  padding: 0;
  min-height: 100vh;
  background: linear-gradient(135deg, #f5f7fa 0%, #ffffff 100%);
}

/* 模板头部 */
.template-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 24px;
  margin-bottom: 24px;
  border-radius: 16px;
  box-shadow: 0 8px 24px rgba(102, 126, 234, 0.2);
}

.back-btn {
  margin-bottom: 20px;
  background: rgba(255, 255, 255, 0.25);
  border: 1px solid rgba(255, 255, 255, 0.4);
  color: #ffffff;
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
}

.back-btn:hover {
  background: rgba(255, 255, 255, 0.35);
  transform: translateX(-4px);
}

.header-content {
  display: flex;
  gap: 32px;
  align-items: flex-start;
}

.header-info {
  flex: 1;
  color: #ffffff;
}

.template-title {
  font-size: 32px;
  font-weight: 700;
  margin: 0 0 16px 0;
  color: #ffffff;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.template-description {
  font-size: 16px;
  line-height: 1.6;
  margin: 0 0 24px 0;
  color: rgba(255, 255, 255, 0.9);
}

.template-stats {
  display: flex;
  gap: 24px;
  flex-wrap: wrap;
  margin-bottom: 20px;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(255, 255, 255, 0.15);
  padding: 10px 16px;
  border-radius: 20px;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  font-size: 14px;
  font-weight: 500;
}

.stat-item .el-icon {
  font-size: 18px;
}

.permission-info {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}

.permission-info .el-tag {
  background: rgba(255, 255, 255, 0.25);
  border: 1px solid rgba(255, 255, 255, 0.4);
  color: #ffffff;
  backdrop-filter: blur(10px);
}

.instance-count {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.9);
}

.header-cover {
  width: 400px;
  height: 300px;
  flex-shrink: 0;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

.image-slot {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #e3f2fd 0%, #f5f7fa 100%);
  color: #b0bec5;
  font-size: 64px;
}

/* 学习单元部分 */
.units-section {
  background: #ffffff;
  padding: 24px;
  border-radius: 16px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
}

.section-title {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 20px;
  font-weight: 600;
  color: #303133;
  margin: 0 0 24px 0;
  padding-bottom: 12px;
  border-bottom: 2px solid #f0f2f5;
}

.section-title .el-icon {
  font-size: 24px;
  color: #409eff;
}

/* 单元列表 */
.units-list {
  margin-top: 16px;
}

.unit-header {
  display: flex;
  align-items: center;
  gap: 16px;
  width: 100%;
  padding: 4px 0;
}

.unit-number {
  font-weight: 700;
  color: #409eff;
  font-size: 16px;
  min-width: 80px;
}

.unit-title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  flex: 1;
}

.unit-meta {
  display: flex;
  gap: 8px;
}

.unit-content {
  padding: 16px 20px;
  background: #fafbfc;
  border-radius: 8px;
}

.unit-description {
  color: #606266;
  line-height: 1.6;
  margin: 0 0 20px 0;
  padding: 12px;
  background: #ffffff;
  border-radius: 6px;
  border-left: 3px solid #409eff;
}

/* 子部分标题 */
.subsection-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  margin: 24px 0 16px 0;
}

.subsection-title .el-icon {
  font-size: 20px;
  color: #409eff;
}

/* 资源列表 */
.unit-resources {
  margin-bottom: 24px;
}

.resources-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.resource-item {
  display: flex;
  gap: 12px;
  padding: 16px;
  background: #ffffff;
  border-radius: 8px;
  border: 1px solid #e4e7ed;
  transition: all 0.3s ease;
}

.resource-item:hover {
  border-color: #409eff;
  box-shadow: 0 2px 8px rgba(64, 158, 255, 0.1);
  transform: translateX(4px);
}

.resource-icon {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #409eff 0%, #3a8ee6 100%);
  border-radius: 8px;
  color: #ffffff;
  flex-shrink: 0;
}

.resource-icon .el-icon {
  font-size: 20px;
}

.resource-info {
  flex: 1;
}

.resource-title {
  font-weight: 600;
  color: #303133;
  margin-bottom: 8px;
}

.resource-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.resource-desc {
  color: #909399;
  font-size: 13px;
}

/* 任务列表 */
.unit-tasks {
  margin-top: 24px;
}

.tasks-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.task-item {
  display: flex;
  gap: 16px;
  padding: 20px;
  background: #ffffff;
  border-radius: 8px;
  border: 1px solid #e4e7ed;
  transition: all 0.3s ease;
}

.task-item:hover {
  border-color: #409eff;
  box-shadow: 0 2px 12px rgba(64, 158, 255, 0.15);
}

.task-number {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #67c23a 0%, #5daf34 100%);
  border-radius: 50%;
  color: #ffffff;
  font-weight: 700;
  flex-shrink: 0;
}

.task-info {
  flex: 1;
}

.task-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.task-title {
  font-weight: 600;
  font-size: 16px;
  color: #303133;
}

.task-description {
  color: #606266;
  line-height: 1.6;
  margin-bottom: 12px;
}

.task-requirements {
  margin-top: 12px;
  padding: 12px;
  background: #f5f7fa;
  border-radius: 6px;
  border-left: 3px solid #e6a23c;
}

.requirements-label {
  font-weight: 600;
  color: #606266;
  margin-bottom: 8px;
}

.requirements-content {
  color: #606266;
  line-height: 1.8;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
  }
  
  .header-cover {
    width: 100%;
    height: 200px;
  }
  
  .template-stats {
    flex-direction: column;
    gap: 12px;
  }
  
  .stat-item {
    width: 100%;
    justify-content: center;
  }
}

/* 折叠面板样式优化 */
:deep(.el-collapse) {
  border: none;
}

:deep(.el-collapse-item) {
  margin-bottom: 16px;
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid #e4e7ed;
  transition: all 0.3s ease;
}

:deep(.el-collapse-item:hover) {
  border-color: #409eff;
  box-shadow: 0 2px 12px rgba(64, 158, 255, 0.1);
}

:deep(.el-collapse-item__header) {
  background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%);
  padding: 16px 20px;
  border: none;
  font-weight: 600;
}

:deep(.el-collapse-item__wrap) {
  border: none;
}

:deep(.el-collapse-item__content) {
  padding: 0;
}
</style>
