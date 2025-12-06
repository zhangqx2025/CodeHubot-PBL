<template>
  <div class="project-detail">
    <div class="project-header">
      <el-button :icon="ArrowLeft" @click="goBack" class="back-btn">返回</el-button>
      <h1>{{ project.title }}</h1>
      <p class="description">{{ project.description }}</p>
    </div>

    <div class="project-content">
      <el-tabs v-model="activeTab">
        <el-tab-pane label="课程概览" name="overview">
          <div class="overview-section">
            <h3>项目介绍</h3>
            <p>{{ project.description }}</p>
            
            <h3>学习目标</h3>
            <ul class="learning-goals">
              <li v-for="goal in project.learningGoals" :key="goal">{{ goal }}</li>
            </ul>
            
            <h3>课程结构</h3>
            <div class="units-list">
              <div 
                class="unit-item" 
                v-for="unit in project.units" 
                :key="unit.id"
                @click="goToUnit(unit.id)"
              >
                <div class="unit-left">
                  <div class="unit-number">第{{ unit.order }}单元</div>
                  <div class="unit-info">
                    <div class="unit-title">{{ unit.title }}</div>
                    <div class="unit-meta" v-if="unit.duration">
                      <span>⏱️ {{ unit.duration }}</span>
                      <span class="divider">•</span>
                      <span>📝 {{ unit.taskCount }}个任务</span>
                    </div>
                  </div>
                </div>
                <div class="unit-status" :class="unit.status">
                  {{ getStatusText(unit.status) }}
                </div>
              </div>
            </div>
          </div>
        </el-tab-pane>
        
        <el-tab-pane label="任务列表" name="tasks">
          <div class="tasks-section">
            <div class="task-item" v-for="task in project.tasks" :key="task.id">
              <div class="task-header">
                <h4>{{ task.title }}</h4>
                <el-tag :type="getTaskTagType(task.status)">{{ getStatusText(task.status) }}</el-tag>
              </div>
              <p>{{ task.description }}</p>
              <div class="task-meta">
                <span>类型: {{ task.type }}</span>
                <span>难度: {{ task.difficulty }}</span>
                <span>预计时长: {{ task.estimatedTime }}</span>
              </div>
              <el-button type="primary" size="small" @click="goToTask(task.id)">
                开始任务
              </el-button>
            </div>
          </div>
        </el-tab-pane>
        
        <el-tab-pane label="团队信息" name="team">
          <div class="team-section">
            <div class="team-header-info" v-if="project.teamName">
                <h2>{{ project.teamName }}</h2>
                <p class="team-slogan">{{ project.teamSlogan }}</p>
            </div>

            <h3>团队成员</h3>
            <div class="team-members">
              <div class="member-item" v-for="member in project.teamMembers" :key="member.id" :class="{ 'is-me': member.isMe }">
                <el-avatar :size="50" class="member-avatar">{{ member.name.charAt(0) }}</el-avatar>
                <div class="member-info">
                  <div class="member-header">
                      <span class="member-name">{{ member.name }}</span>
                      <el-tag size="small" v-if="member.isMe" type="success" effect="dark" class="role-tag">我</el-tag>
                      <el-tag size="small" :type="getRoleTagType(member.role)" effect="plain" class="role-tag">{{ member.role }}</el-tag>
                  </div>
                  <div class="member-tags">
                      <el-tag v-for="tag in member.tags" :key="tag" size="small" type="info" class="skill-tag">{{ tag }}</el-tag>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </el-tab-pane>
      </el-tabs>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ArrowLeft } from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()

const activeTab = ref('overview')

const project = ref({
  id: '',
  title: '',
  description: '',
  learningGoals: [],
  units: [],
  tasks: [],
  teamName: '',
  teamSlogan: '',
  teamMembers: []
})

