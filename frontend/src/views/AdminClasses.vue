<template>
  <div class="admin-classes">
    <el-tabs v-model="activeTab">
      <!-- 班级管理 -->
      <el-tab-pane label="班级管理" name="classes">
        <div class="toolbar">
          <el-button type="primary" @click="showCreateClassDialog">
            <el-icon><Plus /></el-icon>
            创建班级
          </el-button>
        </div>

        <el-table :data="classes" border stripe v-loading="classLoading">
          <el-table-column prop="id" label="ID" width="80" />
          <el-table-column prop="name" label="班级名称" min-width="150" />
          <el-table-column prop="grade" label="年级" width="120" />
          <el-table-column prop="school_name" label="所属学校" width="200" />
          <el-table-column label="学生人数" width="120">
            <template #default="{ row }">
              <el-button link type="primary" @click="viewClassStudents(row)">
                查看学生
              </el-button>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="200" fixed="right">
            <el-button link type="primary" @click="addStudentsToClass(row)">添加学生</el-button>
            <el-button link type="danger" @click="deleteClass(row)">删除</el-button>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <!-- 小组管理 -->
      <el-tab-pane label="小组管理" name="groups">
        <div class="toolbar">
          <el-button type="primary" @click="showCreateGroupDialog">
            <el-icon><Plus /></el-icon>
            创建小组
          </el-button>
        </div>

        <el-table :data="groups" border stripe v-loading="groupLoading">
          <el-table-column prop="id" label="ID" width="80" />
          <el-table-column prop="name" label="小组名称" min-width="150" />
          <el-table-column prop="class_name" label="所属班级" width="150" />
          <el-table-column prop="course_name" label="关联课程" width="200" />
          <el-table-column prop="max_members" label="最大人数" width="100" />
          <el-table-column label="成员" width="120">
            <template #default="{ row }">
              <el-button link type="primary" @click="viewGroupMembers(row)">
                查看成员
              </el-button>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="200" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" @click="addMembersToGroup(row)">添加成员</el-button>
              <el-button link type="danger" @click="deleteGroup(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <!-- 创建班级对话框 -->
    <el-dialog v-model="classDialogVisible" title="创建班级" width="500px">
      <el-form :model="classForm" label-width="100px">
        <el-form-item label="班级名称" required>
          <el-input v-model="classForm.name" placeholder="例如：2024级计算机1班" />
        </el-form-item>
        <el-form-item label="年级">
          <el-input v-model="classForm.grade" placeholder="例如：2024" />
        </el-form-item>
        <el-form-item label="学校ID" required>
          <el-input-number v-model="classForm.school_id" :min="1" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="classDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="createClass">确定</el-button>
      </template>
    </el-dialog>

    <!-- 创建小组对话框 -->
    <el-dialog v-model="groupDialogVisible" title="创建小组" width="500px">
      <el-form :model="groupForm" label-width="100px">
        <el-form-item label="小组名称" required>
          <el-input v-model="groupForm.name" placeholder="例如：第一小组" />
        </el-form-item>
        <el-form-item label="班级ID">
          <el-input-number v-model="groupForm.class_id" :min="1" />
        </el-form-item>
        <el-form-item label="课程ID">
          <el-input-number v-model="groupForm.course_id" :min="1" />
        </el-form-item>
        <el-form-item label="最大人数">
          <el-input-number v-model="groupForm.max_members" :min="1" :max="20" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="groupDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="createGroup">确定</el-button>
      </template>
    </el-dialog>

    <!-- 班级学生列表对话框 -->
    <el-dialog v-model="classStudentsDialogVisible" title="班级学生" width="800px">
      <el-table :data="classStudents" border v-loading="classStudentsLoading">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="姓名" width="120" />
        <el-table-column prop="student_number" label="学号" width="150" />
        <el-table-column prop="gender" label="性别" width="80" />
        <el-table-column prop="phone" label="手机号" width="130" />
        <el-table-column prop="email" label="邮箱" min-width="180" />
      </el-table>
    </el-dialog>

    <!-- 小组成员列表对话框 -->
    <el-dialog v-model="groupMembersDialogVisible" title="小组成员" width="800px">
      <el-table :data="groupMembers" border v-loading="groupMembersLoading">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="姓名" width="120" />
        <el-table-column prop="student_number" label="学号" width="150" />
        <el-table-column prop="gender" label="性别" width="80" />
        <el-table-column label="操作" width="120">
          <template #default="{ row }">
            <el-button 
              link 
              type="danger" 
              @click="removeMemberFromGroup(currentGroupId, row.uuid)"
            >
              移除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-dialog>

    <!-- 添加学生到班级对话框 -->
    <el-dialog v-model="addStudentsDialogVisible" title="添加学生到班级" width="500px">
      <el-form label-width="100px">
        <el-form-item label="学生ID" required>
          <el-input
            v-model="studentIds"
            type="textarea"
            :rows="5"
            placeholder="请输入学生ID，每行一个"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addStudentsDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitAddStudents">确定</el-button>
      </template>
    </el-dialog>

    <!-- 添加成员到小组对话框 -->
    <el-dialog v-model="addMembersDialogVisible" title="添加成员到小组" width="500px">
      <el-form label-width="100px">
        <el-form-item label="学生ID" required>
          <el-input
            v-model="memberIds"
            type="textarea"
            :rows="5"
            placeholder="请输入学生ID，每行一个"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addMembersDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitAddMembers">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import {
  getClassList,
  createClass as createClassApi,
  getClassStudents as getClassStudentsApi,
  addStudentsToClass as addStudentsToClassApi,
  getGroupList,
  createGroup as createGroupApi,
  getGroupMembers as getGroupMembersApi,
  addMembersToGroup as addMembersToGroupApi,
  removeMemberFromGroup as removeMemberApi
} from '@/api/classes'

