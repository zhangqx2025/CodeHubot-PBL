<template>
  <div class="admin-video-permissions">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>视频观看权限设置</span>
        </div>
      </template>

      <!-- 选择课程、单元和视频 -->
      <div class="filter-section">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-select 
              v-model="selectedCourseUuid" 
              placeholder="选择课程" 
              style="width: 100%;" 
              @change="loadUnits"
              clearable
            >
              <el-option
                v-for="course in courses"
                :key="course.uuid"
                :label="course.title"
                :value="course.uuid"
              />
            </el-select>
          </el-col>
          <el-col :span="8">
            <el-select 
              v-model="selectedUnitUuid" 
              placeholder="选择单元" 
              style="width: 100%;" 
              @change="loadResources" 
              :disabled="!selectedCourseUuid"
              clearable
            >
              <el-option
                v-for="unit in units"
                :key="unit.uuid"
                :label="unit.title"
                :value="unit.uuid"
              />
            </el-select>
          </el-col>
          <el-col :span="8">
            <el-select 
              v-model="selectedResourceUuid" 
              placeholder="选择视频" 
              style="width: 100%;" 
              @change="handleVideoSelect"
              :disabled="!selectedUnitUuid"
              clearable
            >
              <el-option
                v-for="resource in videoResources"
                :key="resource.uuid"
                :label="resource.title"
                :value="resource.uuid"
              />
            </el-select>
          </el-col>
        </el-row>
      </div>

      <!-- 视频未选择提示 -->
      <el-empty v-if="!selectedResourceUuid" description="请选择课程、单元和视频" />

      <!-- 已选择视频的设置 -->
      <div v-else class="permission-settings">
        <!-- 全局设置 -->
        <el-card class="setting-card" shadow="never">
          <template #header>
            <div class="card-header">
              <span>全局设置</span>
              <el-button type="primary" size="small" @click="handleGlobalSetting">保存全局设置</el-button>
            </div>
          </template>
          <el-form :model="globalSettings" label-width="140px">
            <el-form-item label="观看次数限制">
              <el-radio-group v-model="globalSettings.limitType">
                <el-radio label="unlimited">不限制</el-radio>
                <el-radio label="limited">限制次数</el-radio>
                <el-radio label="forbidden">禁止观看</el-radio>
              </el-radio-group>
            </el-form-item>
            <el-form-item label="最大观看次数" v-if="globalSettings.limitType === 'limited'">
              <el-input-number v-model="globalSettings.maxViews" :min="1" :max="100" />
              <span style="margin-left: 10px; color: #909399;">次</span>
            </el-form-item>
            <el-form-item label="有效期设置">
              <el-switch v-model="globalSettings.enableValidPeriod" />
            </el-form-item>
            <el-form-item label="有效期范围" v-if="globalSettings.enableValidPeriod">
              <el-date-picker
                v-model="globalSettings.validPeriod"
                type="datetimerange"
                range-separator="至"
                start-placeholder="开始时间"
                end-placeholder="结束时间"
                value-format="YYYY-MM-DD HH:mm:ss"
              />
            </el-form-item>
          </el-form>
        </el-card>

        <!-- 个性化设置 -->
        <el-card class="setting-card" shadow="never">
          <template #header>
            <div class="card-header">
              <span>个性化权限设置</span>
              <div>
                <el-button type="primary" size="small" @click="showSinglePermissionDialog">添加学生权限</el-button>
                <el-button type="success" size="small" @click="showBatchPermissionDialog">批量设置</el-button>
              </div>
            </div>
          </template>

          <!-- 个性化权限列表 -->
          <el-table :data="userPermissions" v-loading="loadingPermissions" stripe>
            <el-table-column prop="user_id" label="学生ID" width="100" />
            <el-table-column prop="username" label="学生账号" width="150" />
            <el-table-column prop="real_name" label="学生姓名" width="120" />
            <el-table-column label="观看次数限制" width="150">
              <template #default="{ row }">
                <el-tag v-if="row.max_views === null" type="info">使用全局配置</el-tag>
                <el-tag v-else-if="row.max_views === 0" type="danger">禁止观看</el-tag>
                <el-tag v-else type="success">{{ row.max_views }} 次</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="有效期" width="350">
              <template #default="{ row }">
                <span v-if="!row.valid_from && !row.valid_until">无限制</span>
                <span v-else>
                  {{ row.valid_from || '不限' }} 至 {{ row.valid_until || '不限' }}
                </span>
              </template>
            </el-table-column>
            <el-table-column prop="reason" label="设置原因" show-overflow-tooltip />
            <el-table-column prop="created_at" label="设置时间" width="180" />
            <el-table-column label="操作" width="180" fixed="right">
              <template #default="{ row }">
                <el-button size="small" @click="handleEditPermission(row)">编辑</el-button>
                <el-button size="small" type="danger" @click="handleDeletePermission(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>

          <el-empty v-if="!userPermissions || userPermissions.length === 0" description="暂无个性化权限配置" />
        </el-card>

        <!-- 观看统计 -->
        <el-card class="setting-card" shadow="never">
          <template #header>
            <div class="card-header">
              <span>观看统计</span>
              <el-button size="small" @click="loadWatchHistory">刷新</el-button>
            </div>
          </template>
          <el-descriptions :column="4" border>
            <el-descriptions-item label="总观看次数">{{ watchStats.watch_count || 0 }}</el-descriptions-item>
            <el-descriptions-item label="总观看时长">{{ formatDuration(watchStats.total_duration) }}</el-descriptions-item>
            <el-descriptions-item label="完整观看次数">{{ watchStats.completed_count || 0 }}</el-descriptions-item>
            <el-descriptions-item label="最后观看时间">{{ watchStats.last_watch_time || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-card>
      </div>
    </el-card>

    <!-- 单个学生权限设置对话框 -->
    <el-dialog
      v-model="permissionDialogVisible"
      :title="permissionDialogTitle"
      width="600px"
    >
      <el-form :model="permissionForm" :rules="permissionRules" ref="permissionFormRef" label-width="120px">
        <el-form-item label="学生" prop="user_id" v-if="!editingPermission">
          <el-select 
            v-model="permissionForm.user_id" 
            placeholder="请选择学生" 
            filterable
            style="width: 100%;"
          >
            <el-option
              v-for="student in students"
              :key="student.id"
              :label="`${student.real_name} (${student.username})`"
              :value="student.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="观看次数限制">
          <el-radio-group v-model="permissionForm.limitType">
            <el-radio label="default">使用全局配置</el-radio>
            <el-radio label="unlimited">不限制</el-radio>
            <el-radio label="limited">限制次数</el-radio>
            <el-radio label="forbidden">禁止观看</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="最大观看次数" v-if="permissionForm.limitType === 'limited'">
          <el-input-number v-model="permissionForm.max_views" :min="1" :max="100" />
          <span style="margin-left: 10px; color: #909399;">次</span>
        </el-form-item>
        <el-form-item label="有效期设置">
          <el-switch v-model="permissionForm.enableValidPeriod" />
        </el-form-item>
        <el-form-item label="有效期范围" v-if="permissionForm.enableValidPeriod">
          <el-date-picker
            v-model="permissionForm.validPeriod"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            value-format="YYYY-MM-DD HH:mm:ss"
          />
        </el-form-item>
        <el-form-item label="设置原因" prop="reason">
          <el-input
            v-model="permissionForm.reason"
            type="textarea"
            :rows="3"
            placeholder="请输入设置原因（如：补课、奖励等）"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="permissionDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handlePermissionSubmit" :loading="submitting">确定</el-button>
      </template>
    </el-dialog>

    <!-- 批量设置对话框 -->
    <el-dialog
      v-model="batchDialogVisible"
      title="批量设置权限"
      width="700px"
    >
      <el-form :model="batchForm" label-width="120px">
        <el-form-item label="选择学生">
          <el-select 
            v-model="batchForm.user_ids" 
            placeholder="请选择学生" 
            multiple
            filterable
            style="width: 100%;"
          >
            <el-option
              v-for="student in students"
              :key="student.id"
              :label="`${student.real_name} (${student.username})`"
              :value="student.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="观看次数限制">
          <el-radio-group v-model="batchForm.limitType">
            <el-radio label="unlimited">不限制</el-radio>
            <el-radio label="limited">限制次数</el-radio>
            <el-radio label="forbidden">禁止观看</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="最大观看次数" v-if="batchForm.limitType === 'limited'">
          <el-input-number v-model="batchForm.max_views" :min="1" :max="100" />
          <span style="margin-left: 10px; color: #909399;">次</span>
        </el-form-item>
        <el-form-item label="有效期设置">
          <el-switch v-model="batchForm.enableValidPeriod" />
        </el-form-item>
        <el-form-item label="有效期范围" v-if="batchForm.enableValidPeriod">
          <el-date-picker
            v-model="batchForm.validPeriod"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            value-format="YYYY-MM-DD HH:mm:ss"
          />
        </el-form-item>
        <el-form-item label="设置原因">
          <el-input
            v-model="batchForm.reason"
            type="textarea"
            :rows="3"
            placeholder="请输入设置原因（如：期末复习、考试限制等）"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="batchDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleBatchSubmit" :loading="submitting">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  getCourses, 
  getUnits, 
  getResources,
  setVideoPermission,
  batchSetVideoPermissions,
  deleteVideoPermission,
  getVideoWatchStats,
  updateResource
} from '@/api/admin'
import { getUserList } from '@/api/users'

const route = useRoute()

// 数据定义
const loading = ref(false)
const loadingPermissions = ref(false)
const submitting = ref(false)
const courses = ref([])
const units = ref([])
const resources = ref([])
const students = ref([])
const userPermissions = ref([])
const watchStats = ref({})

const selectedCourseUuid = ref(null)
const selectedUnitUuid = ref(null)
const selectedResourceUuid = ref(null)
const selectedResource = ref(null)

// 全局设置
const globalSettings = reactive({
  limitType: 'unlimited',
  maxViews: 3,
  enableValidPeriod: false,
  validPeriod: null
})

// 个性化权限设置对话框
const permissionDialogVisible = ref(false)
const permissionDialogTitle = ref('添加学生权限')
const editingPermission = ref(null)
const permissionFormRef = ref(null)
const permissionForm = reactive({
  user_id: null,
  limitType: 'default',
  max_views: 3,
  enableValidPeriod: false,
  validPeriod: null,
  reason: ''
})

const permissionRules = {
  user_id: [{ required: true, message: '请选择学生', trigger: 'change' }]
}

// 批量设置对话框
const batchDialogVisible = ref(false)
const batchForm = reactive({
  user_ids: [],
  limitType: 'limited',
  max_views: 3,
  enableValidPeriod: false,
  validPeriod: null,
  reason: ''
})

// 计算属性
const videoResources = computed(() => {
  return resources.value.filter(r => r.type === 'video')
})

// 加载课程列表
const loadCourses = async () => {
  try {
    const data = await getCourses()
    courses.value = Array.isArray(data) ? data : []
  } catch (error) {
    ElMessage.error('加载课程列表失败')
  }
}

// 加载单元列表
const loadUnits = async () => {
  if (!selectedCourseUuid.value) return
  
  try {
    const data = await getUnits(selectedCourseUuid.value)
    units.value = Array.isArray(data) ? data : []
    selectedUnitUuid.value = null
    selectedResourceUuid.value = null
    resources.value = []
  } catch (error) {
    ElMessage.error('加载单元列表失败')
  }
}

// 加载资源列表
const loadResources = async () => {
  if (!selectedUnitUuid.value) return
  
  loading.value = true
  try {
    const data = await getResources(selectedUnitUuid.value)
    resources.value = Array.isArray(data) ? data : []
    selectedResourceUuid.value = null
  } catch (error) {
    ElMessage.error('加载资料列表失败')
  } finally {
    loading.value = false
  }
}

// 加载学生列表
const loadStudents = async () => {
  try {
    const data = await getUserList({ role: 'student' })
    students.value = Array.isArray(data) ? data : []
  } catch (error) {
    ElMessage.error('加载学生列表失败')
  }
}

// 选择视频
const handleVideoSelect = async () => {
  if (!selectedResourceUuid.value) return
  
  selectedResource.value = resources.value.find(r => r.uuid === selectedResourceUuid.value)
  
  // 加载当前视频的全局设置
  if (selectedResource.value) {
    if (selectedResource.value.max_views === null) {
      globalSettings.limitType = 'unlimited'
    } else if (selectedResource.value.max_views === 0) {
      globalSettings.limitType = 'forbidden'
    } else {
      globalSettings.limitType = 'limited'
      globalSettings.maxViews = selectedResource.value.max_views
    }
    
    globalSettings.enableValidPeriod = !!(selectedResource.value.valid_from || selectedResource.value.valid_until)
    if (globalSettings.enableValidPeriod) {
      globalSettings.validPeriod = [selectedResource.value.valid_from, selectedResource.value.valid_until]
    }
  }
  
  // 加载个性化权限列表（这里需要从后端获取）
  // TODO: 实现获取个性化权限列表的API
  userPermissions.value = []
  
  // 加载观看统计
  loadWatchStats()
}

// 加载观看统计
const loadWatchStats = async () => {
  if (!selectedResourceUuid.value) return
  
  try {
    const data = await getVideoWatchStats(selectedResourceUuid.value)
    watchStats.value = data || {}
  } catch (error) {
    console.error('加载观看统计失败:', error)
  }
}

// 加载观看历史
const loadWatchHistory = async () => {
  loadWatchStats()
}

// 格式化时长
const formatDuration = (seconds) => {
  if (!seconds) return '0秒'
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = seconds % 60
  
  let result = ''
  if (hours > 0) result += `${hours}小时`
  if (minutes > 0) result += `${minutes}分钟`
  if (secs > 0 || result === '') result += `${secs}秒`
  
  return result
}

// 保存全局设置
const handleGlobalSetting = async () => {
  try {
    await ElMessageBox.confirm('确定要更新全局设置吗？这将影响所有没有个性化配置的学生。', '提示', {
      type: 'warning'
    })
    
    submitting.value = true
    
    let maxViews = null
    if (globalSettings.limitType === 'limited') {
      maxViews = globalSettings.maxViews
    } else if (globalSettings.limitType === 'forbidden') {
      maxViews = 0
    }
    
    let validFrom = null
    let validUntil = null
    if (globalSettings.enableValidPeriod && globalSettings.validPeriod) {
      validFrom = globalSettings.validPeriod[0]
      validUntil = globalSettings.validPeriod[1]
    }
    
    await updateResource(selectedResource.value.id, {
      max_views: maxViews,
      valid_from: validFrom,
      valid_until: validUntil
    })
    
    ElMessage.success('全局设置保存成功')
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('保存失败: ' + error.message)
    }
  } finally {
    submitting.value = false
  }
}

