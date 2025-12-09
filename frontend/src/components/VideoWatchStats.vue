<template>
  <div class="video-watch-stats">
    <el-card class="stats-card">
      <template #header>
        <div class="card-header">
          <span>视频观看统计</span>
          <el-button type="primary" size="small" @click="refreshStats">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </div>
      </template>

      <!-- 用户观看统计 -->
      <div v-if="userStats" class="stats-section">
        <h3>我的观看统计</h3>
        <el-row :gutter="20">
          <el-col :span="6">
            <el-statistic title="观看次数" :value="userStats.session_count || 0" />
          </el-col>
          <el-col :span="6">
            <el-statistic 
              title="最高完成率" 
              :value="userStats.max_completion_rate || 0" 
              suffix="%" 
              :precision="2"
            />
          </el-col>
          <el-col :span="6">
            <el-statistic title="完成次数" :value="userStats.completed_count || 0" />
          </el-col>
        </el-row>

        <el-divider v-if="isPlatformAdmin" />

        <!-- 平台管理员可以看到更详细的统计 -->
        <el-row v-if="isPlatformAdmin" :gutter="20">
          <el-col :span="6">
            <el-statistic title="真实观看时长" :value="formatDuration(userStats.total_real_watch_duration)" />
          </el-col>
          <el-col :span="6">
            <el-statistic title="拖动次数" :value="userStats.total_seek_count || 0" />
          </el-col>
          <el-col :span="6">
            <el-statistic title="暂停次数" :value="userStats.total_pause_count || 0" />
          </el-col>
        </el-row>

        <el-divider />

        <el-row :gutter="20">
          <el-col :span="12">
            <div class="time-info">
              <div>首次观看: {{ formatTime(userStats.first_watch_time) }}</div>
              <div>最后观看: {{ formatTime(userStats.last_watch_time) }}</div>
            </div>
          </el-col>
        </el-row>
      </div>

      <!-- 平台管理员：整体统计 -->
      <div v-if="videoStats && isPlatformAdmin" class="stats-section">
        <el-divider />
        <h3>整体观看统计（仅平台管理员可见）</h3>
        <el-row :gutter="20">
          <el-col :span="6">
            <el-statistic title="观看学生数" :value="videoStats.total_students" />
          </el-col>
          <el-col :span="6">
            <el-statistic title="总观看次数" :value="videoStats.total_sessions" />
          </el-col>
          <el-col :span="6">
            <el-statistic title="总观看时长" :value="formatDuration(videoStats.total_real_watch_duration)" />
          </el-col>
          <el-col :span="6">
            <el-statistic 
              title="平均完成率" 
              :value="videoStats.avg_completion_rate" 
              suffix="%" 
              :precision="2"
            />
          </el-col>
        </el-row>

        <el-divider />

        <el-row :gutter="20">
          <el-col :span="6">
            <el-statistic title="完成次数" :value="videoStats.completed_count" />
          </el-col>
          <el-col :span="6">
            <el-statistic 
              title="平均拖动次数" 
              :value="videoStats.avg_seek_count" 
              :precision="2"
            />
          </el-col>
          <el-col :span="6">
            <el-statistic 
              title="平均暂停次数" 
              :value="videoStats.avg_pause_count" 
              :precision="2"
            />
          </el-col>
        </el-row>
      </div>

      <!-- 平台管理员：学生排行榜 -->
      <div v-if="ranking && ranking.length > 0 && isPlatformAdmin" class="stats-section">
        <el-divider />
        <h3>学生观看排行榜（按真实观看时长）</h3>
        <el-table :data="ranking" stripe style="width: 100%">
          <el-table-column prop="rank" label="排名" width="80" />
          <el-table-column prop="real_name" label="学生姓名" />
          <el-table-column prop="username" label="用户名" />
          <el-table-column label="真实观看时长" width="150">
            <template #default="scope">
              {{ formatDuration(scope.row.total_watch_duration) }}
            </template>
          </el-table-column>
          <el-table-column label="最高完成率" width="120">
            <template #default="scope">
              {{ scope.row.max_completion_rate.toFixed(2) }}%
            </template>
          </el-table-column>
          <el-table-column prop="session_count" label="观看次数" width="100" />
        </el-table>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh } from '@element-plus/icons-vue'
import { getUserWatchStats, getVideoWatchStats, getStudentsRanking } from '@/api/video'
import { useUserStore } from '@/stores/user'

const props = defineProps({
  resourceUuid: {
    type: String,
    required: true
  },
  showRanking: {
    type: Boolean,
    default: true
  },
  rankingLimit: {
    type: Number,
    default: 20
  }
})

const userStore = useUserStore()
const isPlatformAdmin = computed(() => userStore.user?.role === 'platform_admin')
const isStudent = computed(() => userStore.user?.role === 'student')

const userStats = ref(null)
const videoStats = ref(null)
const ranking = ref([])
const loading = ref(false)

/**
 * 加载统计数据
 */
const loadStats = async () => {
  loading.value = true
  try {
    // 加载用户观看统计
    const userRes = await getUserWatchStats(props.resourceUuid)
    if (userRes.code === 200) {
      userStats.value = userRes.data
    }

    // 如果是平台管理员，加载整体统计和排行榜
    if (isPlatformAdmin.value) {
      // 加载整体统计
      try {
        const videoRes = await getVideoWatchStats(props.resourceUuid)
        if (videoRes.code === 200) {
          videoStats.value = videoRes.data
        }
      } catch (error) {
        console.log('无权限查看整体统计')
      }

      // 加载排行榜
      if (props.showRanking) {
        try {
          const rankingRes = await getStudentsRanking(props.resourceUuid, props.rankingLimit)
          if (rankingRes.code === 200) {
            ranking.value = rankingRes.data.ranking || []
          }
        } catch (error) {
          console.log('无权限查看排行榜')
        }
      }
    }
  } catch (error) {
    console.error('加载统计数据失败:', error)
    ElMessage.error('加载统计数据失败')
  } finally {
    loading.value = false
  }
}

/**
 * 刷新统计数据
 */
const refreshStats = () => {
  loadStats()
}

/**
 * 格式化时长（秒转为小时:分钟:秒）
 */
const formatDuration = (seconds) => {
  if (!seconds) return '0秒'
  
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = seconds % 60
  
  if (hours > 0) {
    return `${hours}小时${minutes}分${secs}秒`
  } else if (minutes > 0) {
    return `${minutes}分${secs}秒`
  } else {
    return `${secs}秒`
  }
}

/**
 * 格式化时间
 */
const formatTime = (timeStr) => {
  if (!timeStr) return '-'
  
  const date = new Date(timeStr)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

onMounted(() => {
  loadStats()
})
</script>

<style scoped>
.video-watch-stats {
  width: 100%;
}

.stats-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.stats-section {
  margin-top: 20px;
}

.stats-section h3 {
  margin-bottom: 20px;
  font-size: 16px;
  font-weight: bold;
}

.time-info {
  padding: 10px;
  background-color: #f5f7fa;
  border-radius: 4px;
}

.time-info div {
  margin: 5px 0;
  color: #606266;
}

:deep(.el-statistic__head) {
  font-size: 14px;
  color: #909399;
}

:deep(.el-statistic__content) {
  font-size: 24px;
  font-weight: bold;
  color: #303133;
}
</style>
