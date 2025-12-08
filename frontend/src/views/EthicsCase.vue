<template>
  <div class="ethics-case-page">
    <el-page-header @back="goBack" class="page-header">
      <template #content>
        <span class="page-title">{{ ethicsCase.title }}</span>
      </template>
    </el-page-header>

    <el-row :gutter="20" class="main-content">
      <!-- 左侧：案例内容 -->
      <el-col :xs="24" :md="16">
        <el-card class="case-content-card" shadow="never">
          <!-- 案例封面 -->
          <div v-if="ethicsCase.cover_image" class="case-cover">
            <img :src="ethicsCase.cover_image" :alt="ethicsCase.title" />
          </div>

          <!-- 案例信息 -->
          <div class="case-info">
            <div class="case-meta">
              <el-tag
                v-for="topic in ethicsCase.ethics_topics"
                :key="topic"
                type="warning"
                class="topic-tag"
              >
                {{ topic }}
              </el-tag>
              <el-tag :type="getDifficultyType(ethicsCase.difficulty)">
                {{ getDifficultyText(ethicsCase.difficulty) }}
              </el-tag>
            </div>

            <div class="case-stats">
              <span class="stat-item">
                <el-icon><View /></el-icon>
                {{ ethicsCase.view_count }} 次浏览
              </span>
              <span class="stat-item">
                <el-icon><Star /></el-icon>
                {{ ethicsCase.like_count }} 人点赞
              </span>
              <span v-if="ethicsCase.author" class="stat-item">
                <el-icon><User /></el-icon>
                {{ ethicsCase.author }}
              </span>
            </div>
          </div>

          <!-- 案例描述 -->
          <div class="case-description">
            <h3>案例概述</h3>
            <p>{{ ethicsCase.description }}</p>
          </div>

          <!-- 案例详细内容 -->
          <div class="case-detail" v-html="renderedContent"></div>

          <!-- 讨论问题 -->
          <div v-if="ethicsCase.discussion_questions && ethicsCase.discussion_questions.length > 0" class="discussion-questions">
            <h3>思考题</h3>
            <div
              v-for="(question, index) in ethicsCase.discussion_questions"
              :key="index"
              class="question-item"
            >
              <div class="question-number">{{ index + 1 }}</div>
              <div class="question-text">{{ question }}</div>
            </div>
          </div>

          <!-- 参考资料 -->
          <div v-if="ethicsCase.reference_links && ethicsCase.reference_links.length > 0" class="references">
            <h3>参考资料</h3>
            <ul>
              <li v-for="(link, index) in ethicsCase.reference_links" :key="index">
                <a :href="link.url" target="_blank">{{ link.title }}</a>
              </li>
            </ul>
          </div>

          <!-- 互动按钮 -->
          <div class="case-actions">
            <el-button
              type="primary"
              :icon="liked ? StarFilled : Star"
              @click="toggleLike"
            >
              {{ liked ? '已点赞' : '点赞' }}
            </el-button>
            <el-button :icon="Share" @click="shareCase">
              分享
            </el-button>
          </div>
        </el-card>

        <!-- 评论区 -->
        <el-card class="comments-card" shadow="never">
          <template #header>
            <div class="comments-header">
              <span>讨论区 ({{ comments.length }})</span>
            </div>
          </template>

          <!-- 发表评论 -->
          <div class="comment-input-area">
            <el-input
              v-model="newComment"
              type="textarea"
              :rows="3"
              placeholder="分享你的观点和思考..."
              maxlength="500"
              show-word-limit
            />
            <el-button
              type="primary"
              class="submit-comment-btn"
              @click="submitComment"
              :disabled="!newComment.trim()"
            >
              发表评论
            </el-button>
          </div>

          <!-- 评论列表 -->
          <div class="comments-list">
            <div v-for="comment in comments" :key="comment.id" class="comment-item">
              <el-avatar :size="40">{{ comment.user_name.charAt(0) }}</el-avatar>
              <div class="comment-content">
                <div class="comment-header">
                  <span class="comment-user">{{ comment.user_name }}</span>
                  <span class="comment-time">{{ formatDate(comment.created_at) }}</span>
                </div>
                <div class="comment-text">{{ comment.content }}</div>
              </div>
            </div>
            <el-empty v-if="comments.length === 0" description="暂无评论，快来发表第一条吧！" />
          </div>
        </el-card>
      </el-col>

      <!-- 右侧：相关活动和推荐 -->
      <el-col :xs="24" :md="8">
        <!-- 相关活动 -->
        <el-card class="side-card" shadow="never">
          <template #header>
            <span class="side-card-title">相关思辨活动</span>
          </template>
          <div v-if="relatedActivities.length > 0">
            <div
              v-for="activity in relatedActivities"
              :key="activity.uuid"
              class="activity-item"
              @click="viewActivity(activity)"
            >
              <h4>{{ activity.title }}</h4>
              <p>{{ activity.description }}</p>
              <div class="activity-meta">
                <el-tag size="small" :type="getActivityStatusType(activity.status)">
                  {{ getActivityStatusText(activity.status) }}
                </el-tag>
                <span class="activity-time">{{ formatDate(activity.scheduled_at) }}</span>
              </div>
            </div>
          </div>
          <el-empty v-else description="暂无相关活动" :image-size="60" />
        </el-card>

        <!-- 相关案例推荐 -->
        <el-card class="side-card" shadow="never">
          <template #header>
            <span class="side-card-title">相关案例推荐</span>
          </template>
          <div v-if="relatedCases.length > 0">
            <div
              v-for="relatedCase in relatedCases"
              :key="relatedCase.uuid"
              class="related-case-item"
              @click="viewCase(relatedCase)"
            >
              <h4>{{ relatedCase.title }}</h4>
              <p>{{ relatedCase.description }}</p>
              <div class="related-case-tags">
                <el-tag
                  v-for="topic in relatedCase.ethics_topics.slice(0, 2)"
                  :key="topic"
                  size="small"
                  type="warning"
                >
                  {{ topic }}
                </el-tag>
              </div>
            </div>
          </div>
          <el-empty v-else description="暂无相关案例" :image-size="60" />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  View,
  Star,
  StarFilled,
  User,
  Share
} from '@element-plus/icons-vue'
import { marked } from 'marked'
import { getEthicsCaseDetail, likeEthicsCase, getEthicsCases } from '@/api/ethics'

