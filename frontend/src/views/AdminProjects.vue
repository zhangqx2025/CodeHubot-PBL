<template>
  <div class="admin-projects-page">
    <el-card class="filter-card" shadow="never">
      <el-form :model="searchForm" inline>
        <el-form-item label="课程">
          <el-select v-model="searchForm.course_id" placeholder="请选择" clearable filterable>
            <el-option
              v-for="course in courses"
              :key="course.id"
              :label="course.title"
              :value="course.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="searchForm.status" placeholder="请选择" clearable>
            <el-option label="规划中" value="planning" />
            <el-option label="进行中" value="in-progress" />
            <el-option label="评审中" value="review" />
            <el-option label="已完成" value="completed" />
          </el-select>
        </el-form-item>
        <el-form-item label="小组">
          <el-select v-model="searchForm.group_id" placeholder="请选择" clearable filterable>
            <el-option
              v-for="group in groups"
              :key="group.id"
              :label="group.name"
              :value="group.id"
            />
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
          <span>项目列表</span>
          <div>
            <el-button type="primary" :icon="Plus" @click="handleCreate">创建项目</el-button>
            <el-button :icon="Download" @click="handleExport">导出数据</el-button>
          </div>
        </div>
      </template>

      <el-table :data="projects" style="width: 100%" v-loading="loading">
        <el-table-column type="expand">
          <template #default="{ row }">
            <div class="expand-content">
              <el-descriptions :column="2" border>
                <el-descriptions-item label="项目描述" :span="2">
                  {{ row.description }}
                </el-descriptions-item>
                <el-descriptions-item label="代码仓库">
                  <a v-if="row.repo_url" :href="row.repo_url" target="_blank">{{ row.repo_url }}</a>
                  <span v-else>-</span>
                </el-descriptions-item>
                <el-descriptions-item label="创建时间">
                  {{ row.created_at }}
                </el-descriptions-item>
                <el-descriptions-item label="更新时间" :span="2">
                  {{ row.updated_at }}
                </el-descriptions-item>
              </el-descriptions>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="title" label="项目名称" width="200" />
        <el-table-column prop="course_title" label="所属课程" width="180" />
        <el-table-column prop="group_name" label="项目小组" width="150" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)" size="small">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="progress" label="进度" width="150">
          <template #default="{ row }">
            <el-progress :percentage="row.progress" :status="getProgressStatus(row.progress)" />
          </template>
        </el-table-column>
        <el-table-column label="成员" width="200">
          <template #default="{ row }">
            <el-avatar-group :max="3" size="small">
              <el-avatar v-for="member in row.members" :key="member.id">
                {{ member.name.charAt(0) }}
              </el-avatar>
            </el-avatar-group>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="250" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="handleView(row)">查看</el-button>
            <el-button size="small" type="primary" @click="handleEdit(row)">编辑</el-button>
            <el-button size="small" type="warning" @click="handleMonitor(row)">监控</el-button>
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
import { Search, Refresh, Plus, Download } from '@element-plus/icons-vue'
import { getProjects, deleteProject } from '@/api/project'
import { getCourses } from '@/api/admin'
import { getGroupList } from '@/api/classes'

const loading = ref(false)

const searchForm = reactive({
  course_id: '',
  status: '',
  group_id: ''
})

const pagination = reactive({
  page: 1,
  size: 10,
  total: 0
})

const projects = ref([])
const courses = ref([])
const groups = ref([])

const getStatusType = (status) => {
  const types = {
    planning: 'info',
    'in-progress': 'primary',
    review: 'warning',
    completed: 'success'
  }
  return types[status] || 'info'
}

const getStatusText = (status) => {
  const texts = {
    planning: '规划中',
    'in-progress': '进行中',
    review: '评审中',
    completed: '已完成'
  }
  return texts[status] || status
}

const getProgressStatus = (progress) => {
  if (progress === 100) return 'success'
  if (progress >= 80) return ''
  if (progress >= 50) return ''
  return 'exception'
}

const handleSearch = () => {
  loadProjects()
}

const handleReset = () => {
  Object.keys(searchForm).forEach(key => {
    searchForm[key] = ''
  })
  handleSearch()
}

const handleCreate = () => {
  ElMessage.info('创建项目功能开发中...')
}

const handleView = (row) => {
  ElMessage.info(`查看项目: ${row.title}`)
}

const handleEdit = (row) => {
  ElMessage.info('编辑功能开发中...')
}

const handleMonitor = (row) => {
  ElMessage.info(`监控项目: ${row.title}`)
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除这个项目吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await deleteProject(row.uuid)
    ElMessage.success('删除成功')
    handleSearch()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
      ElMessage.error(error.response?.data?.detail || '删除失败')
    }
  }
}

const handleExport = () => {
  ElMessage.info('导出功能开发中...')
}

const loadProjects = async () => {
  loading.value = true
  try {
    const response = await getProjects({
      skip: (pagination.page - 1) * pagination.size,
      limit: pagination.size,
      course_id: searchForm.course_id || undefined,
      status: searchForm.status || undefined,
      group_id: searchForm.group_id || undefined
    })
    
    if (response && response.data) {
      projects.value = response.data.items || []
      pagination.total = response.data.total || 0
    }
  } catch (error) {
    console.error('加载项目列表失败:', error)
    ElMessage.error(error.response?.data?.detail || '加载数据失败')
    projects.value = []
    pagination.total = 0
  } finally {
    loading.value = false
  }
}

const loadCourses = async () => {
  try {
    const response = await getCourses()
    if (response && response.data) {
      courses.value = response.data.items || response.data || []
    }
  } catch (error) {
    console.error('加载课程列表失败:', error)
    courses.value = []
  }
}

const loadGroups = async () => {
  try {
    const response = await getGroupList()
    if (response) {
      groups.value = response.items || response || []
    }
  } catch (error) {
    console.error('加载小组列表失败:', error)
    groups.value = []
  }
}

onMounted(() => {
  loadProjects()
  loadCourses()
  loadGroups()
})
</script>

<style scoped>
.admin-projects-page {
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

.expand-content {
  padding: 20px;
  background: #f5f7fa;
}

.pagination {
  margin-top: 20px;
  justify-content: flex-end;
}
</style>
