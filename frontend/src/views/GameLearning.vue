<template>
  <div class="game-learning-page">
    <!-- 顶部 HUD 仪表盘 -->
    <div class="game-hud">
      <div class="hud-left">
        <el-button circle :icon="Back" class="back-btn" @click="$router.back()" />
        <div class="project-info">
          <span class="project-label">当前探险</span>
          <h2 class="project-title">智能家居系统开发</h2>
        </div>
      </div>
      
      <div class="hud-right">
        <div class="stat-item coin">
          <div class="stat-icon">🪙</div>
          <span class="stat-value">1,250</span>
        </div>
        <div class="stat-item star">
          <div class="stat-icon">⭐</div>
          <span class="stat-value">12/45</span>
        </div>
        <div class="user-avatar-small">
          <el-avatar :size="40" src="https://cube.elemecdn.com/0/88/03b0d39583f48206768a7534e55bcpng.png" />
        </div>
      </div>
    </div>

    <!-- 游戏地图区域 -->
    <div class="map-container" ref="mapContainer">
      <div class="map-content">
        <!-- 背景装饰 -->
        <div class="bg-decoration planet-1"></div>
        <div class="bg-decoration planet-2"></div>
        <div class="bg-decoration rocket">🚀</div>

        <!-- 路径连线 (SVG) -->
        <svg class="path-svg" width="100%" height="100%" viewBox="0 0 800 1200" preserveAspectRatio="xMidYMid meet">
          <!-- 路径背景阴影 -->
          <path 
            d="M400,1100 C400,1100 200,950 200,800 C200,650 600,650 600,500 C600,350 300,350 300,200 C300,100 400,50 400,50" 
            fill="none" 
            stroke="rgba(255,255,255,0.2)" 
            stroke-width="12" 
            stroke-linecap="round"
            stroke-dasharray="20 10"
          />
          <!-- 实际路径 -->
          <path 
            id="levelPath"
            d="M400,1100 C400,1100 200,950 200,800 C200,650 600,650 600,500 C600,350 300,350 300,200 C300,100 400,50 400,50" 
            fill="none" 
            stroke="#4ade80" 
            stroke-width="6" 
            stroke-linecap="round"
            class="path-line"
          />
        </svg>

        <!-- 关卡节点 -->
        <div 
          v-for="(level, index) in levels" 
          :key="level.id"
          class="level-node"
          :class="[level.status, { 'is-current': currentLevelId === level.id }]"
          :style="{ left: level.x + '%', top: level.y + '%' }"
          @click="handleLevelClick(level)"
        >
          <!-- 节点主体 -->
          <div class="node-circle">
            <div class="node-content">
              <el-icon v-if="level.status === 'locked'" class="lock-icon"><Lock /></el-icon>
              <span v-else-if="level.status === 'completed'" class="star-rating">⭐⭐⭐</span>
              <span v-else class="level-number">{{ index + 1 }}</span>
            </div>
            
            <!-- 进度光环 (仅当前关卡) -->
            <div v-if="level.status === 'active'" class="pulse-ring"></div>
          </div>

          <!-- 关卡信息卡片 (悬浮/选中显示) -->
          <div class="level-info-card">
            <div class="level-title">{{ level.title }}</div>
            <div class="level-desc">{{ level.description }}</div>
            <div class="level-rewards" v-if="level.status !== 'locked'">
              <span class="reward-tag">🪙 +{{ level.rewards.coins }}</span>
              <span class="reward-tag">EXP +{{ level.rewards.exp }}</span>
            </div>
            <el-button 
              v-if="level.status !== 'locked'" 
              type="primary" 
              size="small" 
              round 
              class="start-btn"
            >
              {{ level.status === 'completed' ? '复习' : '开始挑战' }}
            </el-button>
          </div>

          <!-- 角色 Avatar (仅在当前关卡显示) -->
          <div v-if="currentLevelId === level.id" class="player-avatar">
            <img src="https://cdn-icons-png.flaticon.com/512/4333/4333609.png" alt="Player" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Back, Lock } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

