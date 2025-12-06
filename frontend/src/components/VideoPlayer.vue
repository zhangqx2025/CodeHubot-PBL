<template>
  <div class="video-player-container" :id="playerId"></div>
</template>

<script setup>
import { onMounted, onBeforeUnmount, watch, nextTick } from 'vue'

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
  }
})

const playerId = `aliplayer-${Math.random().toString(36).substr(2, 9)}`
let player = null

const initPlayer = () => {
  // 销毁旧实例
  if (player) {
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

const emit = defineEmits(['ready', 'play', 'pause', 'ended'])

  // 监听事件
  player.on('ready', () => {
    console.log('播放器准备就绪')
    emit('ready')
  })

  player.on('play', () => {
    console.log('开始播放')
    emit('play')
  })

  player.on('pause', () => {
    console.log('暂停播放')
    emit('pause')
  })

  player.on('ended', () => {
    console.log('播放结束')
    emit('ended')
  })
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

