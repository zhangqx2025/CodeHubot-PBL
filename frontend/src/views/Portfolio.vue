<template>
  <div class="portfolio-page">
    <el-card class="page-header" shadow="never">
      <div class="header-content">
        <div class="header-left">
          <h1>成长档案</h1>
          <p>记录你的学习轨迹，见证AI学习成长历程</p>
        </div>
        <div class="header-right">
          <el-button type="primary" :icon="Download" @click="handleExport">
            导出档案
          </el-button>
        </div>
      </div>
    </el-card>

    <!-- 整体概览 -->
    <el-row :gutter="20" class="overview-section">
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <el-icon class="stat-icon" :size="32" color="#409eff"><Reading /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ portfolioData.projects_count || 0 }}</div>
              <div class="stat-label">完成项目</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <el-icon class="stat-icon" :size="32" color="#67c23a"><Clock /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ portfolioData.total_learning_hours || 0 }}</div>
              <div class="stat-label">学习时长（小时）</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <el-icon class="stat-icon" :size="32" color="#f56c6c"><Medal /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ achievements.length || 0 }}</div>
              <div class="stat-label">获得成就</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <el-icon class="stat-icon" :size="32" color="#e6a23c"><Star /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ portfolioData.avg_score || 0 }}</div>
              <div class="stat-label">平均分数</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 能力雷达图 -->
    <el-card class="section-card" shadow="never">
      <template #header>
        <div class="card-header">
          <span>能力评估</span>
        </div>
      </template>
      <div ref="radarChart" class="chart-container"></div>
    </el-card>

    <!-- 成就徽章 -->
    <el-card class="section-card" shadow="never">
      <template #header>
        <div class="card-header">
          <span>成就徽章</span>
          <el-tag>已获得 {{ achievements.length }} 个</el-tag>
        </div>
      </template>
      <div v-if="achievements.length > 0" class="achievements-grid">
        <div v-for="achievement in achievements" :key="achievement.id" class="achievement-item">
          <el-tooltip :content="achievement.description" placement="top">
            <div class="achievement-badge">
              <el-icon :size="48" color="#ffd700"><Trophy /></el-icon>
              <div class="achievement-name">{{ achievement.name }}</div>
              <div class="achievement-date">{{ formatDate(achievement.unlocked_at) }}</div>
            </div>
          </el-tooltip>
        </div>
      </div>
      <el-empty v-else description="暂无成就，继续努力！" />
    </el-card>

    <!-- 项目作品集 -->
    <el-card class="section-card" shadow="never">
      <template #header>
        <div class="card-header">
          <span>项目作品集</span>
        </div>
      </template>
      <div v-if="completedProjects.length > 0" class="projects-grid">
        <el-card
          v-for="project in completedProjects"
          :key="project.project_id"
          shadow="hover"
          class="project-card"
          @click="viewProject(project)"
        >
          <div class="project-cover">
            <el-icon :size="48"><Folder /></el-icon>
          </div>
          <div class="project-info">
            <h3>{{ project.title }}</h3>
            <div class="project-meta">
              <el-tag size="small" type="success">已完成</el-tag>
              <span class="project-score">得分: {{ project.score }}</span>
            </div>
          </div>
        </el-card>
      </div>
      <el-empty v-else description="暂无完成的项目" />
    </el-card>

    <!-- 教师评语 -->
    <el-card v-if="portfolioData.teacher_comments" class="section-card" shadow="never">
      <template #header>
        <div class="card-header">
          <span>教师评语</span>
        </div>
      </template>
      <div class="comments-content">
        <p>{{ portfolioData.teacher_comments }}</p>
      </div>
    </el-card>

    <!-- 自我反思 -->
    <el-card class="section-card" shadow="never">
      <template #header>
        <div class="card-header">
          <span>自我反思</span>
          <el-button size="small" @click="editReflection">编辑</el-button>
        </div>
      </template>
      <div v-if="!isEditingReflection" class="reflection-content">
        <p v-if="portfolioData.self_reflection">{{ portfolioData.self_reflection }}</p>
        <el-empty v-else description="还没有写自我反思哦" :image-size="80" />
      </div>
      <el-input
        v-else
        v-model="reflectionText"
        type="textarea"
        :rows="6"
        placeholder="写下你在AI学习过程中的收获、感悟和成长..."
        class="reflection-input"
      />
      <div v-if="isEditingReflection" class="reflection-actions">
        <el-button @click="cancelReflection">取消</el-button>
        <el-button type="primary" @click="saveReflection">保存</el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  Download,
  Reading,
  Clock,
  Medal,
  Star,
  Trophy,
  Folder
} from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import { getMyPortfolio, updateSelfReflection, exportPortfolio } from '@/api/portfolio'

const portfolioData = ref({})
const achievements = ref([])
const completedProjects = ref([])
const isEditingReflection = ref(false)
const reflectionText = ref('')
const radarChart = ref(null)
const loading = ref(false)

const formatDate = (date) => {
  if (!date) return ''
  return new Date(date).toLocaleDateString('zh-CN')
}

const handleExport = async () => {
  try {
    if (!portfolioData.value.uuid) {
      ElMessage.warning('暂无可导出的档案')
      return
    }
    loading.value = true
    const response = await exportPortfolio(portfolioData.value.uuid)
    ElMessage.success('导出成功')
    // 如果后端返回文件，可以在这里处理下载
    console.log('导出数据:', response)
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('导出失败')
  } finally {
    loading.value = false
  }
}

