from sqlalchemy import Column, Integer, String, Text, Enum, ForeignKey, TIMESTAMP, JSON, DECIMAL, BigInteger
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
    max_views = Column(Integer, default=None, comment='最大观看次数（NULL表示不限制，0表示禁止观看，大于0表示限制次数）')
    valid_from = Column(TIMESTAMP, default=None, comment='全局有效开始时间（NULL表示立即生效）')
    valid_until = Column(TIMESTAMP, default=None, comment='全局有效结束时间（NULL表示永久有效）')
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


class PBLSchoolCourse(Base):
    """学校课程分配表：平台管理员为学校分配课程"""
    __tablename__ = "pbl_school_courses"

    id = Column(BigInteger, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    school_id = Column(Integer, nullable=False)  # Foreign Key to aiot_schools
    course_id = Column(BigInteger, ForeignKey("pbl_courses.id"), nullable=False)
    assigned_by = Column(Integer)  # Foreign Key to aiot_core_users (平台管理员)
    assigned_at = Column(TIMESTAMP, server_default=func.now())
    status = Column(Enum('active', 'inactive', 'archived'), default='active')
    start_date = Column(TIMESTAMP)
    end_date = Column(TIMESTAMP)
    max_students = Column(Integer)  # NULL表示无限制
    current_students = Column(Integer, default=0)
    remarks = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLCourseEnrollment(Base):
    """学生选课表：学校管理员为学生分配课程"""
    __tablename__ = "pbl_course_enrollments"

    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("pbl_courses.id"), nullable=False)
    user_id = Column(Integer, nullable=False) # Foreign Key to aiot_core_users
    enrollment_status = Column(Enum('enrolled', 'dropped', 'completed'), default='enrolled')
    enrolled_at = Column(TIMESTAMP)
    dropped_at = Column(TIMESTAMP)
    completed_at = Column(TIMESTAMP)
    progress = Column(Integer, default=0)
    final_score = Column(Integer)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLProjectOutput(Base):
    __tablename__ = "pbl_project_outputs"

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    project_id = Column(Integer, ForeignKey("pbl_projects.id"), nullable=False)
    task_id = Column(Integer, ForeignKey("pbl_tasks.id"))
    user_id = Column(Integer, nullable=False) # Foreign Key to aiot_core_users
    group_id = Column(Integer) # Foreign Key to aiot_course_groups
    output_type = Column(Enum('report', 'code', 'design', 'video', 'presentation', 'model', 'dataset', 'other'), nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    file_url = Column(String(500))
    file_size = Column(Integer)
    file_type = Column(String(50))
    repo_url = Column(String(500))
    demo_url = Column(String(500))
    thumbnail = Column(String(500))
    meta_data = Column(JSON)
    is_public = Column(Integer, default=0)
    view_count = Column(Integer, default=0)
    like_count = Column(Integer, default=0)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLClass(Base):
    __tablename__ = "pbl_classes"

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    school_id = Column(Integer, nullable=False)
    name = Column(String(100), nullable=False)
    grade = Column(String(50))
    academic_year = Column(String(20))
    class_teacher_id = Column(Integer)
    max_students = Column(Integer, default=50)
    is_active = Column(Integer, default=1)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLGroup(Base):
    __tablename__ = "pbl_groups"

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    class_id = Column(Integer, ForeignKey("pbl_classes.id"))
    course_id = Column(Integer, ForeignKey("pbl_courses.id"))
    name = Column(String(100), nullable=False)
    description = Column(Text)
    leader_id = Column(Integer)
    max_members = Column(Integer, default=6)
    is_active = Column(Integer, default=1)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLGroupMember(Base):
    __tablename__ = "pbl_group_members"

    id = Column(Integer, primary_key=True, index=True)
    group_id = Column(Integer, ForeignKey("pbl_groups.id"), nullable=False)
    user_id = Column(Integer, nullable=False)
    role = Column(Enum('member', 'leader', 'deputy_leader'), default='member')
    joined_at = Column(TIMESTAMP, server_default=func.now())
    is_active = Column(Integer, default=1)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLAssessment(Base):
    __tablename__ = "pbl_assessments"

    id = Column(BigInteger, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    assessor_id = Column(Integer, nullable=False)
    assessor_role = Column(Enum('teacher', 'student', 'expert', 'self'), nullable=False)
    target_type = Column(Enum('project', 'task', 'output', 'student'), nullable=False)
    target_id = Column(BigInteger, nullable=False)
    student_id = Column(Integer, nullable=False)
    group_id = Column(Integer)
    assessment_type = Column(Enum('formative', 'summative'), default='formative')
    dimensions = Column(JSON, nullable=False)
    total_score = Column(DECIMAL(5, 2))
    max_score = Column(DECIMAL(5, 2), default=100.00)
    comments = Column(Text)
    strengths = Column(Text)
    improvements = Column(Text)
    tags = Column(JSON)
    is_public = Column(Integer, default=0)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLAssessmentTemplate(Base):
    __tablename__ = "pbl_assessment_templates"

    id = Column(BigInteger, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text)
    applicable_to = Column(Enum('project', 'task', 'output'), nullable=False)
    grade_level = Column(String(50))
    dimensions = Column(JSON, nullable=False)
    created_by = Column(Integer)
    is_system = Column(Integer, default=0)
    is_active = Column(Integer, default=1)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLDataset(Base):
    __tablename__ = "pbl_datasets"

    id = Column(BigInteger, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text)
    data_type = Column(Enum('image', 'text', 'audio', 'video', 'tabular', 'mixed'), nullable=False)
    category = Column(String(50))
    file_url = Column(String(500))
    file_size = Column(BigInteger)
    sample_count = Column(Integer)
    class_count = Column(Integer)
    classes = Column(JSON)
    is_labeled = Column(Integer, default=0)
    label_format = Column(String(50))
    split_ratio = Column(JSON)
    grade_level = Column(String(50))
    applicable_projects = Column(JSON)
    source = Column(String(200))
    license = Column(String(100))
    preview_images = Column(JSON)
    download_count = Column(Integer, default=0)
    creator_id = Column(Integer)
    school_id = Column(Integer)
    is_public = Column(Integer, default=1)
    quality_score = Column(DECIMAL(3, 2))
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLEthicsCase(Base):
    __tablename__ = "pbl_ethics_cases"

    id = Column(BigInteger, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    content = Column(Text)
    grade_level = Column(String(50))
    ethics_topics = Column(JSON, nullable=False)
    difficulty = Column(Enum('basic', 'intermediate', 'advanced'), default='basic')
    discussion_questions = Column(JSON)
    reference_links = Column(JSON)
    cover_image = Column(String(255))
    author = Column(String(100))
    source = Column(String(200))
    is_published = Column(Integer, default=1)
    view_count = Column(Integer, default=0)
    like_count = Column(Integer, default=0)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLEthicsActivity(Base):
    __tablename__ = "pbl_ethics_activities"

    id = Column(BigInteger, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    case_id = Column(BigInteger, ForeignKey("pbl_ethics_cases.id"))
    course_id = Column(BigInteger, ForeignKey("pbl_courses.id"))
    unit_id = Column(BigInteger, ForeignKey("pbl_units.id"))
    activity_type = Column(Enum('debate', 'case_analysis', 'role_play', 'discussion', 'reflection'), nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    participants = Column(JSON)
    group_id = Column(Integer)
    facilitator_id = Column(Integer)
    status = Column(Enum('planned', 'ongoing', 'completed', 'cancelled'), default='planned')
    discussion_records = Column(JSON)
    conclusions = Column(Text)
    reflections = Column(JSON)
    scheduled_at = Column(TIMESTAMP)
    completed_at = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLExternalExpert(Base):
    __tablename__ = "pbl_external_experts"

    id = Column(BigInteger, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    name = Column(String(100), nullable=False)
    organization = Column(String(200))
    title = Column(String(100))
    expertise_areas = Column(JSON)
    bio = Column(Text)
    email = Column(String(255))
    phone = Column(String(20))
    avatar = Column(String(255))
    is_active = Column(Integer, default=1)
    participated_projects = Column(Integer, default=0)
    avg_rating = Column(DECIMAL(3, 2))
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLSocialActivity(Base):
    __tablename__ = "pbl_social_activities"

    id = Column(BigInteger, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    activity_type = Column(Enum('company_visit', 'lab_tour', 'workshop', 'competition', 'exhibition', 'volunteer', 'lecture'), nullable=False)
    organizer = Column(String(200))
    partner_organization = Column(String(200))
    location = Column(String(500))
    scheduled_at = Column(TIMESTAMP)
    duration = Column(Integer)
    max_participants = Column(Integer)
    current_participants = Column(Integer, default=0)
    participants = Column(JSON)
    facilitators = Column(JSON)
    status = Column(Enum('planned', 'registration', 'ongoing', 'completed', 'cancelled'), default='planned')
    photos = Column(JSON)
    summary = Column(Text)
    feedback = Column(JSON)
    created_by = Column(Integer)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLStudentPortfolio(Base):
    __tablename__ = "pbl_student_portfolios"

    id = Column(BigInteger, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    student_id = Column(Integer, nullable=False)
    school_year = Column(String(20), nullable=False)
    grade_level = Column(String(50), nullable=False)
    completed_projects = Column(JSON)
    achievements = Column(JSON)
    skill_assessment = Column(JSON)
    growth_trajectory = Column(JSON)
    highlights = Column(JSON)
    total_learning_hours = Column(Integer, default=0)
    projects_count = Column(Integer, default=0)
    avg_score = Column(DECIMAL(5, 2))
    teacher_comments = Column(Text)
    self_reflection = Column(Text)
    parent_feedback = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLAchievement(Base):
    __tablename__ = "pbl_achievements"

    id = Column(BigInteger, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text)
    icon = Column(String(255))
    condition = Column(JSON)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLUserAchievement(Base):
    __tablename__ = "pbl_user_achievements"

    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    achievement_id = Column(BigInteger, ForeignKey("pbl_achievements.id"), nullable=False)
    unlocked_at = Column(TIMESTAMP, server_default=func.now())
    created_at = Column(TIMESTAMP, server_default=func.now())


class PBLLearningProgress(Base):
    __tablename__ = "pbl_learning_progress"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)  # Foreign Key to aiot_core_users
    course_id = Column(BigInteger, ForeignKey("pbl_courses.id"), nullable=False)
    unit_id = Column(BigInteger, ForeignKey("pbl_units.id"))
    resource_id = Column(BigInteger, ForeignKey("pbl_resources.id"))
    task_id = Column(BigInteger, ForeignKey("pbl_tasks.id"))
    progress_type = Column(Enum('resource_view', 'video_watch', 'document_read', 'task_submit', 'unit_complete'), nullable=False)
    progress_value = Column(Integer, default=0)
    status = Column(Enum('in_progress', 'completed'), default='in_progress')
    completed_at = Column(TIMESTAMP)
    time_spent = Column(Integer, default=0)
    meta_data = Column(JSON)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLVideoWatchRecord(Base):
    """视频观看记录表"""
    __tablename__ = "pbl_video_watch_records"

    id = Column(BigInteger, primary_key=True, index=True)
    resource_id = Column(BigInteger, ForeignKey("pbl_resources.id"), nullable=False)
    user_id = Column(Integer, nullable=False)  # Foreign Key to aiot_core_users
    watch_time = Column(TIMESTAMP, server_default=func.now(), nullable=False)
    duration = Column(Integer, default=0, comment='观看时长（秒）')
    completed = Column(Integer, default=0, comment='是否观看完成')
    ip_address = Column(String(45))
    user_agent = Column(String(500))
    created_at = Column(TIMESTAMP, server_default=func.now())


class PBLVideoUserPermission(Base):
    """视频用户权限表 - 个性化观看次数和有效期设置"""
    __tablename__ = "pbl_video_user_permissions"

    id = Column(BigInteger, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    resource_id = Column(BigInteger, ForeignKey("pbl_resources.id"), nullable=False)
    user_id = Column(Integer, nullable=False)  # Foreign Key to aiot_core_users
    max_views = Column(Integer, default=None, comment='该学生对该视频的最大观看次数')
    valid_from = Column(TIMESTAMP, default=None, comment='有效开始时间')
    valid_until = Column(TIMESTAMP, default=None, comment='有效结束时间')
    reason = Column(String(500), comment='设置原因')
    created_by = Column(Integer, nullable=False, comment='创建者ID')
    is_active = Column(Integer, default=1, comment='是否启用')
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLVideoPlayProgress(Base):
    """视频播放进度追踪表"""
    __tablename__ = "pbl_video_play_progress"

    id = Column(BigInteger, primary_key=True, index=True)
    uuid = Column(String(36), unique=True, default=generate_uuid, nullable=False)
    resource_id = Column(BigInteger, ForeignKey("pbl_resources.id"), nullable=False)
    user_id = Column(Integer, nullable=False)  # Foreign Key to aiot_core_users
    session_id = Column(String(64), nullable=False, comment='播放会话ID')
    
    # 播放进度信息
    current_position = Column(Integer, default=0, comment='当前播放位置（秒）')
    duration = Column(Integer, default=0, comment='视频总时长（秒）')
    play_duration = Column(Integer, default=0, comment='本次会话累计播放时长（秒）')
    real_watch_duration = Column(Integer, default=0, comment='真实观看时长（秒）')
    
    # 播放状态
    status = Column(String(20), default='playing', comment='播放状态')
    last_event = Column(String(50), comment='最后一次事件')
    last_event_time = Column(TIMESTAMP, comment='最后一次事件时间')
    
    # 播放行为统计
    seek_count = Column(Integer, default=0, comment='拖动次数')
    pause_count = Column(Integer, default=0, comment='暂停次数')
    pause_duration = Column(Integer, default=0, comment='累计暂停时长（秒）')
    replay_count = Column(Integer, default=0, comment='重播次数')
    
    # 播放范围
    watched_ranges = Column(Text, comment='已观看的时间段（JSON数组）')
    
    # 完成度
    completion_rate = Column(DECIMAL(5, 2), default=0.00, comment='完成度（百分比）')
    is_completed = Column(Integer, default=0, comment='是否观看完成')
    
    # 客户端信息
    ip_address = Column(String(45), comment='客户端IP地址')
    user_agent = Column(String(500), comment='用户代理')
    device_type = Column(String(50), comment='设备类型')
    
    # 时间信息
    start_time = Column(TIMESTAMP, server_default=func.now(), nullable=False, comment='开始播放时间')
    end_time = Column(TIMESTAMP, comment='结束播放时间')
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class PBLVideoPlayEvent(Base):
    """视频播放事件表"""
    __tablename__ = "pbl_video_play_events"

    id = Column(BigInteger, primary_key=True, index=True)
    session_id = Column(String(64), nullable=False, comment='播放会话ID')
    resource_id = Column(BigInteger, ForeignKey("pbl_resources.id"), nullable=False)
    user_id = Column(Integer, nullable=False)  # Foreign Key to aiot_core_users
    event_type = Column(String(50), nullable=False, comment='事件类型')
    event_data = Column(Text, comment='事件数据（JSON格式）')
    position = Column(Integer, default=0, comment='事件发生时的播放位置（秒）')
    timestamp = Column(TIMESTAMP, server_default=func.now(), nullable=False)