const router = useRouter()
const mapContainer = ref(null)

// 模拟关卡数据
const currentLevelId = ref(3)
const levels = ref([
  {
    id: 1,
    title: '初识智能体',
    description: '了解 Agent 基本概念与架构',
    status: 'completed',
    x: 50, // 百分比位置，对应 SVG 路径
    y: 90,
    rewards: { coins: 100, exp: 50 }
  },
  {
    id: 2,
    title: 'Coze 平台入门',
    description: '注册账号并熟悉界面操作',
    status: 'completed',
    x: 25,
    y: 70,
    rewards: { coins: 150, exp: 80 }
  },
  {
    id: 3,
    title: '编写你的第一个 Prompt',
    description: '使用 RTF 框架设计人设',
    status: 'active',
    x: 60,
    y: 50,
    rewards: { coins: 200, exp: 100 }
  },
  {
    id: 4,
    title: '知识库搭建',
    description: '上传文档并配置 RAG',
    status: 'locked',
    x: 40,
    y: 30,
    rewards: { coins: 250, exp: 120 }
  },
  {
    id: 5,
    title: '最终挑战：发布应用',
    description: '调试并发布你的智能体',
    status: 'locked',
    x: 50,
    y: 10,
    rewards: { coins: 500, exp: 300 }
  }
])

const handleLevelClick = (level) => {
  if (level.status === 'locked') {
    ElMessage.warning('请先完成前序关卡以解锁！')
    return
  }
  
  // 模拟跳转
  if (level.id === 3) {
    router.push('/unit/unit-1') // 跳转到具体单元
  } else {
    ElMessage.success(`准备进入关卡：${level.title}`)
    // router.push(...)
  }
}

onMounted(() => {
  // 自动滚动到当前关卡
  if (mapContainer.value) {
    // 简单的视差或滚动逻辑
  }
})
</script>

