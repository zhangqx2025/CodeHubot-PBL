"""
PBL项目管理API端点
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, File, UploadFile, status
from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.core.deps import get_db, get_current_user, get_current_user_flexible
from app.models.pbl import PBLProject, PBLProjectOutput, PBLCourse
from app.models.admin import User

router = APIRouter()


# ==================== 项目管理 ====================

@router.get("/projects")
async def get_projects(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    course_id: Optional[int] = None,
    status: Optional[str] = None,
    group_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_flexible)
):
    """
    获取项目列表
    """
    query = db.query(PBLProject)
    
    if course_id:
        query = query.filter(PBLProject.course_id == course_id)
    if status:
        query = query.filter(PBLProject.status == status)
    if group_id:
        query = query.filter(PBLProject.group_id == group_id)
    
    total = query.count()
    projects = query.offset(skip).limit(limit).all()
    
    items = []
    for project in projects:
        course = db.query(PBLCourse).filter(PBLCourse.id == project.course_id).first()
        items.append({
            "id": project.id,
            "uuid": project.uuid,
            "title": project.title,
            "description": project.description,
            "course_id": project.course_id,
            "course_title": course.title if course else None,
            "group_id": project.group_id,
            "status": project.status,
            "progress": project.progress,
            "repo_url": project.repo_url,
            "created_at": project.created_at.isoformat() if project.created_at else None,
            "updated_at": project.updated_at.isoformat() if project.updated_at else None
        })
    
    return {
        "items": items,
        "total": total
    }


@router.get("/my-projects")
async def get_my_projects(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取我的项目列表
    """
    query = db.query(PBLProject)
    
    # 根据用户的group_id查询项目
    if current_user.group_id:
        query = query.filter(PBLProject.group_id == current_user.group_id)
    else:
        # 如果用户没有小组,返回空列表
        return {
            "items": [],
            "total": 0
        }
    
    if status:
        query = query.filter(PBLProject.status == status)
    
    total = query.count()
    projects = query.offset(skip).limit(limit).all()
    
    items = []
    for project in projects:
        course = db.query(PBLCourse).filter(PBLCourse.id == project.course_id).first()
        items.append({
            "id": project.id,
            "uuid": project.uuid,
            "title": project.title,
            "description": project.description,
            "course_id": project.course_id,
            "course_title": course.title if course else None,
            "group_id": project.group_id,
            "status": project.status,
            "progress": project.progress,
            "repo_url": project.repo_url,
            "created_at": project.created_at.isoformat() if project.created_at else None,
            "updated_at": project.updated_at.isoformat() if project.updated_at else None
        })
    
    return {
        "items": items,
        "total": total
    }


@router.get("/projects/{project_uuid}")
async def get_project_detail(
    project_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_flexible)
):
    """
    获取项目详情
    """
    project = db.query(PBLProject).filter(PBLProject.uuid == project_uuid).first()
    
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="项目不存在")
    
    course = db.query(PBLCourse).filter(PBLCourse.id == project.course_id).first()
    
    # 获取项目成果
    outputs = db.query(PBLProjectOutput).filter(PBLProjectOutput.project_id == project.id).all()
    output_list = [{
        "id": output.id,
        "uuid": output.uuid,
        "title": output.title,
        "output_type": output.output_type,
        "file_url": output.file_url,
        "thumbnail": output.thumbnail,
        "view_count": output.view_count,
        "like_count": output.like_count,
        "created_at": output.created_at.isoformat() if output.created_at else None
    } for output in outputs]
    
    return {
        "id": project.id,
        "uuid": project.uuid,
        "title": project.title,
        "description": project.description,
        "course_id": project.course_id,
        "course_title": course.title if course else None,
        "group_id": project.group_id,
        "status": project.status,
        "progress": project.progress,
        "repo_url": project.repo_url,
        "outputs": output_list,
        "created_at": project.created_at.isoformat() if project.created_at else None,
        "updated_at": project.updated_at.isoformat() if project.updated_at else None
    }


