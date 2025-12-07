from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette import status
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.middleware.base import BaseHTTPMiddleware
import time

from app.api.endpoints import projects, admin_auth, admin_courses, admin_units, admin_resources, student_courses, student_auth
from app.core.response import error_response
from app.core.logging_config import setup_logging, get_logger
from app.db.session import engine
from app.models import pbl, admin  # Import models to register them

# 初始化日志系统
setup_logging(level="DEBUG")
logger = get_logger(__name__)

logger.info("正在启动 CodeHubot PBL System API...")

# Create tables (for development/sqlite)
# All models use the same Base, so only need to create once
# 注意：生产环境使用 MySQL 时，应该使用 Alembic 进行数据库迁移，而不是直接 create_all
if "sqlite" in str(engine.url):
    logger.warning("检测到使用 SQLite 数据库，这仅适用于开发环境")
    pbl.Base.metadata.create_all(bind=engine)
    logger.info("SQLite 数据库表初始化完成")
else:
    logger.info(f"使用生产数据库: {engine.url.drivername}://{engine.url.host}/{engine.url.database}")
    # 生产环境不自动创建表，需要手动执行 SQL 脚本
    logger.info("生产环境请手动执行 SQL/init_database.sql 初始化数据库")

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
app.include_router(projects.router, prefix="/api/v1/projects", tags=["projects"])

# Student routers
app.include_router(student_auth.router, prefix="/api/v1/student/auth", tags=["student-auth"])
app.include_router(student_courses.router, prefix="/api/v1/student", tags=["student"])

# Admin routers
app.include_router(admin_auth.router, prefix="/api/v1/admin/auth", tags=["admin-auth"])
app.include_router(admin_courses.router, prefix="/api/v1/admin/courses", tags=["admin-courses"])
app.include_router(admin_units.router, prefix="/api/v1/admin/units", tags=["admin-units"])
app.include_router(admin_resources.router, prefix="/api/v1/admin/resources", tags=["admin-resources"])

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
