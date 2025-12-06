<template>
  <div class="chat-panel">
    <div class="panel-header">
      <h2>🤖 AI 学习助手</h2>
      <div class="ai-status">
        <span class="status-indicator" :class="{ online: isOnline }"></span>
        <span class="status-text">{{ isOnline ? '在线' : '离线' }}</span>
      </div>
    </div>

    <div class="chat-container">
      <!-- 聊天消息区域 -->
      <div class="messages-area" ref="messagesAreaRef">
        <div class="welcome-message" v-if="messages.length === 0">
          <div class="ai-avatar">🤖</div>
          <div class="welcome-content">
            <h3>你好！我是你的AI学习助手</h3>
            <p>我可以帮助你：</p>
            <ul>
              <li>🔍 解答学习中的疑问</li>
              <li>💡 提供编程建议和最佳实践</li>
              <li>🐛 协助调试代码问题</li>
              <li>📚 推荐学习资源</li>
            </ul>
            <p>有什么问题尽管问我吧！</p>
          </div>
        </div>

        <div 
          v-for="message in messages" 
          :key="message.id"
          :class="['message', message.type]"
        >
          <div class="message-avatar">
            {{ message.type === 'user' ? '👤' : '🤖' }}
          </div>
          <div class="message-content">
            <div class="message-text" v-html="formatMessage(message.content)"></div>
            <div class="message-time">{{ formatTime(message.timestamp) }}</div>
          </div>
        </div>

        <!-- 正在输入指示器 -->
        <div v-if="isTyping" class="message ai typing-indicator">
          <div class="message-avatar">🤖</div>
          <div class="message-content">
            <div class="typing-dots">
              <span></span>
              <span></span>
              <span></span>
            </div>
          </div>
        </div>
      </div>

      <!-- 快捷问题 -->
      <div class="quick-questions" v-if="messages.length === 0">
        <h4>💬 常见问题</h4>
        <div class="question-buttons">
          <button 
            v-for="question in quickQuestions" 
            :key="question.id"
            @click="askQuickQuestion(question.text)"
            class="question-btn"
          >
            {{ question.text }}
          </button>
        </div>
      </div>

      <!-- 输入区域 -->
      <div class="input-area">
        <div class="input-container">
          <textarea
            v-model="inputMessage"
            @keydown.enter.prevent="handleEnterKey"
            ref="messageInputRef"
            placeholder="输入你的问题..."
            class="message-input"
            rows="1"
            :disabled="isTyping"
          ></textarea>
          
          <div class="input-actions">
            <button 
              @click="clearChat" 
              class="action-btn clear-btn"
              title="清空对话"
            >
              🗑️
            </button>
            <button 
              @click="sendMessage" 
              :disabled="!inputMessage.trim() || isTyping"
              class="action-btn send-btn"
            >
              {{ isTyping ? '⏳' : '📤' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, nextTick, watch } from 'vue'

const messagesAreaRef = ref(null)
const messageInputRef = ref(null)

const isOnline = ref(true)
const isTyping = ref(false)
const inputMessage = ref('')

const messages = ref([])

const quickQuestions = ref([
  { id: 1, text: '这个单元的重点是什么？' },
  { id: 2, text: '如何开始这个任务？' },
  { id: 3, text: '遇到问题怎么办？' },
  { id: 4, text: '推荐一些学习资源' }
])

const formatMessage = (content) => {
  // 简单的Markdown格式化
  return content
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    .replace(/\n/g, '<br>')
}

const formatTime = (timestamp) => {
  const date = new Date(timestamp)
  return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
}

const scrollToBottom = () => {
  nextTick(() => {
    if (messagesAreaRef.value) {
      messagesAreaRef.value.scrollTop = messagesAreaRef.value.scrollHeight
    }
  })
}

const sendMessage = async () => {
  if (!inputMessage.value.trim() || isTyping.value) return

  const userMessage = {
    id: Date.now(),
    type: 'user',
    content: inputMessage.value,
    timestamp: Date.now()
  }

  messages.value.push(userMessage)
  const message = inputMessage.value
  inputMessage.value = ''
  scrollToBottom()

  // 模拟AI回复
  isTyping.value = true
  await new Promise(resolve => setTimeout(resolve, 1000))

  const aiMessage = {
    id: Date.now() + 1,
    type: 'ai',
    content: `关于"${message}"，这是一个很好的问题。让我为你详细解答...`,
    timestamp: Date.now()
  }

  messages.value.push(aiMessage)
  isTyping.value = false
  scrollToBottom()
}

const handleEnterKey = (event) => {
  if (event.shiftKey) {
    return // Shift+Enter 换行
  }
  sendMessage()
}

const askQuickQuestion = (question) => {
  inputMessage.value = question
  sendMessage()
}

const clearChat = () => {
  messages.value = []
}

watch(messages, () => {
  scrollToBottom()
}, { deep: true })
</script>

<style scoped>
.chat-panel {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: white;
  border-radius: 8px;
  overflow: hidden;
}

.panel-header {
  padding: 16px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.panel-header h2 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
}

.ai-status {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
}

.status-indicator {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #ef4444;
}

.status-indicator.online {
  background: #10b981;
}

.chat-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.messages-area {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
  background: #f8fafc;
}

.welcome-message {
  display: flex;
  gap: 12px;
  margin-bottom: 24px;
}

.ai-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  flex-shrink: 0;
}

