<template>
  <div class="admin-experts-page">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>专家管理</span>
          <el-button type="primary" :icon="Plus" @click="handleCreate">添加专家</el-button>
        </div>
      </template>
      <el-table :data="experts" v-loading="loading" style="width: 100%">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="name" label="姓名" width="120" />
        <el-table-column prop="organization" label="所属单位" width="180" />
        <el-table-column prop="title" label="职称/职位" width="150" />
        <el-table-column prop="expertise_areas" label="专业领域" width="200">
          <template #default="{ row }">
            <el-tag
              v-for="area in (row.expertise_areas || []).slice(0, 2)"
              :key="area"
              size="small"
              style="margin-right: 4px;"
            >
              {{ area }}
            </el-tag>
            <span v-if="!row.expertise_areas || row.expertise_areas.length === 0">-</span>
          </template>
        </el-table-column>
        <el-table-column prop="participated_projects" label="参与项目" width="100" />
        <el-table-column prop="is_active" label="状态" width="80">
          <template #default="{ row }">
            <el-switch v-model="row.is_active" @change="handleStatusChange(row)" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="handleView(row)">查看</el-button>
            <el-button size="small" type="primary" @click="handleEdit(row)">编辑</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { getExperts, updateExpert } from '@/api/expert'

const loading = ref(false)
const experts = ref([])

const loadExperts = async () => {
  loading.value = true
  try {
    const response = await getExperts()
    console.log('专家数据:', response)
    experts.value = response.items || []
    if (experts.value.length === 0) {
      console.log('提示：数据库中暂无专家数据')
    }
  } catch (error) {
    console.error('加载专家列表失败:', error)
    ElMessage.error('加载数据失败: ' + (error.message || '未知错误'))
    experts.value = []
  } finally {
    loading.value = false
  }
}

const handleCreate = () => {
  ElMessage.info('添加专家功能开发中...')
}

const handleView = (row) => {
  ElMessage.info(`查看专家: ${row.name}`)
}

const handleEdit = (row) => {
  ElMessage.info('编辑功能开发中...')
}

const handleStatusChange = async (row) => {
  try {
    await updateExpert(row.uuid, { is_active: row.is_active })
    ElMessage.success('状态更新成功')
  } catch (error) {
    console.error('更新状态失败:', error)
    ElMessage.error('更新状态失败')
    row.is_active = !row.is_active
  }
}

onMounted(() => {
  loadExperts()
})
</script>

<style scoped>
.admin-experts-page {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
