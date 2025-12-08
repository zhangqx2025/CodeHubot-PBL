<template>
  <div class="dashboard">
    <!-- 欢迎横幅 -->
    <section class="welcome-banner">
      <div class="banner-content">
        <div class="welcome-text">
          <h1>欢迎来到项目式学习世界</h1>
          <p>通过真实项目探索知识，培养21世纪核心技能</p>
          <div class="learning-stats">
            <div class="stat-card">
              <div class="stat-number">{{ userStats.completedProjects }}</div>
              <div class="stat-label">已完成项目</div>
            </div>
            <div class="stat-card">
              <div class="stat-number">{{ userStats.currentProjects }}</div>
              <div class="stat-label">进行中项目</div>
            </div>
            <div class="stat-card">
              <div class="stat-number">{{ userStats.totalHours }}</div>
              <div class="stat-label">学习时长(小时)</div>
            </div>
          </div>
        </div>
        <div class="banner-illustration">
          <div class="learning-icon">🎯</div>
        </div>
      </div>
    </section>

    <!-- 我的课程 -->
    <section class="my-courses-section">
      <div class="section-header">
        <h2 class="section-title">我的课程</h2>
        <el-button type="primary" link @click="viewAllCourses">查看全部 →</el-button>
      </div>
      <div class="courses-quick-access">
        <div 
          v-for="course in myCourses" 
          :key="course.id"
          class="course-quick-card"
          @click="gotoCourseDetail(course.uuid)"
        >
          <div class="course-icon">📚</div>
          <div class="course-content">
            <h3>{{ course.title }}</h3>
            <div class="course-progress">
              <el-progress 
                :percentage="course.progress" 
                :show-text="false" 
                :stroke-width="4"
              />
              <span class="progress-text">{{ course.progress }}%</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- 我的项目进度 -->
    <section class="my-progress">
      <h2 class="section-title">进行中的项目</h2>
      <div class="progress-cards">
        <div class="progress-card" v-for="project in myProjects" :key="project.id">
          <div class="project-header">
            <div class="project-icon">{{ project.icon }}</div>
            <div class="project-info">
              <h3>{{ project.title }}</h3>
              <p>{{ project.description }}</p>
            </div>
            <div class="project-status" :class="project.status">
              {{ getStatusText(project.status) }}
            </div>
          </div>
          <div class="progress-bar">
            <div class="progress-fill" :style="{ width: project.progress + '%' }"></div>
          </div>
          <div class="progress-info">
            <span>进度: {{ project.progress }}%</span>
            <span>剩余: {{ project.remainingDays }}天</span>
          </div>
          <div class="project-actions">
            <el-button type="primary" size="small" @click="continueProject(project.id)">
              继续学习
            </el-button>
            <el-button size="small" @click="viewProjectDetail(project.id)">
              查看详情
            </el-button>
          </div>
        </div>
      </div>
    </section>

    <!-- 推荐项目 -->
    <section class="recommended-projects">
      <h2 class="section-title">为你推荐</h2>
      <div class="project-grid">
        <div 
          class="project-card" 
          :class="{ 'disabled': project.disabled }" 
          v-for="project in recommendedProjects" 
          :key="project.id"
        >
          <div class="card-header">
            <div class="project-category">{{ project.category }}</div>
            <div class="difficulty-badge" :class="project.difficulty">
              {{ project.difficulty }}
            </div>
            <div v-if="project.disabled" class="disabled-overlay">
              <span class="disabled-text">暂不可用</span>
            </div>
          </div>
          <div class="card-content">
            <h3>{{ project.title }}</h3>
            <p>{{ project.description }}</p>
            <div class="project-features">
              <div class="feature-item">
                <span class="feature-icon">⏱️</span>
                <span>{{ project.duration }}</span>
              </div>
              <div class="feature-item">
                <span class="feature-icon">👥</span>
                <span>{{ project.teamSize }}</span>
              </div>
              <div class="feature-item">
                <span class="feature-icon">🎯</span>
                <span>{{ project.skills.length }}项技能</span>
              </div>
            </div>
          </div>
          <div class="card-footer">
            <el-button 
              type="primary" 
              :disabled="project.disabled"
              @click="!project.disabled && startProject(project.id)"
            >
              开始项目
            </el-button>
            <el-button 
              :disabled="project.disabled"
              @click="!project.disabled && learnMore(project.id)"
            >
              了解更多
            </el-button>
          </div>
        </div>
      </div>
      <div class="section-footer">
        <el-button type="primary" size="large" @click="viewAllProjects" class="view-more-btn">
          查看更多项目 →
        </el-button>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/store/auth'

const router = useRouter()
const authStore = useAuthStore()

const userStats = reactive({
  completedProjects: 3,
  currentProjects: 2,
  totalHours: 45
})

const myCourses = ref([
  {
    id: 1,
    title: '智能家居AI助手项目',
    progress: 65
  }
])

const myProjects = ref([
  {
    id: 'smart-home',
    title: '智能家居AI助手项目',
    description: '创建智能AI助手，实现智能家居控制和自动化',
    icon: '🏠',
    status: 'in-progress',
    progress: 65,
    remainingDays: 12
  }
])

const recommendedProjects = ref([
  {
    id: 'smart-home',
    title: '智能家居AI助手项目',
    description: '通过8次课程学习如何创建智能AI助手，实现智能家居控制、语音交互、工作流自动化等功能',
    category: '科技创新',
    difficulty: '中级',
    duration: '8周',
    teamSize: '3-4人',
    skills: ['AI应用', '提示词设计', '工作流设计', '系统集成']
  },
  {
    id: 'eco-garden',
    title: '生态花园设计',
    description: '学习可持续发展理念，设计和建造校园生态花园，培养环保意识和实践能力',
    category: '环境科学',
    difficulty: '初级',
    duration: '6周',
    teamSize: '4-5人',
    skills: ['生态设计', '植物学', '环境保护', '团队协作'],
    disabled: true
  }
])

const getStatusText = (status) => {
  const statusMap = {
    'in-progress': '进行中',
    'completed': '已完成',
    'not-started': '未开始'
  }
  return statusMap[status] || status
}

const continueProject = (projectId) => {
  router.push(`/project/${projectId}`)
}

const viewProjectDetail = (projectId) => {
  router.push(`/project/${projectId}`)
}

const startProject = (projectId) => {
  router.push(`/project/${projectId}`)
}

const learnMore = (projectId) => {
  router.push('/projects')
}

const viewAllProjects = () => {
  router.push('/projects')
}

const viewAllCourses = () => {
  router.push('/courses')
}

const gotoCourseDetail = (courseId) => {
  router.push(`/course/${courseId}`)
}

onMounted(() => {
  // 可以在这里加载用户数据
})
</script>

<style scoped>
.dashboard {
  background: #f8fafc;
  min-height: calc(100vh - 64px);
  padding: 24px;
}

.welcome-banner {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 16px;
  padding: 48px;
  margin-bottom: 32px;
  color: white;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
}

.banner-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  max-width: 1200px;
  margin: 0 auto;
}

.welcome-text h1 {
  font-size: 32px;
  font-weight: 700;
  margin: 0 0 12px 0;
}

.welcome-text p {
  font-size: 18px;
  opacity: 0.9;
  margin: 0 0 24px 0;
}


.learning-stats {
  display: flex;
  gap: 24px;
}

.stat-card {
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(10px);
  border-radius: 12px;
  padding: 20px;
  text-align: center;
  min-width: 120px;
}

.stat-number {
  font-size: 36px;
  font-weight: 700;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 14px;
  opacity: 0.9;
}

.banner-illustration {
  font-size: 120px;
}

.section-title {
  font-size: 24px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 24px 0;
}

.my-courses-section {
  margin-bottom: 48px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.courses-quick-access {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
}

.course-quick-card {
  background: white;
  padding: 20px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  gap: 16px;
}

.course-quick-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
}

.course-icon {
  font-size: 48px;
  line-height: 1;
}

.course-content {
  flex: 1;
}

.course-content h3 {
  font-size: 16px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 12px 0;
}

.course-progress {
  display: flex;
  align-items: center;
  gap: 12px;
}

.course-progress .progress-text {
  font-size: 12px;
  color: #64748b;
  min-width: 35px;
}

.my-progress {
  margin-bottom: 48px;
}

.progress-cards {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.progress-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: transform 0.2s, box-shadow 0.2s;
}

.progress-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
}

.project-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 16px;
}

.project-icon {
  font-size: 48px;
}

.project-info {
  flex: 1;
}

.project-info h3 {
  font-size: 20px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 8px 0;
}

.project-info p {
  color: #64748b;
  margin: 0;
}

.project-status {
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
}

.project-status.in-progress {
  background: #dbeafe;
  color: #1e40af;
}

.progress-bar {
  height: 8px;
  background: #e5e7eb;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 12px;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #3b82f6, #8b5cf6);
  transition: width 0.3s ease;
}

.progress-info {
  display: flex;
  justify-content: space-between;
  font-size: 14px;
  color: #64748b;
  margin-bottom: 16px;
}

.project-actions {
  display: flex;
  gap: 12px;
}

.recommended-projects {
  margin-bottom: 48px;
}

.project-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 24px;
  margin-bottom: 32px;
}

.project-card {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: transform 0.2s, box-shadow 0.2s;
  position: relative;
}

.project-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.12);
}

.project-card.disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
}

.project-category {
  font-size: 12px;
  color: #64748b;
  font-weight: 500;
}

.difficulty-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
}

.difficulty-badge.中级 {
  background: #fef3c7;
  color: #92400e;
}

.difficulty-badge.初级 {
  background: #d1fae5;
  color: #065f46;
}

.disabled-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(255, 255, 255, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10;
}

.disabled-text {
  font-size: 18px;
  font-weight: 600;
  color: #64748b;
}

.card-content {
  padding: 20px;
}

.card-content h3 {
  font-size: 20px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 12px 0;
}

.card-content p {
  color: #64748b;
  font-size: 14px;
  line-height: 1.6;
  margin: 0 0 16px 0;
}

.project-features {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 16px;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #64748b;
}

.feature-icon {
  font-size: 16px;
}

.card-footer {
  padding: 16px 20px;
  border-top: 1px solid #e5e7eb;
  display: flex;
  gap: 12px;
}

.section-footer {
  text-align: center;
}

.view-more-btn {
  padding: 12px 32px;
}

@media (max-width: 768px) {
  .banner-content {
    flex-direction: column;
    text-align: center;
  }
  
  .learning-stats {
    justify-content: center;
  }
  
  .project-grid {
    grid-template-columns: 1fr;
  }
}
</style>

