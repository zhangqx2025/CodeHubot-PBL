<template>
  <div class="unit-learning" v-if="currentUnit">
    <!-- 单元导航栏 -->
    <nav class="unit-nav">
      <div class="nav-content">
        <el-button :icon="ArrowLeft" @click="goBack" size="small" link>返回</el-button>
        <div class="unit-info">
          <el-breadcrumb separator="/">
            <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item :to="{ path: '/project/smart-home' }">项目详情</el-breadcrumb-item>
            <el-breadcrumb-item>{{ currentUnit.title }}</el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <div class="unit-navigation">
          <el-button-group>
            <el-button 
              v-if="previousUnit" 
              @click="goToUnit(previousUnit.id)"
              :icon="ArrowLeft"
              size="small"
            >
              上一节
            </el-button>
            <el-button 
              v-if="nextUnit && nextUnit.status !== 'locked'" 
              @click="goToUnit(nextUnit.id)"
              size="small"
            >
              下一节
              <el-icon class="el-icon--right"><ArrowRight /></el-icon>
            </el-button>
          </el-button-group>
        </div>
      </div>
    </nav>

    <!-- 三栏学习布局 -->
    <div class="learning-layout">
      <!-- 左侧：学习路径与目录 -->
      <div class="left-panel">
        <div class="panel-header custom-tabs-header">
          <el-tabs v-model="leftPanelTab" class="left-panel-tabs">
            <el-tab-pane label="当前任务" name="path"></el-tab-pane>
            <el-tab-pane label="课程目录" name="outline"></el-tab-pane>
          </el-tabs>
        </div>
        
        <div class="panel-content path-content">
          <!-- 视图1：当前任务路径 -->
          <div v-if="leftPanelTab === 'path'" class="learning-steps">
            <div class="path-summary">
              <span class="progress-text">{{ completedSteps }}/{{ learningPath.length }} 完成</span>
              <el-progress :percentage="progressPercentage" :show-text="false" :stroke-width="4" />
            </div>
            
            <div 
              v-for="(step, index) in learningPath" 
              :key="step.id"
              class="step-item"
              :class="{ 
                'active': currentStep?.id === step.id,
                'locked': step.status === 'locked',
                'completed': step.status === 'completed'
              }"
              @click="selectStep(step)"
            >
              <div class="step-indicator">
                <div class="step-line" v-if="index < learningPath.length - 1"></div>
                <div class="step-icon">
                  <el-icon v-if="step.status === 'completed'"><Check /></el-icon>
                  <el-icon v-else-if="step.status === 'locked'"><Lock /></el-icon>
                  <span v-else>{{ index + 1 }}</span>
                </div>
              </div>
              <div class="step-content">
                <div class="step-title">{{ step.title }}</div>
                <div class="step-type">
                  <el-tag size="small" :type="getStepTypeTag(step.type)">{{ getStepTypeName(step.type) }}</el-tag>
                  <el-tag 
                    v-if="step.type === 'task' && step.taskCategory" 
                    size="small" 
                    effect="plain"
                    :type="step.taskCategory === 'group' ? 'warning' : 'info'"
                    style="margin-left: 8px"
                  >
                    {{ step.taskCategory === 'group' ? '小组' : '个人' }}
                  </el-tag>
                  <span class="step-duration" v-if="step.duration">{{ step.duration }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- 视图2：课程大纲 -->
          <div v-else class="course-outline">
            <div 
              v-for="unit in courseUnits" 
              :key="unit.id"
              class="outline-item"
              :class="{ 'active': unit.id === currentUnit.id, 'locked': unit.status === 'locked' }"
              @click="switchUnit(unit)"
            >
              <div class="outline-status">
                 <el-icon v-if="unit.status === 'locked'"><Lock /></el-icon>
                 <el-icon v-else-if="unit.id === currentUnit.id"><VideoPlay /></el-icon>
                 <div v-else class="status-dot"></div>
              </div>
              <div class="outline-info">
                <div class="outline-title">{{ unit.title }}</div>
                <div class="outline-meta">{{ unit.duration }} | {{ unit.status === 'completed' ? '已完成' : '进行中' }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 中间：动态内容区 -->
      <div class="center-panel">
        <div class="panel-header">
          <h2>
            {{ currentStep?.title || '请选择学习步骤' }}
            <el-tag v-if="currentStep?.status === 'completed'" type="success" effect="dark" size="small" class="ml-2">已完成</el-tag>
          </h2>
          <!-- 新增手动标记按钮 -->
          <div class="header-actions" v-if="currentStep">
             <el-button 
               v-if="currentStep.status !== 'completed'" 
               type="success" 
               plain 
               size="small" 
               @click="manualCompleteStep"
             >
               标记为已完成
             </el-button>
             <el-button 
               v-else 
               type="info" 
               plain 
               size="small" 
               @click="manualUncompleteStep"
             >
               标记为未完成
             </el-button>
          </div>
        </div>
        
        <div class="panel-content main-learning-area" v-if="currentStep">
          <!-- 场景1：视频学习 -->
          <div v-if="currentStep.type === 'video'" class="video-learning">
            <VideoPlayer 
              :source="currentStep.data.url" 
              :cover="currentStep.data.cover"
              :autoplay="true"
              height="100%"
              @ended="handleVideoEnded"
            />
            <div class="learning-tips" v-if="currentStep.status !== 'completed'">
              <el-alert title="请完整观看视频以解锁下一步骤" type="info" :closable="false" show-icon />
            </div>
          </div>

          <!-- 场景2：文档阅读 -->
          <div v-else-if="currentStep.type === 'document'" class="document-learning">
            <div class="document-viewer" v-html="currentStep.data.content"></div>
            <div class="step-actions">
              <el-button 
                type="primary" 
                size="large" 
                @click="completeCurrentStep"
                :disabled="currentStep.status === 'completed'"
              >
                {{ currentStep.status === 'completed' ? '已完成阅读' : '我已阅读完成，下一步' }}
              </el-button>
            </div>
          </div>

          <!-- 场景3：实践任务 -->
          <div v-else-if="currentStep.type === 'task'" class="task-learning">
            <div class="task-detail">
              <div class="task-description">
                <h3>任务描述</h3>
                <p>{{ currentStep.data.description }}</p>
              </div>
              
              <div class="task-requirements">
                <h3>任务要求</h3>
                <ul>
                  <li v-for="(req, idx) in currentStep.data.requirements" :key="idx">{{ req }}</li>
                </ul>
              </div>

              <div class="submission-area">
                <h3>作业提交</h3>
                <el-form label-position="top">
                  <el-form-item label="作业内容 / 代码链接">
                    <el-input 
                      v-model="submissionContent" 
                      type="textarea" 
                      :rows="4" 
                      placeholder="请输入你的作业内容或粘贴代码仓库链接..."
                      :disabled="currentStep.status === 'completed'"
                    />
                  </el-form-item>
                  <el-form-item>
                    <el-button 
                      type="primary" 
                      @click="submitTask" 
                      :loading="submitting"
                      :disabled="currentStep.status === 'completed'"
                    >
                      {{ currentStep.status === 'completed' ? '已提交' : '提交作业' }}
                    </el-button>
                  </el-form-item>
                </el-form>
              </div>
            </div>
          </div>

          <!-- 场景4：在线测验 -->
          <div v-else-if="currentStep.type === 'quiz'" class="quiz-learning">
            <div class="quiz-container">
              <div v-for="(question, index) in currentStep.data.questions" :key="index" class="quiz-item">
                <div class="question-title">{{ index + 1 }}. {{ question.title }}</div>
                <el-radio-group v-model="quizAnswers[index]" :disabled="currentStep.status === 'completed'">
                  <el-radio 
                    v-for="(option, optIndex) in question.options" 
                    :key="optIndex" 
                    :label="optIndex"
                    class="quiz-option"
                  >
                    {{ option }}
                  </el-radio>
                </el-radio-group>
              </div>
              
              <div class="step-actions">
                <el-button 
                  type="primary" 
                  size="large" 
                  @click="submitQuiz"
                  :loading="submitting"
                  :disabled="currentStep.status === 'completed'"
                >
                  {{ currentStep.status === 'completed' ? '已通过测验' : '提交答案' }}
                </el-button>
              </div>
            </div>
          </div>
        </div>

        <div class="empty-state" v-else>
          <el-empty description="请从左侧选择一个学习步骤开始" />
        </div>
      </div>

      <!-- 右侧：AI助手 -->
      <div class="right-panel">
        <ChatPanel />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ArrowLeft, ArrowRight, Check, Lock, VideoPlay } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import ChatPanel from '@/components/ChatPanel.vue'
import VideoPlayer from '@/components/VideoPlayer.vue'

const router = useRouter()
const route = useRoute()

// 状态管理
const leftPanelTab = ref('path')
const currentUnit = ref(null)
const learningPath = ref([])
const currentStep = ref(null)
const submissionContent = ref('')
const submitting = ref(false)
const quizAnswers = ref({})

// 智能家居项目 - 单元列表
const smartHomeUnits = [
  { id: 'unit-1', title: '第一单元：智能体基础与扣子平台入门', status: 'active', duration: '1周' },
  { id: 'unit-2', title: '第二单元：硬件设备接入与通信协议', status: 'locked', duration: '1周' },
  { id: 'unit-3', title: '第三单元：智能体框架与决策引擎', status: 'locked', duration: '1.5周' },
  { id: 'unit-4', title: '第四单元：自然语言处理与语音交互', status: 'locked', duration: '1.5周' },
  { id: 'unit-5', title: '第五单元：用户界面与交互设计', status: 'locked', duration: '1周' },
  { id: 'unit-6', title: '第六单元：场景联动与自动化', status: 'locked', duration: '1周' },
  { id: 'unit-7', title: '第七单元：安全与隐私保护', status: 'locked', duration: '1周' },
  { id: 'unit-8', title: '第八单元：系统集成与项目部署', status: 'locked', duration: '1周' }
]

const courseUnits = ref([])

// 智能家居项目 - 第一单元详细内容
const smartHomeUnit1Steps = [
  {
    id: 101,
    title: 'Agent 101：从 ChatGPT 到智能体',
    type: 'video',
    status: 'available',
    duration: '10:00',
    data: {
      url: 'https://player.alicdn.com/video/aliyunmedia.mp4', // 替换为实际视频
      cover: 'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
      description: '了解什么是 AI Agent（智能体），它与普通聊天机器人的区别，以及 LLM + Memory + Tools + Planning 的核心架构。'
    }
  },
  {
    id: 102,
    title: 'Coze 平台保姆级教程',
    type: 'video',
    status: 'locked',
    duration: '20:00',
    data: {
      url: 'https://player.alicdn.com/video/aliyunmedia.mp4',
      cover: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80'
    }
  },
  {
    id: 103,
    title: '知识讲义：RTF 提示词框架',
    type: 'document',
    status: 'locked',
    duration: '15分钟',
    data: {
      content: `
        <h2>✍️ 高效 Prompt 编写指南：RTF 框架</h2>
        <p>怎么让 AI 听话？我们需要写好“人设”。推荐使用 <strong>RTF 框架</strong>：</p>
        
        <h3>R (Role) - 角色</h3>
        <p>你是谁？定义 Agent 的身份、背景和性格。</p>
        <p class="example">例：你是一个专业的家庭管家 Jarvis。</p>
        
        <h3>T (Task) - 任务</h3>
        <p>你要做什么？明确 Agent 的主要职责和目标。</p>
        <p class="example">例：你需要根据用户的模糊指令控制家电设备，并给出温馨的反馈。</p>
        
        <h3>F (Format) - 格式</h3>
        <p>你输出什么格式？规定回复的风格、长度或结构。</p>
        <p class="example">例：请用简短、口语化的中文回答，不要长篇大论。</p>
        
        <div style="background: #f0f9ff; padding: 15px; border-radius: 8px; margin-top: 20px;">
          <h4>📌 练习</h4>
          <p>试着为你未来的“智能家居中控”写一段 Prompt，包含以上三个要素。</p>
        </div>
      `
    }
  },
  {
    id: 104,
    title: '实战任务 1.1：Hello World',
    type: 'task',
    taskCategory: 'individual',
    status: 'locked',
    duration: '30分钟',
    data: {
      description: '访问 Coze 官网，注册账号并创建一个全新的 Bot，命名为 Jarvis-Lite（或你喜欢的名字）。',
      requirements: [
        '完成 Coze 账号注册',
        '创建 Bot，填写名称和简介',
        '生成并设置 Bot 头像',
        '提交 Bot ID 或截图'
      ]
    }
  },
  {
    id: 105,
    title: '实战任务 1.2：注入灵魂',
    type: 'task',
    taskCategory: 'group',
    status: 'locked',
    duration: '45分钟',
    data: {
      description: '使用 RTF 框架编写 Prompt，并填入“人设与回复逻辑”区域。让你的 Agent 知道自己是管家，而不是百科全书。',
      requirements: [
        '编写包含 Role, Task, Format 的 Prompt',
        '设定“意图识别”技能',
        '在右侧预览窗口进行不少于 3 轮的对话测试',
        '提交 Prompt 内容和对话截图'
      ]
    }
  },
  {
    id: 106,
    title: '实战任务 1.3：初次调试',
    type: 'task',
    taskCategory: 'individual',
    status: 'locked',
    duration: '20分钟',
    data: {
      description: '在预览窗口验证人设是否生效。尝试输入“你是谁？”、“把灯打开”等指令，观察它的反应。',
      requirements: [
        '测试自我介绍',
        '测试设备控制指令（模拟）',
        '测试闲聊话题（验证约束条件）',
        '提交测试报告'
      ]
    }
  }
]

const previousUnit = ref(null)
const nextUnit = ref({ id: 'unit-2', title: '第二单元', status: 'locked' })

// 计算属性
const completedSteps = computed(() => {
  return learningPath.value.filter(s => s.status === 'completed').length
})

const progressPercentage = computed(() => {
  if (learningPath.value.length === 0) return 0
  return Math.round((completedSteps.value / learningPath.value.length) * 100)
})

// 方法
const switchUnit = (unit) => {
  if (unit.status === 'locked') {
    ElMessage.warning('请先完成前序单元')
    return
  }
  // 如果是当前单元，不做操作
  if (unit.id === currentUnit.value.id) return
  
  // 切换单元
  router.push(`/unit/${unit.id}`)
  ElMessage.success(`切换到: ${unit.title}`)
}

const getStepTypeName = (type) => {
  const map = { video: '视频', document: '文档', task: '作业', quiz: '测验' }
  return map[type] || '未知'
}

const getStepTypeTag = (type) => {
  const map = { video: '', document: 'info', task: 'warning', quiz: 'danger' }
  return map[type] || ''
}

const selectStep = (step) => {
  if (step.status === 'locked') {
    ElMessage.warning('请先完成上一步骤解锁此内容')
    return
  }
  currentStep.value = step
  // 重置提交内容
  if (step.type === 'task') {
    submissionContent.value = '' 
  }
  // 重置测验
  if (step.type === 'quiz') {
    quizAnswers.value = {}
  }
}

// 解锁下一步
const unlockNextStep = (currentStepId) => {
  const currentIndex = learningPath.value.findIndex(s => s.id === currentStepId)
  if (currentIndex < learningPath.value.length - 1) {
    const nextStep = learningPath.value[currentIndex + 1]
    if (nextStep.status === 'locked') {
      nextStep.status = 'available'
      ElMessage.success('恭喜！下一步骤已解锁')
    }
  } else {
    ElMessage.success('恭喜！本单元所有内容已完成')
  }
}

// 视频播放结束处理
const handleVideoEnded = () => {
  if (currentStep.value.status !== 'completed') {
    currentStep.value.status = 'completed'
    ElMessage.success('视频观看完成！')
    unlockNextStep(currentStep.value.id)
  }
}

// 文档阅读完成处理
const completeCurrentStep = () => {
  if (currentStep.value.status !== 'completed') {
    currentStep.value.status = 'completed'
    unlockNextStep(currentStep.value.id)
    
    // 自动跳转到下一步
    const currentIndex = learningPath.value.findIndex(s => s.id === currentStep.value.id)
    if (currentIndex < learningPath.value.length - 1) {
      setTimeout(() => {
        selectStep(learningPath.value[currentIndex + 1])
      }, 1000)
    }
  }
}

// 提交作业处理
const submitTask = async () => {
  if (!submissionContent.value.trim()) {
    ElMessage.warning('请输入作业内容')
    return
  }
  
  submitting.value = true
  // 模拟API调用
  await new Promise(resolve => setTimeout(resolve, 1000))
  
  submitting.value = false
  currentStep.value.status = 'completed'
  ElMessage.success('作业提交成功！')
  unlockNextStep(currentStep.value.id)
}

// 提交测验处理
const submitQuiz = async () => {
  if (Object.keys(quizAnswers.value).length < currentStep.value.data.questions.length) {
    ElMessage.warning('请回答所有问题')
    return
  }

  submitting.value = true
  // 模拟API验证
  await new Promise(resolve => setTimeout(resolve, 800))
  submitting.value = false

  // 验证答案 (这里简化处理，实际应由后端验证)
  let allCorrect = true
  currentStep.value.data.questions.forEach((q, idx) => {
    if (quizAnswers.value[idx] !== q.answer) {
      allCorrect = false
    }
  })

  if (allCorrect) {
    currentStep.value.status = 'completed'
    ElMessage.success('恭喜！全部回答正确')
    unlockNextStep(currentStep.value.id)
  } else {
    ElMessage.error('有题目回答错误，请重试')
  }
}

// 手动标记完成
const manualCompleteStep = () => {
  if (currentStep.value) {
    currentStep.value.status = 'completed'
    ElMessage.success('已手动标记为完成')
    unlockNextStep(currentStep.value.id)
  }
}

// 手动取消完成
const manualUncompleteStep = () => {
  if (currentStep.value) {
    currentStep.value.status = 'available'
    ElMessage.info('已撤销完成状态')
  }
}

const goBack = () => router.push('/project/smart-home')
const goToUnit = (id) => router.push(`/unit/${id}`)

onMounted(() => {
  const unitId = route.params.unitId
  
  // 根据 ID 加载不同数据
  // 这里简单判断，实际应调用 API
  if (unitId.startsWith('unit-')) {
    courseUnits.value = smartHomeUnits
    // 假设只实现了 Unit 1 的内容
    if (unitId === 'unit-1') {
      learningPath.value = smartHomeUnit1Steps
      currentUnit.value = smartHomeUnits[0]
      nextUnit.value = smartHomeUnits[1]
      previousUnit.value = null
    } else {
      // 其他单元显示占位
      learningPath.value = []
      currentUnit.value = smartHomeUnits.find(u => u.id === unitId) || smartHomeUnits[0]
    }
  }

  // 默认选中第一个可用的步骤
  if (learningPath.value.length > 0) {
    const firstAvailable = learningPath.value.find(s => s.status !== 'locked')
    if (firstAvailable) {
      selectStep(firstAvailable)
    }
  }
})
</script>

<style scoped>
.unit-learning {
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: #f8fafc;
}

.unit-nav {
  background: white;
  padding: 8px 16px;
  border-bottom: 1px solid #e5e7eb;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  height: 48px;
  display: flex;
  align-items: center;
  flex-shrink: 0;
}

.nav-content {
  display: flex;
  align-items: center;
  gap: 16px;
  width: 100%;
}

.unit-info {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.unit-info h1 {
  font-size: 16px;
  font-weight: 600;
  color: #1e293b;
  margin: 0;
}

.learning-layout {
  flex: 1;
  display: grid;
  grid-template-columns: 280px 1fr 320px;
  gap: 0;
  overflow: hidden;
}

.left-panel,
.center-panel,
.right-panel {
  background: white;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  border-right: 1px solid #e5e7eb;
}

.right-panel {
  border-right: none;
}

.panel-header {
  padding: 12px 16px;
  background: #f8fafc;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 48px;
  box-sizing: border-box;
}

.panel-header h2 {
  font-size: 14px;
  font-weight: 600;
  color: #1e293b;
  margin: 0;
}

.custom-tabs-header {
  padding: 0 16px;
}

.left-panel-tabs :deep(.el-tabs__header) {
  margin: 0;
}

.left-panel-tabs :deep(.el-tabs__nav-wrap::after) {
  height: 1px;
}

.progress-text {
  font-size: 12px;
  color: #64748b;
}

.path-summary {
  padding: 16px;
  border-bottom: 1px solid #f1f5f9;
}

.path-summary .el-progress {
  margin-top: 8px;
}

.panel-content {
  flex: 1;
  overflow-y: auto;
}

/* 课程目录样式 */
.course-outline {
  padding: 0;
}

.outline-item {
  display: flex;
  padding: 16px;
  cursor: pointer;
  transition: all 0.2s;
  border-bottom: 1px solid #f1f5f9;
}

.outline-item:hover {
  background: #f8fafc;
}

.outline-item.active {
  background: #eff6ff;
  border-left: 3px solid #3b82f6;
}

.outline-item.locked {
  cursor: not-allowed;
  opacity: 0.6;
}

.outline-status {
  width: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #94a3b8;
}

.outline-item.active .outline-status {
  color: #3b82f6;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #cbd5e1;
}

.outline-info {
  flex: 1;
}

.outline-title {
  font-size: 14px;
  font-weight: 500;
  color: #1e293b;
  margin-bottom: 4px;
}

.outline-meta {
  font-size: 12px;
  color: #94a3b8;
}

/* 学习路径样式 */
.path-content {
  padding: 0;
}

.step-item {
  display: flex;
  padding: 16px;
  cursor: pointer;
  transition: all 0.2s;
  border-bottom: 1px solid #f1f5f9;
}

.step-item:hover {
  background: #f8fafc;
}

.step-item.active {
  background: #eff6ff;
}

.step-item.locked {
  cursor: not-allowed;
  opacity: 0.7;
  background: #f8fafc;
}

.step-indicator {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-right: 12px;
  position: relative;
  width: 24px;
}

.step-icon {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #e2e8f0;
  color: #64748b;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  z-index: 2;
}

.step-item.active .step-icon {
  background: #3b82f6;
  color: white;
}

.step-item.completed .step-icon {
  background: #10b981;
  color: white;
}

.step-line {
  position: absolute;
  top: 24px;
  bottom: -24px; /* Extend to next item */
  width: 2px;
  background: #e2e8f0;
  z-index: 1;
}

.step-item:last-child .step-line {
  display: none;
}

.step-content {
  flex: 1;
}

.step-title {
  font-size: 14px;
  font-weight: 500;
  color: #1e293b;
  margin-bottom: 4px;
}

.step-type {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.step-duration {
  font-size: 12px;
  color: #94a3b8;
}

/* 中间区域样式 */
.main-learning-area {
  padding: 24px;
  background: #fff;
}

.video-learning {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.learning-tips {
  margin-top: 16px;
}

.document-learning {
  max-width: 800px;
  margin: 0 auto;
}

.document-viewer {
  line-height: 1.8;
  color: #334155;
  margin-bottom: 32px;
}

.document-viewer h2 {
  font-size: 24px;
  margin-top: 0;
  margin-bottom: 16px;
  color: #0f172a;
}

.document-viewer h3 {
  font-size: 18px;
  margin-top: 24px;
  margin-bottom: 12px;
  color: #1e293b;
}

.document-viewer p {
  margin-bottom: 12px;
}

.document-viewer .example {
  background: #f8fafc;
  padding: 12px;
  border-left: 4px solid #3b82f6;
  margin: 8px 0;
  color: #475569;
}

.step-actions {
  display: flex;
  justify-content: center;
  padding-top: 24px;
  border-top: 1px solid #e5e7eb;
}

.task-learning {
  max-width: 800px;
  margin: 0 auto;
}

.task-detail h3 {
  font-size: 18px;
  color: #1e293b;
  margin-bottom: 16px;
  border-left: 4px solid #3b82f6;
  padding-left: 12px;
}

.task-description, .task-requirements {
  margin-bottom: 32px;
  background: #f8fafc;
  padding: 20px;
  border-radius: 8px;
}

.submission-area {
  border: 1px solid #e5e7eb;
  padding: 24px;
  border-radius: 8px;
}

.quiz-learning {
  max-width: 800px;
  margin: 0 auto;
  padding-bottom: 40px;
}

.quiz-container {
  background: #fff;
}

.quiz-item {
  margin-bottom: 32px;
  padding: 24px;
  background: #f8fafc;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.question-title {
  font-size: 16px;
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 16px;
}

.quiz-option {
  display: block;
  margin-bottom: 12px;
  margin-left: 0 !important;
  padding: 12px;
  border-radius: 6px;
  width: 100%;
  border: 1px solid transparent;
  transition: all 0.2s;
}

.quiz-option:hover {
  background: #fff;
  border-color: #cbd5e1;
}

.quiz-option.is-checked {
  background: #eff6ff;
  border-color: #3b82f6;
}

@media (max-width: 1200px) {
  .learning-layout {
    grid-template-columns: 240px 1fr 280px;
  }
}
</style>