const router = useRouter()
const route = useRoute()

const ethicsCase = ref({})
const liked = ref(false)
const newComment = ref('')
const comments = ref([])
const relatedActivities = ref([])
const relatedCases = ref([])

const renderedContent = computed(() => {
  if (!ethicsCase.value.content) return ''
  return marked(ethicsCase.value.content)
})

const goBack = () => {
  router.back()
}

const getDifficultyType = (difficulty) => {
  const types = {
    basic: 'success',
    intermediate: 'warning',
    advanced: 'danger'
  }
  return types[difficulty] || 'info'
}

const getDifficultyText = (difficulty) => {
  const texts = {
    basic: '基础',
    intermediate: '进阶',
    advanced: '高级'
  }
  return texts[difficulty] || difficulty
}

const getActivityStatusType = (status) => {
  const types = {
    planned: 'info',
    ongoing: 'success',
    completed: 'warning'
  }
  return types[status] || 'info'
}

const getActivityStatusText = (status) => {
  const texts = {
    planned: '计划中',
    ongoing: '进行中',
    completed: '已完成'
  }
  return texts[status] || status
}

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const toggleLike = async () => {
  try {
    await likeEthicsCase(ethicsCase.value.uuid)
    liked.value = !liked.value
    if (liked.value) {
      ethicsCase.value.like_count++
      ElMessage.success('点赞成功')
    } else {
      ethicsCase.value.like_count--
    }
  } catch (error) {
    console.error('点赞失败:', error)
    ElMessage.error(error.response?.data?.detail || '操作失败')
  }
}

const shareCase = () => {
  ElMessage.info('分享功能开发中...')
}

const submitComment = async () => {
  if (!newComment.value.trim()) return
  
  try {
    // 暂时使用本地添加方式，等待后端实现评论API
    const comment = {
      id: Date.now(),
      user_name: '当前用户',
      content: newComment.value,
      created_at: new Date().toISOString()
    }
    comments.value.unshift(comment)
    newComment.value = ''
    ElMessage.success('评论发表成功')
  } catch (error) {
    console.error('评论发表失败:', error)
    ElMessage.error(error.response?.data?.detail || '评论发表失败')
  }
}

const viewActivity = (activity) => {
  ElMessage.info(`查看活动: ${activity.title}`)
}

const viewCase = (relatedCase) => {
  router.push(`/ethics/case/${relatedCase.uuid}`)
}

const loadCaseDetail = async () => {
  try {
    const uuid = route.params.uuid
    
    // 获取案例详情
    const response = await getEthicsCaseDetail(uuid)
    if (response && response.data) {
      ethicsCase.value = response.data
      
      // 加载评论（如果后端返回了评论数据）
      comments.value = response.data.comments || []
    }
    
    // 加载相关案例
    const relatedResponse = await getEthicsCases({ limit: 3 })
    if (relatedResponse && relatedResponse.data) {
      relatedCases.value = (relatedResponse.data.items || []).filter(c => c.uuid !== uuid)
    }
    
    // 相关活动暂时留空，等待后端实现
    relatedActivities.value = []
  } catch (error) {
    console.error('加载案例详情失败:', error)
    ElMessage.error(error.response?.data?.detail || '加载数据失败')
  }
}

