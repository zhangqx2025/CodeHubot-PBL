<template>
  <div class="projects-page">
    <div class="page-header">
      <h1>项目列表</h1>
      <p>浏览所有可用的项目式学习课程</p>
    </div>

    <div class="filters">
      <el-select v-model="selectedCategory" placeholder="选择分类" clearable style="width: 200px">
        <el-option label="全部" value="" />
        <el-option label="科技创新" value="科技创新" />
        <el-option label="环境科学" value="环境科学" />
        <el-option label="社会科学" value="社会科学" />
      </el-select>
      
      <el-select v-model="selectedDifficulty" placeholder="选择难度" clearable style="width: 200px">
        <el-option label="全部" value="" />
        <el-option label="beginner" value="beginner" />
        <el-option label="intermediate" value="intermediate" />
        <el-option label="advanced" value="advanced" />
      </el-select>
      
      <el-input
        v-model="searchText"
        placeholder="搜索项目..."
        :prefix-icon="Search"
        style="width: 300px"
        clearable
      />
    </div>

    <div v-if="loading" class="loading-container">
      <el-skeleton :rows="5" animated />
    </div>

    <div v-else-if="error" class="error-container">
      <el-empty :description="error" />
    </div>

    <div v-else class="projects-grid">
      <div 
        class="project-card" 
        v-for="project in filteredProjects" 
        :key="project.id"
        @click="viewProject(project.id)"
      >
        <div class="card-header">
          <div class="project-category">{{ project.category || '综合实践' }}</div>
          <div class="difficulty-badge" :class="project.course?.difficulty || 'beginner'">
            {{ getDifficultyLabel(project.course?.difficulty) }}
          </div>
        </div>
        <div class="card-content">
          <h3>{{ project.title }}</h3>
          <p>{{ project.description }}</p>
          <div class="project-features">
            <div class="feature-item" v-if="project.course?.duration">
              <span class="feature-icon">⏱️</span>
              <span>{{ project.course.duration }}</span>
            </div>
            <div class="feature-item">
              <span class="feature-icon">👥</span>
              <span>{{ project.teamSize || '3-4人' }}</span>
            </div>
            <div class="feature-item" v-if="project.skills">
              <span class="feature-icon">🎯</span>
              <span>{{ project.skills.length }}项技能</span>
            </div>
          </div>
        </div>
        <div class="card-footer">
          <el-button type="primary" @click.stop="startProject(project.id)">
            开始项目
          </el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Search } from '@element-plus/icons-vue'
import { getProjects } from '../api/project'

const router = useRouter()

const selectedCategory = ref('')
const selectedDifficulty = ref('')
const searchText = ref('')
const projects = ref([])
const loading = ref(false)
const error = ref(null)

const fetchProjects = async () => {
  loading.value = true
  error.value = null
  try {
    const data = await getProjects()
    projects.value = data.map(p => ({
        ...p,
        // Mock data for display if missing
        category: '科技创新', 
        teamSize: '3-4人',
        skills: ['AI应用', '系统集成']
    }))
  } catch (err) {
    console.error('Failed to fetch projects:', err)
    error.value = '获取项目列表失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchProjects()
})

const getDifficultyLabel = (difficulty) => {
    const map = {
        'beginner': '初级',
        'intermediate': '中级',
        'advanced': '高级'
    }
    return map[difficulty] || '初级'
}

const filteredProjects = computed(() => {
  return projects.value.filter(project => {
    const matchCategory = !selectedCategory.value || project.category === selectedCategory.value
    const matchDifficulty = !selectedDifficulty.value || (project.course && project.course.difficulty === selectedDifficulty.value)
    const matchSearch = !searchText.value || 
      project.title.toLowerCase().includes(searchText.value.toLowerCase()) ||
      (project.description && project.description.toLowerCase().includes(searchText.value.toLowerCase()))
    
    return matchCategory && matchDifficulty && matchSearch
  })
})

const viewProject = (projectId) => {
  router.push(`/project/${projectId}`)
}

const startProject = (projectId) => {
  router.push(`/project/${projectId}`)
}
</script>

<style scoped>
.projects-page {
  padding: 24px;
  max-width: 1400px;
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

.filters {
  display: flex;
  gap: 16px;
  margin-bottom: 32px;
  flex-wrap: wrap;
}

.projects-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 24px;
}

.loading-container, .error-container {
    padding: 40px;
    text-align: center;
}

.project-card {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: transform 0.2s, box-shadow 0.2s;
  cursor: pointer;
}

.project-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.12);
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

.difficulty-badge.intermediate {
  background: #fef3c7;
  color: #92400e;
}

.difficulty-badge.beginner {
  background: #d1fae5;
  color: #065f46;
}

.difficulty-badge.advanced {
    background: #fee2e2;
    color: #991b1b;
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
}

@media (max-width: 768px) {
  .projects-grid {
    grid-template-columns: 1fr;
  }
}
</style>
