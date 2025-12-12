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
                  <el-dropdown-item command="courses">
                    <el-icon><Reading /></el-icon>
                    课程管理
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

    <!-- 创建班级对话框 -->
    <el-dialog 
      v-model="dialogVisible" 
      title="创建班级"
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
      </el-form>
      
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitClassForm" :loading="submitting">
          创建
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Plus, School, Grid, Medal, FolderOpened, Star, Trophy,
  MoreFilled, View, Edit, UserFilled, Reading, Delete,
  User, Clock
} from '@element-plus/icons-vue'
import {
  getClubClasses, createClubClass, deleteClubClass
} from '@/api/club'
import dayjs from 'dayjs'

const router = useRouter()

// ===== 状态管理 =====
const loading = ref(false)
const classes = ref([])
const classTypeFilter = ref('')
const currentClassName = ref('')
const currentClassId = ref(null)
const currentClassUuid = ref(null)

// 创建班级对话框
const dialogVisible = ref(false)
const submitting = ref(false)
const classForm = reactive({
  name: '',
  class_type: 'club',
  description: '',
  max_students: 30,
  is_open: true
})

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

// 提交创建班级表单
const submitClassForm = async () => {
  try {
    await classFormRef.value.validate()
  } catch {
    return
  }
  
  submitting.value = true
  try {
    await createClubClass(classForm)
    ElMessage.success('班级创建成功')
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
      // 跳转到详情页
      router.push(`/admin/classes/${cls.uuid}`)
      break
    case 'edit':
      // 跳转到编辑页
      router.push(`/admin/classes/${cls.uuid}/edit`)
      break
    case 'members':
      // 跳转到成员管理页
      router.push(`/admin/classes/${cls.uuid}/members`)
      break
    case 'courses':
      // 跳转到课程管理页
      router.push(`/admin/classes/${cls.uuid}/courses`)
      break
    case 'groups':
      // 跳转到小组管理页
      router.push(`/admin/classes/${cls.uuid}/groups`)
      break
    case 'course':
      // 跳转到创建课程页
      router.push(`/admin/classes/${cls.uuid}/create-course`)
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

:deep(.el-dropdown-menu__item) {
  display: flex;
  align-items: center;
  gap: 8px;
}
</style>