const activeTab = ref('classes')

// 班级相关
const classLoading = ref(false)
const classes = ref([])
const classDialogVisible = ref(false)
const classForm = reactive({
  name: '',
  grade: '',
  school_id: null
})

// 小组相关
const groupLoading = ref(false)
const groups = ref([])
const groupDialogVisible = ref(false)
const groupForm = reactive({
  name: '',
  class_id: null,
  course_id: null,
  max_members: 6
})

// 班级学生
const classStudentsDialogVisible = ref(false)
const classStudentsLoading = ref(false)
const classStudents = ref([])
const currentClassId = ref(null)

// 小组成员
const groupMembersDialogVisible = ref(false)
const groupMembersLoading = ref(false)
const groupMembers = ref([])
const currentGroupId = ref(null)

// 添加学生/成员
const addStudentsDialogVisible = ref(false)
const addMembersDialogVisible = ref(false)
const studentIds = ref('')
const memberIds = ref('')

// 加载班级列表
const loadClasses = async () => {
  classLoading.value = true
  try {
    classes.value = await getClassList()
  } catch (error) {
    ElMessage.error(error.message || '加载班级列表失败')
  } finally {
    classLoading.value = false
  }
}

// 显示创建班级对话框
const showCreateClassDialog = () => {
  Object.assign(classForm, {
    name: '',
    grade: '',
    school_id: null
  })
  classDialogVisible.value = true
}

// 创建班级
const createClass = async () => {
  if (!classForm.name || !classForm.school_id) {
    ElMessage.warning('请填写必填项')
    return
  }
  
  try {
    await createClassApi(classForm)
    ElMessage.success('班级创建成功')
    classDialogVisible.value = false
    loadClasses()
  } catch (error) {
    ElMessage.error(error.message || '班级创建失败')
  }
}

// 查看班级学生
const viewClassStudents = async (row) => {
  currentClassId.value = row.uuid
  classStudentsLoading.value = true
  classStudentsDialogVisible.value = true
  
  try {
    classStudents.value = await getClassStudentsApi(row.uuid)
  } catch (error) {
    ElMessage.error(error.message || '加载学生列表失败')
  } finally {
    classStudentsLoading.value = false
  }
}