.welcome-content {
  background: white;
  padding: 16px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.welcome-content h3 {
  margin: 0 0 12px 0;
  font-size: 16px;
  color: #1e293b;
}

.welcome-content ul {
  margin: 12px 0;
  padding-left: 20px;
  color: #64748b;
}

.message {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
}

.message.user {
  flex-direction: row-reverse;
}

.message-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  flex-shrink: 0;
}

.message.user .message-avatar {
  background: #3b82f6;
}

.message.ai .message-avatar {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.message-content {
  max-width: 70%;
  background: white;
  padding: 12px 16px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.message.user .message-content {
  background: #3b82f6;
  color: white;
}

.message-text {
  color: #1e293b;
  line-height: 1.6;
  word-wrap: break-word;
}

.message.user .message-text {
  color: white;
}

.message-time {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 4px;
}

.message.user .message-time {
  color: rgba(255, 255, 255, 0.7);
}

.typing-indicator {
  opacity: 0.7;
}

.typing-dots {
  display: flex;
  gap: 4px;
}

.typing-dots span {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #94a3b8;
  animation: typing 1.4s infinite;
}

.typing-dots span:nth-child(2) {
  animation-delay: 0.2s;
}

.typing-dots span:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes typing {
  0%, 60%, 100% {
    transform: translateY(0);
  }
  30% {
    transform: translateY(-10px);
  }
}

.quick-questions {
  padding: 16px;
  background: white;
  border-top: 1px solid #e5e7eb;
}

.quick-questions h4 {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #64748b;
}

.question-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.question-btn {
  padding: 6px 12px;
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12px;
  color: #475569;
  cursor: pointer;
  transition: all 0.2s;
}

.question-btn:hover {
  background: #e2e8f0;
  border-color: #cbd5e1;
}

.input-area {
  padding: 16px;
  background: white;
  border-top: 1px solid #e5e7eb;
}

.input-container {
  display: flex;
  gap: 8px;
  align-items: flex-end;
}

.message-input {
  flex: 1;
  padding: 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 14px;
  resize: none;
  font-family: inherit;
  min-height: 40px;
  max-height: 120px;
}

.message-input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.input-actions {
  display: flex;
  gap: 8px;
}

.action-btn {
  width: 40px;
  height: 40px;
  border: none;
  border-radius: 8px;
  background: #f1f5f9;
  cursor: pointer;
  font-size: 18px;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.action-btn:hover:not(:disabled) {
  background: #e2e8f0;
}

.action-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.send-btn {
  background: #3b82f6;
  color: white;
}

.send-btn:hover:not(:disabled) {
  background: #2563eb;
}
</style>

