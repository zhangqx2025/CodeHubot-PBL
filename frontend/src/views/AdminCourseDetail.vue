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
              <el-button type="primary" size="small" @click="editCourse">
                <el-icon><Edit /></el-icon>
                编辑课程
              </el-button>
            </div>
          </template>
          
          <div class="course-info-simple">
            <div class="info-item">
              <span class="info-label">课程标题:</span>
              <span class="info-value">{{ courseDetail.title }}</span>
            </div>
            
            <div class="info-item">
              <span class="info-label">时长:</span>
              <span class="info-value">{{ courseDetail.duration || '未设置' }}</span>
            </div>
            
            <div class="info-item full-width">
              <span class="info-label">描述:</span>
              <p class="info-value description">{{ courseDetail.description || '暂无描述' }}</p>
            </div>
          </div>
        </el-card>

        <!-- 单元列表 -->
        <el-card class="units-card">
          <template #header>
            <div class="card-header">
              <span>课程结构（共 {{ courseDetail.units?.length || 0 }} 个单元）</span>
              <el-button type="primary" size="small" @click="showAddUnitDialog">
                <el-icon><Plus /></el-icon>
                添加单元
              </el-button>
            </div>
          </template>

          <div v-if="courseDetail.units && courseDetail.units.length > 0">
            <el-collapse v-model="activeUnits">
              <el-collapse-item 
                v-for="unit in courseDetail.units" 
                :key="unit.id" 
                :name="unit.id"
              >
                <template #title>
                  <div class="unit-title-wrapper">
                    <div class="unit-title">
                      <span class="unit-order">单元 {{ unit.order }}</span>
                      <span class="unit-name">{{ unit.title }}</span>
                      <el-tag :type="getUnitStatusType(unit.status)" size="small">
                        {{ getUnitStatusText(unit.status) }}
                      </el-tag>
                    </div>
                    <div class="unit-actions" @click.stop>
                      <el-button 
                        type="primary" 
                        size="small" 
                        :icon="Edit"
                        @click="editUnit(unit)"
                      >
                        编辑
                      </el-button>
                      <el-button 
                        type="danger" 
                        size="small" 
                        :icon="Delete"
                        @click="handleDeleteUnit(unit)"
                      >
                        删除
                      </el-button>
                    </div>
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
                    <div class="section-header">
                      <h4>学习资料（{{ unit.resources?.length || 0 }} 个）</h4>
                      <el-button 
                        type="primary" 
                        size="small"
                        @click="showAddResourceDialog(unit)"
                      >
                        <el-icon><Plus /></el-icon>
                        添加资料
                      </el-button>
                    </div>
                    
                    <el-table 
                      v-if="unit.resources && unit.resources.length > 0"
                      :data="unit.resources" 
                      stripe
                      size="small"
                      class="resources-table"
                    >
                      <el-table-column prop="order" label="序号" width="80" align="center" />
                      <el-table-column prop="title" label="资料标题" min-width="180" />
                      <el-table-column prop="type" label="类型" width="100" align="center">
                        <template #default="{ row }">
                          <el-tag :type="getResourceType(row.type)" size="small">
                            {{ getResourceText(row.type) }}
                          </el-tag>
                        </template>
                      </el-table-column>
                      <el-table-column prop="duration" label="时长" width="100" align="center">
                        <template #default="{ row }">
                          {{ row.duration ? `${row.duration}分钟` : '-' }}
                        </template>
                      </el-table-column>
                      <el-table-column prop="description" label="描述" min-width="150" show-overflow-tooltip />
                      <el-table-column label="操作" width="220" align="center" fixed="right">
                        <template #default="{ row, $index }">
                          <el-button-group>
                            <el-button 
                              size="small" 
                              :icon="Top"
                              :disabled="$index === 0"
                              @click="moveResource(unit, row, 'up')"
                              title="上移"
                            />
                            <el-button 
                              size="small" 
                              :icon="Bottom"
                              :disabled="$index === unit.resources.length - 1"
                              @click="moveResource(unit, row, 'down')"
                              title="下移"
                            />
                            <el-button 
                              size="small" 
                              type="primary"
                              :icon="Edit"
                              @click="editResource(unit, row)"
                            >
                              编辑
                            </el-button>
                            <el-button 
                              size="small" 
                              type="danger"
                              :icon="Delete"
                              @click="handleDeleteResource(unit, row)"
                            >
                              删除
                            </el-button>
                          </el-button-group>
                        </template>
                      </el-table-column>
                    </el-table>
                    <el-empty v-else description="暂无资料" :image-size="80" />
                  </div>

                  <!-- 任务列表 -->
                  <div class="tasks-section">
                    <div class="section-header">
                      <h4>学习任务（{{ unit.tasks?.length || 0 }} 个）</h4>
                      <el-button 
                        type="primary" 
                        size="small"
                        @click="showAddTaskDialog(unit)"
                      >
                        <el-icon><Plus /></el-icon>
                        添加任务
                      </el-button>
                    </div>
                    
                    <el-table 
                      v-if="unit.tasks && unit.tasks.length > 0"
                      :data="unit.tasks" 
                      stripe
                      size="small"
                      class="tasks-table"
                    >
                      <el-table-column prop="id" label="ID" width="80" align="center" />
                      <el-table-column prop="title" label="任务标题" min-width="180" />
                      <el-table-column prop="type" label="任务类型" width="100" align="center">
                        <template #default="{ row }">
                          <el-tag :type="getTaskTypeColor(row.type)" size="small">
                            {{ getTaskTypeText(row.type) }}
                          </el-tag>
                        </template>
                      </el-table-column>
                      <el-table-column prop="difficulty" label="难度" width="100" align="center">
                        <template #default="{ row }">
                          <el-tag :type="getTaskDifficultyType(row.difficulty)" size="small">
                            {{ getTaskDifficultyText(row.difficulty) }}
                          </el-tag>
                        </template>
                      </el-table-column>
                      <el-table-column prop="estimated_time" label="预计时长" width="120" align="center" />
                      <el-table-column prop="description" label="描述" min-width="150" show-overflow-tooltip />
                      <el-table-column label="操作" width="160" align="center" fixed="right">
                        <template #default="{ row }">
                          <el-button 
                            size="small" 
                            type="primary"
                            :icon="Edit"
                            @click="editTask(unit, row)"
                          >
                            编辑
                          </el-button>
                          <el-button 
                            size="small" 
                            type="danger"
                            :icon="Delete"
                            @click="handleDeleteTask(unit, row)"
                          >
                            删除
                          </el-button>
                        </template>
                      </el-table-column>
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

    <!-- 编辑课程对话框 -->
    <el-dialog
      v-model="courseDialogVisible"
      title="编辑课程"
      width="600px"
    >
      <el-form :model="courseForm" label-width="100px">
        <el-form-item label="课程标题">
          <el-input v-model="courseForm.title" />
        </el-form-item>
        <el-form-item label="时长">
          <el-input v-model="courseForm.duration" placeholder="如：8周" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="courseForm.description" type="textarea" :rows="4" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="courseDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveCourse">保存</el-button>
      </template>
    </el-dialog>

    <!-- 添加/编辑单元对话框 -->
    <el-dialog
      v-model="unitDialogVisible"
      :title="unitForm.uuid ? '编辑单元' : '添加单元'"
      width="600px"
    >
      <el-form :model="unitForm" label-width="100px">
        <el-form-item label="单元标题">
          <el-input v-model="unitForm.title" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="unitForm.description" type="textarea" :rows="4" />
        </el-form-item>
        <el-form-item label="顺序">
          <el-input-number v-model="unitForm.order" :min="0" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="unitForm.status">
            <el-option label="未开放" value="locked" />
            <el-option label="可学习" value="available" />
            <el-option label="已完成" value="completed" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="unitDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveUnit">保存</el-button>
      </template>
    </el-dialog>

    <!-- 添加/编辑资源对话框 -->
    <el-dialog
      v-model="resourceDialogVisible"
      :title="resourceForm.uuid ? '编辑资源' : '添加资源'"
      width="600px"
    >
      <el-form :model="resourceForm" label-width="100px">
        <el-form-item label="资源类型">
          <el-select v-model="resourceForm.type">
            <el-option label="视频" value="video" />
            <el-option label="文档" value="document" />
            <el-option label="链接" value="link" />
          </el-select>
        </el-form-item>
        <el-form-item label="资源标题">
          <el-input v-model="resourceForm.title" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="resourceForm.description" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="资源URL">
          <el-input v-model="resourceForm.url" />
        </el-form-item>
        <el-form-item label="时长(分钟)" v-if="resourceForm.type === 'video'">
          <el-input-number v-model="resourceForm.duration" :min="0" />
        </el-form-item>
        <el-form-item label="顺序">
          <el-input-number v-model="resourceForm.order" :min="0" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="resourceDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveResource">保存</el-button>
      </template>
    </el-dialog>

    <!-- 添加/编辑任务对话框 -->
    <el-dialog
      v-model="taskDialogVisible"
      :title="taskForm.uuid ? '编辑任务' : '添加任务'"
      width="600px"
    >
      <el-form :model="taskForm" label-width="100px">
        <el-form-item label="任务标题">
          <el-input v-model="taskForm.title" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="taskForm.description" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="任务类型">
          <el-select v-model="taskForm.type">
            <el-option label="分析" value="analysis" />
            <el-option label="编码" value="coding" />
            <el-option label="设计" value="design" />
            <el-option label="部署" value="deployment" />
          </el-select>
        </el-form-item>
        <el-form-item label="难度">
          <el-select v-model="taskForm.difficulty">
            <el-option label="简单" value="easy" />
            <el-option label="中等" value="medium" />
            <el-option label="困难" value="hard" />
          </el-select>
        </el-form-item>
        <el-form-item label="预计时长">
          <el-input v-model="taskForm.estimated_time" placeholder="如：2小时" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="taskDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveTask">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Edit, Delete, Plus, Top, Bottom } from '@element-plus/icons-vue'
