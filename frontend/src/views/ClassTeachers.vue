<template>
  <div class="class-teachers-container">
    <!-- 返回按钮 -->
    <div class="page-header">
      <el-button @click="goBack" text>
        <el-icon><ArrowLeft /></el-icon>
        返回班级详情
      </el-button>
    </div>

    <!-- 页面标题和操作 -->
    <el-card shadow="never" class="header-card">
      <div class="header-content">
        <div class="header-left">
          <h1 class="page-title">教师管理</h1>
          <p class="page-subtitle">{{ className }}</p>
        </div>
        <div class="header-right">
          <el-button type="primary" size="large" @click="showAddTeacherDialog">
            <el-icon><Plus /></el-icon>
            添加教师
          </el-button>
        </div>
      </div>
    </el-card>

    <!-- 搜索和统计 -->
    <el-card shadow="never" class="filter-card">
      <div class="filter-content">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索教师（姓名）"
          style="width: 400px"
          size="large"
          clearable
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        
        <el-statistic title="教师总数" :value="teachers.length" />
      </div>
    </el-card>

    <!-- 教师列表 -->
    <el-card shadow="never" class="table-card">
      <el-table 
        :data="filteredTeachers" 
        v-loading="loading" 
        stripe
        style="width: 100%"
      >
        <el-table-column prop="name" label="姓名" width="150" />
        <el-table-column prop="username" label="用户名" width="180" />
        <el-table-column prop="role" label="角色" width="150">
          <template #default="{ row }">
            <el-tag :type="getRoleTagType(row.role)" size="default">
              {{ getRoleName(row.role) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="added_at" label="添加时间" width="200">
          <template #default="{ row }">
            {{ formatDateTime(row.added_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" fixed="right">
          <template #default="{ row }">
            <el-dropdown @command="(cmd) => handleTeacherAction(cmd, row)">
              <el-button link type="primary">
                操作
                <el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </el-button>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="main" v-if="row.role !== 'main'">
                    <el-icon><User /></el-icon>
                    设为主讲教师
                  </el-dropdown-item>
                  <el-dropdown-item command="assistant" v-if="row.role !== 'assistant'">
                    <el-icon><User /></el-icon>
                    设为助教
                  </el-dropdown-item>
                  <el-dropdown-item command="remove" divided>
                    <el-icon><Delete /></el-icon>
                    移除教师
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </template>
        </el-table-column>
      </el-table>

      <el-empty 
        v-if="!loading && teachers.length === 0" 
        description="暂无教师"
        style="padding: 60px 0"
      >
        <el-button type="primary" @click="showAddTeacherDialog">添加第一个教师</el-button>
      </el-empty>
    </el-card>

    <!-- 添加教师对话框 -->
    <el-dialog 
      v-model="addTeacherDialogVisible" 
      title="添加教师" 
      width="500px"
      :close-on-click-modal="false"
    >
      <el-form :model="teacherForm" label-width="100px">
        <el-form-item label="教师ID" required>
          <el-input
            v-model="teacherIdsText"
            type="textarea"
            :rows="6"
            placeholder="请输入教师ID，每行一个"
          />
          <div class="form-tip">
            提示：每行输入一个教师ID
          </div>
        </el-form-item>
        
        <el-form-item label="角色" required>
          <el-radio-group v-model="teacherForm.role">
            <el-radio value="main">主讲教师</el-radio>
            <el-radio value="assistant">助教</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="addTeacherDialogVisible = false" size="large">取消</el-button>
        <el-button type="primary" @click="submitAddTeachers" :loading="addingTeachers" size="large">
          添加
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  ArrowLeft, Plus, Search, ArrowDown, User, Delete
} from '@element-plus/icons-vue'
import { getClubClassDetail } from '@/api/club'
import dayjs from 'dayjs'
import request from '@/api/request'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const teachers = ref([])
const searchKeyword = ref('')
const className = ref('')
const addTeacherDialogVisible = ref(false)
const teacherIdsText = ref('')
const addingTeachers = ref(false)
const teacherForm = ref({
  role: 'assistant'
})

// 计算属性
const filteredTeachers = computed(() => {
  if (!searchKeyword.value) return teachers.value
  const keyword = searchKeyword.value.toLowerCase()
  return teachers.value.filter(t => 
    t.name.toLowerCase().includes(keyword) || 
    (t.username && t.username.toLowerCase().includes(keyword))
  )
})

// 加载班级名称
const loadClassName = async () => {
  try {
    const res = await getClubClassDetail(route.params.uuid)
    className.value = res.data.data.name
  } catch (error) {
    console.error('加载班级名称失败:', error)
  }
}

// 加载教师列表
const loadTeachers = async () => {
  loading.value = true
  try {
    const res = await request({
      url: `/admin/club/classes/${route.params.uuid}/teachers`,
      method: 'get'
    })
    teachers.value = res.data.data || []
  } catch (error) {
    ElMessage.error(error.message || '加载教师列表失败')
  } finally {
    loading.value = false
  }
}

// 显示添加教师对话框
const showAddTeacherDialog = () => {
  teacherIdsText.value = ''
  teacherForm.value.role = 'assistant'
  addTeacherDialogVisible.value = true
}

// 提交添加教师
const submitAddTeachers = async () => {
  const ids = teacherIdsText.value
    .split('\n')
    .map(id => parseInt(id.trim()))
    .filter(id => !isNaN(id))
  
  if (ids.length === 0) {
    ElMessage.warning('请输入有效的教师ID')
    return
  }
  
  addingTeachers.value = true
  try {
    await request({
      url: `/admin/club/classes/${route.params.uuid}/teachers`,
      method: 'post',
      data: {
        teacher_ids: ids,
        role: teacherForm.value.role
      }
    })
    ElMessage.success(`成功添加 ${ids.length} 位教师`)
    addTeacherDialogVisible.value = false
    loadTeachers()
  } catch (error) {
    ElMessage.error(error.message || '添加教师失败')
  } finally {
    addingTeachers.value = false
  }
}

// 处理教师操作
const handleTeacherAction = async (command, teacher) => {
  if (command === 'remove') {
    try {
      await ElMessageBox.confirm(
        `确定要移除教师"${teacher.name}"吗？`,
        '确认移除',
        {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        }
      )
      
      await request({
        url: `/admin/club/classes/${route.params.uuid}/teachers/${teacher.teacher_id}`,
        method: 'delete'
      })
      ElMessage.success('教师已移除')
      loadTeachers()
    } catch (error) {
      if (error !== 'cancel') {
        ElMessage.error(error.message || '移除失败')
      }
    }
  } else {
    // 更新角色
    try {
      await request({
        url: `/admin/club/classes/${route.params.uuid}/teachers/${teacher.teacher_id}/role`,
        method: 'put',
        data: { role: command }
      })
      ElMessage.success('角色已更新')
      loadTeachers()
    } catch (error) {
      ElMessage.error(error.message || '更新失败')
    }
  }
}

// 工具方法
const getRoleName = (role) => {
  const map = {
    main: '主讲教师',
    assistant: '助教'
  }
  return map[role] || role
}

const getRoleTagType = (role) => {
  const map = {
    main: 'danger',
    assistant: 'warning'
  }
  return map[role] || 'info'
}

const formatDateTime = (dateStr) => {
  if (!dateStr) return '-'
  return dayjs(dateStr).format('YYYY-MM-DD HH:mm')
}

const goBack = () => {
  router.push(`/admin/classes/${route.params.uuid}`)
}

onMounted(() => {
  loadClassName()
  loadTeachers()
})
</script>

<style scoped lang="scss">
.class-teachers-container {
  padding: 24px;
  background: #f5f7fa;
  min-height: calc(100vh - 60px);
}

.page-header {
  margin-bottom: 24px;
}

.header-card {
  margin-bottom: 24px;
  border-radius: 12px;
  
  .header-content {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    
    .header-left {
      .page-title {
        margin: 0 0 8px 0;
        font-size: 24px;
        font-weight: 600;
        color: #303133;
      }
      
      .page-subtitle {
        margin: 0;
        font-size: 14px;
        color: #909399;
      }
    }
  }
}

.filter-card {
  margin-bottom: 24px;
  border-radius: 12px;
  
  .filter-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
    
    :deep(.el-statistic) {
      .el-statistic__head {
        font-size: 14px;
        color: #909399;
      }
      
      .el-statistic__content {
        font-size: 28px;
        font-weight: 600;
        color: #409eff;
      }
    }
  }
}

.table-card {
  border-radius: 12px;
}

.form-tip {
  margin-top: 8px;
  font-size: 12px;
  color: #909399;
  line-height: 1.5;
}

:deep(.el-dropdown-menu__item) {
  display: flex;
  align-items: center;
  gap: 8px;
}
</style>