// 显示单个权限设置对话框
const showSinglePermissionDialog = () => {
  editingPermission.value = null
  permissionDialogTitle.value = '添加学生权限'
  Object.assign(permissionForm, {
    user_id: null,
    limitType: 'default',
    max_views: 3,
    enableValidPeriod: false,
    validPeriod: null,
    reason: ''
  })
  permissionDialogVisible.value = true
}

// 显示批量设置对话框
const showBatchPermissionDialog = () => {
  Object.assign(batchForm, {
    user_ids: [],
    limitType: 'limited',
    max_views: 3,
    enableValidPeriod: false,
    validPeriod: null,
    reason: ''
  })
  batchDialogVisible.value = true
}

// 编辑权限
const handleEditPermission = (row) => {
  editingPermission.value = row
  permissionDialogTitle.value = '编辑学生权限'
  
  let limitType = 'default'
  if (row.max_views === null) {
    limitType = 'default'
  } else if (row.max_views === 0) {
    limitType = 'forbidden'
  } else {
    limitType = 'limited'
  }
  
  Object.assign(permissionForm, {
    user_id: row.user_id,
    limitType: limitType,
    max_views: row.max_views || 3,
    enableValidPeriod: !!(row.valid_from || row.valid_until),
    validPeriod: row.valid_from || row.valid_until ? [row.valid_from, row.valid_until] : null,
    reason: row.reason || ''
  })
  
  permissionDialogVisible.value = true
}