import { 
  getCourseFullDetail, 
  updateCourse,
  createCourseUnit,
  updateCourseUnit,
  deleteCourseUnit,
  createCourseResource,
  updateCourseResource,
  deleteCourseResource,
  updateResourceOrder,
  createCourseTask,
  updateCourseTask,
  deleteCourseTask
} from '@/api/admin'

const router = useRouter()
const route = useRoute()

const loading = ref(false)
const courseDetail = ref(null)
const activeUnits = ref([])

// 获取课程UUID
const courseId = ref(route.params.courseId)

// 对话框控制
const courseDialogVisible = ref(false)
const unitDialogVisible = ref(false)
const resourceDialogVisible = ref(false)
const taskDialogVisible = ref(false)

// 表单数据
const courseForm = ref({
  title: '',
  description: '',
  duration: ''
})

const unitForm = ref({
  uuid: null,
  title: '',
  description: '',
  order: 0,
  status: 'locked',
  course_uuid: ''
})

const resourceForm = ref({
  uuid: null,
  unit_uuid: null,
  type: 'video',
  title: '',
  description: '',
  url: '',
  duration: null,
  order: 0
})

const taskForm = ref({
  uuid: null,
  unit_uuid: null,
  unit_id: null,
  title: '',
  description: '',
  type: 'analysis',
  difficulty: 'easy',
  estimated_time: ''
})

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