// 添加学生到班级
const addStudentsToClass = (row) => {
  currentClassId.value = row.uuid
  studentIds.value = ''
  addStudentsDialogVisible.value = true
}

// 提交添加学生
const submitAddStudents = async () => {
  const ids = studentIds.value.split('\n').map(id => parseInt(id.trim())).filter(id => !isNaN(id))
  
  if (ids.length === 0) {
    ElMessage.warning('请输入有效的学生ID')
    return
  }
  
  try {
    await addStudentsToClassApi(currentClassId.value, ids)
    ElMessage.success('添加学生成功')
    addStudentsDialogVisible.value = false
  } catch (error) {
    ElMessage.error(error.message || '添加学生失败')
  }
}

// 删除班级
const deleteClass = async (row) => {
  await ElMessageBox.confirm('确定要删除该班级吗？', '警告', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
  
  ElMessage.warning('删除班级功能待实现')
}

// 加载小组列表
const loadGroups = async () => {
  groupLoading.value = true
  try {
    groups.value = await getGroupList()
  } catch (error) {
    ElMessage.error(error.message || '加载小组列表失败')
  } finally {
    groupLoading.value = false
  }
}

// 显示创建小组对话框
const showCreateGroupDialog = () => {
  Object.assign(groupForm, {
    name: '',
    class_id: null,
    course_id: null,
    max_members: 6
  })
  groupDialogVisible.value = true
}

// 创建小组
const createGroup = async () => {
  if (!groupForm.name) {
    ElMessage.warning('请填写小组名称')
    return
  }
  
  try {
    await createGroupApi(groupForm)
    ElMessage.success('小组创建成功')
    groupDialogVisible.value = false
    loadGroups()
  } catch (error) {
    ElMessage.error(error.message || '小组创建失败')
  }
}

// 查看小组成员
const viewGroupMembers = async (row) => {
  currentGroupId.value = row.uuid
  groupMembersLoading.value = true
  groupMembersDialogVisible.value = true
  
  try {
    groupMembers.value = await getGroupMembersApi(row.uuid)
  } catch (error) {
    ElMessage.error(error.message || '加载成员列表失败')
  } finally {
    groupMembersLoading.value = false
  }
}

// 添加成员到小组
const addMembersToGroup = (row) => {
  currentGroupId.value = row.uuid
  memberIds.value = ''
  addMembersDialogVisible.value = true
}

// 提交添加成员
const submitAddMembers = async () => {
  const ids = memberIds.value.split('\n').map(id => parseInt(id.trim())).filter(id => !isNaN(id))
  
  if (ids.length === 0) {
    ElMessage.warning('请输入有效的学生ID')
    return
  }
  
  try {
    await addMembersToGroupApi(currentGroupId.value, ids)
    ElMessage.success('添加成员成功')
    addMembersDialogVisible.value = false
  } catch (error) {
    ElMessage.error(error.message || '添加成员失败')
  }
}

// 从小组移除成员
const removeMemberFromGroup = async (groupId, studentId) => {
  await ElMessageBox.confirm('确定要移除该成员吗？', '警告', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
  
  try {
    await removeMemberApi(groupId, studentId)
    ElMessage.success('成员已移除')
    viewGroupMembers({ id: groupId })
  } catch (error) {
    ElMessage.error(error.message || '移除成员失败')
  }
}

// 删除小组
const deleteGroup = async (row) => {
  await ElMessageBox.confirm('确定要删除该小组吗？', '警告', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
  
  ElMessage.warning('删除小组功能待实现')
}

onMounted(() => {
  loadClasses()
  loadGroups()
})
</script>

<style scoped>
.admin-classes {
  background: white;
  padding: 20px;
  border-radius: 4px;
}

.toolbar {
  margin-bottom: 20px;
}
</style>
