<template>
  <div class="student-portfolio-container">
    <el-card class="header-card">
      <div class="page-header">
        <div>
          <h2>学习档案</h2>
          <p class="subtitle">记录你的成长轨迹，展示学习成果</p>
        </div>
        <el-button type="primary" :icon="Share" @click="handleSharePortfolio">
          分享档案
        </el-button>
      </div>
    </el-card>

    <!-- 个人信息卡片 -->
    <el-card class="profile-card">
      <div class="profile-header">
        <el-avatar :size="80" :src="studentInfo.avatar">
          {{ studentInfo.name?.charAt(0) }}
        </el-avatar>
        <div class="profile-info">
          <h3>{{ studentInfo.name }}</h3>
          <p>{{ studentInfo.school }} - {{ studentInfo.class }}</p>
          <div class="profile-stats">
            <div class="stat-item">
              <span class="stat-value">{{ statistics.totalCourses }}</span>
              <span class="stat-label">学习课程</span>
            </div>
            <div class="stat-item">
              <span class="stat-value">{{ statistics.completedProjects }}</span>
              <span class="stat-label">完成项目</span>
            </div>
            <div class="stat-item">
              <span class="stat-value">{{ statistics.totalOutputs }}</span>
              <span class="stat-label">项目成果</span>
            </div>
            <div class="stat-item">
              <span class="stat-value">{{ statistics.achievements }}</span>
              <span class="stat-label">获得成就</span>
            </div>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 标签页导航 -->
    <el-card class="content-card">
      <el-tabs v-model="activeTab" @tab-change="handleTabChange">
        <!-- 学习历程 -->
        <el-tab-pane label="学习历程" name="timeline">
          <el-timeline>
            <el-timeline-item
              v-for="item in timeline"
              :key="item.id"
              :timestamp="item.timestamp"
              placement="top"
            >
              <el-card>
                <h4>{{ item.title }}</h4>
                <p>{{ item.content }}</p>
                <el-tag v-if="item.type" :type="getTypeTagType(item.type)" size="small">
                  {{ getTypeLabel(item.type) }}
                </el-tag>
              </el-card>
            </el-timeline-item>
          </el-timeline>
          
          <el-empty
            v-if="timeline.length === 0"
            description="还没有学习记录"
          />
        </el-tab-pane>

        <!-- 技能雷达图 -->
        <el-tab-pane label="能力分析" name="skills">
          <div class="skills-section">
            <div class="radar-chart">
              <div ref="radarChartRef" style="width: 100%; height: 400px;"></div>
            </div>
            
            <div class="skills-list">
              <h3>技能详情</h3>
              <div
                v-for="skill in skills"
                :key="skill.name"
                class="skill-item"
              >
                <div class="skill-header">
                  <span class="skill-name">{{ skill.name }}</span>
                  <span class="skill-value">{{ skill.value }}%</span>
                </div>
                <el-progress
                  :percentage="skill.value"
                  :color="skill.color"
                  :show-text="false"
                />
              </div>
            </div>
          </div>
        </el-tab-pane>

        <!-- 成就徽章 -->
        <el-tab-pane label="成就徽章" name="achievements">
          <div class="achievements-grid">
            <div
              v-for="achievement in achievements"
              :key="achievement.id"
              class="achievement-card"
              :class="{ unlocked: achievement.unlocked }"
            >
              <div class="achievement-icon">
                <img v-if="achievement.icon" :src="achievement.icon" alt="成就图标" />
                <el-icon v-else :size="50"><Trophy /></el-icon>
              </div>
              <h4>{{ achievement.name }}</h4>
              <p>{{ achievement.description }}</p>
              <div v-if="achievement.unlocked" class="unlock-date">
                {{ formatDate(achievement.unlocked_at) }} 解锁
              </div>
              <div v-else class="locked-overlay">
                <el-icon><Lock /></el-icon>
              </div>
            </div>
          </div>
          
          <el-empty
            v-if="achievements.length === 0"
            description="还没有获得成就"
          />
        </el-tab-pane>

        <!-- 项目作品集 -->
        <el-tab-pane label="作品展示" name="portfolio">
          <div class="portfolio-grid">
            <el-card
              v-for="work in portfolioWorks"
              :key="work.id"
              class="work-card"
              shadow="hover"
            >
              <div class="work-cover">
                <img v-if="work.thumbnail" :src="work.thumbnail" alt="作品封面" />
                <div v-else class="placeholder-cover">
                  <el-icon :size="50"><Document /></el-icon>
                </div>
              </div>
              <div class="work-info">
                <h4>{{ work.title }}</h4>
                <p>{{ work.description }}</p>
                <div class="work-meta">
                  <el-tag size="small">{{ work.course_name }}</el-tag>
                  <span>{{ formatDate(work.created_at) }}</span>
                </div>
              </div>
            </el-card>
          </div>
          
          <el-empty
            v-if="portfolioWorks.length === 0"
            description="还没有作品"
          />
        </el-tab-pane>

        <!-- 评价记录 -->
        <el-tab-pane label="评价记录" name="assessments">
          <div class="assessments-list">
            <el-card
              v-for="assessment in assessments"
              :key="assessment.id"
              class="assessment-card"
            >
              <div class="assessment-header">
                <div>
                  <h4>{{ assessment.project_name }}</h4>
                  <span class="assessment-type">
                    {{ getAssessmentTypeLabel(assessment.assessor_role) }}
                  </span>
                </div>
                <div class="assessment-score">
                  <span class="score-value">{{ assessment.total_score }}</span>
                  <span class="score-max">/{{ assessment.max_score }}</span>
                </div>
              </div>
              
              <div class="assessment-dimensions">
                <div
                  v-for="dim in assessment.dimensions"
                  :key="dim.dimension"
                  class="dimension-item"
                >
                  <span class="dimension-name">{{ dim.dimension }}</span>
                  <el-rate
                    :model-value="dim.score / 20"
                    disabled
                    show-score
                    text-color="#ff9900"
                  />
                </div>
              </div>
              
              <div v-if="assessment.comments" class="assessment-comments">
                <p><strong>评语：</strong>{{ assessment.comments }}</p>
              </div>
              
              <div class="assessment-footer">
                <span>{{ formatDate(assessment.created_at) }}</span>
              </div>
            </el-card>
          </div>
          
          <el-empty
            v-if="assessments.length === 0"
            description="还没有评价记录"
          />
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import {
  Share,
  Document,
  Trophy,
  Lock
} from '@element-plus/icons-vue'

