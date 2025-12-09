<template>
  <div class="video-player-container" :id="playerId"></div>
</template>

<script setup>
import { onMounted, onBeforeUnmount, watch, nextTick, ref } from 'vue'
import {
  createPlaySession,
  updatePlayProgress,
  recordSeekEvent,
  recordPauseEvent,
  recordEndEvent
} from '@/api/video'

const props = defineProps({
  vid: {
    type: String,
    default: ''
  },
  playAuth: {
    type: String,
    default: ''
  },
  source: {
    type: String,
    default: ''
  },
  cover: {
    type: String,
    default: ''
  },
  width: {
    type: String,
    default: '100%'
  },
  height: {
    type: String,
    default: '500px'
  },
  autoplay: {
    type: Boolean,
    default: false
  },
  resourceUuid: {
    type: String,
    default: ''
  },
  enableTracking: {
    type: Boolean,
    default: true
  }
})

const emit = defineEmits(['ready', 'play', 'pause', 'ended', 'session-created'])

const playerId = `aliplayer-${Math.random().toString(36).substr(2, 9)}`
let player = null

// 播放追踪相关状态
const sessionId = ref(null)
const lastPosition = ref(0)
const progressUpdateInterval = ref(null)
const isTracking = ref(props.enableTracking)

const initPlayer = () => {
  // 销毁旧实例
  if (player) {
    cleanupTracking()
    player.dispose()
    player = null
  }

  // 确保容器存在
  const container = document.getElementById(playerId)
  if (!container) return

  // 初始化配置
  const options = {
    id: playerId,
    width: props.width,
    height: props.height,
    autoplay: props.autoplay,
    cover: props.cover,
    // 优先使用 vid + playAuth，否则使用 source
    vid: props.vid,
    playauth: props.playAuth,
    source: !props.vid ? props.source : undefined,
    // 其它常用配置
    isLive: false,
    rePlay: false,
    playsinline: true,
    preload: true,
    controlBarVisibility: 'hover',
    useH5Prism: true
  }

  // 创建播放器实例
  // eslint-disable-next-line no-undef
  player = new Aliplayer(options, function (player) {
    console.log('播放器创建成功')
  })

  // 监听事件
  player.on('ready', () => {
    console.log('播放器准备就绪')
    emit('ready')
    
    // 如果启用了追踪且有资源UUID，创建播放会话
    if (isTracking.value && props.resourceUuid) {
      initPlaySession()
    }
  })

  player.on('play', () => {
    console.log('开始播放')
    emit('play')
    
    // 启动进度更新定时器
    if (isTracking.value && sessionId.value) {
      startProgressTracking()
    }
  })

  player.on('pause', () => {
    console.log('暂停播放')
    emit('pause')
    
    // 停止进度更新定时器
    stopProgressTracking()
    
    // 记录暂停事件
    if (isTracking.value && sessionId.value && player) {
      const currentPos = Math.floor(player.getCurrentTime())
      handlePauseEvent(currentPos)
    }
  })

  player.on('ended', () => {
    console.log('播放结束')
    emit('ended')
    
    // 停止进度更新定时器
    stopProgressTracking()
    
    // 记录播放结束事件
    if (isTracking.value && sessionId.value && player) {
      const currentPos = Math.floor(player.getCurrentTime())
      handleEndEvent(currentPos)
    }
  })

  // 监听拖动事件
  player.on('seeked', () => {
    if (isTracking.value && sessionId.value && player) {
      const currentPos = Math.floor(player.getCurrentTime())
      handleSeekEvent(lastPosition.value, currentPos)
      lastPosition.value = currentPos
    }
  })

  // 监听时间更新事件
  player.on('timeupdate', () => {
    if (player) {
      lastPosition.value = Math.floor(player.getCurrentTime())
    }
  })
}

// ========== 播放追踪功能 ==========

/**
 * 初始化播放会话
 */