// 智能家居项目数据
const smartHomeProject = {
  id: 'smart-home',
  title: 'EcoHome - AI Agent 驱动的智能家居中控实战',
  description: '利用 Coze 平台搭建一个具备自然语言理解能力的“管家智能体” Jarvis-Lite，它可以理解复杂的模糊指令，并自主决策调用 API 控制家里的设备，甚至根据环境自动执行任务。',
  learningGoals: [
    '理解 AI Agent 核心概念：LLM + Memory + Tools + Planning',
    '掌握 Coze 平台开发与提示词工程 (Prompt Engineering)',
    '学习物联网设备接入与 HTTP/MQTT 通信协议',
    '设计智能体决策工作流与意图识别逻辑',
    '实现自然语言处理 (NLP) 与语音交互',
    '开发前端可视化界面并对接 AI Agent API',
    '掌握系统安全、隐私保护与自动化场景联动',
    '完成全链路集成测试与项目部署'
  ],
  units: [
    { id: 'unit-1', order: 1, title: '智能体基础与扣子平台入门', status: 'in-progress', duration: '1周', taskCount: 6 },
    { id: 'unit-2', order: 2, title: '硬件设备接入与通信协议', status: 'locked', duration: '1周', taskCount: 2 },
    { id: 'unit-3', order: 3, title: '智能体框架与决策引擎', status: 'locked', duration: '1.5周', taskCount: 2 },
    { id: 'unit-4', order: 4, title: '自然语言处理与语音交互', status: 'locked', duration: '1.5周', taskCount: 2 },
    { id: 'unit-5', order: 5, title: '用户界面与交互设计', status: 'locked', duration: '1周', taskCount: 2 },
    { id: 'unit-6', order: 6, title: '场景联动与自动化', status: 'locked', duration: '1周', taskCount: 2 },
    { id: 'unit-7', order: 7, title: '安全与隐私保护', status: 'locked', duration: '1周', taskCount: 2 },
    { id: 'unit-8', order: 8, title: '系统集成与项目部署', status: 'locked', duration: '1周', taskCount: 2 }
  ],
  tasks: [
    {
      id: 'task-1-1',
      title: 'Hello World (创建你的 Agent)',
      description: '注册 Coze 账号，创建一个名为 Jarvis-Lite 的 Bot，并设置基本信息。',
      type: '实践',
      difficulty: '简单',
      estimatedTime: '30分钟',
      status: 'completed'
    },
    {
      id: 'task-1-2',
      title: '注入灵魂 (编写人设 Prompt)',
      description: '使用 RTF 框架编写 Prompt，设定管家的人设与回复逻辑，让它知道自己是谁。',
      type: '实践',
      difficulty: '中等',
      estimatedTime: '45分钟',
      status: 'in-progress'
    },
    {
      id: 'task-1-3',
      title: '初次调试',
      description: '在预览窗口与 Agent 对话，验证人设是否生效，测试基本问答。',
      type: '测试',
      difficulty: '简单',
      estimatedTime: '20分钟',
      status: 'pending'
    },
    {
      id: 'task-1-4',
      title: '外挂大脑 (知识库)',
      description: '创建“家庭设备说明书”知识库并上传文档，增强 Agent 的回答能力。',
      type: '实践',
      difficulty: '中等',
      estimatedTime: '40分钟',
      status: 'pending'
    },
    {
      id: 'task-1-5',
      title: '初识插件',
      description: '添加天气或时间插件，让 Agent 具备查询实时信息的能力。',
      type: '实践',
      difficulty: '简单',
      estimatedTime: '30分钟',
      status: 'pending'
    },
    {
      id: 'task-1-6',
      title: '记忆管理与发布',
      description: '设置数据库变量记住用户偏好，并将 Agent 发布到豆包或微信客服。',
      type: '实践',
      difficulty: '中等',
      estimatedTime: '45分钟',
      status: 'pending'
    }
  ],
  teamName: '🚀 智行者小队',
  teamSlogan: '用 AI 改变生活，让家更懂你',
  teamMembers: [
    { id: 101, name: '张齐勋', role: '组长', tags: ['全栈', '统筹'], isMe: true },
    { id: 102, name: '李明', role: '成员', tags: ['PM', '设计'], isMe: false },
    { id: 103, name: '王强', role: '成员', tags: ['AI', '后端'], isMe: false },
    { id: 104, name: '赵雪', role: '成员', tags: ['前端', '测试'], isMe: false },
    { id: 201, name: '孙老师', role: '导师', tags: ['指导'], isMe: false }
  ]
}

// 默认演示项目数据
const defaultProject = {
  id: 'demo',
  title: '示例项目：Web开发入门',
  description: '这是一个示例项目，用于演示平台功能。',
  learningGoals: ['掌握HTML/CSS基础', '学习Vue.js框架'],
  units: [
    { id: 'u1', order: 1, title: 'HTML基础', status: 'completed', duration: '1周', taskCount: 3 },
    { id: 'u2', order: 2, title: 'CSS样式', status: 'in-progress', duration: '1周', taskCount: 4 }
  ],
  tasks: [
    { id: 't1', title: '编写第一个HTML页面', description: '创建一个包含标题和段落的HTML文件', type: '实践', difficulty: '简单', estimatedTime: '30分钟', status: 'completed' }
  ],
  teamName: 'Web 探索者',
  teamSlogan: 'Hello World!',
  teamMembers: [
    { id: 1, name: '张三', role: '组长', tags: ['前端'], isMe: true },
    { id: 2, name: '李四', role: '成员', tags: ['设计'], isMe: false }
  ]
}

const loadProjectData = () => {
  const projectId = route.params.id
  if (projectId === 'smart-home') {
    project.value = smartHomeProject
  } else {
    // 默认显示演示数据，实际项目中应从 API 获取
    project.value = defaultProject
    project.value.id = projectId
  }
}

