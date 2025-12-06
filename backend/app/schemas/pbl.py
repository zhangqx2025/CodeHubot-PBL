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
