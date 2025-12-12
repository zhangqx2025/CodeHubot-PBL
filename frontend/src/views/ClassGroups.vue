<template>
  <div class="class-groups-container">
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
          <h1 class="page-title">小组管理</h1>
          <p class="page-subtitle">{{ className }}</p>
        </div>
        <div class="header-right">
          <el-button type="primary" size="large" @click="showCreateGroupDialog">
            <el-icon><Plus /></el-icon>
            创建小组
          </el-button>
        </div>
      </div>
    </el-card>

    <!-- 统计 -->
    <el-card shadow="never" class="stats-card">
      <el-statistic title="小组总数" :value="groups.length" />
    </el-card>

    <!-- 小组列表 -->
    <el-card shadow="never" class="table-card">
      <el-table 
        :data="groups" 
        v-loading="loading" 
        stripe
        border
        style="width: 100%"
      >
        <el-table-column prop="name" label="小组名称" min-width="200" />
        <el-table-column prop="course_id" label="关联课程ID" width="150" align="center">
          <template #default="{ row }">
            {{ row.course_id || '-' }}
          </template>
        </el-table-column>
        <el-table-column label="组长" width="150">
          <template #default="{ row }">
            {{ row.leader?.name || '-' }}
          </template>
        </el-table-column>
        <el-table-column label="成员" width="150" align="center">
          <template #default="{ row }">
            <el-tag size="large">{{ row.member_count }}/{{ row.max_members }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="280" fixed="right" align="center">
          <template #default="{ row }">
            <el-button link type="primary" @click="viewGroupMembers(row)">
              <el-icon><User /></el-icon>
              查看成员
            </el-button>
            <el-button link type="primary" @click="addMembersToGroupAction(row)">
              <el-icon><Plus /></el-icon>
              添加成员
            </el-button>
            <el-button link type="danger" @click="deleteGroupAction(row)">
              <el-icon><Delete /></el-icon>
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-empty 
        v-if="!loading && groups.length === 0" 
        description="暂无小组"
        style="padding: 60px 0"
      >
        <el-button type="primary" @click="showCreateGroupDialog">创建第一个小组</el-button>
      </el-empty>
    </el-card>

    <!-- 创建小组对话框 -->
    <el-dialog 
      v-model="groupDialogVisible" 
      title="创建小组" 
      width="500px"
      :close-on-click-modal="false"
    >
      <el-form :model="groupForm" :rules="groupRules" ref="groupFormRef" label-width="100px">
        <el-alert 
          title="提示" 
          type="info" 
          :closable="false"
          style="margin-bottom: 20px"
        >
          将在 <strong>{{ className }}</strong> 中创建小组
        </el-alert>
        
        <el-form-item label="小组名称" prop="name">
          <el-input 
            v-model="groupForm.name" 
            placeholder="例如：第一小组" 
            maxlength="50"
            show-word-limit
          />
        </el-form-item>
        
        <el-form-item label="关联课程">
          <el-input-number 
            v-model="groupForm.course_id" 
            :min="0"
            placeholder="可选"
            style="width: 100%"
          />
          <div class="form-tip">
            可选项，输入课程ID关联到具体课程
          </div>
        </el-form-item>
        
        <el-form-item label="最大人数" prop="max_members">
          <el-input-number 
            v-model="groupForm.max_members" 
            :min="1" 
            :max="20" 
            style="width: 100%"
          />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="groupDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitGroupForm" :loading="submittingGroup">
          创建
        </el-button>
      </template>
    </el-dialog>

    <!-- 小组成员管理对话框 -->
    <el-dialog 
      v-model="groupMembersDialogVisible" 
      :title="`小组成员管理 - ${currentGroupName}`"
      width="800px"
      :close-on-click-modal="false"
    >
      <div class="members-header">
        <el-input
          v-model="groupMemberSearchKeyword"
          placeholder="搜索成员"
          style="width: 300px"
          clearable
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        <el-button type="primary" @click="showAddGroupMemberDialog">
          <el-icon><Plus /></el-icon>
          添加成员
        </el-button>
      </div>
      
      <el-table :data="filteredGroupMembers" v-loading="groupMembersLoading" style="margin-top: 16px">
        <el-table-column prop="name" label="姓名" width="120" />
        <el-table-column prop="student_number" label="学号" width="150" />
        <el-table-column prop="gender" label="性别" width="80" />
        <el-table-column prop="role" label="角色" width="120">
          <template #default="{ row }">
            <el-tag :type="getGroupRoleTagType(row.role)" size="small">
              {{ getGroupRoleName(row.role) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="joined_at" label="加入时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.joined_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button link type="danger" @click="removeGroupMemberAction(row)">
              移除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-dialog>

    <!-- 添加小组成员对话框 -->
    <el-dialog 
      v-model="addGroupMemberDialogVisible" 
      title="添加成员" 
      width="500px"
      :close-on-click-modal="false"
    >
      <el-form label-width="100px">
        <el-form-item label="学生ID" required>
          <el-input
            v-model="groupMemberIdsText"
            type="textarea"
            :rows="8"
            placeholder="请输入学生ID，每行一个"
          />
          <div class="form-tip">
            提示：每行输入一个学生ID
          </div>
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="addGroupMemberDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitAddGroupMembers" :loading="addingGroupMembers">
          添加
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  ArrowLeft, Plus, User, Delete, Search
} from '@element-plus/icons-vue'
import {
  getClubClassDetail, getGroups, createGroup, deleteGroup,
  getGroupMembers, addMembersToGroup, removeMemberFromGroup
} from '@/api/club'
import dayjs from 'dayjs'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const groups = ref([])
const className = ref('')
const classId = ref(null)

// 创建小组
const groupDialogVisible = ref(false)
const submittingGroup = ref(false)
const groupForm = reactive({
  name: '',
  class_id: null,
  course_id: null,
  max_members: 6
})
const groupFormRef = ref(null)
const groupRules = {
  name: [
    { required: true, message: '请输入小组名称', trigger: 'blur' },
    { min: 2, max: 50, message: '长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  max_members: [
    { required: true, message: '请输入最大人数', trigger: 'blur' }
  ]
}

// 小组成员管理
const groupMembersDialogVisible = ref(false)
const groupMembersLoading = ref(false)
const groupMembers = ref([])
const groupMemberSearchKeyword = ref('')
const currentGroupUuid = ref(null)
const currentGroupName = ref('')
const addGroupMemberDialogVisible = ref(false)
const groupMemberIdsText = ref('')
const addingGroupMembers = ref(false)

// 计算属性
const filteredGroupMembers = computed(() => {
  if (!groupMemberSearchKeyword.value) return groupMembers.value
  const keyword = groupMemberSearchKeyword.value.toLowerCase()
  return groupMembers.value.filter(m => 
    m.name.toLowerCase().includes(keyword) || 
    m.student_number.includes(keyword)
  )
})

// 加载小组列表
const loadGroups = async () => {
  loading.value = true
  try {
    const res = await getClubClassDetail(route.params.uuid)
    className.value = res.data.data.name
    classId.value = res.data.data.id
    
    const groupRes = await getGroups({ class_id: classId.value })
    groups.value = groupRes.data.data || []
  } catch (error) {
    ElMessage.error(error.message || '加载小组列表失败')
  } finally {
    loading.value = false
  }
}

// 显示创建小组对话框
const showCreateGroupDialog = () => {
  Object.assign(groupForm, {
    name: '',
    class_id: classId.value,
    course_id: null,
    max_members: 6
  })
  groupDialogVisible.value = true
  nextTick(() => {
    groupFormRef.value?.clearValidate()
  })
}

// 提交小组表单
const submitGroupForm = async () => {
  try {
    await groupFormRef.value.validate()
  } catch {
    return
  }
  
  submittingGroup.value = true
  try {
    await createGroup(groupForm)
    ElMessage.success('小组创建成功')
    groupDialogVisible.value = false
    loadGroups()
  } catch (error) {
    ElMessage.error(error.message || '创建小组失败')
  } finally {
    submittingGroup.value = false
  }
}

// 删除小组
const deleteGroupAction = async (group) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除小组"${group.name}"吗？删除后将无法恢复。`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await deleteGroup(group.uuid)
    ElMessage.success('小组已删除')
    loadGroups()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '删除失败')
    }
  }
}

// 查看小组成员
const viewGroupMembers = async (group) => {
  currentGroupUuid.value = group.uuid
  currentGroupName.value = group.name
  groupMembersLoading.value = true
  groupMembersDialogVisible.value = true
  
  try {
    const res = await getGroupMembers(group.uuid)
    groupMembers.value = res.data.data || []
  } catch (error) {
    ElMessage.error(error.message || '加载小组成员失败')
  } finally {
    groupMembersLoading.value = false
  }
}

// 添加小组成员
const addMembersToGroupAction = (group) => {
  currentGroupUuid.value = group.uuid
  currentGroupName.value = group.name
  showAddGroupMemberDialog()
}

// 显示添加小组成员对话框
const showAddGroupMemberDialog = () => {
  groupMemberIdsText.value = ''
  addGroupMemberDialogVisible.value = true
}

// 提交添加小组成员
const submitAddGroupMembers = async () => {
  const ids = groupMemberIdsText.value
    .split('\n')
    .map(id => parseInt(id.trim()))
    .filter(id => !isNaN(id))
  
  if (ids.length === 0) {
    ElMessage.warning('请输入有效的学生ID')
    return
  }
  
  addingGroupMembers.value = true
  try {
    const res = await addMembersToGroup(currentGroupUuid.value, {
      student_ids: ids
    })
    ElMessage.success(`成功添加 ${res.data.data.added_count} 名成员`)
    addGroupMemberDialogVisible.value = false
    // 如果小组成员对话框是打开的，刷新成员列表
    if (groupMembersDialogVisible.value) {
      viewGroupMembers({ uuid: currentGroupUuid.value, name: currentGroupName.value })
    }
    // 刷新小组列表
    loadGroups()
  } catch (error) {
    ElMessage.error(error.message || '添加成员失败')
  } finally {
    addingGroupMembers.value = false
  }
}

// 移除小组成员
const removeGroupMemberAction = async (member) => {
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
    
    await removeMemberFromGroup(currentGroupUuid.value, member.id)
    ElMessage.success('成员已移除')
    viewGroupMembers({ uuid: currentGroupUuid.value, name: currentGroupName.value })
    // 刷新小组列表
    loadGroups()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '移除失败')
    }
  }
}

// 工具方法
const getGroupRoleName = (role) => {
  const map = {
    member: '成员',
    leader: '组长'
  }
  return map[role] || role
}

const getGroupRoleTagType = (role) => {
  const map = {
    member: 'info',
    leader: 'danger'
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
  loadGroups()
})
</script>

<style scoped lang="scss">
.class-groups-container {
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

.stats-card {
  margin-bottom: 24px;
  border-radius: 12px;
  
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

.table-card {
  border-radius: 12px;
}

.members-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.form-tip {
  margin-top: 8px;
  font-size: 12px;
  color: #909399;
  line-height: 1.5;
}
</style>
