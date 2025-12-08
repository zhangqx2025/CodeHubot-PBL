<template>
  <div class="admin-course-detail">
    <el-page-header @back="goBack" title="返回">
      <template #content>
        <span class="page-title">课程详情</span>
      </template>
    </el-page-header>

    <div v-loading="loading" class="content-wrapper">
      <template v-if="!loading && courseDetail">
        <!-- 课程基本信息 -->
        <el-card class="course-info-card">
          <template #header>
            <div class="card-header">
              <span>课程信息</span>
            </div>
          </template>
          <el-descriptions :column="2" border>
            <el-descriptions-item label="课程ID">{{ courseDetail.id }}</el-descriptions-item>
            <el-descriptions-item label="课程标题">{{ courseDetail.title }}</el-descriptions-item>
            <el-descriptions-item label="难度">
              <el-tag :type="getDifficultyType(courseDetail.difficulty)">
                {{ getDifficultyText(courseDetail.difficulty) }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="状态">
              <el-tag :type="getStatusType(courseDetail.status)">
                {{ getStatusText(courseDetail.status) }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="时长">{{ courseDetail.duration || '未设置' }}</el-descriptions-item>
            <el-descriptions-item label="创建时间">{{ courseDetail.created_at }}</el-descriptions-item>
            <el-descriptions-item label="描述" :span="2">
              {{ courseDetail.description || '暂无描述' }}
            </el-descriptions-item>
          </el-descriptions>
        </el-card>

        <!-- 单元列表 -->
        <el-card class="units-card">
          <template #header>
            <div class="card-header">
              <span>课程结构（共 {{ courseDetail.units?.length || 0 }} 个单元）</span>
            </div>
          </template>

          <div v-if="courseDetail.units && courseDetail.units.length > 0">
            <el-collapse v-model="activeUnits" accordion>
              <el-collapse-item 
                v-for="unit in courseDetail.units" 
                :key="unit.id" 
                :name="unit.id"
              >
                <template #title>
                  <div class="unit-title">
                    <span class="unit-order">单元 {{ unit.order }}</span>
                    <span class="unit-name">{{ unit.title }}</span>
                    <el-tag :type="getUnitStatusType(unit.status)" size="small" style="margin-left: 10px;">
                      {{ getUnitStatusText(unit.status) }}
                    </el-tag>
                  </div>
                </template>

                <!-- 单元描述 -->
                <div class="unit-content">
                  <div class="unit-description">
                    <h4>单元描述</h4>
                    <p>{{ unit.description || '暂无描述' }}</p>
                  </div>

                  <!-- 资料列表 -->
                  <div class="resources-section">
                    <h4>学习资料（{{ unit.resources?.length || 0 }} 个）</h4>
                    <el-table 
                      v-if="unit.resources && unit.resources.length > 0"
                      :data="unit.resources" 
                      stripe
                      size="small"
                    >
                      <el-table-column prop="order" label="序号" width="80" />
                      <el-table-column prop="title" label="资料标题" />
                      <el-table-column prop="type" label="类型" width="100">
                        <template #default="{ row }">
                          <el-tag :type="getResourceType(row.type)" size="small">
                            {{ getResourceText(row.type) }}
                          </el-tag>
                        </template>
                      </el-table-column>
                      <el-table-column prop="duration" label="时长" width="100">
                        <template #default="{ row }">
                          {{ row.duration ? `${row.duration}分钟` : '-' }}
                        </template>
                      </el-table-column>
                      <el-table-column prop="description" label="描述" show-overflow-tooltip />
                    </el-table>
                    <el-empty v-else description="暂无资料" :image-size="80" />
                  </div>

                  <!-- 任务列表 -->
                  <div class="tasks-section">
                    <h4>学习任务（{{ unit.tasks?.length || 0 }} 个）</h4>
                    <el-table 
                      v-if="unit.tasks && unit.tasks.length > 0"
                      :data="unit.tasks" 
                      stripe
                      size="small"
                    >
                      <el-table-column prop="id" label="ID" width="80" />
                      <el-table-column prop="title" label="任务标题" />
                      <el-table-column prop="type" label="任务类型" width="100">
                        <template #default="{ row }">
                          <el-tag :type="getTaskTypeColor(row.type)" size="small">
                            {{ getTaskTypeText(row.type) }}
                          </el-tag>
                        </template>
                      </el-table-column>
                      <el-table-column prop="difficulty" label="难度" width="100">
                        <template #default="{ row }">
                          <el-tag :type="getTaskDifficultyType(row.difficulty)" size="small">
                            {{ getTaskDifficultyText(row.difficulty) }}
                          </el-tag>
                        </template>
                      </el-table-column>
                      <el-table-column prop="estimated_time" label="预计时长" width="120" />
                      <el-table-column prop="description" label="描述" show-overflow-tooltip />
                    </el-table>
                    <el-empty v-else description="暂无任务" :image-size="80" />
                  </div>
                </div>
              </el-collapse-item>
            </el-collapse>
          </div>
          <el-empty v-else description="该课程暂无单元" />
        </el-card>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { getCourseFullDetail } from '@/api/admin'

const router = useRouter()
const route = useRoute()

const loading = ref(false)
const courseDetail = ref(null)
const activeUnits = ref([])

// 获取课程UUID
const courseId = ref(route.params.courseId)

// 辅助函数
const getDifficultyType = (difficulty) => {
  const types = {
    beginner: 'success',
    intermediate: 'warning',
    advanced: 'danger'
  }
  return types[difficulty] || ''
}

const getDifficultyText = (difficulty) => {
  const texts = {
    beginner: '初级',
    intermediate: '中级',
    advanced: '高级'
  }
  return texts[difficulty] || difficulty
}

const getStatusType = (status) => {
  const types = {
    draft: 'info',
    published: 'success',
    archived: ''
  }
  return types[status] || ''
}

const getStatusText = (status) => {
  const texts = {
    draft: '草稿',
    published: '已发布',
    archived: '已归档'
  }
  return texts[status] || status
}

const getUnitStatusType = (status) => {
  const types = {
    locked: 'info',
    available: 'success',
    completed: ''
  }
  return types[status] || ''
}

const getUnitStatusText = (status) => {
  const texts = {
    locked: '未开放',
    available: '可学习',
    completed: '已完成'
  }
  return texts[status] || status
}

const getResourceType = (type) => {
  const types = {
    video: 'primary',
    document: 'success',
    link: 'info'
  }
  return types[type] || ''
}

const getResourceText = (type) => {
  const texts = {
    video: '视频',
    document: '文档',
    link: '链接'
  }
  return texts[type] || type
}

const getTaskTypeColor = (type) => {
  const types = {
    analysis: 'primary',
    coding: 'success',
    design: 'warning',
    deployment: 'danger'
  }
  return types[type] || ''
}

const getTaskTypeText = (type) => {
  const texts = {
    analysis: '分析',
    coding: '编码',
    design: '设计',
    deployment: '部署'
  }
  return texts[type] || type
}

const getTaskDifficultyType = (difficulty) => {
  const types = {
    easy: 'success',
    medium: 'warning',
    hard: 'danger'
  }
  return types[difficulty] || ''
}

const getTaskDifficultyText = (difficulty) => {
  const texts = {
    easy: '简单',
    medium: '中等',
    hard: '困难'
  }
  return texts[difficulty] || difficulty
}

// 加载课程详情
const loadCourseDetail = async () => {
  loading.value = true
  try {
    const data = await getCourseFullDetail(courseId.value)
    courseDetail.value = data
    // 默认展开第一个单元
    if (data.units && data.units.length > 0) {
      activeUnits.value = [data.units[0].id]
    }
  } catch (error) {
    ElMessage.error('加载课程详情失败：' + error.message)
  } finally {
    loading.value = false
  }
}

const goBack = () => {
  router.back()
}

onMounted(() => {
  loadCourseDetail()
})
</script>

<style scoped>
.admin-course-detail {
  padding: 20px;
}

.page-title {
  font-size: 18px;
  font-weight: bold;
}

.content-wrapper {
  margin-top: 20px;
  min-height: 400px;
}

.course-info-card {
  margin-bottom: 20px;
}

.units-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: bold;
}

.unit-title {
  display: flex;
  align-items: center;
  font-size: 16px;
  font-weight: bold;
}

.unit-order {
  color: #409eff;
  margin-right: 10px;
}

.unit-name {
  flex: 1;
}

.unit-content {
  padding: 15px 0;
}

.unit-description {
  margin-bottom: 20px;
}

.unit-description h4 {
  margin: 0 0 10px 0;
  color: #303133;
  font-size: 14px;
}

.unit-description p {
  margin: 0;
  color: #606266;
  line-height: 1.6;
}

.resources-section,
.tasks-section {
  margin-top: 20px;
}

.resources-section h4,
.tasks-section h4 {
  margin: 0 0 10px 0;
  color: #303133;
  font-size: 14px;
}

:deep(.el-collapse-item__header) {
  font-size: 16px;
  padding: 10px 0;
}

:deep(.el-collapse-item__content) {
  padding-bottom: 15px;
}
</style>
