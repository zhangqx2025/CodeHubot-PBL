<template>
  <div class="ethics-page">
    <el-card class="page-header" shadow="never">
      <div class="header-content">
        <div class="header-left">
          <h1>伦理思辨</h1>
          <p>探索人工智能伦理，培养批判性思维和社会责任感</p>
        </div>
      </div>
    </el-card>

    <!-- 伦理主题标签 -->
    <el-card class="filter-card" shadow="never">
      <div class="filter-section">
        <span class="filter-label">伦理议题：</span>
        <el-tag
          v-for="topic in ethicsTopics"
          :key="topic"
          :type="selectedTopic === topic ? 'primary' : 'info'"
          :effect="selectedTopic === topic ? 'dark' : 'plain'"
          class="topic-tag"
          @click="selectTopic(topic)"
        >
          {{ topic }}
        </el-tag>
      </div>
      <div class="filter-section">
        <span class="filter-label">难度：</span>
        <el-radio-group v-model="selectedDifficulty" @change="loadCases">
          <el-radio-button label="all">全部</el-radio-button>
          <el-radio-button label="basic">基础</el-radio-button>
          <el-radio-button label="intermediate">进阶</el-radio-button>
          <el-radio-button label="advanced">高级</el-radio-button>
        </el-radio-group>
      </div>
    </el-card>

    <!-- 案例列表 -->
    <el-row :gutter="20">
      <el-col
        v-for="ethicsCase in ethicsCases"
        :key="ethicsCase.uuid"
        :xs="24"
        :sm="12"
        :md="8"
        :lg="6"
      >
        <el-card
          shadow="hover"
          class="case-card"
          @click="viewCase(ethicsCase)"
        >
          <div class="case-cover">
            <img
              v-if="ethicsCase.cover_image"
              :src="ethicsCase.cover_image"
              :alt="ethicsCase.title"
            />
            <div v-else class="case-cover-placeholder">
              <el-icon :size="48"><ChatDotRound /></el-icon>
            </div>
          </div>
          <div class="case-content">
            <h3 class="case-title">{{ ethicsCase.title }}</h3>
            <p class="case-description">{{ ethicsCase.description }}</p>
            <div class="case-tags">
              <el-tag
                v-for="topic in ethicsCase.ethics_topics.slice(0, 2)"
                :key="topic"
                size="small"
                type="warning"
              >
                {{ topic }}
              </el-tag>
            </div>
            <div class="case-meta">
              <div class="meta-item">
                <el-icon><View /></el-icon>
                <span>{{ ethicsCase.view_count }}</span>
              </div>
              <div class="meta-item">
                <el-icon><Star /></el-icon>
                <span>{{ ethicsCase.like_count }}</span>
              </div>
              <el-tag :type="getDifficultyType(ethicsCase.difficulty)" size="small">
                {{ getDifficultyText(ethicsCase.difficulty) }}
              </el-tag>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 我的思辨活动 -->
    <el-card class="section-card" shadow="never">
      <template #header>
        <div class="card-header">
          <span>我的思辨活动</span>
          <el-button type="primary" size="small" @click="viewAllActivities">
            查看全部
          </el-button>
        </div>
      </template>
      <el-timeline v-if="myActivities.length > 0">
        <el-timeline-item
          v-for="activity in myActivities"
          :key="activity.uuid"
          :timestamp="activity.scheduled_at"
          placement="top"
        >
          <el-card shadow="hover">
            <div class="activity-item">
              <div class="activity-header">
                <h4>{{ activity.title }}</h4>
                <el-tag :type="getActivityStatusType(activity.status)">
                  {{ getActivityStatusText(activity.status) }}
                </el-tag>
              </div>
              <p class="activity-desc">{{ activity.description }}</p>
              <div class="activity-meta">
                <el-tag size="small">{{ getActivityTypeText(activity.activity_type) }}</el-tag>
                <el-button
                  v-if="activity.status === 'ongoing'"
                  type="primary"
                  size="small"
                  @click="joinActivity(activity)"
                >
                  参与讨论
                </el-button>
              </div>
            </div>
          </el-card>
        </el-timeline-item>
      </el-timeline>
      <el-empty v-else description="暂无参与的思辨活动" />
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  ChatDotRound,
  View,
  Star
} from '@element-plus/icons-vue'