@router.post("/projects")
async def create_project(
    project_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    创建项目
    """
    # 检查课程是否存在
    course = db.query(PBLCourse).filter(PBLCourse.id == project_data.get("course_id")).first()
    if not course:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="课程不存在")
    
    new_project = PBLProject(
        course_id=project_data.get("course_id"),
        title=project_data.get("title"),
        description=project_data.get("description"),
        group_id=project_data.get("group_id") or current_user.group_id,
        status=project_data.get("status", "planning"),
        progress=project_data.get("progress", 0),
        repo_url=project_data.get("repo_url")
    )
    
    db.add(new_project)
    db.commit()
    db.refresh(new_project)
    
    return {
        "id": new_project.id,
        "uuid": new_project.uuid,
        "title": new_project.title,
        "description": new_project.description,
        "course_id": new_project.course_id,
        "group_id": new_project.group_id,
        "status": new_project.status,
        "progress": new_project.progress,
        "repo_url": new_project.repo_url,
        "created_at": new_project.created_at.isoformat() if new_project.created_at else None
    }


@router.put("/projects/{project_uuid}")
async def update_project(
    project_uuid: str,
    project_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新项目
    """
    project = db.query(PBLProject).filter(PBLProject.uuid == project_uuid).first()
    
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="项目不存在")
    
    # 权限检查:只有项目所属小组的成员可以更新
    if current_user.group_id != project.group_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限修改此项目")
    
    # 更新字段
    if "title" in project_data:
        project.title = project_data["title"]
    if "description" in project_data:
        project.description = project_data["description"]
    if "status" in project_data:
        project.status = project_data["status"]
    if "progress" in project_data:
        project.progress = project_data["progress"]
    if "repo_url" in project_data:
        project.repo_url = project_data["repo_url"]
    
    db.commit()
    db.refresh(project)
    
    return {
        "id": project.id,
        "uuid": project.uuid,
        "title": project.title,
        "description": project.description,
        "status": project.status,
        "progress": project.progress,
        "repo_url": project.repo_url,
        "updated_at": project.updated_at.isoformat() if project.updated_at else None
    }


@router.delete("/projects/{project_uuid}")
async def delete_project(
    project_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    删除项目
    """
    project = db.query(PBLProject).filter(PBLProject.uuid == project_uuid).first()
    
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="项目不存在")
    
    # 权限检查
    if current_user.group_id != project.group_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限删除此项目")
    
    db.delete(project)
    db.commit()
    
    return {"message": "删除成功"}


@router.put("/projects/{project_uuid}/status")
async def update_project_status(
    project_uuid: str,
    status_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新项目状态
    """
    project = db.query(PBLProject).filter(PBLProject.uuid == project_uuid).first()
    
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="项目不存在")
    
    # 权限检查
    if current_user.group_id != project.group_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限修改此项目")
    
    new_status = status_data.get("status")
    if new_status not in ['planning', 'in-progress', 'review', 'completed']:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="无效的状态值")
    
    project.status = new_status
    db.commit()
    
    return {"message": "更新成功", "status": project.status}


@router.put("/projects/{project_uuid}/progress")
async def update_project_progress(
    project_uuid: str,
    progress_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新项目进度
    """
    project = db.query(PBLProject).filter(PBLProject.uuid == project_uuid).first()
    
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="项目不存在")
    
    # 权限检查
    if current_user.group_id != project.group_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限修改此项目")
    
    new_progress = progress_data.get("progress")
    if new_progress is None or not (0 <= new_progress <= 100):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="进度值必须在0-100之间")
    
    project.progress = new_progress
    db.commit()
    
    return {"message": "更新成功", "progress": project.progress}


# ==================== 项目成果 ====================

@router.get("/projects/{project_uuid}/outputs")
async def get_project_outputs(
    project_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_flexible)
):
    """
    获取项目成果列表
    """
    project = db.query(PBLProject).filter(PBLProject.uuid == project_uuid).first()
    
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="项目不存在")
    
    outputs = db.query(PBLProjectOutput).filter(PBLProjectOutput.project_id == project.id).all()
    
    result = []
    for output in outputs:
        user = db.query(User).filter(User.id == output.user_id).first()
        result.append({
            "id": output.id,
            "uuid": output.uuid,
            "title": output.title,
            "description": output.description,
            "output_type": output.output_type,
            "file_url": output.file_url,
            "file_size": output.file_size,
            "file_type": output.file_type,
            "repo_url": output.repo_url,
            "demo_url": output.demo_url,
            "thumbnail": output.thumbnail,
            "is_public": output.is_public,
            "view_count": output.view_count,
            "like_count": output.like_count,
            "user_id": output.user_id,
            "user_name": user.full_name if user else None,
            "created_at": output.created_at.isoformat() if output.created_at else None
        })
    
    return result


@router.post("/project-outputs")
async def submit_project_output(
    output_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    提交项目成果
    """
    # 检查项目是否存在
    project = db.query(PBLProject).filter(PBLProject.id == output_data.get("project_id")).first()
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="项目不存在")
    
    # 权限检查
    if current_user.group_id != project.group_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限提交此项目成果")
    
    new_output = PBLProjectOutput(
        project_id=output_data.get("project_id"),
        task_id=output_data.get("task_id"),
        user_id=current_user.id,
        group_id=project.group_id,
        output_type=output_data.get("output_type"),
        title=output_data.get("title"),
        description=output_data.get("description"),
        file_url=output_data.get("file_url"),
        file_size=output_data.get("file_size"),
        file_type=output_data.get("file_type"),
        repo_url=output_data.get("repo_url"),
        demo_url=output_data.get("demo_url"),
        thumbnail=output_data.get("thumbnail"),
        meta_data=output_data.get("metadata"),
        is_public=output_data.get("is_public", False)
    )
    
    db.add(new_output)
    db.commit()
    db.refresh(new_output)
    
    return {
        "id": new_output.id,
        "uuid": new_output.uuid,
        "title": new_output.title,
        "output_type": new_output.output_type,
        "file_url": new_output.file_url,
        "created_at": new_output.created_at.isoformat() if new_output.created_at else None
    }


