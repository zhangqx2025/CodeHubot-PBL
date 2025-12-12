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
          placeholder="搜索成员（姓名、学号）"
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
        <el-table-column prop="student_number" label="学号" width="180" />
        <el-table-column prop="gender" label="性别" width="100" />
        <el-table-column prop="role" label="角色" width="150">
          <template #default="{ row }">
            <el-tag :type="getRoleTagType(row.role)" size="default">
              {{ getRoleName(row.role) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="joined_at" label="加入时间" width="200">
          <template #default="{ row }">
            {{ formatDateTime(row.joined_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" fixed="right">
          <template #default="{ row }">
            <el-dropdown @command="(cmd) => handleMemberAction(cmd, row)">
              <el-button link type="primary">
                操作
                <el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </el-button>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="leader" v-if="row.role !== 'leader'">
                    <el-icon><User /></el-icon>
                    设为班长
                  </el-dropdown-item>
                  <el-dropdown-item command="deputy" v-if="row.role !== 'deputy'">
                    <el-icon><User /></el-icon>
                    设为副班长
                  </el-dropdown-item>
                  <el-dropdown-item command="member" v-if="row.role !== 'member'">
                    <el-icon><User /></el-icon>
                    设为普通成员
                  </el-dropdown-item>
                  <el-dropdown-item command="remove" divided>
                    <el-icon><Delete /></el-icon>
                    移除成员
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
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
      width="500px"
      :close-on-click-modal="false"
    >
      <el-form label-width="100px">
        <el-form-item label="学生ID" required>
          <el-input
            v-model="memberIdsText"
            type="textarea"
            :rows="10"
            placeholder="请输入学生ID，每行一个"
          />
          <div class="form-tip">
            提示：每行输入一个学生ID，添加后将自动为其选上班级的所有课程
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
  ArrowLeft, Plus, Search, ArrowDown, User, Delete
} from '@element-plus/icons-vue'
import {
  getClubClassMembers, addMembersToClubClass, removeMemberFromClubClass,
  updateMemberRole, getClubClassDetail
} from '@/api/club'
import dayjs from 'dayjs'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const members = ref([])
const searchKeyword = ref('')
const className = ref('')
const addMemberDialogVisible = ref(false)
const memberIdsText = ref('')
const addingMembers = ref(false)

// 计算属性
const filteredMembers = computed(() => {
  if (!searchKeyword.value) return members.value
  const keyword = searchKeyword.value.toLowerCase()
  return members.value.filter(m => 
    m.name.toLowerCase().includes(keyword) || 
    m.student_number.includes(keyword)
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

// 显示添加成员对话框
const showAddMemberDialog = () => {
  memberIdsText.value = ''
  addMemberDialogVisible.value = true
}

// 提交添加成员
const submitAddMembers = async () => {
  const ids = memberIdsText.value
    .split('\n')
    .map(id => parseInt(id.trim()))
    .filter(id => !isNaN(id))
  
  if (ids.length === 0) {
    ElMessage.warning('请输入有效的学生ID')
    return
  }
  
  addingMembers.value = true
  try {
    const res = await addMembersToClubClass(route.params.uuid, {
      student_ids: ids,
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

// 处理成员操作
const handleMemberAction = async (command, member) => {
  if (command === 'remove') {
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
  } else {
    // 更新角色
    try {
      await updateMemberRole(route.params.uuid, member.student_id, { role: command })
      ElMessage.success('角色已更新')
      loadMembers()
    } catch (error) {
      ElMessage.error(error.message || '更新失败')
    }
  }
}

// 工具方法
const getRoleName = (role) => {
  const map = {
    member: '成员',
    leader: '班长',
    deputy: '副班长'
  }
  return map[role] || role
}

const getRoleTagType = (role) => {
  const map = {
    member: 'info',
    leader: 'danger',
    deputy: 'warning'
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
