<template>
  <div class="club-classes-container">
    <!-- 页面标题 -->
    <div class="page-header">
      <div class="header-left">
        <h1 class="page-title">
          <el-icon class="title-icon"><School /></el-icon>
          项目式课程管理
        </h1>
        <p class="page-subtitle">创建班级、组织学生、从模板导入或自定义课程</p>
      </div>
      <el-button type="primary" size="large" @click="showCreateDialog" class="create-btn">
        <el-icon><Plus /></el-icon>
        创建班级
      </el-button>
    </div>

    <!-- 班级管理 -->
    <div class="classes-section">
        <!-- 筛选器 -->
        <el-card class="filter-card" shadow="never">
          <div class="filter-container">
            <el-radio-group v-model="classTypeFilter" @change="loadClasses" class="class-type-filter">
              <el-radio-button label="">
                <el-icon><Grid /></el-icon>
                全部
              </el-radio-button>
              <el-radio-button label="club">
                <el-icon><Medal /></el-icon>
                社团班
              </el-radio-button>
              <el-radio-button label="project">
                <el-icon><FolderOpened /></el-icon>
                项目班
              </el-radio-button>
              <el-radio-button label="interest">
                <el-icon><Star /></el-icon>
                兴趣班
              </el-radio-button>
              <el-radio-button label="competition">
                <el-icon><Trophy /></el-icon>
                竞赛班
              </el-radio-button>
            </el-radio-group>
            
            <div class="filter-stats">
              <el-statistic title="班级总数" :value="classes.length" />
            </div>
          </div>
        </el-card>

    <!-- 班级列表 -->
    <div v-loading="loading" class="classes-grid">
      <el-empty v-if="!loading && classes.length === 0" description="暂无班级数据">
        <el-button type="primary" @click="showCreateDialog">创建第一个班级</el-button>
      </el-empty>
      
      <div v-for="cls in classes" :key="cls.id" class="class-card">
        <el-card shadow="hover" :body-style="{ padding: '0' }">
          <!-- 卡片头部 -->
          <div class="card-header" :class="`type-${cls.class_type}`">
            <div class="header-left">
              <el-tag :type="getClassTypeTagType(cls.class_type)" size="small" effect="dark">
                {{ getClassTypeName(cls.class_type) }}
              </el-tag>
              <h3 class="class-name">{{ cls.name }}</h3>
            </div>
            <el-dropdown trigger="click" @command="(cmd) => handleClassAction(cmd, cls)">
              <el-button text circle>
                <el-icon><MoreFilled /></el-icon>
              </el-button>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="detail">
                    <el-icon><View /></el-icon>
                    查看详情
                  </el-dropdown-item>
                  <el-dropdown-item command="edit">
                    <el-icon><Edit /></el-icon>
                    编辑信息
                  </el-dropdown-item>
                  <el-dropdown-item command="members">
                    <el-icon><UserFilled /></el-icon>
                    成员管理
                  </el-dropdown-item>
                  <el-dropdown-item command="groups">
                    <el-icon><Grid /></el-icon>
                    小组管理
                  </el-dropdown-item>
                  <el-dropdown-item command="course">
                    <el-icon><Reading /></el-icon>
                    创建课程
                  </el-dropdown-item>
                  <el-dropdown-item command="delete" divided>
                    <el-icon><Delete /></el-icon>
                    删除班级
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>

          <!-- 卡片内容 -->
          <div class="card-body">
            <p class="class-description">{{ cls.description || '暂无描述' }}</p>
            
            <div class="class-stats">
              <div class="stat-item">
                <el-icon class="stat-icon"><User /></el-icon>
                <div class="stat-content">
                  <span class="stat-value">{{ cls.current_members }}/{{ cls.max_students }}</span>
                  <span class="stat-label">成员</span>
                </div>
              </div>
              <div class="stat-item">
                <el-icon class="stat-icon"><Reading /></el-icon>
                <div class="stat-content">
                  <span class="stat-value">{{ cls.course_count }}</span>
                  <span class="stat-label">课程</span>
                </div>
              </div>
            </div>

            <!-- 进度条 -->
            <el-progress 
              :percentage="getClassFullnessPercentage(cls)" 
              :color="getProgressColor(getClassFullnessPercentage(cls))"
              :show-text="false"
              :stroke-width="8"
              style="margin-top: 12px"
            />
            
            <div class="card-footer">
              <span class="create-time">
                <el-icon><Clock /></el-icon>
                {{ formatDate(cls.created_at) }}
              </span>
              <el-tag 
                :type="cls.is_open ? 'success' : 'info'" 
                size="small"
                effect="plain"
              >
                {{ cls.is_open ? '开放加入' : '关闭加入' }}
              </el-tag>
            </div>
          </div>
        </el-card>
      </div>
    </div>
    </div>

    <!-- 创建/编辑班级对话框 -->
    <el-dialog 
      v-model="dialogVisible" 
      :title="dialogMode === 'create' ? '创建班级' : '编辑班级'"
      width="600px"
      :close-on-click-modal="false"
    >
      <el-form :model="classForm" :rules="classRules" ref="classFormRef" label-width="100px">
        <el-form-item label="班级名称" prop="name">
          <el-input 
            v-model="classForm.name" 
            placeholder="例如：0501班、AI兴趣班" 
            maxlength="50"
            show-word-limit
          />
        </el-form-item>
        
        <el-form-item label="班级类型" prop="class_type">
          <el-select v-model="classForm.class_type" placeholder="请选择班级类型" style="width: 100%">
            <el-option label="社团班" value="club">
              <span style="display: flex; align-items: center">
                <el-icon style="margin-right: 8px"><Medal /></el-icon>
                社团班
              </span>
            </el-option>
            <el-option label="项目班" value="project">
              <span style="display: flex; align-items: center">
                <el-icon style="margin-right: 8px"><FolderOpened /></el-icon>
                项目班
              </span>
            </el-option>
            <el-option label="兴趣班" value="interest">
              <span style="display: flex; align-items: center">
                <el-icon style="margin-right: 8px"><Star /></el-icon>
                兴趣班
              </span>
            </el-option>
            <el-option label="竞赛班" value="competition">
              <span style="display: flex; align-items: center">
                <el-icon style="margin-right: 8px"><Trophy /></el-icon>
                竞赛班
              </span>
            </el-option>
          </el-select>
        </el-form-item>
        
        <el-form-item label="班级描述" prop="description">
          <el-input 
            v-model="classForm.description" 
            type="textarea" 
            :rows="4" 
            placeholder="请输入班级描述"
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
        
        <el-form-item label="最大人数" prop="max_students">
          <el-input-number 
            v-model="classForm.max_students" 
            :min="1" 
            :max="200" 
            style="width: 100%"
          />
        </el-form-item>
        
        <el-form-item v-if="dialogMode === 'edit'" label="开放状态">
          <el-switch 
            v-model="classForm.is_open" 
            active-text="开放加入" 
            inactive-text="关闭加入"
          />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitClassForm" :loading="submitting">
          {{ dialogMode === 'create' ? '创建' : '保存' }}
        </el-button>
      </template>
    </el-dialog>

    <!-- 成员管理对话框 -->
    <el-dialog 
      v-model="membersDialogVisible" 
      title="成员管理" 
      width="800px"
      :close-on-click-modal="false"
    >
      <div class="members-header">
        <el-input
          v-model="memberSearchKeyword"
          placeholder="搜索成员"
          style="width: 300px"
          clearable
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        <el-button type="primary" @click="showAddMemberDialog">
          <el-icon><Plus /></el-icon>
          添加成员
        </el-button>
      </div>
      
      <el-table :data="filteredMembers" v-loading="membersLoading" style="margin-top: 16px">
        <el-table-column prop="name" label="姓名" width="120" />
        <el-table-column prop="student_number" label="学号" width="150" />
        <el-table-column prop="gender" label="性别" width="80" />
        <el-table-column prop="role" label="角色" width="120">
          <template #default="{ row }">
            <el-tag :type="getRoleTagType(row.role)" size="small">
              {{ getRoleName(row.role) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="joined_at" label="加入时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.joined_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-dropdown @command="(cmd) => handleMemberAction(cmd, row)">
              <el-button link type="primary">
                操作
                <el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </el-button>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="leader" v-if="row.role !== 'leader'">
                    设为班长
                  </el-dropdown-item>
                  <el-dropdown-item command="deputy" v-if="row.role !== 'deputy'">
                    设为副班长
                  </el-dropdown-item>
                  <el-dropdown-item command="member" v-if="row.role !== 'member'">
                    设为普通成员
                  </el-dropdown-item>
                  <el-dropdown-item command="remove" divided>
                    移除成员
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </template>
        </el-table-column>
      </el-table>
    </el-dialog>

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
            :rows="8"
            placeholder="请输入学生ID，每行一个"
          />
          <div style="color: var(--el-text-color-secondary); font-size: 12px; margin-top: 8px">
            提示：每行输入一个学生ID，添加后将自动为其选上班级的所有课程
          </div>
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="addMemberDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitAddMembers" :loading="addingMembers">
          添加
        </el-button>
      </template>
    </el-dialog>

    <!-- 创建课程对话框 -->
    <el-dialog 
      v-model="createCourseDialogVisible" 
      title="为班级创建课程" 
      width="700px"
      :close-on-click-modal="false"
    >
      <el-form :model="courseForm" label-width="120px">
        <el-alert 
          title="提示" 
          type="info" 
          :closable="false"
          style="margin-bottom: 20px"
        >
          基于模板创建课程，将自动复制模板的单元、资源和任务，并可为班级成员自动选课
        </el-alert>
        
        <el-form-item label="课程模板" required>
          <el-select 
            v-model="courseForm.template_id" 
            placeholder="请选择课程模板" 
            style="width: 100%"
            @change="onTemplateChange"
          >
            <el-option
              v-for="template in courseTemplates"
              :key="template.id"
              :label="template.title"
              :value="template.id"
            >
              <div style="display: flex; justify-content: space-between; align-items: center">
                <span>{{ template.title }}</span>
                <el-tag :type="getDifficultyTagType(template.difficulty)" size="small">
                  {{ getDifficultyName(template.difficulty) }}
                </el-tag>
              </div>
            </el-option>
          </el-select>
        </el-form-item>
        
        <el-form-item label="课程名称">
          <el-input 
            v-model="courseForm.title" 
            placeholder="默认为：班级名+模板名"
          />
        </el-form-item>
        
        <el-form-item label="自动选课">
          <el-switch 
            v-model="courseForm.auto_enroll" 
            active-text="自动为班级成员选课"
          />
          <div style="color: var(--el-text-color-secondary); font-size: 12px; margin-top: 8px">
            开启后，班级所有成员将自动选上该课程
          </div>
        </el-form-item>
        
        <el-divider />
        
        <div v-if="selectedTemplate" class="template-info">
          <h4>模板信息</h4>
          <el-descriptions :column="2" border>
            <el-descriptions-item label="模板名称">{{ selectedTemplate.name }}</el-descriptions-item>
            <el-descriptions-item label="难度">{{ getDifficultyName(selectedTemplate.difficulty) }}</el-descriptions-item>
            <el-descriptions-item label="预计时长">{{ selectedTemplate.duration }}</el-descriptions-item>
            <el-descriptions-item label="分类">{{ selectedTemplate.category }}</el-descriptions-item>
            <el-descriptions-item label="使用次数" :span="2">{{ selectedTemplate.usage_count }}</el-descriptions-item>
            <el-descriptions-item label="描述" :span="2">
              {{ selectedTemplate.description }}
            </el-descriptions-item>
          </el-descriptions>
        </div>
      </el-form>
      
      <template #footer>
        <el-button @click="createCourseDialogVisible = false">取消</el-button>
        <el-button 
          type="primary" 
          @click="submitCreateCourse" 
          :loading="creatingCourse"
          :disabled="!courseForm.template_id"
        >
          创建课程
        </el-button>
      </template>
    </el-dialog>

    <!-- 小组管理对话框 -->
    <el-dialog 
      v-model="classGroupsDialogVisible" 
      :title="`小组管理 - ${currentClassName}`"
      width="1000px"
      :close-on-click-modal="false"
    >
      <div class="groups-management">
        <div class="groups-header">
          <el-statistic title="小组总数" :value="currentClassGroups.length" />
          <el-button type="primary" @click="showCreateGroupDialog">
            <el-icon><Plus /></el-icon>
            创建小组
          </el-button>
        </div>

        <el-table 
          :data="currentClassGroups" 
          v-loading="groupLoading" 
          style="margin-top: 16px"
          border
          stripe
        >
          <el-table-column prop="name" label="小组名称" min-width="150" />
          <el-table-column prop="course_id" label="关联课程" width="120">
            <template #default="{ row }">
              {{ row.course_id || '-' }}
            </template>
          </el-table-column>
          <el-table-column label="组长" width="120">
            <template #default="{ row }">
              {{ row.leader?.name || '-' }}
            </template>
          </el-table-column>
          <el-table-column label="成员" width="120">
            <template #default="{ row }">
              <el-tag>{{ row.member_count }}/{{ row.max_members }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="created_at" label="创建时间" width="160">
            <template #default="{ row }">
              {{ formatDateTime(row.created_at) }}
            </template>
          </el-table-column>
          <el-table-column label="操作" width="220" fixed="right">
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
          v-if="!groupLoading && currentClassGroups.length === 0" 
          description="暂无小组，创建第一个小组吧"
          style="margin-top: 40px"
        >
          <el-button type="primary" @click="showCreateGroupDialog">创建小组</el-button>
        </el-empty>
      </div>
    </el-dialog>

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
          将在 <strong>{{ currentClassName }}</strong> 中创建小组
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
          <div style="color: var(--el-text-color-secondary); font-size: 12px; margin-top: 4px">
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
      title="小组成员管理" 
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
          <div style="color: var(--el-text-color-secondary); font-size: 12px; margin-top: 8px">
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
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Plus, School, Grid, Medal, FolderOpened, Star, Trophy,
  MoreFilled, View, Edit, UserFilled, Reading, Delete,
  User, Clock, Search, ArrowDown
} from '@element-plus/icons-vue'
import {
  getClubClasses, createClubClass, updateClubClass, deleteClubClass,
  getClubClassMembers, addMembersToClubClass, removeMemberFromClubClass,
  updateMemberRole, getCourseTemplates, createCourseFromTemplate,
  getGroups, createGroup, deleteGroup, getGroupMembers, addMembersToGroup, removeMemberFromGroup
} from '@/api/club'
import dayjs from 'dayjs'

// ===== 状态管理 =====
const loading = ref(false)
const classes = ref([])
const classTypeFilter = ref('')
const currentClassName = ref('')
const currentClassId = ref(null)

// 对话框
const dialogVisible = ref(false)
const dialogMode = ref('create') // create | edit
const submitting = ref(false)
const classForm = reactive({
  name: '',
  class_type: 'club',
  description: '',
  max_students: 30,
  is_open: true
})
const currentClassUuid = ref(null)

// 成员管理
const membersDialogVisible = ref(false)
const membersLoading = ref(false)
const members = ref([])
const memberSearchKeyword = ref('')
const addMemberDialogVisible = ref(false)
const memberIdsText = ref('')
const addingMembers = ref(false)

// 创建课程
const createCourseDialogVisible = ref(false)
const courseTemplates = ref([])
const courseForm = reactive({
  template_id: null,
  class_id: null,
  title: '',
  auto_enroll: true
})
const creatingCourse = ref(false)

// 小组管理
const groupLoading = ref(false)
const classGroupsDialogVisible = ref(false)
const currentClassGroups = ref([])
const groupDialogVisible = ref(false)
const submittingGroup = ref(false)
const groupForm = reactive({
  name: '',
  class_id: null,
  course_id: null,
  max_members: 6
})
const groupFormRef = ref(null)
const currentGroupUuid = ref(null)

// 小组成员管理
const groupMembersDialogVisible = ref(false)
const groupMembersLoading = ref(false)
const groupMembers = ref([])
const groupMemberSearchKeyword = ref('')
const addGroupMemberDialogVisible = ref(false)
const groupMemberIdsText = ref('')
const addingGroupMembers = ref(false)

// 表单校验
const classFormRef = ref(null)
const classRules = {
  name: [
    { required: true, message: '请输入班级名称', trigger: 'blur' },
    { min: 2, max: 50, message: '长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  class_type: [
    { required: true, message: '请选择班级类型', trigger: 'change' }
  ],
  max_students: [
    { required: true, message: '请输入最大人数', trigger: 'blur' }
  ]
}

const groupRules = {
  name: [
    { required: true, message: '请输入小组名称', trigger: 'blur' },
    { min: 2, max: 50, message: '长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  max_members: [
    { required: true, message: '请输入最大人数', trigger: 'blur' }
  ]
}

// ===== 计算属性 =====
const filteredMembers = computed(() => {
  if (!memberSearchKeyword.value) return members.value
  const keyword = memberSearchKeyword.value.toLowerCase()
  return members.value.filter(m => 
    m.name.toLowerCase().includes(keyword) || 
    m.student_number.includes(keyword)
  )
})

const filteredGroupMembers = computed(() => {
  if (!groupMemberSearchKeyword.value) return groupMembers.value
  const keyword = groupMemberSearchKeyword.value.toLowerCase()
  return groupMembers.value.filter(m => 
    m.name.toLowerCase().includes(keyword) || 
    m.student_number.includes(keyword)
  )
})

const selectedTemplate = computed(() => {
  if (!courseForm.template_id) return null
  return courseTemplates.value.find(t => t.id === courseForm.template_id)
})

// ===== 方法 =====

// 加载班级列表
const loadClasses = async () => {
  loading.value = true
  try {
    const params = {}
    if (classTypeFilter.value) {
      params.class_type = classTypeFilter.value
    }
    const res = await getClubClasses(params)
    classes.value = res.data.data || []
  } catch (error) {
    ElMessage.error(error.message || '加载班级列表失败')
  } finally {
    loading.value = false
  }
}

// 显示创建对话框
const showCreateDialog = () => {
  dialogMode.value = 'create'
  Object.assign(classForm, {
    name: '',
    class_type: 'club',
    description: '',
    max_students: 30,
    is_open: true
  })
  dialogVisible.value = true
  nextTick(() => {
    classFormRef.value?.clearValidate()
  })
}

// 提交表单
const submitClassForm = async () => {
  try {
    await classFormRef.value.validate()
  } catch {
    return
  }
  
  submitting.value = true
  try {
    if (dialogMode.value === 'create') {
      await createClubClass(classForm)
      ElMessage.success('班级创建成功')
    } else {
      await updateClubClass(currentClassUuid.value, classForm)
      ElMessage.success('班级更新成功')
    }
    dialogVisible.value = false
    loadClasses()
  } catch (error) {
    ElMessage.error(error.message || '操作失败')
  } finally {
    submitting.value = false
  }
}

// 处理班级操作
const handleClassAction = async (command, cls) => {
  currentClassUuid.value = cls.uuid
  currentClassName.value = cls.name
  currentClassId.value = cls.id
  
  switch (command) {
    case 'detail':
      // TODO: 跳转到详情页
      ElMessage.info('详情页面开发中')
      break
    case 'edit':
      dialogMode.value = 'edit'
      Object.assign(classForm, {
        name: cls.name,
        class_type: cls.class_type,
        description: cls.description,
        max_students: cls.max_students,
        is_open: cls.is_open
      })
      dialogVisible.value = true
      break
    case 'members':
      await loadMembers(cls.uuid)
      membersDialogVisible.value = true
      break
    case 'groups':
      await loadClassGroups(cls.id)
      classGroupsDialogVisible.value = true
      break
    case 'course':
      courseForm.class_id = cls.id
      courseForm.template_id = null
      courseForm.title = ''
      courseForm.auto_enroll = true
      await loadCourseTemplates()
      createCourseDialogVisible.value = true
      break
    case 'delete':
      await handleDelete(cls)
      break
  }
}

// 删除班级
const handleDelete = async (cls) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除班级"${cls.name}"吗？删除后将无法恢复。`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await deleteClubClass(cls.uuid)
    ElMessage.success('班级已删除')
    loadClasses()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '删除失败')
    }
  }
}

// 加载成员列表
const loadMembers = async (classUuid) => {
  membersLoading.value = true
  try {
    const res = await getClubClassMembers(classUuid)
    members.value = res.data.data || []
  } catch (error) {
    ElMessage.error(error.message || '加载成员列表失败')
  } finally {
    membersLoading.value = false
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
    const res = await addMembersToClubClass(currentClassUuid.value, {
      student_ids: ids,
      role: 'member'
    })
    ElMessage.success(`成功添加 ${res.data.added_count} 名成员`)
    addMemberDialogVisible.value = false
    loadMembers(currentClassUuid.value)
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
      
      await removeMemberFromClubClass(currentClassUuid.value, member.student_id)
      ElMessage.success('成员已移除')
      loadMembers(currentClassUuid.value)
    } catch (error) {
      if (error !== 'cancel') {
        ElMessage.error(error.message || '移除失败')
      }
    }
  } else {
    // 更新角色
    try {
      await updateMemberRole(currentClassUuid.value, member.student_id, { role: command })
      ElMessage.success('角色已更新')
      loadMembers(currentClassUuid.value)
    } catch (error) {
      ElMessage.error(error.message || '更新失败')
    }
  }
}

// 加载课程模板
const loadCourseTemplates = async () => {
  try {
    const res = await getCourseTemplates()
    courseTemplates.value = res.data.data || []
  } catch (error) {
    ElMessage.error(error.message || '加载课程模板失败')
  }
}

// 模板选择变化
const onTemplateChange = () => {
  if (selectedTemplate.value && !courseForm.title) {
    // 自动生成课程名称
    const currentClass = classes.value.find(c => c.id === courseForm.class_id)
    if (currentClass) {
      courseForm.title = `${currentClass.name}${selectedTemplate.value.name}`
    }
  }
}

// 提交创建课程
const submitCreateCourse = async () => {
  if (!courseForm.template_id) {
    ElMessage.warning('请选择课程模板')
    return
  }
  
  creatingCourse.value = true
  try {
    const res = await createCourseFromTemplate(courseForm)
    ElMessage.success(`课程创建成功！已为 ${res.data.enrolled_students} 名学生选课`)
    createCourseDialogVisible.value = false
    loadClasses()
  } catch (error) {
    ElMessage.error(error.message || '创建课程失败')
  } finally {
    creatingCourse.value = false
  }
}

// ===== 小组管理方法 =====

// 加载小组列表
const loadClassGroups = async (classId) => {
  groupLoading.value = true
  try {
    const params = { class_id: classId }
    const res = await getGroups(params)
    currentClassGroups.value = res.data.data || []
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
    class_id: currentClassId.value,
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
    // 刷新当前班级的小组列表
    await loadClassGroups(currentClassId.value)
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
    // 刷新当前班级的小组列表
    await loadClassGroups(currentClassId.value)
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '删除失败')
    }
  }
}

// 查看小组成员
const viewGroupMembers = async (group) => {
  currentGroupUuid.value = group.uuid
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

// 显示添加小组成员对话框
const showAddGroupMemberDialog = () => {
  groupMemberIdsText.value = ''
  addGroupMemberDialogVisible.value = true
}

// 添加小组成员
const addMembersToGroupAction = (group) => {
  currentGroupUuid.value = group.uuid
  showAddGroupMemberDialog()
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
      viewGroupMembers({ uuid: currentGroupUuid.value })
    }
    // 刷新当前班级的小组列表
    await loadClassGroups(currentClassId.value)
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
    viewGroupMembers({ uuid: currentGroupUuid.value })
    // 刷新当前班级的小组列表
    await loadClassGroups(currentClassId.value)
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '移除失败')
    }
  }
}

// ===== 工具方法 =====
const getClassTypeName = (type) => {
  const map = {
    club: '社团班',
    project: '项目班',
    interest: '兴趣班',
    competition: '竞赛班',
    regular: '普通班'
  }
  return map[type] || type
}

const getClassTypeTagType = (type) => {
  const map = {
    club: 'primary',
    project: 'success',
    interest: 'warning',
    competition: 'danger',
    regular: 'info'
  }
  return map[type] || 'info'
}

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

const getDifficultyName = (difficulty) => {
  const map = {
    beginner: '入门',
    intermediate: '中级',
    advanced: '高级'
  }
  return map[difficulty] || difficulty
}

const getDifficultyTagType = (difficulty) => {
  const map = {
    beginner: 'success',
    intermediate: 'warning',
    advanced: 'danger'
  }
  return map[difficulty] || 'info'
}

const getClassFullnessPercentage = (cls) => {
  if (cls.max_students === 0) return 0
  return Math.round((cls.current_members / cls.max_students) * 100)
}

const getProgressColor = (percentage) => {
  if (percentage < 50) return '#67c23a'
  if (percentage < 80) return '#e6a23c'
  return '#f56c6c'
}

const formatDate = (dateStr) => {
  if (!dateStr) return '-'
  return dayjs(dateStr).format('YYYY-MM-DD')
}

const formatDateTime = (dateStr) => {
  if (!dateStr) return '-'
  return dayjs(dateStr).format('YYYY-MM-DD HH:mm')
}

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

// ===== 生命周期 =====
onMounted(() => {
  loadClasses()
})
</script>

<style scoped lang="scss">
.club-classes-container {
  padding: 24px;
  background: #f5f7fa;
  min-height: calc(100vh - 60px);
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
}

.header-left {
  .page-title {
    display: flex;
    align-items: center;
    font-size: 28px;
    font-weight: 600;
    color: #303133;
    margin: 0;
    
    .title-icon {
      font-size: 32px;
      margin-right: 12px;
      color: #409eff;
    }
  }
  
  .page-subtitle {
    margin: 8px 0 0 44px;
    font-size: 14px;
    color: #909399;
  }
}

.create-btn {
  height: 44px;
  padding: 0 24px;
  font-size: 16px;
  border-radius: 8px;
}

.filter-card {
  margin-bottom: 24px;
  border-radius: 12px;
  
  :deep(.el-card__body) {
    padding: 20px;
  }
}

.filter-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  
  .class-type-filter {
    :deep(.el-radio-button__inner) {
      padding: 10px 20px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      gap: 6px;
    }
  }
  
  .filter-stats {
    :deep(.el-statistic) {
      .el-statistic__head {
        font-size: 14px;
        color: #909399;
      }
      
      .el-statistic__content {
        font-size: 24px;
        font-weight: 600;
        color: #409eff;
      }
    }
  }
}

.classes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
  gap: 24px;
}

.class-card {
  .el-card {
    border-radius: 12px;
    border: none;
    transition: all 0.3s;
    
    &:hover {
      transform: translateY(-4px);
    }
  }
  
  .card-header {
    padding: 20px;
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    border-bottom: 1px solid #f0f0f0;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    
    &.type-club {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    
    &.type-project {
      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
    }
    
    &.type-interest {
      background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
    }
    
    &.type-competition {
      background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
    }
    
    .header-left {
      flex: 1;
      
      .el-tag {
        margin-bottom: 12px;
      }
      
      .class-name {
        margin: 0;
        font-size: 20px;
        font-weight: 600;
        color: white;
      }
    }
    
    .el-button {
      color: white;
      
      &:hover {
        background: rgba(255, 255, 255, 0.2);
      }
    }
  }
  
  .card-body {
    padding: 20px;
    
    .class-description {
      margin: 0 0 16px 0;
      font-size: 14px;
      color: #606266;
      line-height: 1.6;
      min-height: 44px;
      display: -webkit-box;
      -webkit-box-orient: vertical;
      -webkit-line-clamp: 2;
      overflow: hidden;
    }
    
    .class-stats {
      display: flex;
      gap: 24px;
      margin-bottom: 16px;
      
      .stat-item {
        display: flex;
        align-items: center;
        gap: 8px;
        
        .stat-icon {
          font-size: 24px;
          color: #409eff;
        }
        
        .stat-content {
          display: flex;
          flex-direction: column;
          
          .stat-value {
            font-size: 18px;
            font-weight: 600;
            color: #303133;
            line-height: 1;
          }
          
          .stat-label {
            font-size: 12px;
            color: #909399;
            margin-top: 4px;
          }
        }
      }
    }
    
    .card-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-top: 16px;
      padding-top: 16px;
      border-top: 1px solid #f0f0f0;
      
      .create-time {
        display: flex;
        align-items: center;
        gap: 4px;
        font-size: 12px;
        color: #909399;
      }
    }
  }
}

.members-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.template-info {
  h4 {
    margin: 0 0 16px 0;
    font-size: 16px;
    color: #303133;
  }
}

:deep(.el-dropdown-menu__item) {
  display: flex;
  align-items: center;
  gap: 8px;
}

:deep(.el-progress__text) {
  display: none;
}

.groups-management {
  .groups-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    padding: 20px;
    background: #f5f7fa;
    border-radius: 8px;
    
    :deep(.el-statistic) {
      .el-statistic__head {
        font-size: 14px;
        color: #909399;
      }
      
      .el-statistic__content {
        font-size: 24px;
        font-weight: 600;
        color: #409eff;
      }
    }
  }
}
</style>