// 编辑课程
const editCourse = () => {
  courseForm.value = {
    title: courseDetail.value.title,
    description: courseDetail.value.description,
    duration: courseDetail.value.duration
  }
  courseDialogVisible.value = true
}

const saveCourse = async () => {
  try {
    await updateCourse(courseId.value, courseForm.value)
    ElMessage.success('课程更新成功')
    courseDialogVisible.value = false
    loadCourseDetail()
  } catch (error) {
    ElMessage.error('更新失败：' + error.message)
  }
}

// 单元管理
const showAddUnitDialog = () => {
  unitForm.value = {
    uuid: null,
    title: '',
    description: '',
    order: (courseDetail.value.units?.length || 0) + 1,
    status: 'locked',
    course_uuid: courseId.value
  }
  unitDialogVisible.value = true
}

const editUnit = (unit) => {
  unitForm.value = {
    uuid: unit.uuid,
    title: unit.title,
    description: unit.description,
    order: unit.order,
    status: unit.status,
    course_uuid: courseId.value
  }
  unitDialogVisible.value = true
}

const saveUnit = async () => {
  try {
    if (unitForm.value.uuid) {
      // 更新
      await updateCourseUnit(courseId.value, unitForm.value.uuid, {
        title: unitForm.value.title,
        description: unitForm.value.description,
        order: unitForm.value.order,
        status: unitForm.value.status
      })
      ElMessage.success('单元更新成功')
    } else {
      // 创建
      await createCourseUnit(courseId.value, {
        title: unitForm.value.title,
        description: unitForm.value.description,
        order: unitForm.value.order,
        status: unitForm.value.status,
        course_uuid: courseId.value
      })
      ElMessage.success('单元创建成功')
    }
    unitDialogVisible.value = false
    loadCourseDetail()
  } catch (error) {
    ElMessage.error('保存失败：' + error.message)
  }
}