onMounted(() => {
  loadCaseDetail()
})
</script>

<style scoped>
.ethics-case-page {
  padding: 0;
}

.page-header {
  margin-bottom: 20px;
}

.page-title {
  font-size: 20px;
  font-weight: 600;
}

.main-content {
  margin-top: 20px;
}

.case-content-card,
.comments-card,
.side-card {
  margin-bottom: 20px;
  border-radius: 12px;
  border: none;
}

.case-cover {
  width: 100%;
  height: 300px;
  margin-bottom: 24px;
  border-radius: 8px;
  overflow: hidden;
}

.case-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.case-info {
  margin-bottom: 24px;
}

.case-meta {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 12px;
}

.topic-tag {
  font-size: 13px;
}

.case-stats {
  display: flex;
  gap: 20px;
  font-size: 14px;
  color: #909399;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 4px;
}

.case-description {
  margin-bottom: 24px;
  padding: 16px;
  background: #f5f7fa;
  border-radius: 8px;
}

.case-description h3 {
  margin: 0 0 12px 0;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.case-description p {
  margin: 0;
  line-height: 1.8;
  color: #606266;
}

.case-detail {
  margin-bottom: 32px;
  line-height: 1.8;
  color: #303133;
}

.case-detail :deep(h2) {
  font-size: 20px;
  margin: 24px 0 16px 0;
  color: #303133;
}

.case-detail :deep(h3) {
  font-size: 16px;
  margin: 20px 0 12px 0;
  color: #606266;
}

.case-detail :deep(p) {
  margin-bottom: 16px;
}

.discussion-questions {
  margin-bottom: 24px;
  padding: 20px;
  background: #fff7e6;
  border-radius: 8px;
  border-left: 4px solid #e6a23c;
}

.discussion-questions h3 {
  margin: 0 0 16px 0;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.question-item {
  display: flex;
  gap: 12px;
  margin-bottom: 12px;
  align-items: flex-start;
}

.question-item:last-child {
  margin-bottom: 0;
}

.question-number {
  flex-shrink: 0;
  width: 24px;
  height: 24px;
  background: #e6a23c;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 600;
}

.question-text {
  flex: 1;
  line-height: 1.6;
  color: #606266;
}

.references {
  margin-bottom: 24px;
  padding: 16px;
  background: #f0f9ff;
  border-radius: 8px;
}

.references h3 {
  margin: 0 0 12px 0;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.references ul {
  margin: 0;
  padding-left: 20px;
}

.references li {
  margin-bottom: 8px;
}

.references a {
  color: #409eff;
  text-decoration: none;
}

.references a:hover {
  text-decoration: underline;
}

.case-actions {
  display: flex;
  gap: 12px;
  padding: 20px 0;
  border-top: 1px solid #e4e7ed;
}

.comments-header {
  font-weight: 600;
  font-size: 16px;
}

.comment-input-area {
  margin-bottom: 24px;
}

.submit-comment-btn {
  margin-top: 12px;
}

.comments-list {
  max-height: 600px;
  overflow-y: auto;
}

.comment-item {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
  padding-bottom: 20px;
  border-bottom: 1px solid #e4e7ed;
}

.comment-item:last-child {
  border-bottom: none;
  margin-bottom: 0;
  padding-bottom: 0;
}

.comment-content {
  flex: 1;
}

.comment-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.comment-user {
  font-weight: 600;
  color: #303133;
}

.comment-time {
  font-size: 12px;
  color: #909399;
}

.comment-text {
  line-height: 1.6;
  color: #606266;
}

.side-card-title {
  font-weight: 600;
  font-size: 14px;
}

.activity-item,
.related-case-item {
  padding: 12px;
  margin-bottom: 12px;
  background: #f5f7fa;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.activity-item:hover,
.related-case-item:hover {
  background: #e4e7ed;
  transform: translateX(4px);
}

.activity-item:last-child,
.related-case-item:last-child {
  margin-bottom: 0;
}

.activity-item h4,
.related-case-item h4 {
  margin: 0 0 8px 0;
  font-size: 14px;
  font-weight: 600;
  color: #303133;
}

.activity-item p,
.related-case-item p {
  margin: 0 0 8px 0;
  font-size: 13px;
  color: #606266;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.activity-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.activity-time {
  font-size: 12px;
  color: #909399;
}

.related-case-tags {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}
</style>
