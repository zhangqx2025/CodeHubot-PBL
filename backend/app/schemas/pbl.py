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
        orm_mode = True

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
        orm_mode = True

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
    learning_guide: Optional[dict] = None

class UnitCreate(UnitBase):
    course_id: int

class UnitUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    order: Optional[int] = None
    status: Optional[str] = None
    learning_guide: Optional[dict] = None

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
    unit_id: int

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
