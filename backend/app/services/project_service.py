from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from ..models.pbl import PBLProject
from ..schemas.pbl import ProjectCreate, ProjectUpdate

def get_project(db: Session, project_id: int):
    return db.query(PBLProject).options(joinedload(PBLProject.course)).filter(PBLProject.id == project_id).first()

def get_projects(db: Session, skip: int = 0, limit: int = 100):
    return db.query(PBLProject).options(joinedload(PBLProject.course)).offset(skip).limit(limit).all()

def create_project(db: Session, project: ProjectCreate):
    db_project = PBLProject(
        title=project.title,
        description=project.description,
        course_id=project.course_id,
        group_id=project.group_id,
        repo_url=project.repo_url,
        status=project.status,
        progress=project.progress
    )
    db.add(db_project)
    db.commit()
    db.refresh(db_project)
    # Reload with course relation
    db_project = get_project(db, db_project.id)
    return db_project

def update_project(db: Session, project_id: int, project_update: ProjectUpdate):
    db_project = get_project(db, project_id)
    if not db_project:
        return None
    
    update_data = project_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_project, field, value)

    db.add(db_project)
    db.commit()
    db.refresh(db_project)
    return db_project

def delete_project(db: Session, project_id: int):
    db_project = get_project(db, project_id)
    if db_project:
        db.delete(db_project)
        db.commit()
    return db_project
