from sqlalchemy import Column, Integer, String, Text, Enum, ForeignKey, TIMESTAMP, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
from ..db.base_class import Base

def generate_uuid():
    return str(uuid.uuid4())

class PBLCourse(Base):
    __tablename__ = "pbl_courses"

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    cover_image = Column(String(255))
    duration = Column(String(50))
    difficulty = Column(Enum('beginner', 'intermediate', 'advanced'), default='beginner')
    status = Column(Enum('draft', 'published', 'archived'), default='draft')
    creator_id = Column(Integer)  # Foreign Key to aiot_core_users
    school_id = Column(Integer)   # Foreign Key to aiot_schools
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

    units = relationship("PBLUnit", back_populates="course", cascade="all, delete-orphan")
    projects = relationship("PBLProject", back_populates="course")


class PBLUnit(Base):
    __tablename__ = "pbl_units"

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    course_id = Column(Integer, ForeignKey("pbl_courses.id"), nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    order = Column(Integer, default=0)
    status = Column(Enum('locked', 'available', 'completed'), default='locked')
    learning_guide = Column(JSON)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

    course = relationship("PBLCourse", back_populates="units")
    resources = relationship("PBLResource", back_populates="unit", cascade="all, delete-orphan")
    tasks = relationship("PBLTask", back_populates="unit", cascade="all, delete-orphan")


class PBLResource(Base):
    __tablename__ = "pbl_resources"

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    unit_id = Column(Integer, ForeignKey("pbl_units.id"), nullable=False)
    type = Column(Enum('video', 'document', 'link'), nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    url = Column(String(500))
    content = Column(Text) # longtext
    duration = Column(Integer)
    order = Column(Integer, default=0)
    video_id = Column(String(100))
    video_cover_url = Column(String(255))
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

    unit = relationship("PBLUnit", back_populates="resources")


class PBLTask(Base):
    __tablename__ = "pbl_tasks"

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    unit_id = Column(Integer, ForeignKey("pbl_units.id"), nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    type = Column(Enum('analysis', 'coding', 'design', 'deployment'), default='analysis')
    difficulty = Column(Enum('easy', 'medium', 'hard'), default='easy')
    estimated_time = Column(String(50))
    requirements = Column(JSON)
    prerequisites = Column(JSON)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

    unit = relationship("PBLUnit", back_populates="tasks")
    progress = relationship("PBLTaskProgress", back_populates="task")


class PBLProject(Base):
    __tablename__ = "pbl_projects"

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    group_id = Column(Integer) # Foreign Key to aiot_course_groups
    course_id = Column(Integer, ForeignKey("pbl_courses.id"), nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    status = Column(Enum('planning', 'in-progress', 'review', 'completed'), default='planning')
    progress = Column(Integer, default=0)
    repo_url = Column(String(500))
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

    course = relationship("PBLCourse", back_populates="projects")


class PBLTaskProgress(Base):
    __tablename__ = "pbl_task_progress"

    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("pbl_tasks.id"), nullable=False)
    user_id = Column(Integer, nullable=False) # Foreign Key to aiot_core_users
    status = Column(Enum('pending', 'in-progress', 'blocked', 'review', 'completed'), default='pending')
    progress = Column(Integer, default=0)
    submission = Column(JSON)
    score = Column(Integer)
    feedback = Column(Text)
    graded_by = Column(Integer) # Foreign Key to aiot_core_users
    graded_at = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

    task = relationship("PBLTask", back_populates="progress")
