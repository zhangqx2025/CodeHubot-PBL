<template>
  <div class="progress-page">
    <div class="page-header">
      <h1>学习进度</h1>
      <p>查看你的学习统计和成就</p>
    </div>

    <div class="stats-overview">
      <div class="stat-card">
        <div class="stat-icon">📚</div>
        <div class="stat-content">
          <div class="stat-value">{{ stats.totalCourses }}</div>
          <div class="stat-label">学习课程</div>
        </div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon">✅</div>
        <div class="stat-content">
          <div class="stat-value">{{ stats.completedTasks }}</div>
          <div class="stat-label">完成任务</div>
        </div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon">⏱️</div>
        <div class="stat-content">
          <div class="stat-value">{{ stats.totalHours }}</div>
          <div class="stat-label">学习时长(小时)</div>
        </div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon">🏆</div>
        <div class="stat-content">
          <div class="stat-value">{{ stats.achievements }}</div>
          <div class="stat-label">获得成就</div>
        </div>
      </div>
    </div>

    <div class="progress-sections">
      <div class="section-card">
        <h2>课程进度</h2>
        <div class="course-progress-list">
          <div 
            class="course-item" 
            v-for="course in courses" 
            :key="course.id"
          >
            <div class="course-info">
              <h3>{{ course.title }}</h3>
              <p>{{ course.description }}</p>
            </div>
            <div class="course-progress">
              <el-progress :percentage="course.progress" />
              <span class="progress-text">{{ course.progress }}%</span>
            </div>
            <el-button type="primary" size="small" @click="continueCourse(course.id)">
              继续学习
            </el-button>
          </div>
        </div>
      </div>

      <div class="section-card">
        <h2>最近活动</h2>
        <div class="activity-list">
          <div 
            class="activity-item" 
            v-for="activity in recentActivities" 
            :key="activity.id"
          >
            <div class="activity-icon">{{ activity.icon }}</div>
            <div class="activity-content">
              <div class="activity-title">{{ activity.title }}</div>
              <div class="activity-time">{{ activity.time }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

const stats = ref({
  totalCourses: 3,
  completedTasks: 15,
  totalHours: 45,
  achievements: 8
})

const courses = ref([
  {
    id: 'smart-home',
    title: '智能家居AI助手项目',
    description: '通过8次课程学习如何创建智能AI助手',
    progress: 65
  },
  {
    id: 'eco-garden',
    title: '生态花园设计',
    description: '学习可持续发展理念，设计和建造校园生态花园',
    progress: 30
  }
])

const recentActivities = ref([
  {
    id: 1,
    icon: '✅',
    title: '完成了任务：创建第一个智能体',
    time: '2小时前'
  },
  {
    id: 2,
    icon: '📚',
    title: '学习了单元：提示词优化',
    time: '1天前'
  },
  {
    id: 3,
    icon: '🏆',
    title: '获得了成就：初出茅庐',
    time: '2天前'
  }
])

const continueCourse = (courseId) => {
  router.push(`/project/${courseId}`)
}
</script>

<style scoped>
.progress-page {
  padding: 24px;
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 32px;
}

.page-header h1 {
  font-size: 32px;
  font-weight: 700;
  color: #1e293b;
  margin: 0 0 8px 0;
}

.page-header p {
  color: #64748b;
  font-size: 16px;
  margin: 0;
}

.stats-overview {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 24px;
  margin-bottom: 32px;
}

.stat-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.stat-icon {
  font-size: 48px;
}

.stat-content {
  flex: 1;
}

.stat-value {
  font-size: 32px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 14px;
  color: #64748b;
}

.progress-sections {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}

.section-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.section-card h2 {
  font-size: 20px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 24px 0;
}

.course-progress-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.course-item {
  padding: 16px;
  background: #f8fafc;
  border-radius: 8px;
}

.course-info h3 {
  font-size: 16px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 8px 0;
}

.course-info p {
  font-size: 14px;
  color: #64748b;
  margin: 0 0 12px 0;
}

.course-progress {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.course-progress .el-progress {
  flex: 1;
}

.progress-text {
  font-size: 14px;
  font-weight: 600;
  color: #3b82f6;
  min-width: 50px;
}

.activity-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.activity-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: #f8fafc;
  border-radius: 8px;
}

.activity-icon {
  font-size: 24px;
}

.activity-content {
  flex: 1;
}

.activity-title {
  font-size: 14px;
  font-weight: 500;
  color: #1e293b;
  margin-bottom: 4px;
}

.activity-time {
  font-size: 12px;
  color: #64748b;
}

@media (max-width: 768px) {
  .progress-sections {
    grid-template-columns: 1fr;
  }
  
  .stats-overview {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>