const initPlaySession = async () => {
  if (!props.resourceUuid || !player) return
  
  try {
    const duration = Math.floor(player.getDuration() || 0)
    if (duration === 0) {
      // 如果还没有获取到时长，等待一段时间后重试
      setTimeout(initPlaySession, 1000)
      return
    }
    
    const deviceType = getDeviceType()
    const res = await createPlaySession(props.resourceUuid, duration, deviceType)
    
    if (res.code === 200 && res.data) {
      sessionId.value = res.data.session_id
      console.log('播放会话创建成功:', sessionId.value)
      emit('session-created', sessionId.value)
    }
  } catch (error) {
    console.error('创建播放会话失败:', error)
  }
}

/**
 * 启动进度追踪
 */
const startProgressTracking = () => {
  // 清除之前的定时器
  stopProgressTracking()
  
  // 每10秒上报一次进度
  progressUpdateInterval.value = setInterval(() => {
    updateProgress()
  }, 10000)
}

/**
 * 停止进度追踪
 */
const stopProgressTracking = () => {
  if (progressUpdateInterval.value) {
    clearInterval(progressUpdateInterval.value)
    progressUpdateInterval.value = null
  }
}

/**
 * 更新播放进度
 */
const updateProgress = async () => {
  if (!sessionId.value || !player) return
  
  try {
    const currentPos = Math.floor(player.getCurrentTime())
    const isPaused = player.paused()
    const status = isPaused ? 'paused' : 'playing'
    
    await updatePlayProgress(sessionId.value, currentPos, status, 'progress')
  } catch (error) {
    console.error('更新播放进度失败:', error)
  }
}

/**
 * 处理拖动事件
 */
const handleSeekEvent = async (fromPos, toPos) => {
  if (!sessionId.value) return
  
  try {
    await recordSeekEvent(sessionId.value, fromPos, toPos)
    console.log('记录拖动事件:', fromPos, '->', toPos)
  } catch (error) {
    console.error('记录拖动事件失败:', error)
  }
}

/**
 * 处理暂停事件
 */
const handlePauseEvent = async (position) => {
  if (!sessionId.value) return
  
  try {
    await recordPauseEvent(sessionId.value, position)
    console.log('记录暂停事件:', position)
  } catch (error) {
    console.error('记录暂停事件失败:', error)
  }
}

/**
 * 处理播放结束事件
 */
const handleEndEvent = async (position) => {
  if (!sessionId.value) return
  
  try {
    await recordEndEvent(sessionId.value, position)
    console.log('记录播放结束事件:', position)
  } catch (error) {
    console.error('记录播放结束事件失败:', error)
  }
}

/**
 * 清理追踪资源
 */
const cleanupTracking = () => {
  stopProgressTracking()
  sessionId.value = null
  lastPosition.value = 0
}

/**
 * 获取设备类型
 */
const getDeviceType = () => {
  const ua = navigator.userAgent
  if (/(tablet|ipad|playbook|silk)|(android(?!.*mobi))/i.test(ua)) {
    return 'Tablet'
  }
  if (/Mobile|Android|iP(hone|od)|IEMobile|BlackBerry|Kindle|Silk-Accelerated|(hpw|web)OS|Opera M(obi|ini)/.test(ua)) {
    return 'Mobile'
  }
  return 'PC'
}

onMounted(() => {
  nextTick(() => {
    if (window.Aliplayer) {
      initPlayer()
    } else {
      // 如果脚本还没加载完，轮询检查
      const checkInterval = setInterval(() => {
        if (window.Aliplayer) {
          clearInterval(checkInterval)
          initPlayer()
        }
      }, 100)
    }
  })
})

onBeforeUnmount(() => {
  // 清理追踪资源
  cleanupTracking()
  
  // 销毁播放器
  if (player) {
    player.dispose()
    player = null
  }
})

// 监听属性变化，重新初始化或更新播放器
watch(() => [props.vid, props.source], () => {
  nextTick(() => {
    initPlayer()
  })
})
</script>

<style scoped>
.video-player-container {
  width: 100%;
  height: 100%;
  background-color: #000;
}
</style>

