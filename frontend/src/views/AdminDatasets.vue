<template>
  <div class="admin-datasets-page">
    <el-card class="filter-card" shadow="never">
      <el-form :model="searchForm" inline>
        <el-form-item label="数据类型">
          <el-select v-model="searchForm.data_type" placeholder="请选择" clearable>
            <el-option label="图像" value="image" />
            <el-option label="文本" value="text" />
            <el-option label="音频" value="audio" />
            <el-option label="视频" value="video" />
            <el-option label="表格" value="tabular" />
            <el-option label="混合" value="mixed" />
          </el-select>
        </el-form-item>
        <el-form-item label="分类">
          <el-input v-model="searchForm.category" placeholder="如：垃圾分类" clearable />
        </el-form-item>
        <el-form-item label="学段">
          <el-select v-model="searchForm.grade_level" placeholder="请选择" clearable>
            <el-option label="1-2年级" value="1-2年级" />
            <el-option label="3-4年级" value="3-4年级" />
            <el-option label="5-6年级" value="5-6年级" />
            <el-option label="7-9年级" value="7-9年级" />
            <el-option label="10-12年级" value="10-12年级" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :icon="Search" @click="handleSearch">查询</el-button>
          <el-button :icon="Refresh" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>数据集管理</span>
          <el-button type="primary" :icon="Plus" @click="handleCreate">上传数据集</el-button>
        </div>
      </template>

      <el-table :data="datasets" style="width: 100%" v-loading="loading">
        <el-table-column prop="name" label="数据集名称" width="200" />
        <el-table-column prop="data_type" label="数据类型" width="100">
          <template #default="{ row }">
            <el-tag :type="getDataTypeColor(row.data_type)" size="small">
              {{ getDataTypeText(row.data_type) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="category" label="分类" width="120" />
        <el-table-column prop="sample_count" label="样本数" width="100">
          <template #default="{ row }">
            {{ row.sample_count ? row.sample_count.toLocaleString() : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="class_count" label="类别数" width="100" />
        <el-table-column prop="file_size" label="文件大小" width="120">
          <template #default="{ row }">
            {{ formatFileSize(row.file_size) }}
          </template>
        </el-table-column>
        <el-table-column prop="is_labeled" label="已标注" width="80">
          <template #default="{ row }">
            <el-tag :type="row.is_labeled ? 'success' : 'info'" size="small">
              {{ row.is_labeled ? '是' : '否' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="quality_score" label="质量评分" width="100">
          <template #default="{ row }">
            <el-rate v-model="row.quality_score" disabled show-score />
          </template>
        </el-table-column>
        <el-table-column prop="download_count" label="下载次数" width="100" />
        <el-table-column prop="is_public" label="公开" width="80">
          <template #default="{ row }">
            <el-switch v-model="row.is_public" @change="handlePublicChange(row)" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="250" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="handleView(row)">查看</el-button>
            <el-button size="small" type="success" @click="handleDownload(row)">下载</el-button>
            <el-button size="small" type="primary" @click="handleEdit(row)">编辑</el-button>
            <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.size"
        :total="pagination.total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSearch"
        @current-change="handleSearch"
        class="pagination"
      />
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Refresh, Plus } from '@element-plus/icons-vue'
import { getDatasets, deleteDataset, updateDatasetPublicStatus, downloadDataset } from '@/api/dataset'

const loading = ref(false)

const searchForm = reactive({
  data_type: '',
  category: '',
  grade_level: ''
})

const pagination = reactive({
  page: 1,
  size: 10,
  total: 0
})

const datasets = ref([])

const getDataTypeColor = (type) => {
  const colors = {
    image: 'primary',
    text: 'success',
    audio: 'warning',
    video: 'danger',
    tabular: 'info',
    mixed: ''
  }
  return colors[type] || 'info'
}

const getDataTypeText = (type) => {
  const texts = {
    image: '图像',
    text: '文本',
    audio: '音频',
    video: '视频',
    tabular: '表格',
    mixed: '混合'
  }
  return texts[type] || type
}

const formatFileSize = (bytes) => {
  if (!bytes) return '-'
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB'
  if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(2) + ' MB'
  return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB'
}

const handleSearch = () => {
  loadDatasets()
}

const handleReset = () => {
  Object.keys(searchForm).forEach(key => {
    searchForm[key] = ''
  })
  handleSearch()
}

const handleCreate = () => {
  ElMessage.info('上传数据集功能开发中...')
}

const handleView = (row) => {
  ElMessage.info(`查看数据集: ${row.name}`)
}

const handleDownload = async (row) => {
  try {
    loading.value = true
    const response = await downloadDataset(row.uuid)
    // 创建下载链接
    const url = window.URL.createObjectURL(new Blob([response.data]))
    const link = document.createElement('a')
    link.href = url
    link.setAttribute('download', `${row.name}.zip`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    ElMessage.success('下载成功')
  } catch (error) {
    console.error('下载失败:', error)
    ElMessage.error('下载失败')
  } finally {
    loading.value = false
  }
}

const handleEdit = (row) => {
  ElMessage.info('编辑功能开发中...')
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除这个数据集吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await deleteDataset(row.uuid)
    ElMessage.success('删除成功')
    handleSearch()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
      ElMessage.error(error.response?.data?.detail || '删除失败')
    }
  }
}

const handlePublicChange = async (row) => {
  try {
    await updateDatasetPublicStatus(row.uuid, row.is_public)
    ElMessage.success('状态更新成功')
  } catch (error) {
    console.error('状态更新失败:', error)
    row.is_public = !row.is_public
    ElMessage.error(error.response?.data?.detail || '状态更新失败')
  }
}

const loadDatasets = async () => {
  loading.value = true
  try {
    const response = await getDatasets({
      skip: (pagination.page - 1) * pagination.size,
      limit: pagination.size,
      data_type: searchForm.data_type || undefined,
      category: searchForm.category || undefined,
      grade_level: searchForm.grade_level || undefined
    })
    
    if (response && response.data) {
      datasets.value = response.data.items || []
      pagination.total = response.data.total || 0
    }
  } catch (error) {
    console.error('加载数据集失败:', error)
    ElMessage.error(error.response?.data?.detail || '加载数据失败')
    datasets.value = []
    pagination.total = 0
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadDatasets()
})
</script>

<style scoped>
.admin-datasets-page {
  padding: 0;
}

.filter-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.pagination {
  margin-top: 20px;
  justify-content: flex-end;
}
</style>