const viewProject = (project) => {
  // 跳转到项目详情页
  if (project.project_id) {
    window.location.href = `#/project/${project.project_id}`
  } else {
    ElMessage.info(`查看项目: ${project.title}`)
  }
}

const editReflection = () => {
  reflectionText.value = portfolioData.value.self_reflection || ''
  isEditingReflection.value = true
}

const cancelReflection = () => {
  isEditingReflection.value = false
  reflectionText.value = ''
}

const saveReflection = async () => {
  try {
    if (!portfolioData.value.uuid) {
      ElMessage.warning('档案信息不完整')
      return
    }
    loading.value = true
    await updateSelfReflection(portfolioData.value.uuid, reflectionText.value)
    portfolioData.value.self_reflection = reflectionText.value
    isEditingReflection.value = false
    ElMessage.success('保存成功')
  } catch (error) {
    console.error('保存失败:', error)
    ElMessage.error('保存失败')
  } finally {
    loading.value = false
  }
}

const initRadarChart = () => {
  if (!radarChart.value) return
  
  const chart = echarts.init(radarChart.value)
  const option = {
    title: {
      text: '能力雷达图'
    },
    radar: {
      indicator: [
        { name: '技术能力', max: 100 },
        { name: '创新能力', max: 100 },
        { name: '协作能力', max: 100 },
        { name: '问题解决', max: 100 },
        { name: '伦理意识', max: 100 }
      ]
    },
    series: [
      {
        name: '能力评估',
        type: 'radar',
        data: [
          {
            value: [
              portfolioData.value.skill_assessment?.技术能力 || 0,
              portfolioData.value.skill_assessment?.创新能力 || 0,
              portfolioData.value.skill_assessment?.协作能力 || 0,
              portfolioData.value.skill_assessment?.问题解决 || 0,
              portfolioData.value.skill_assessment?.伦理意识 || 0
            ],
            name: '我的能力',
            areaStyle: {
              color: 'rgba(64, 158, 255, 0.3)'
            }
          }
        ]
      }
    ]
  }
  chart.setOption(option)
}

const loadPortfolioData = async () => {
  try {
    loading.value = true
    // 调用真实API获取成长档案数据
    const response = await getMyPortfolio()
    
    if (response && response.data) {
      const data = response.data
      portfolioData.value = data
      
      // 从档案数据中提取成就和已完成项目
      achievements.value = data.achievements || []
      completedProjects.value = data.completed_projects || []
      
      // 延迟初始化雷达图，确保DOM已渲染
      setTimeout(() => {
        initRadarChart()
      }, 100)
    }
  } catch (error) {
    console.error('加载成长档案失败:', error)
    ElMessage.error(error.response?.data?.detail || '加载数据失败')
    
    // 如果加载失败，初始化空数据
    portfolioData.value = {
      projects_count: 0,
      total_learning_hours: 0,
      avg_score: 0,
      skill_assessment: {}
    }
    achievements.value = []
    completedProjects.value = []
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadPortfolioData()
})
</script>

<style scoped>
.portfolio-page {
  padding: 0;
}

.page-header {
  margin-bottom: 20px;
  border-radius: 12px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
}

.page-header :deep(.el-card__body) {
  padding: 32px;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left h1 {
  margin: 0 0 8px 0;
  font-size: 28px;
  font-weight: 600;
}

.header-left p {
  margin: 0;
  opacity: 0.9;
  font-size: 14px;
}

.overview-section {
  margin-bottom: 20px;
}

.stat-card {
  border-radius: 12px;
  border: none;
  transition: all 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-icon {
  flex-shrink: 0;
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 28px;
  font-weight: 600;
  color: #303133;
  line-height: 1.2;
}

.stat-label {
  font-size: 14px;
  color: #909399;
  margin-top: 4px;
}

.section-card {
  margin-bottom: 20px;
  border-radius: 12px;
  border: none;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: 600;
  font-size: 16px;
}

.chart-container {
  height: 400px;
  width: 100%;
}

.achievements-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 20px;
}

.achievement-item {
  text-align: center;
}

.achievement-badge {
  padding: 20px;
  border-radius: 12px;
  background: linear-gradient(135deg, #ffeaa7 0%, #fdcb6e 100%);
  cursor: pointer;
  transition: all 0.3s ease;
}

.achievement-badge:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(253, 203, 110, 0.4);
}

.achievement-name {
  margin-top: 8px;
  font-weight: 600;
  color: #8b4513;
}

.achievement-date {
  margin-top: 4px;
  font-size: 12px;
  color: #a0522d;
}

.projects-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
}

.project-card {
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.project-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.project-cover {
  text-align: center;
  padding: 20px;
  background: linear-gradient(135deg, #e0f7fa 0%, #b2ebf2 100%);
  border-radius: 8px;
  margin-bottom: 12px;
}

.project-info h3 {
  margin: 0 0 12px 0;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.project-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.project-score {
  font-size: 14px;
  color: #67c23a;
  font-weight: 600;
}

.comments-content,
.reflection-content {
  padding: 16px;
  background: #f5f7fa;
  border-radius: 8px;
  line-height: 1.8;
}

.reflection-input {
  margin-bottom: 12px;
}

.reflection-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}
</style>
