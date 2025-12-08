<template>
  <div class="admin-portfolios-page">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>学生成长档案</span>
          <el-button type="primary" :icon="Download" @click="handleExport">批量导出</el-button>
        </div>
      </template>
      <el-table :data="portfolios" v-loading="loading">
        <el-table-column prop="student_name" label="学生姓名" width="120" />
        <el-table-column prop="grade_level" label="学段" width="100" />
        <el-table-column prop="school_year" label="学年" width="120" />
        <el-table-column prop="projects_count" label="完成项目" width="100" />
        <el-table-column prop="total_learning_hours" label="学习时长(h)" width="120" />
        <el-table-column prop="avg_score" label="平均分" width="100" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="handleView(row)">查看档案</el-button>
            <el-button size="small" type="primary" @click="handleEdit(row)">编辑评语</el-button>
          </template>
        </el-table-column>
      </el-table>
      
      <!-- 分页 -->
      <div class="pagination-container">
        <el-pagination
          v-model:current-page="currentPage"
          :page-size="pageSize"
          :total="total"
          layout="total, prev, pager, next"
          @current-change="handlePageChange"
        />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Download } from '@element-plus/icons-vue'
import { getAdminPortfolios } from '@/api/portfolio'

const loading = ref(false)
const portfolios = ref([])
const total = ref(0)
const currentPage = ref(1)
const pageSize = ref(20)

// 加载数据
const loadPortfolios = async () => {
  loading.value = true
  try {
    const params = {
      skip: (currentPage.value - 1) * pageSize.value,
      limit: pageSize.value
    }
    const response = await getAdminPortfolios(params)
    if (response && response.data) {
      portfolios.value = response.data.items || []
      total.value = response.data.total || 0
    }
  } catch (error) {
    console.error('加载成长档案失败:', error)
    ElMessage.error('加载成长档案失败')
  } finally {
    loading.value = false
  }
}

const handleExport = () => {
  ElMessage.info('导出功能开发中...')
}

const handleView = (row) => {
  ElMessage.info(`查看档案: ${row.student_name}`)
}

const handleEdit = (row) => {
  ElMessage.info('编辑评语功能开发中...')
}

const handlePageChange = (page) => {
  currentPage.value = page
  loadPortfolios()
}

onMounted(() => {
  loadPortfolios()
})
</script>

<style scoped>
.admin-portfolios-page {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.pagination-container {
  margin-top: 20px;
  display: flex;
  justify-content: center;
}
</style>
