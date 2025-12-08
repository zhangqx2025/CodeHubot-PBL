<template>
  <div class="admin-outputs-page">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>成果管理</span>
          <div class="filter-area">
            <el-select v-model="filters.output_type" placeholder="成果类型" clearable style="width: 120px; margin-right: 10px" @change="loadOutputs">
              <el-option label="全部" value="" />
              <el-option label="报告" value="report" />
              <el-option label="代码" value="code" />
              <el-option label="设计" value="design" />
              <el-option label="视频" value="video" />
              <el-option label="演示" value="presentation" />
              <el-option label="模型" value="model" />
              <el-option label="数据集" value="dataset" />
              <el-option label="其他" value="other" />
            </el-select>
            <el-select v-model="filters.is_public" placeholder="公开状态" clearable style="width: 120px; margin-right: 10px" @change="loadOutputs">
              <el-option label="全部" :value="null" />
              <el-option label="已公开" :value="true" />
              <el-option label="未公开" :value="false" />
            </el-select>
            <el-input v-model="filters.search" placeholder="搜索标题/学生/项目" clearable style="width: 200px" @clear="loadOutputs" @keyup.enter="loadOutputs">
              <template #append>
                <el-button icon="Search" @click="loadOutputs" />
              </template>
            </el-input>
          </div>
        </div>
      </template>
      <el-table :data="outputs" v-loading="loading">
        <el-table-column prop="title" label="成果标题" min-width="200" show-overflow-tooltip />
        <el-table-column prop="output_type" label="成果类型" width="100">
          <template #default="{ row }">
            <el-tag>{{ getOutputTypeText(row.output_type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="student_name" label="提交人" width="120" />
        <el-table-column prop="project_title" label="所属项目" min-width="180" show-overflow-tooltip />
        <el-table-column prop="is_public" label="公开展示" width="100">
          <template #default="{ row }">
            <el-switch 
              :model-value="row.is_public"
              :active-value="true"
              :inactive-value="false"
              :loading="row.statusUpdating" 
              @update:model-value="(val) => handlePublicChange(row, val)" 
            />
          </template>
        </el-table-column>
        <el-table-column prop="view_count" label="浏览" width="80" />
        <el-table-column prop="like_count" label="点赞" width="80" />
        <el-table-column prop="created_at" label="提交时间" width="160">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="handleView(row)">查看</el-button>
            <el-button size="small" type="primary" @click="handleReview(row)">评审</el-button>
            <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      
      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.page_size"
          :page-sizes="[10, 20, 50, 100]"
          :total="pagination.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="loadOutputs"
          @current-change="loadOutputs"
        />
      </div>
    </el-card>

    <!-- 评审对话框 -->
    <el-dialog v-model="reviewDialog.visible" title="成果评审" width="600px">
      <el-form :model="reviewDialog.form" label-width="80px">
        <el-form-item label="成果标题">
          <div>{{ reviewDialog.output?.title }}</div>
        </el-form-item>
        <el-form-item label="提交人">
          <div>{{ reviewDialog.output?.student_name }}</div>
        </el-form-item>
        <el-form-item label="评分" required>
          <el-input-number v-model="reviewDialog.form.score" :min="0" :max="100" :precision="1" />
          <span style="margin-left: 10px; color: #999">分</span>
        </el-form-item>
        <el-form-item label="评审意见" required>
          <el-input v-model="reviewDialog.form.feedback" type="textarea" :rows="5" placeholder="请输入评审意见" />
        </el-form-item>
        <el-form-item label="审核结果" required>
          <el-radio-group v-model="reviewDialog.form.is_approved">
            <el-radio :label="true">通过</el-radio>
            <el-radio :label="false">不通过</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="reviewDialog.visible = false">取消</el-button>
        <el-button type="primary" @click="submitReview" :loading="reviewDialog.loading">提交评审</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getOutputs, updateOutputStatus, reviewOutput, deleteOutput } from '@/api/admin'

const loading = ref(false)
const outputs = ref([])

const filters = reactive({
  output_type: '',
  is_public: null,
  search: ''
})

const pagination = reactive({
  page: 1,
  page_size: 20,
  total: 0
})

const reviewDialog = reactive({
  visible: false,
  loading: false,
  output: null,
  form: {
    score: 0,
    feedback: '',
    is_approved: true
  }
})

const getOutputTypeText = (type) => {
  const texts = {
    report: '报告',
    code: '代码',
    design: '设计',
    video: '视频',
    presentation: '演示',
    model: '模型',
    dataset: '数据集',
    other: '其他'
  }
  return texts[type] || type
}

const formatDate = (dateStr) => {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const loadOutputs = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      page_size: pagination.page_size,
      ...filters
    }
    
    // 清空空值
    Object.keys(params).forEach(key => {
      if (params[key] === '' || params[key] === null) {
        delete params[key]
      }
    })
    
    const response = await getOutputs(params)
    // 为每条记录添加状态更新标志，并确保 is_public 是布尔类型
    outputs.value = (response.items || []).map(item => ({
      ...item,
      is_public: Boolean(item.is_public), // 确保转换为布尔类型
      statusUpdating: false
    }))
    pagination.total = response.total || 0
  } catch (error) {
    ElMessage.error('加载成果列表失败: ' + error.message)
  } finally {
    loading.value = false
  }
}

const handlePublicChange = async (row, newValue) => {
  // 如果正在更新或值没有变化，忽略请求
  if (row.statusUpdating || row.is_public === newValue) {
    return
  }
  
  // 保存原始状态，用于失败时恢复
  const originalStatus = row.is_public
  
  // 先更新UI显示
  row.is_public = newValue
  
  // 设置加载状态
  row.statusUpdating = true
  
  try {
    await updateOutputStatus(row.uuid, newValue)
    ElMessage.success(`已${newValue ? '公开' : '取消公开'}该成果`)
  } catch (error) {
    ElMessage.error('状态更新失败: ' + error.message)
    // 恢复原状态
    row.is_public = originalStatus
  } finally {
    // 延迟移除加载状态，避免过快的重复点击
    setTimeout(() => {
      row.statusUpdating = false
    }, 300)
  }
}

const handleView = (row) => {
  // TODO: 实现查看详情功能
  ElMessage.info(`查看成果: ${row.title}`)
}

const handleReview = (row) => {
  reviewDialog.output = row
  reviewDialog.form = {
    score: 0,
    feedback: '',
    is_approved: true
  }
  reviewDialog.visible = true
}

const submitReview = async () => {
  if (!reviewDialog.form.feedback) {
    ElMessage.warning('请输入评审意见')
    return
  }
  
  reviewDialog.loading = true
  try {
    await reviewOutput(reviewDialog.output.uuid, reviewDialog.form)
    ElMessage.success('评审提交成功')
    reviewDialog.visible = false
    loadOutputs()
  } catch (error) {
    ElMessage.error('评审提交失败: ' + error.message)
  } finally {
    reviewDialog.loading = false
  }
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除成果"${row.title}"吗？此操作不可恢复。`,
      '删除确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    loading.value = true
    await deleteOutput(row.uuid)
    ElMessage.success('删除成功')
    loadOutputs()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败: ' + error.message)
    }
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadOutputs()
})
</script>

<style scoped>
.admin-outputs-page {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.filter-area {
  display: flex;
  align-items: center;
}

.pagination {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}
</style>