const activeTab = ref('timeline')
const radarChartRef = ref(null)

const studentInfo = reactive({
  name: '学生用户',
  avatar: '',
  school: '示例学校',
  class: '示例班级'
})

const statistics = reactive({
  totalCourses: 0,
  completedProjects: 0,
  totalOutputs: 0,
  achievements: 0
})

const timeline = ref([])
const skills = ref([])
const achievements = ref([])
const portfolioWorks = ref([])
const assessments = ref([])

const getTypeLabel = (type) => {
  const typeMap = {
    course: '课程',
    project: '项目',
    task: '任务',
    achievement: '成就',
    assessment: '评价'
  }
  return typeMap[type] || type
}

const getTypeTagType = (type) => {
  const typeMap = {
    course: 'primary',
    project: 'success',
    task: 'warning',
    achievement: 'danger',
    assessment: 'info'
  }
  return typeMap[type] || ''
}

const getAssessmentTypeLabel = (role) => {
  const roleMap = {
    teacher: '教师评价',
    student: '同学互评',
    expert: '专家评价',
    self: '自我评价'
  }
  return roleMap[role] || role
}

const formatDate = (date) => {
  if (!date) return ''
  return new Date(date).toLocaleDateString('zh-CN')
}

const handleTabChange = (tabName) => {
  if (tabName === 'skills') {
    nextTick(() => {
      initRadarChart()
    })
  }
}

const handleSharePortfolio = () => {
  ElMessage.info('分享功能开发中...')
}

const loadStudentInfo = async () => {
  try {
    // TODO: 调用API获取学生信息
    ElMessage.info('学生信息加载功能开发中...')
  } catch (error) {
    console.error('加载学生信息失败:', error)
  }
}

const loadStatistics = async () => {
  try {
    // TODO: 调用API获取统计数据
  } catch (error) {
    console.error('加载统计数据失败:', error)
  }
}

const loadTimeline = async () => {
  try {
    // TODO: 调用API获取学习历程
    timeline.value = []
  } catch (error) {
    console.error('加载学习历程失败:', error)
  }
}

const loadSkills = async () => {
  try {
    // TODO: 调用API获取技能数据
    skills.value = [
      { name: '计算思维', value: 85, color: '#409EFF' },
      { name: '编程能力', value: 78, color: '#67C23A' },
      { name: '问题解决', value: 82, color: '#E6A23C' },
      { name: '创新设计', value: 75, color: '#F56C6C' },
      { name: '团队协作', value: 88, color: '#909399' },
      { name: '伦理素养', value: 80, color: '#409EFF' }
    ]
  } catch (error) {
    console.error('加载技能数据失败:', error)
  }
}

const loadAchievements = async () => {
  try {
    // TODO: 调用API获取成就数据
    achievements.value = []
  } catch (error) {
    console.error('加载成就数据失败:', error)
  }
}