const handleDeleteUnit = (unit) => {
  ElMessageBox.confirm(
    '确定要删除这个单元吗？单元下的所有资源和任务也将被删除。',
    '警告',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(async () => {
    try {
      await deleteCourseUnit(courseId.value, unit.uuid)
      ElMessage.success('单元删除成功')
      loadCourseDetail()
    } catch (error) {
      ElMessage.error('删除失败：' + error.message)
    }
  }).catch(() => {})
}

// 资源管理
const showAddResourceDialog = (unit) => {
  resourceForm.value = {
    uuid: null,
    unit_uuid: unit.uuid,
    type: 'video',
    title: '',
    description: '',
    url: '',
    duration: null,
    order: (unit.resources?.length || 0) + 1
  }
  resourceDialogVisible.value = true
}

const editResource = (unit, resource) => {
  resourceForm.value = {
    uuid: resource.uuid,
    unit_uuid: unit.uuid,
    type: resource.type,
    title: resource.title,
    description: resource.description,
    url: resource.url,
    duration: resource.duration,
    order: resource.order
  }
  resourceDialogVisible.value = true
}

const saveResource = async () => {
  try {
    if (resourceForm.value.uuid) {
      // 更新
      await updateCourseResource(
        courseId.value, 
        resourceForm.value.unit_uuid, 
        resourceForm.value.uuid,
        {
          type: resourceForm.value.type,
          title: resourceForm.value.title,
          description: resourceForm.value.description,
          url: resourceForm.value.url,
          duration: resourceForm.value.duration,
          order: resourceForm.value.order
        }
      )
      ElMessage.success('资源更新成功')
    } else {
      // 创建
      await createCourseResource(
        courseId.value,
        resourceForm.value.unit_uuid,
        {
          type: resourceForm.value.type,
          title: resourceForm.value.title,
          description: resourceForm.value.description,
          url: resourceForm.value.url,
          duration: resourceForm.value.duration,
          order: resourceForm.value.order
        }
      )
      ElMessage.success('资源创建成功')
    }
    resourceDialogVisible.value = false
    loadCourseDetail()
  } catch (error) {
    ElMessage.error('保存失败：' + error.message)
  }
}

const handleDeleteResource = (unit, resource) => {
  ElMessageBox.confirm(
    '确定要删除这个资源吗？',
    '警告',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(async () => {
    try {
      await deleteCourseResource(courseId.value, unit.uuid, resource.uuid)
      ElMessage.success('资源删除成功')
      loadCourseDetail()
    } catch (error) {
      ElMessage.error('删除失败：' + error.message)
    }
  }).catch(() => {})
}

const moveResource = async (unit, resource, direction) => {
  try {
    const currentIndex = unit.resources.findIndex(r => r.uuid === resource.uuid)
    let newOrder = resource.order
    
    if (direction === 'up' && currentIndex > 0) {
      newOrder = unit.resources[currentIndex - 1].order
    } else if (direction === 'down' && currentIndex < unit.resources.length - 1) {
      newOrder = unit.resources[currentIndex + 1].order
    }
    
    await updateResourceOrder(courseId.value, unit.uuid, resource.uuid, newOrder)
    ElMessage.success('资源顺序更新成功')
    loadCourseDetail()
  } catch (error) {
    ElMessage.error('更新失败：' + error.message)
  }
}

// 任务管理
const showAddTaskDialog = (unit) => {
  taskForm.value = {
    uuid: null,
    unit_uuid: unit.uuid,
    unit_id: unit.id,
    title: '',
    description: '',
    type: 'analysis',
    difficulty: 'easy',
    estimated_time: ''
  }
  taskDialogVisible.value = true
}

const editTask = (unit, task) => {
  taskForm.value = {
    uuid: task.uuid,
    unit_uuid: unit.uuid,
    unit_id: unit.id,
    title: task.title,
    description: task.description,
    type: task.type,
    difficulty: task.difficulty,
    estimated_time: task.estimated_time
  }
  taskDialogVisible.value = true
}

const saveTask = async () => {
  try {
    if (taskForm.value.uuid) {
      // 更新
      await updateCourseTask(
        courseId.value,
        taskForm.value.unit_uuid,
        taskForm.value.uuid,
        {
          title: taskForm.value.title,
          description: taskForm.value.description,
          type: taskForm.value.type,
          difficulty: taskForm.value.difficulty,
          estimated_time: taskForm.value.estimated_time
        }
      )
      ElMessage.success('任务更新成功')
    } else {
      // 创建
      await createCourseTask(
        courseId.value,
        taskForm.value.unit_uuid,
        {
          unit_id: taskForm.value.unit_id,
          title: taskForm.value.title,
          description: taskForm.value.description,
          type: taskForm.value.type,
          difficulty: taskForm.value.difficulty,
          estimated_time: taskForm.value.estimated_time
        }
      )
      ElMessage.success('任务创建成功')
    }
    taskDialogVisible.value = false
    loadCourseDetail()
  } catch (error) {
    ElMessage.error('保存失败：' + error.message)
  }
}

const handleDeleteTask = (unit, task) => {
  ElMessageBox.confirm(
    '确定要删除这个任务吗？',
    '警告',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(async () => {
    try {
      await deleteCourseTask(courseId.value, unit.uuid, task.uuid)
      ElMessage.success('任务删除成功')
      loadCourseDetail()
    } catch (error) {
      ElMessage.error('删除失败：' + error.message)
    }
  }).catch(() => {})
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

/* 课程信息简化布局 */
.course-info-simple {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.info-item.full-width {
  width: 100%;
}

.info-label {
  font-size: 14px;
  color: #909399;
  font-weight: 500;
}

.info-value {
  font-size: 15px;
  color: #303133;
  font-weight: 500;
}

.info-value.description {
  line-height: 1.8;
  white-space: pre-wrap;
  margin: 0;
  color: #606266;
  font-weight: 400;
}

/* 单元标题 */
.unit-title-wrapper {
  width: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-right: 20px;
}

.unit-title {
  display: flex;
  align-items: center;
  font-size: 16px;
  font-weight: bold;
  gap: 12px;
  flex: 1;
}

.unit-order {
  color: #409eff;
  font-weight: 700;
}

.unit-name {
  flex: 1;
}

.unit-actions {
  display: flex;
  gap: 8px;
}

.unit-content {
  padding: 20px 0;
}

.unit-description {
  margin-bottom: 24px;
  padding: 16px;
  background: #f5f7fa;
  border-radius: 8px;
}

.unit-description h4 {
  margin: 0 0 12px 0;
  color: #303133;
  font-size: 15px;
  font-weight: 600;
}

.unit-description p {
  margin: 0;
  color: #606266;
  line-height: 1.8;
}

/* 资源和任务区域 */
.resources-section,
.tasks-section {
  margin-top: 24px;
  padding: 16px;
  background: #ffffff;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.section-header h4 {
  margin: 0;
  color: #303133;
  font-size: 15px;
  font-weight: 600;
}

.resources-table,
.tasks-table {
  margin-top: 12px;
}

/* 折叠面板样式优化 */
:deep(.el-collapse-item__header) {
  font-size: 16px;
  padding: 16px 0;
  background: transparent;
}

:deep(.el-collapse-item__content) {
  padding-bottom: 20px;
}

:deep(.el-collapse-item__wrap) {
  border-bottom: none;
}

/* 响应式 */
@media (max-width: 768px) {
  .unit-title-wrapper {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }
  
  .unit-actions {
    width: 100%;
    justify-content: flex-end;
  }
}
</style>