<style scoped>
.game-learning-page {
  height: 100vh;
  width: 100vw;
  background: linear-gradient(180deg, #0f172a 0%, #1e293b 100%);
  color: white;
  overflow: hidden;
  position: relative;
  font-family: 'Nunito', sans-serif; /* 卡通感字体 */
}

/* HUD 样式 */
.game-hud {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 80px;
  padding: 0 32px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  z-index: 100;
  background: rgba(15, 23, 42, 0.8);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.hud-left {
  display: flex;
  align-items: center;
  gap: 20px;
}

.back-btn {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
}

.project-info {
  display: flex;
  flex-direction: column;
}

.project-label {
  font-size: 12px;
  color: #94a3b8;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.project-title {
  margin: 0;
  font-size: 20px;
  font-weight: 700;
  background: linear-gradient(45deg, #4ade80, #22d3ee);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.hud-right {
  display: flex;
  align-items: center;
  gap: 24px;
}

.stat-item {
  display: flex;
  align-items: center;
  background: rgba(0, 0, 0, 0.3);
  padding: 8px 16px;
  border-radius: 20px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  gap: 8px;
}

.stat-icon {
  font-size: 18px;
}

.stat-value {
  font-weight: 700;
  color: #fcd34d; /* Gold */
}

.star .stat-value {
  color: #fff;
}

/* 地图区域样式 */
.map-container {
  height: calc(100vh - 80px);
  margin-top: 80px;
  overflow-y: auto;
  overflow-x: hidden;
  position: relative;
  /* 自定义滚动条 */
  scrollbar-width: none;
}

.map-container::-webkit-scrollbar {
  display: none;
}

.map-content {
  width: 800px;
  height: 1200px; /* 比视口长，产生滚动 */
  margin: 0 auto;
  position: relative;
  padding: 50px 0;
}

/* 背景装饰 */
.bg-decoration {
  position: absolute;
  opacity: 0.1;
  pointer-events: none;
}

.planet-1 {
  width: 200px;
  height: 200px;
  background: radial-gradient(circle, #6366f1 0%, transparent 70%);
  border-radius: 50%;
  top: 10%;
  left: -100px;
}

.planet-2 {
  width: 300px;
  height: 300px;
  background: radial-gradient(circle, #ec4899 0%, transparent 70%);
  border-radius: 50%;
  bottom: 20%;
  right: -150px;
}

.rocket {
  font-size: 100px;
  top: 5%;
  right: 10%;
  transform: rotate(-45deg);
  opacity: 0.2;
}

/* 路径 SVG */
.path-svg {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  z-index: 1;
}

.path-line {
  stroke-dasharray: 1000;
  stroke-dashoffset: 0;
  animation: dash 5s linear infinite;
}

@keyframes dash {
  to {
    stroke-dashoffset: -2000;
  }
}

/* 关卡节点 */
.level-node {
  position: absolute;
  transform: translate(-50%, -50%);
  z-index: 2;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

.level-node:hover {
  transform: translate(-50%, -50%) scale(1.1);
  z-index: 10; /* 悬浮时层级提高 */
}

.node-circle {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: #1e293b;
  border: 4px solid #334155;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
  transition: all 0.3s;
}

.node-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  color: white;
}

.level-number {
  font-size: 32px;
  font-weight: 800;
  color: #64748b;
}

/* 状态样式: Active */
.level-node.active .node-circle {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  border-color: #60a5fa;
  box-shadow: 0 0 30px rgba(59, 130, 246, 0.6);
}

.level-node.active .level-number {
  color: white;
}

/* 状态样式: Completed */
.level-node.completed .node-circle {
  background: #10b981;
  border-color: #34d399;
}

.star-rating {
  font-size: 16px;
}

/* 状态样式: Locked */
.level-node.locked .node-circle {
  background: #0f172a;
  border-color: #1e293b;
  opacity: 0.7;
}

.lock-icon {
  font-size: 24px;
  color: #475569;
}

/* 呼吸光环 */
.pulse-ring {
  position: absolute;
  top: -10px;
  left: -10px;
  right: -10px;
  bottom: -10px;
  border-radius: 50%;
  border: 4px solid #3b82f6;
  opacity: 0;
  animation: pulse-ring 2s infinite;
}

@keyframes pulse-ring {
  0% { transform: scale(0.8); opacity: 1; }
  100% { transform: scale(1.5); opacity: 0; }
}

/* 信息卡片 */
.level-info-card {
  position: absolute;
  bottom: 100px;
  left: 50%;
  transform: translateX(-50%);
  width: 220px;
  background: white;
  border-radius: 12px;
  padding: 16px;
  text-align: center;
  color: #1e293b;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  opacity: 0;
  visibility: hidden;
  transition: all 0.3s;
  pointer-events: none;
}

.level-info-card::after {
  content: '';
  position: absolute;
  bottom: -8px;
  left: 50%;
  transform: translateX(-50%);
  border-left: 8px solid transparent;
  border-right: 8px solid transparent;
  border-top: 8px solid white;
}

.level-node:hover .level-info-card {
  opacity: 1;
  visibility: visible;
  transform: translateX(-50%) translateY(-10px);
  pointer-events: auto;
}

.level-title {
  font-weight: 700;
  margin-bottom: 4px;
  font-size: 16px;
}

.level-desc {
  font-size: 12px;
  color: #64748b;
  margin-bottom: 12px;
}

.level-rewards {
  display: flex;
  justify-content: center;
  gap: 8px;
  margin-bottom: 12px;
}

.reward-tag {
  background: #f1f5f9;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 600;
  color: #475569;
}

.start-btn {
  width: 100%;
  background: #2563eb;
  border-color: #2563eb;
}

/* 角色 Avatar */
.player-avatar {
  position: absolute;
  top: -60px;
  left: 50%;
  transform: translateX(-50%);
  width: 60px;
  height: 60px;
  z-index: 5;
  animation: bounce 2s infinite;
}

.player-avatar img {
  width: 100%;
  height: 100%;
  filter: drop-shadow(0 4px 6px rgba(0,0,0,0.3));
}

@keyframes bounce {
  0%, 100% { transform: translateX(-50%) translateY(0); }
  50% { transform: translateX(-50%) translateY(-10px); }
}
</style>