@router.get("/project-outputs/{output_uuid}")
async def get_output_detail(
    output_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取成果详情
    """
    output = db.query(PBLProjectOutput).filter(PBLProjectOutput.uuid == output_uuid).first()
    
    if not output:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="成果不存在")
    
    # 增加浏览次数
    output.view_count += 1
    db.commit()
    
    user = db.query(User).filter(User.id == output.user_id).first()
    project = db.query(PBLProject).filter(PBLProject.id == output.project_id).first()
    
    return {
        "id": output.id,
        "uuid": output.uuid,
        "title": output.title,
        "description": output.description,
        "output_type": output.output_type,
        "file_url": output.file_url,
        "file_size": output.file_size,
        "file_type": output.file_type,
        "repo_url": output.repo_url,
        "demo_url": output.demo_url,
        "thumbnail": output.thumbnail,
        "metadata": output.meta_data,
        "is_public": output.is_public,
        "view_count": output.view_count,
        "like_count": output.like_count,
        "user_id": output.user_id,
        "user_name": user.full_name if user else None,
        "project_id": output.project_id,
        "project_title": project.title if project else None,
        "created_at": output.created_at.isoformat() if output.created_at else None,
        "updated_at": output.updated_at.isoformat() if output.updated_at else None
    }


@router.put("/project-outputs/{output_uuid}")
async def update_output(
    output_uuid: str,
    output_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新成果
    """
    output = db.query(PBLProjectOutput).filter(PBLProjectOutput.uuid == output_uuid).first()
    
    if not output:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="成果不存在")
    
    # 权限检查:只有提交者可以更新
    if output.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限修改此成果")
    
    # 更新字段
    if "title" in output_data:
        output.title = output_data["title"]
    if "description" in output_data:
        output.description = output_data["description"]
    if "file_url" in output_data:
        output.file_url = output_data["file_url"]
    if "file_size" in output_data:
        output.file_size = output_data["file_size"]
    if "file_type" in output_data:
        output.file_type = output_data["file_type"]
    if "repo_url" in output_data:
        output.repo_url = output_data["repo_url"]
    if "demo_url" in output_data:
        output.demo_url = output_data["demo_url"]
    if "thumbnail" in output_data:
        output.thumbnail = output_data["thumbnail"]
    if "metadata" in output_data:
        output.meta_data = output_data["metadata"]
    if "is_public" in output_data:
        output.is_public = output_data["is_public"]
    
    db.commit()
    db.refresh(output)
    
    return {
        "id": output.id,
        "uuid": output.uuid,
        "title": output.title,
        "description": output.description,
        "file_url": output.file_url,
        "updated_at": output.updated_at.isoformat() if output.updated_at else None
    }


@router.delete("/project-outputs/{output_uuid}")
async def delete_output(
    output_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    删除成果
    """
    output = db.query(PBLProjectOutput).filter(PBLProjectOutput.uuid == output_uuid).first()
    
    if not output:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="成果不存在")
    
    # 权限检查
    if output.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限删除此成果")
    
    db.delete(output)
    db.commit()
    
    return {"message": "删除成功"}


@router.post("/project-outputs/{output_uuid}/like")
async def like_output(
    output_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    点赞成果
    """
    output = db.query(PBLProjectOutput).filter(PBLProjectOutput.uuid == output_uuid).first()
    
    if not output:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="成果不存在")
    
    # 增加点赞数
    output.like_count += 1
    db.commit()
    
    return {"message": "点赞成功", "like_count": output.like_count}


@router.post("/project-outputs/upload")
async def upload_output_file(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    上传成果文件
    """
    import os
    from datetime import datetime
    
    # 创建上传目录
    upload_dir = "uploads/project-outputs"
    os.makedirs(upload_dir, exist_ok=True)
    
    # 生成唯一文件名
    timestamp = get_beijing_time_naive().strftime("%Y%m%d%H%M%S")
    file_extension = os.path.splitext(file.filename)[1]
    filename = f"{current_user.id}_{timestamp}{file_extension}"
    file_path = os.path.join(upload_dir, filename)
    
    # 保存文件
    with open(file_path, "wb") as buffer:
        content = await file.read()
        buffer.write(content)
    
    file_size = len(content)
    file_url = f"/{file_path}"  # 相对路径
    
    return {
        "file_url": file_url,
        "file_size": file_size,
        "file_type": file.content_type,
        "message": "上传成功"
    }
