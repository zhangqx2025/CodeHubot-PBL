<template>
  <div class="admin-users">
    <!-- 工具栏 -->
    <div class="toolbar">
      <el-form :inline="true">
        <el-form-item label="角色">
          <el-select v-model="searchParams.role" placeholder="全部" clearable @change="loadUsers">
            <el-option label="全部" value="" />
            <el-option label="平台管理员" value="platform_admin" />
            <el-option label="学校管理员" value="school_admin" />
            <el-option label="教师" value="teacher" />
            <el-option label="学生" value="student" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="showCreateDialog">
            <el-icon><Plus /></el-icon>
            创建用户
          </el-button>
          <el-button @click="showBatchImportDialog">
            <el-icon><Upload /></el-icon>
            批量导入
          </el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 用户列表 -->
    <el-table :data="users" border stripe v-loading="loading">
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="username" label="用户名" width="150" />
      <el-table-column prop="name" label="姓名" width="120" />
      <el-table-column label="角色" width="120">
        <template #default="{ row }">
          <el-tag :type="getRoleType(row.role)">{{ getRoleLabel(row.role) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="phone" label="手机号" width="130" />
      <el-table-column prop="email" label="邮箱" min-width="180" show-overflow-tooltip />
      <el-table-column label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="row.is_active ? 'success' : 'danger'">
            {{ row.is_active ? '启用' : '禁用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="280" fixed="right">
        <template #default="{ row }">
          <el-button link type="primary" @click="editUser(row)">编辑</el-button>
          <el-button link type="warning" @click="resetPassword(row)">重置密码</el-button>
          <el-button 
            link 
            :type="row.is_active ? 'danger' : 'success'" 
            @click="toggleActive(row)"
          >
            {{ row.is_active ? '禁用' : '启用' }}
          </el-button>
          <el-button link type="danger" @click="deleteUser(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div class="pagination">
      <el-pagination
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.pageSize"
        :page-sizes="[10, 20, 50, 100]"
        :total="pagination.total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="loadUsers"
        @current-change="loadUsers"
      />
    </div>

    <!-- 创建/编辑用户对话框 -->
    <el-dialog 
      v-model="userDialogVisible" 
      :title="isEditing ? '编辑用户' : '创建用户'"
      width="600px"
    >
      <el-form :model="userForm" :rules="userRules" ref="userFormRef" label-width="100px">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="userForm.username" :disabled="isEditing" />
        </el-form-item>
        <el-form-item label="姓名" prop="name">
          <el-input v-model="userForm.name" />
        </el-form-item>
        <el-form-item label="角色" prop="role">
          <el-select v-model="userForm.role" placeholder="请选择角色" :disabled="isEditing">
            <el-option label="平台管理员" value="platform_admin" />
            <el-option label="学校管理员" value="school_admin" />
            <el-option label="教师" value="teacher" />
            <el-option label="学生" value="student" />
          </el-select>
        </el-form-item>
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="userForm.phone" />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="userForm.email" />
        </el-form-item>
        <el-form-item label="密码" prop="password" v-if="!isEditing">
          <el-input v-model="userForm.password" type="password" />
        </el-form-item>
        <el-form-item label="性别">
          <el-select v-model="userForm.gender" placeholder="请选择">
            <el-option label="男" value="男" />
            <el-option label="女" value="女" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="userDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveUser">确定</el-button>
      </template>
    </el-dialog>

    <!-- 批量导入对话框 -->
    <el-dialog v-model="importDialogVisible" title="批量导入用户" width="600px">
      <el-form label-width="100px">
        <el-form-item label="导入类型">
          <el-radio-group v-model="importType">
            <el-radio label="students">学生</el-radio>
            <el-radio label="teachers">教师</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="学校ID">
          <el-input v-model.number="importSchoolId" placeholder="请输入学校ID" />
        </el-form-item>
        <el-form-item label="CSV文件">
          <el-upload
            ref="uploadRef"
            :auto-upload="false"
            :limit="1"
            accept=".csv"
            :on-change="handleFileChange"
          >
            <template #trigger>
              <el-button type="primary">选择文件</el-button>
            </template>
            <template #tip>
              <div class="el-upload__tip">
                <p>只支持CSV格式文件</p>
                <p v-if="importType === 'students'">
                  学生CSV格式：username,name,student_number,class_id,gender,phone,email,password
                </p>
                <p v-else>
                  教师CSV格式：username,name,teacher_number,subject,gender,phone,email,password
                </p>
              </div>
            </template>
          </el-upload>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="importDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleImport" :loading="importing">开始导入</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Upload } from '@element-plus/icons-vue'
import {
  getUserList,
  createUser,
  updateUser,
  deleteUser as deleteUserApi,
  toggleUserActive,
  resetUserPassword as resetPasswordApi,
  batchImportStudents,
  batchImportTeachers
} from '@/api/users'

const loading = ref(false)
const users = ref([])
const searchParams = reactive({
  role: ''
})
const pagination = reactive({
  page: 1,
  pageSize: 20,
  total: 0
})

// 对话框相关
const userDialogVisible = ref(false)
const isEditing = ref(false)
const userFormRef = ref(null)
const userForm = reactive({
  id: null,
  username: '',
  name: '',
  role: '',
  phone: '',
  email: '',
  password: '',
  gender: ''
})

const userRules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  role: [{ required: true, message: '请选择角色', trigger: 'change' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}

// 批量导入相关
const importDialogVisible = ref(false)
const importType = ref('students')
const importSchoolId = ref(null)
const importFile = ref(null)
const importing = ref(false)

// 获取角色标签
const getRoleLabel = (role) => {
  const labels = {
    'platform_admin': '平台管理员',
    'school_admin': '学校管理员',
    'teacher': '教师',
    'student': '学生'
  }
  return labels[role] || role
}

// 获取角色标签类型
const getRoleType = (role) => {
  const types = {
    'platform_admin': 'danger',
    'school_admin': 'warning',
    'teacher': 'primary',
    'student': 'success'
  }
  return types[role] || 'info'
}

// 加载用户列表
const loadUsers = async () => {
  loading.value = true
  try {
    const params = {
      role: searchParams.role || undefined,
      skip: (pagination.page - 1) * pagination.pageSize,
      limit: pagination.pageSize
    }
    const result = await getUserList(params)
    users.value = result.items || []
    pagination.total = result.total || 0
  } catch (error) {
    ElMessage.error(error.message || '加载用户列表失败')
  } finally {
    loading.value = false
  }
}

// 显示创建对话框
const showCreateDialog = () => {
  isEditing.value = false
  Object.assign(userForm, {
    id: null,
    username: '',
    name: '',
    role: '',
    phone: '',
    email: '',
    password: '',
    gender: ''
  })
  userDialogVisible.value = true
}

// 编辑用户
const editUser = (row) => {
  isEditing.value = true
  Object.assign(userForm, {
    uuid: row.uuid,
    username: row.username,
    name: row.name || row.real_name,
    role: row.role,
    phone: row.phone || '',
    email: row.email || '',
    gender: row.gender || ''
  })
  userDialogVisible.value = true
}

// 保存用户
const saveUser = async () => {
  await userFormRef.value.validate()
  
  try {
    if (isEditing.value) {
      await updateUser(userForm.uuid, {
        name: userForm.name,
        phone: userForm.phone,
        email: userForm.email,
        gender: userForm.gender
      })
      ElMessage.success('用户更新成功')
    } else {
      await createUser(userForm)
      ElMessage.success('用户创建成功')
    }
    userDialogVisible.value = false
    loadUsers()
  } catch (error) {
    ElMessage.error(error.message || '操作失败')
  }
}

// 重置密码
const resetPassword = async (row) => {
  const { value: newPassword } = await ElMessageBox.prompt('请输入新密码', '重置密码', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    inputPattern: /.{6,}/,
    inputErrorMessage: '密码至少6位'
  })
  
  if (newPassword) {
    try {
      await resetPasswordApi(row.uuid, newPassword)
      ElMessage.success('密码重置成功')
    } catch (error) {
      ElMessage.error(error.message || '密码重置失败')
    }
  }
}

// 启用/禁用用户
const toggleActive = async (row) => {
  try {
    await toggleUserActive(row.uuid)
    ElMessage.success(row.is_active ? '已禁用用户' : '已启用用户')
    loadUsers()
  } catch (error) {
    ElMessage.error(error.message || '操作失败')
  }
}

// 删除用户
const deleteUser = async (row) => {
  await ElMessageBox.confirm('确定要删除该用户吗？', '警告', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
  
  try {
    await deleteUserApi(row.uuid)
    ElMessage.success('用户删除成功')
    loadUsers()
  } catch (error) {
    ElMessage.error(error.message || '用户删除失败')
  }
}

// 显示批量导入对话框
const showBatchImportDialog = () => {
  importType.value = 'students'
  importSchoolId.value = null
  importFile.value = null
  importDialogVisible.value = true
}

// 处理文件选择
const handleFileChange = (file) => {
  importFile.value = file.raw
}

// 批量导入
const handleImport = async () => {
  if (!importSchoolId.value) {
    ElMessage.warning('请输入学校ID')
    return
  }
  
  if (!importFile.value) {
    ElMessage.warning('请选择CSV文件')
    return
  }
  
  importing.value = true
  try {
    let result
    if (importType.value === 'students') {
      result = await batchImportStudents(importSchoolId.value, importFile.value)
    } else {
      result = await batchImportTeachers(importSchoolId.value, importFile.value)
    }
    
    ElMessage.success(result.message || '导入完成')
    importDialogVisible.value = false
    loadUsers()
  } catch (error) {
    ElMessage.error(error.message || '导入失败')
  } finally {
    importing.value = false
  }
}

onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
.admin-users {
  background: white;
  padding: 20px;
  border-radius: 4px;
}

.toolbar {
  margin-bottom: 20px;
}

.pagination {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}

.el-upload__tip {
  color: #999;
  font-size: 12px;
  line-height: 1.5;
}

.el-upload__tip p {
  margin: 5px 0;
}
</style>