const router = useRouter()

const ethicsTopics = [
  '全部',
  '数据隐私',
  '算法偏见',
  '技术滥用',
  'AI幻觉',
  '认知外包',
  '就业影响',
  '环境影响'
]

const selectedTopic = ref('全部')
const selectedDifficulty = ref('all')
const ethicsCases = ref([])
const myActivities = ref([])

const selectTopic = (topic) => {
  selectedTopic.value = topic
  loadCases()
}

const getDifficultyType = (difficulty) => {
  const types = {
    basic: 'success',
    intermediate: 'warning',
    advanced: 'danger'
  }
  return types[difficulty] || 'info'
}

const getDifficultyText = (difficulty) => {
  const texts = {
    basic: '基础',
    intermediate: '进阶',
    advanced: '高级'
  }
  return texts[difficulty] || difficulty
}

const getActivityStatusType = (status) => {
  const types = {
    planned: 'info',
    ongoing: 'success',
    completed: 'warning',
    cancelled: 'danger'
  }
  return types[status] || 'info'
}

const getActivityStatusText = (status) => {
  const texts = {
    planned: '计划中',
    ongoing: '进行中',
    completed: '已完成',
    cancelled: '已取消'
  }
  return texts[status] || status
}

const getActivityTypeText = (type) => {
  const texts = {
    debate: '辩论',
    case_analysis: '案例分析',
    role_play: '角色扮演',
    discussion: '讨论',
    reflection: '反思'
  }
  return texts[type] || type
}

const viewCase = (ethicsCase) => {
  router.push(`/ethics/case/${ethicsCase.uuid}`)
}

const viewAllActivities = () => {
  ElMessage.info('查看全部活动功能开发中...')
}

const joinActivity = (activity) => {
  ElMessage.info(`参与活动: ${activity.title}`)
}

const loadCases = async () => {
  try {
    const params = {}
    if (selectedTopic.value !== '全部') {
      params.topic = selectedTopic.value
    }
    if (selectedDifficulty.value !== 'all') {
      params.difficulty = selectedDifficulty.value
    }
    
    const response = await getEthicsCases(params)
    if (response && response.data) {
      ethicsCases.value = response.data.items || response.data || []
    }
  } catch (error) {
    console.error('加载案例失败:', error)
    ElMessage.error(error.response?.data?.detail || '加载数据失败')
    ethicsCases.value = []
  }
}

const loadMyActivities = async () => {
  try {
    const response = await getEthicsActivities({ limit: 5 })
    if (response && response.data) {
      myActivities.value = response.data.items || response.data || []
    }
  } catch (error) {
    console.error('加载活动失败:', error)
    myActivities.value = []
  }
}

onMounted(() => {
  loadCases()
  loadMyActivities()
})
</script>

<style scoped>
.ethics-page {
  padding: 0;
}

.page-header {
  margin-bottom: 20px;
  border-radius: 12px;
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
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

.filter-card {
  margin-bottom: 20px;
  border-radius: 12px;
  border: none;
}

.filter-section {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.filter-section:last-child {
  margin-bottom: 0;
}

.filter-label {
  font-weight: 600;
  color: #606266;
  white-space: nowrap;
}

.topic-tag {
  cursor: pointer;
  transition: all 0.3s ease;
}

.topic-tag:hover {
  transform: translateY(-2px);
}

.case-card {
  margin-bottom: 20px;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  border: none;
  overflow: hidden;
}

.case-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.case-cover {
  width: 100%;
  height: 180px;
  overflow: hidden;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
}

.case-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.case-cover-placeholder {
  color: white;
}

.case-content {
  padding: 16px 0;
}

.case-title {
  margin: 0 0 8px 0;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.case-description {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #606266;
  line-height: 1.6;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.case-tags {
  margin-bottom: 12px;
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.case-meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 14px;
  color: #909399;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 4px;
}

.section-card {
  margin-top: 20px;
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

.activity-item {
  cursor: pointer;
}

.activity-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.activity-header h4 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.activity-desc {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #606266;
  line-height: 1.6;
}

.activity-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