const loadPortfolioWorks = async () => {
  try {
    // TODO: 调用API获取作品集
    portfolioWorks.value = []
  } catch (error) {
    console.error('加载作品集失败:', error)
  }
}

const loadAssessments = async () => {
  try {
    // TODO: 调用API获取评价记录
    assessments.value = []
  } catch (error) {
    console.error('加载评价记录失败:', error)
  }
}

const initRadarChart = () => {
  // TODO: 使用 ECharts 初始化雷达图
  // 需要安装 echarts: npm install echarts
  if (!radarChartRef.value) return
  
  // 示例：
  // import * as echarts from 'echarts'
  // const chart = echarts.init(radarChartRef.value)
  // chart.setOption({ ... })
}

onMounted(() => {
  loadStudentInfo()
  loadStatistics()
  loadTimeline()
  loadSkills()
  loadAchievements()
  loadPortfolioWorks()
  loadAssessments()
})
</script>

<style scoped>
.student-portfolio-container {
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

.profile-card {
  margin-bottom: 20px;
}

.profile-header {
  display: flex;
  gap: 24px;
  align-items: center;
}

.profile-info h3 {
  margin: 0 0 8px 0;
  font-size: 20px;
  color: #1e293b;
}

.profile-info p {
  margin: 0 0 16px 0;
  color: #64748b;
}

.profile-stats {
  display: flex;
  gap: 32px;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.stat-value {
  font-size: 24px;
  font-weight: 600;
  color: #3b82f6;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 12px;
  color: #64748b;
}

.content-card {
  margin-bottom: 20px;
}

.skills-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 32px;
}

.skills-list h3 {
  margin: 0 0 20px 0;
  font-size: 18px;
  color: #1e293b;
}

.skill-item {
  margin-bottom: 20px;
}

.skill-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
}

.skill-name {
  font-weight: 500;
  color: #1e293b;
}

.skill-value {
  color: #64748b;
  font-size: 14px;
}

.achievements-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 20px;
}

.achievement-card {
  position: relative;
  padding: 24px;
  text-align: center;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  transition: all 0.3s;
}

.achievement-card.unlocked {
  border-color: #3b82f6;
  background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%);
}

.achievement-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
}

.achievement-icon {
  width: 80px;
  height: 80px;
  margin: 0 auto 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.achievement-icon img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 50%;
}

.achievement-card h4 {
  margin: 0 0 8px 0;
  font-size: 16px;
  color: #1e293b;
}

.achievement-card p {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #64748b;
  line-height: 1.5;
}

.unlock-date {
  font-size: 12px;
  color: #3b82f6;
}

.locked-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 32px;
  border-radius: 12px;
}

.portfolio-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
}

.work-card {
  cursor: pointer;
  transition: all 0.3s;
}

.work-card:hover {
  transform: translateY(-4px);
}

.work-cover {
  width: 100%;
  height: 160px;
  overflow: hidden;
  border-radius: 8px;
  margin-bottom: 12px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.work-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.placeholder-cover {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.work-info h4 {
  margin: 0 0 8px 0;
  font-size: 16px;
  color: #1e293b;
}

.work-info p {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #64748b;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.work-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  color: #94a3b8;
}

.assessments-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.assessment-card {
  padding: 20px;
}

.assessment-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}

.assessment-header h4 {
  margin: 0 0 8px 0;
  font-size: 16px;
  color: #1e293b;
}

.assessment-type {
  display: inline-block;
  padding: 2px 8px;
  background: #e0e7ff;
  color: #3b82f6;
  border-radius: 4px;
  font-size: 12px;
}

.assessment-score {
  text-align: right;
}

.score-value {
  font-size: 32px;
  font-weight: 600;
  color: #3b82f6;
}

.score-max {
  font-size: 16px;
  color: #94a3b8;
}

.assessment-dimensions {
  margin-bottom: 16px;
  padding: 16px;
  background: #f8fafc;
  border-radius: 8px;
}

.dimension-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.dimension-item:last-child {
  margin-bottom: 0;
}

.dimension-name {
  font-size: 14px;
  color: #475569;
  font-weight: 500;
}

.assessment-comments {
  margin-bottom: 16px;
  padding: 12px;
  background: #fef3c7;
  border-left: 3px solid #f59e0b;
  border-radius: 4px;
  font-size: 14px;
  line-height: 1.6;
}

.assessment-footer {
  padding-top: 12px;
  border-top: 1px solid #e2e8f0;
  font-size: 12px;
  color: #94a3b8;
}

:deep(.el-timeline-item__timestamp) {
  color: #64748b;
  font-size: 13px;
}
</style>