// 提交权限设置
const handlePermissionSubmit = async () => {
  if (!permissionFormRef.value) return
  
  try {
    const valid = await permissionFormRef.value.validate()
    if (!valid) return
    
    submitting.value = true
    
    let maxViews = null
    if (permissionForm.limitType === 'limited') {
      maxViews = permissionForm.max_views
    } else if (permissionForm.limitType === 'forbidden') {
      maxViews = 0
    } else if (permissionForm.limitType === 'default') {
      maxViews = null
    }
    
    let validFrom = null
    let validUntil = null
    if (permissionForm.enableValidPeriod && permissionForm.validPeriod) {
      validFrom = permissionForm.validPeriod[0]
      validUntil = permissionForm.validPeriod[1]
    }
    
    await setVideoPermission(selectedResourceUuid.value, {
      user_id: permissionForm.user_id,
      max_views: maxViews,
      valid_from: validFrom,
      valid_until: validUntil,
      reason: permissionForm.reason
    })
    
    ElMessage.success('权限设置成功')
    permissionDialogVisible.value = false
    // TODO: 重新加载个性化权限列表
  } catch (error) {
    ElMessage.error('设置失败: ' + error.message)
  } finally {
    submitting.value = false
  }
}

// 批量设置提交
const handleBatchSubmit = async () => {
  if (batchForm.user_ids.length === 0) {
    ElMessage.warning('请选择至少一个学生')
    return
  }
  
  try {
    await ElMessageBox.confirm(`确定要为 ${batchForm.user_ids.length} 个学生批量设置权限吗？`, '提示', {
      type: 'warning'
    })
    
    submitting.value = true
    
    let maxViews = null
    if (batchForm.limitType === 'limited') {
      maxViews = batchForm.max_views
    } else if (batchForm.limitType === 'forbidden') {
      maxViews = 0
    }
    
    let validFrom = null
    let validUntil = null
    if (batchForm.enableValidPeriod && batchForm.validPeriod) {
      validFrom = batchForm.validPeriod[0]
      validUntil = batchForm.validPeriod[1]
    }
    
    await batchSetVideoPermissions(selectedResourceUuid.value, {
      user_ids: batchForm.user_ids,
      max_views: maxViews,
      valid_from: validFrom,
      valid_until: validUntil,
      reason: batchForm.reason
    })
    
    ElMessage.success('批量设置成功')
    batchDialogVisible.value = false
    // TODO: 重新加载个性化权限列表
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('批量设置失败: ' + error.message)
    }
  } finally {
    submitting.value = false
  }
}

// 删除权限
const handleDeletePermission = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除该学生的个性化权限吗？删除后将使用全局配置。', '提示', {
      type: 'warning'
    })
    
    await deleteVideoPermission(selectedResourceUuid.value, row.user_id)
    ElMessage.success('删除成功')
    // TODO: 重新加载个性化权限列表
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败: ' + error.message)
    }
  }
}

// 初始化
onMounted(async () => {
  await loadCourses()
  await loadStudents()
  
  // 从URL参数中获取预选的课程、单元和资源
  const { courseUuid, unitUuid, resourceUuid } = route.query
  
  if (courseUuid) {
    selectedCourseUuid.value = courseUuid
    await loadUnits()
    
    if (unitUuid) {
      selectedUnitUuid.value = unitUuid
      await loadResources()
      
      if (resourceUuid) {
        selectedResourceUuid.value = resourceUuid
        await handleVideoSelect()
      }
    }
  }
})
</script>

<style scoped>
.admin-video-permissions {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.filter-section {
  margin-bottom: 20px;
}

.permission-settings {
  margin-top: 20px;
}

.setting-card {
  margin-bottom: 20px;
}

.setting-card:last-child {
  margin-bottom: 0;
}
</style>
