from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from ...db.session import SessionLocal
from ...core.response import error_response, success_response
from ...schemas import pbl as schemas
from ...services import project_service

router = APIRouter()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Use "" to avoid automatic 307 redirects from missing trailing slash
@router.get("")
def read_projects(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    projects = project_service.get_projects(db, skip=skip, limit=limit)
    return success_response(projects)

@router.post("")
def create_project(project: schemas.ProjectCreate, db: Session = Depends(get_db)):
    created = project_service.create_project(db=db, project=project)
    return success_response(created, message="created")

@router.get("/{project_id}")
def read_project(project_id: int, db: Session = Depends(get_db)):
    db_project = project_service.get_project(db, project_id=project_id)
    if db_project is None:
        return error_response("Project not found", code=404, status_code=404)
    return success_response(db_project)

@router.put("/{project_id}")
def update_project(project_id: int, project: schemas.ProjectUpdate, db: Session = Depends(get_db)):
    db_project = project_service.update_project(db, project_id=project_id, project_update=project)
    if db_project is None:
        return error_response("Project not found", code=404, status_code=404)
    return success_response(db_project, message="updated")

@router.get("/{project_id}/progress")
def read_project_progress(project_id: int, db: Session = Depends(get_db)):
    db_project = project_service.get_project(db, project_id=project_id)
    if db_project is None:
        return error_response("Project not found", code=404, status_code=404)
    return success_response(db_project.progress)
