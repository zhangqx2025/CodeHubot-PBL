<template>
  <div class="admin-ethics-cases-page">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>伦理案例库</span>
          <el-button type="primary" :icon="Plus" @click="handleCreate">新建案例</el-button>
        </div>
      </template>
      <el-table :data="cases" v-loading="loading" style="width: 100%">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="title" label="案例标题" width="200" />
        <el-table-column prop="difficulty" label="难度" width="100">
          <template #default="{ row }">
            <el-tag :type="getDifficultyType(row.difficulty)" size="small">
              {{ getDifficultyText(row.difficulty) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="grade_level" label="适用学段" width="120" />
        <el-table-column prop="ethics_topics" label="伦理议题" width="200">
          <template #default="{ row }">
            <el-tag
              v-for="topic in (row.ethics_topics || []).slice(0, 2)"
              :key="topic"
              size="small"
              style="margin-right: 4px;"
            >
              {{ topic }}
            </el-tag>
            <span v-if="!row.ethics_topics || row.ethics_topics.length === 0">-</span>
          </template>
        </el-table-column>
        <el-table-column prop="view_count" label="浏览" width="80" />
        <el-table-column prop="like_count" label="点赞" width="80" />
        <el-table-column prop="is_published" label="状态" width="80">
          <template #default="{ row }">
            <el-switch v-model="row.is_published" @change="handlePublishChange(row)" />
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
import { getEthicsCases, updateEthicsCase, deleteEthicsCase } from '@/api/ethics'

const loading = ref(false)
const cases = ref([])

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

const loadCases = async () => {
  loading.value = true
  try {
    const response = await getEthicsCases()
    console.log('伦理案例原始响应:', response)
    // 兼容不同的响应格式
    const data = response.data || response
    console.log('伦理案例数据:', data)
    cases.value = data.items || []
    if (cases.value.length === 0) {
      console.log('提示：数据库中暂无伦理案例数据')
    }
  } catch (error) {
    console.error('加载伦理案例失败:', error)
    ElMessage.error('加载数据失败: ' + (error.message || '未知错误'))
    cases.value = []
  } finally {
    loading.value = false
  }
}

const handleCreate = () => {
  ElMessage.info('新建案例功能开发中...')
}

const handleView = (row) => {
  ElMessage.info(`查看案例: ${row.title}`)
}

const handleEdit = (row) => {
  ElMessage.info('编辑功能开发中...')
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除此案例吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await deleteEthicsCase(row.uuid)
    ElMessage.success('删除成功')
    loadCases()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
      ElMessage.error('删除失败')
    }
  }
}

const handlePublishChange = async (row) => {
  try {
    await updateEthicsCase(row.uuid, { is_published: row.is_published })
    ElMessage.success('状态更新成功')
  } catch (error) {
    console.error('更新状态失败:', error)
    ElMessage.error('更新状态失败')
    row.is_published = !row.is_published
  }
}

onMounted(() => {
  loadCases()
})
</script>

<style scoped>
.admin-ethics-cases-page {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
