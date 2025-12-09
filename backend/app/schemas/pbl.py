from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime
from enum import Enum

class ProjectStatus(str, Enum):
    planning = 'planning'
    in_progress = 'in-progress'
    review = 'review'
    completed = 'completed'

# --- Course Schemas ---
class CourseBase(BaseModel):
    title: str
    description: Optional[str] = None
    cover_image: Optional[str] = None
    duration: Optional[str] = None
    difficulty: Optional[str] = None

class Course(CourseBase):
    id: int
    uuid: str
    
    class Config:
        from_attributes = True

# --- Project Schemas ---

class ProjectBase(BaseModel):
    title: str
    description: Optional[str] = None
    course_id: int
    group_id: Optional[int] = None
    repo_url: Optional[str] = None
    status: Optional[ProjectStatus] = ProjectStatus.planning
    progress: Optional[int] = 0

class ProjectCreate(ProjectBase):
    pass

class ProjectUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[ProjectStatus] = None
    progress: Optional[int] = None
    repo_url: Optional[str] = None

class ProjectInDBBase(ProjectBase):
    id: int
    uuid: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class Project(ProjectInDBBase):
    course: Optional[Course] = None

class ProjectList(BaseModel):
    total: int
    items: List[Project]

# --- Unit Schemas ---
class UnitBase(BaseModel):
    title: str
    description: Optional[str] = None
    order: Optional[int] = 0
    status: Optional[str] = 'locked'
    learning_guide: Optional[Any] = None  # 支持 dict 或 list 类型

class UnitCreate(UnitBase):
    course_uuid: str

class UnitUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    order: Optional[int] = None
    status: Optional[str] = None
    learning_guide: Optional[Any] = None  # 支持 dict 或 list 类型

class Unit(UnitBase):
    id: int
    uuid: str
    course_id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# --- Resource Schemas ---
class ResourceBase(BaseModel):
    type: str  # 'video', 'document', 'link'
    title: str
    description: Optional[str] = None
    url: Optional[str] = None
    content: Optional[str] = None
    duration: Optional[int] = None
    order: Optional[int] = 0
    video_id: Optional[str] = None
    video_cover_url: Optional[str] = None

class ResourceCreate(ResourceBase):
    unit_id: Optional[int] = None
    unit_uuid: Optional[str] = None

class ResourceUpdate(BaseModel):
    type: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    url: Optional[str] = None
    content: Optional[str] = None
    duration: Optional[int] = None
    order: Optional[int] = None
    video_id: Optional[str] = None
    video_cover_url: Optional[str] = None

class Resource(ResourceBase):
    id: int
    uuid: str
    unit_id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# --- Task Schemas ---
class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    type: Optional[str] = 'analysis'  # 'analysis', 'coding', 'design', 'deployment'
    difficulty: Optional[str] = 'easy'  # 'easy', 'medium', 'hard'
    estimated_time: Optional[str] = None
    order: Optional[int] = 0  # 顺序（与资源统一排序）
    requirements: Optional[Any] = None  # 支持 dict 或 list 类型
    prerequisites: Optional[Any] = None  # 支持 dict 或 list 类型

class TaskCreate(TaskBase):
    unit_id: int

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    type: Optional[str] = None
    difficulty: Optional[str] = None
    estimated_time: Optional[str] = None
    order: Optional[int] = None  # 顺序（与资源统一排序）
    requirements: Optional[Any] = None  # 支持 dict 或 list 类型
    prerequisites: Optional[Any] = None  # 支持 dict 或 list 类型

class Task(TaskBase):
    id: int
    uuid: str
    unit_id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# --- School Course Schemas ---
class SchoolCourseStatus(str, Enum):
    """学校课程状态"""
    active = 'active'
    inactive = 'inactive'
    archived = 'archived'

class SchoolCourseBase(BaseModel):
    """学校课程基础模型"""
    school_id: int
    course_id: int
    status: Optional[SchoolCourseStatus] = SchoolCourseStatus.active
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    max_students: Optional[int] = None
    remarks: Optional[str] = None

class SchoolCourseCreate(SchoolCourseBase):
    """创建学校课程分配"""
    pass

class SchoolCourseUpdate(BaseModel):
    """更新学校课程分配"""
    status: Optional[SchoolCourseStatus] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    max_students: Optional[int] = None
    remarks: Optional[str] = None

class SchoolCourse(SchoolCourseBase):
    """学校课程返回模型"""
    id: int
    uuid: str
    assigned_by: Optional[int] = None
    assigned_at: datetime
    current_students: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class SchoolCourseWithDetails(SchoolCourse):
    """学校课程详情（包含课程信息）"""
    course: Optional[Course] = None

# --- Course Enrollment Schemas ---
class EnrollmentStatus(str, Enum):
    """学生选课状态"""
    enrolled = 'enrolled'
    dropped = 'dropped'
    completed = 'completed'

class CourseEnrollmentBase(BaseModel):
    """学生选课基础模型"""
    course_id: int
    user_id: int
    enrollment_status: Optional[EnrollmentStatus] = EnrollmentStatus.enrolled

class CourseEnrollmentCreate(CourseEnrollmentBase):
    """创建学生选课"""
    pass

class CourseEnrollmentUpdate(BaseModel):
    """更新学生选课"""
    enrollment_status: Optional[EnrollmentStatus] = None
    progress: Optional[int] = None
    final_score: Optional[int] = None

class CourseEnrollment(CourseEnrollmentBase):
    """学生选课返回模型"""
    id: int
    enrolled_at: Optional[datetime] = None
    dropped_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    progress: int
    final_score: Optional[int] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class CourseEnrollmentWithDetails(CourseEnrollment):
    """学生选课详情（包含课程信息）"""
    course: Optional[Course] = None
