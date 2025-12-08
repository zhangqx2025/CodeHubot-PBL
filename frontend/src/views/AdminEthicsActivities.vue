<template>
  <div class="admin-ethics-activities-page">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>思辨活动管理</span>
          <el-button type="primary" :icon="Plus" @click="handleCreate">创建活动</el-button>
        </div>
      </template>
      <el-table :data="activities" v-loading="loading" style="width: 100%">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="title" label="活动标题" width="200" />
        <el-table-column prop="activity_type" label="活动类型" width="100">
          <template #default="{ row }">
            {{ getActivityTypeText(row.activity_type) }}
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)" size="small">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="scheduled_at" label="计划时间" width="160">
          <template #default="{ row }">
            {{ row.scheduled_at ? new Date(row.scheduled_at).toLocaleString('zh-CN') : '-' }}
          </template>
        </el-table-column>
        <el-table-column label="参与人数" width="100">
          <template #default="{ row }">
            {{ (row.participants || []).length }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="handleView(row)">查看</el-button>
            <el-button size="small" type="primary" @click="handleEdit(row)">编辑</el-button>
            <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { getEthicsActivities, deleteEthicsActivity } from '@/api/ethics'

const loading = ref(false)
const activities = ref([])

const getActivityTypeText = (type) => {
  const texts = {
    debate: '辩论',
    case_analysis: '案例分析',
    role_play: '角色扮演',
    discussion: '讨论',
    reflection: '反思'
  }
  return texts[type] || type
}

const getStatusType = (status) => {
  const types = {
    planned: 'info',
    ongoing: 'success',
    completed: 'warning',
    cancelled: 'danger'
  }
  return types[status] || 'info'
}

const getStatusText = (status) => {
  const texts = {
    planned: '计划中',
    ongoing: '进行中',
    completed: '已完成',
    cancelled: '已取消'
  }
  return texts[status] || status
}

const loadActivities = async () => {
  loading.value = true
  try {
    const response = await getEthicsActivities()
    console.log('思辨活动原始响应:', response)
    // 兼容不同的响应格式
    const data = response.data || response
    console.log('思辨活动数据:', data)
    activities.value = data.items || []
    if (activities.value.length === 0) {
      console.log('提示：数据库中暂无思辨活动数据')
    }
  } catch (error) {
    console.error('加载思辨活动失败:', error)
    ElMessage.error('加载数据失败: ' + (error.message || '未知错误'))
    activities.value = []
  } finally {
    loading.value = false
  }
}

const handleCreate = () => {
  ElMessage.info('创建活动功能开发中...')
}

const handleView = (row) => {
  ElMessage.info(`查看活动: ${row.title}`)
}

const handleEdit = (row) => {
  ElMessage.info('编辑功能开发中...')
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除此活动吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await deleteEthicsActivity(row.uuid)
    ElMessage.success('删除成功')
    loadActivities()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
      ElMessage.error('删除失败')
    }
  }
}

onMounted(() => {
  loadActivities()
})
</script>

<style scoped>
.admin-ethics-activities-page {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