const getStatusText = (status) => {
  const statusMap = {
    'completed': '已完成',
    'in-progress': '进行中',
    'locked': '未解锁',
    'pending': '待开始'
  }
  return statusMap[status] || status
}

const getTaskTagType = (status) => {
  const typeMap = {
    'completed': 'success',
    'in-progress': 'warning',
    'pending': 'info',
    'locked': 'info'
  }
  return typeMap[status] || 'info'
}

const getRoleTagType = (role) => {
    const roleMap = {
        '组长': 'primary',
        '成员': 'info',
        '导师': 'warning'
    }
    return roleMap[role] || 'info'
}

const goBack = () => {
  router.push('/')
}

const goToUnit = (unitId) => {
  if (unitId) {
    // 实际项目中可能需要传递 projectId
    router.push(`/unit/${unitId}`)
  }
}

const goToTask = (taskId) => {
  router.push(`/tasks/${taskId}`)
}

onMounted(() => {
  loadProjectData()
})

watch(() => route.params.id, () => {
  loadProjectData()
})
</script>

<style scoped>
.project-detail {
  padding: 24px;
  max-width: 1200px;
  margin: 0 auto;
}

.project-header {
  margin-bottom: 32px;
}

.back-btn {
  margin-bottom: 16px;
}

.project-header h1 {
  font-size: 32px;
  font-weight: 700;
  color: #1e293b;
  margin: 0 0 12px 0;
}

.project-header p.description {
  color: #64748b;
  font-size: 16px;
  line-height: 1.6;
  margin: 0;
  max-width: 800px;
}

.project-content {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.overview-section h3 {
  font-size: 20px;
  font-weight: 600;
  color: #1e293b;
  margin: 24px 0 16px 0;
  padding-bottom: 8px;
  border-bottom: 1px solid #f1f5f9;
}

.overview-section h3:first-child {
  margin-top: 0;
}

.overview-section p {
  color: #475569;
  line-height: 1.6;
}

.learning-goals {
  padding-left: 24px;
  color: #475569;
}

.learning-goals li {
  margin-bottom: 8px;
}

.units-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.unit-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.unit-item:hover {
  background: #f1f5f9;
  transform: translateY(-2px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  border-color: #cbd5e1;
}

.unit-left {
  display: flex;
  align-items: center;
  gap: 20px;
}

.unit-number {
  font-weight: 700;
  color: #3b82f6;
  font-size: 14px;
  background: #eff6ff;
  padding: 6px 12px;
  border-radius: 20px;
  white-space: nowrap;
}

.unit-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.unit-title {
  font-weight: 600;
  color: #1e293b;
  font-size: 16px;
}

.unit-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #64748b;
}

.unit-meta .divider {
  color: #cbd5e1;
}

.unit-status {
  padding: 6px 16px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  white-space: nowrap;
}

.unit-status.completed {
  background: #dcfce7;
  color: #166534;
}

.unit-status.in-progress {
  background: #dbeafe;
  color: #1e40af;
}

.unit-status.locked {
  background: #f1f5f9;
  color: #64748b;
}

.tasks-section {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.task-item {
  padding: 20px;
  background: #f8fafc;
  border-radius: 8px;
  border-left: 4px solid #3b82f6;
  transition: all 0.2s;
}

.task-item:hover {
  background: #f1f5f9;
}

.task-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.task-header h4 {
  font-size: 18px;
  font-weight: 600;
  color: #1e293b;
  margin: 0;
}

.task-meta {
  display: flex;
  gap: 16px;
  font-size: 14px;
  color: #64748b;
  margin: 12px 0;
}

.team-section h3 {
  font-size: 20px;
  font-weight: 600;
  color: #1e293b;
  margin: 24px 0 24px 0;
}

.team-header-info {
    margin-bottom: 32px;
    padding-bottom: 24px;
    border-bottom: 1px solid #f1f5f9;
}

.team-header-info h2 {
    font-size: 24px;
    font-weight: 700;
    color: #1e293b;
    margin: 0 0 8px 0;
}

.team-slogan {
    font-size: 16px;
    color: #64748b;
    margin: 0;
    font-style: italic;
}

.team-members {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
}

.member-item {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 20px;
  background: #f8fafc;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  transition: all 0.2s ease;
}

.member-item:hover {
    background: #fff;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
    transform: translateY(-2px);
}

.member-item.is-me {
    border-color: #3b82f6;
    background: #eff6ff;
}

.member-item.is-me:hover {
    background: #dbeafe;
}

.member-avatar {
    background: #3b82f6;
    font-weight: 600;
    font-size: 20px;
}

.member-info {
    flex: 1;
}

.member-header {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 8px;
    flex-wrap: wrap;
}

.member-name {
  font-weight: 600;
  color: #1e293b;
  font-size: 16px;
}

.role-tag {
    margin-left: 4px;
}

.member-tags {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
}

.skill-tag {
    background: white;
    border-color: #e2e8f0;
}
</style>
