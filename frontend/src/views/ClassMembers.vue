<template>
  <div class="class-members-container">
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
          <h1 class="page-title">成员管理</h1>
          <p class="page-subtitle">{{ className }}</p>
        </div>
        <div class="header-right">
          <el-button type="primary" size="large" @click="showAddMemberDialog">
            <el-icon><Plus /></el-icon>
            添加成员
          </el-button>
        </div>
      </div>
    </el-card>

    <!-- 搜索和统计 -->
    <el-card shadow="never" class="filter-card">
      <div class="filter-content">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索成员（姓名、学号、登录名）"
          style="width: 400px"
          size="large"
          clearable
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        
        <el-statistic title="成员总数" :value="members.length" />
      </div>
    </el-card>

    <!-- 成员列表 -->
    <el-card shadow="never" class="table-card">
      <el-table 
        :data="filteredMembers" 
        v-loading="loading" 
        stripe
        style="width: 100%"
      >
        <el-table-column prop="name" label="姓名" width="150" />
        <el-table-column prop="student_number" label="学号" width="150" />
        <el-table-column prop="login_name" label="登录名" width="220">
          <template #default="{ row }">
            {{ row.login_name || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="gender" label="性别" width="100">
          <template #default="{ row }">
            {{ getGenderName(row.gender) }}
          </template>
        </el-table-column>
        <el-table-column prop="joined_at" label="加入时间" width="200">
          <template #default="{ row }">
            {{ formatDateTime(row.joined_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="250" fixed="right">
          <template #default="{ row }">
            <el-button 
              link 
              type="warning" 
              @click="handleResetPassword(row)"
            >
              <el-icon><Lock /></el-icon>
              重置密码
            </el-button>
            <el-button 
              link 
              type="danger" 
              @click="handleRemoveMember(row)"
            >
              <el-icon><Delete /></el-icon>
              移除成员
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-empty 
        v-if="!loading && members.length === 0" 
        description="暂无成员"
        style="padding: 60px 0"
      >
        <el-button type="primary" @click="showAddMemberDialog">添加第一个成员</el-button>
      </el-empty>
    </el-card>

    <!-- 添加成员对话框 -->
    <el-dialog 
      v-model="addMemberDialogVisible" 
      title="添加成员" 
      width="600px"
      :close-on-click-modal="false"
      @open="handleDialogOpen"
    >
      <el-form label-width="100px">
        <el-form-item label="搜索学生">
          <el-input
            v-model="studentSearchKeyword"
            placeholder="输入姓名或学号搜索"
            clearable
            @input="searchAvailableStudents"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </el-form-item>
        <el-form-item label="选择学生" required>
          <el-select
            v-model="selectedStudentIds"
            multiple
            filterable
            placeholder="请选择要添加的学生"
            style="width: 100%"
            :loading="loadingStudents"
            :multiple-limit="20"
          >
            <el-option
              v-for="student in availableStudents"
              :key="student.id"
              :label="`${student.name} (${student.student_number})`"
              :value="student.id"
            >
              <div style="display: flex; justify-content: space-between; align-items: center">
                <span>{{ student.name }}</span>
                <span style="color: #8492a6; font-size: 13px">{{ student.student_number }}</span>
              </div>
            </el-option>
          </el-select>
          <div class="form-tip">
            提示：从学校学生库中选择未在该班级的学生，添加后将自动为其选上班级的所有课程
          </div>
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="addMemberDialogVisible = false" size="large">取消</el-button>
        <el-button type="primary" @click="submitAddMembers" :loading="addingMembers" size="large">
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
  ArrowLeft, Plus, Search, Delete, Lock
} from '@element-plus/icons-vue'
import {
  getClubClassMembers, addMembersToClubClass, removeMemberFromClubClass, getClubClassDetail,
  getAvailableStudentsForClass, resetMemberPassword
} from '@/api/club'
import dayjs from 'dayjs'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const members = ref([])
const searchKeyword = ref('')
const className = ref('')
const addMemberDialogVisible = ref(false)
const addingMembers = ref(false)

// 可添加的学生列表
const availableStudents = ref([])
const selectedStudentIds = ref([])
const studentSearchKeyword = ref('')
const loadingStudents = ref(false)

// 计算属性
const filteredMembers = computed(() => {
  if (!searchKeyword.value) return members.value
  const keyword = searchKeyword.value.toLowerCase()
  return members.value.filter(m => 
    m.name.toLowerCase().includes(keyword) || 
    m.student_number.includes(keyword) ||
    (m.login_name && m.login_name.toLowerCase().includes(keyword))
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

// 加载成员列表
const loadMembers = async () => {
  loading.value = true
  try {
    const res = await getClubClassMembers(route.params.uuid)
    members.value = res.data.data || []
  } catch (error) {
    ElMessage.error(error.message || '加载成员列表失败')
  } finally {
    loading.value = false
  }
}

// 加载可添加的学生列表
const loadAvailableStudents = async (search = '') => {
  loadingStudents.value = true
  try {
    const res = await getAvailableStudentsForClass(route.params.uuid, {
      search: search || undefined
    })
    availableStudents.value = res.data.data || []
  } catch (error) {
    console.error('加载学生列表失败:', error)
    ElMessage.error('加载学生列表失败')
  } finally {
    loadingStudents.value = false
  }
}

// 搜索可添加的学生
let searchTimer = null
const searchAvailableStudents = () => {
  if (searchTimer) clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    loadAvailableStudents(studentSearchKeyword.value)
  }, 300)
}

// 对话框打开时加载学生列表
const handleDialogOpen = () => {
  selectedStudentIds.value = []
  studentSearchKeyword.value = ''
  loadAvailableStudents()
}

// 显示添加成员对话框
const showAddMemberDialog = () => {
  addMemberDialogVisible.value = true
}

// 提交添加成员
const submitAddMembers = async () => {
  if (selectedStudentIds.value.length === 0) {
    ElMessage.warning('请选择要添加的学生')
    return
  }
  
  addingMembers.value = true
  try {
    const res = await addMembersToClubClass(route.params.uuid, {
      student_ids: selectedStudentIds.value,
      role: 'member'
    })
    ElMessage.success(`成功添加 ${res.data.added_count} 名成员`)
    addMemberDialogVisible.value = false
    loadMembers()
  } catch (error) {
    ElMessage.error(error.message || '添加成员失败')
  } finally {
    addingMembers.value = false
  }
}

// 处理移除成员
const handleRemoveMember = async (member) => {
  try {
    await ElMessageBox.confirm(
      `确定要移除成员"${member.name}"吗？`,
      '确认移除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await removeMemberFromClubClass(route.params.uuid, member.student_id)
    ElMessage.success('成员已移除')
    loadMembers()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '移除失败')
    }
  }
}

// 处理重置密码
const handleResetPassword = async (member) => {
  try {
    await ElMessageBox.confirm(
      `确定要重置成员"${member.name}"的密码吗？密码将被重置为默认密码 Aa123456，该学生下次登录后需强制修改密码。`,
      '确认重置密码',
      {
        confirmButtonText: '确定重置',
        cancelButtonText: '取消',
        type: 'warning',
        dangerouslyUseHTMLString: true
      }
    )
    
    const res = await resetMemberPassword(route.params.uuid, member.student_id)
    
    // 显示成功消息，包含默认密码
    await ElMessageBox.alert(
      `<p>密码重置成功！</p>
       <p style="margin-top: 12px;">学生姓名：<strong>${member.name}</strong></p>
       <p>学号：<strong>${member.student_number}</strong></p>
       <p>新密码：<strong style="color: #409eff; font-size: 16px;">Aa123456</strong></p>
       <p style="margin-top: 12px; color: #f56c6c;">请及时将新密码告知学生，学生下次登录后需强制修改密码。</p>`,
      '密码重置成功',
      {
        confirmButtonText: '我知道了',
        dangerouslyUseHTMLString: true,
        type: 'success'
      }
    )
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '重置密码失败')
    }
  }
}

// 工具方法
const getGenderName = (gender) => {
  const map = {
    male: '男',
    female: '女'
  }
  return map[gender] || gender
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
  loadMembers()
})
</script>

<style scoped lang="scss">
.class-members-container {
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
