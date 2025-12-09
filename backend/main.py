from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette import status
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.middleware.base import BaseHTTPMiddleware
import time

from app.api.endpoints import projects, admin_auth, admin_courses, admin_units, admin_resources, student_courses, student_auth, admin_tasks, student_tasks, admin_users, enrollments, classes_groups, learning_progress, assessments, assessment_templates, datasets, ethics, experts, social_activities, admin_outputs, portfolios, school_courses, video_play, video_progress
from app.core.response import error_response
from app.core.logging_config import setup_logging, get_logger
from app.db.session import engine
from app.models import pbl, admin  # Import models to register them

# 初始化日志系统
setup_logging(level="DEBUG")
logger = get_logger(__name__)

logger.info("正在启动 CodeHubot PBL System API...")

# 数据库初始化检查
# 注意：生产环境应该使用手动执行 SQL 脚本进行数据库初始化，而不是使用 create_all
logger.info(f"使用 MySQL 数据库: {engine.url.drivername}://{engine.url.host}/{engine.url.database}")
logger.info("请确保已手动执行 SQL/init_database.sql 初始化数据库")
logger.info("数据库表结构更新请使用 SQL/update/ 目录下的脚本")

app = FastAPI(
    title="CodeHubot PBL System API",
    description="API for Project Based Learning System",
    version="1.0.0"
)

logger.info("FastAPI 应用初始化完成")

# Request logging middleware
class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        # 记录请求信息
        logger.info(f"收到请求: {request.method} {request.url.path}")
        logger.debug(f"请求头: {dict(request.headers)}")
        
        # 处理请求
        response = await call_next(request)
        
        # 计算处理时间
        process_time = time.time() - start_time
        
        # 记录响应信息
        logger.info(f"响应: {request.method} {request.url.path} - 状态码: {response.status_code} - 耗时: {process_time:.3f}秒")
        
        return response

app.add_middleware(RequestLoggingMiddleware)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logger.info("CORS 中间件配置完成")

# Include routers
# Student routers
app.include_router(student_auth.router, prefix="/api/v1/student/auth", tags=["student-auth"])
app.include_router(student_courses.router, prefix="/api/v1/student", tags=["student"])
app.include_router(student_tasks.router, prefix="/api/v1/student", tags=["student-tasks"])
app.include_router(enrollments.router, prefix="/api/v1/student/enrollments", tags=["enrollments"])
app.include_router(learning_progress.router, prefix="/api/v1/student/learning-progress", tags=["learning-progress"])

# Admin routers
app.include_router(admin_auth.router, prefix="/api/v1/admin/auth", tags=["admin-auth"])
app.include_router(admin_courses.router, prefix="/api/v1/admin/courses", tags=["admin-courses"])
app.include_router(admin_units.router, prefix="/api/v1/admin/units", tags=["admin-units"])
app.include_router(admin_resources.router, prefix="/api/v1/admin/resources", tags=["admin-resources"])
app.include_router(admin_tasks.router, prefix="/api/v1/admin/tasks", tags=["admin-tasks"])
app.include_router(admin_users.router, prefix="/api/v1/admin/users", tags=["admin-users"])
app.include_router(admin_outputs.router, prefix="/api/v1", tags=["admin-outputs"])
app.include_router(classes_groups.router, prefix="/api/v1/admin/classes-groups", tags=["classes-groups"])
app.include_router(school_courses.router, prefix="/api/v1/admin/school-courses", tags=["school-courses"])
app.include_router(enrollments.router, prefix="/api/v1/admin/enrollments", tags=["admin-enrollments"])
app.include_router(learning_progress.router, prefix="/api/v1/admin/learning-progress", tags=["admin-learning-progress"])

# PBL routers
app.include_router(projects.router, prefix="/api/v1/pbl", tags=["pbl-projects"])
app.include_router(assessments.router, prefix="/api/v1/pbl", tags=["pbl-assessments"])
app.include_router(assessment_templates.router, prefix="/api/v1/pbl", tags=["pbl-assessment-templates"])
app.include_router(datasets.router, prefix="/api/v1/pbl", tags=["pbl-datasets"])
app.include_router(ethics.router, prefix="/api/v1/pbl", tags=["pbl-ethics"])
app.include_router(experts.router, prefix="/api/v1/pbl", tags=["pbl-experts"])
app.include_router(social_activities.router, prefix="/api/v1/pbl", tags=["pbl-social-activities"])
app.include_router(portfolios.router, prefix="/api/v1/pbl", tags=["pbl-portfolios"])

# Video play router (accessible by both students and admins)
app.include_router(video_play.router, prefix="/api/v1/video", tags=["video-play"])
app.include_router(video_progress.router, prefix="/api/v1/video/progress", tags=["video-progress"])

logger.info("所有路由注册完成")

@app.get("/")
async def root():
    return {"message": "Welcome to CodeHubot PBL System API"}


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    # Standardize HTTP errors
    logger.warning(f"HTTP异常: {exc.status_code} - {exc.detail} - 路径: {request.url.path}")
    return JSONResponse(
        status_code=exc.status_code,
        content={"code": exc.status_code, "message": exc.detail or "error", "data": None},
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    logger.warning(f"请求验证错误 - 路径: {request.url.path} - 错误: {exc.errors()}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "code": status.HTTP_422_UNPROCESSABLE_ENTITY,
            "message": "Validation error",
            "data": exc.errors(),
        },
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.error(f"未处理的异常 - 路径: {request.url.path} - 异常: {str(exc)}", exc_info=True)
    return error_response(
        message="Internal server error",
        code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )
