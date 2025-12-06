from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.endpoints import projects
from app.db.session import engine
from app.models import pbl # Import models to register them

# Create tables (for development/sqlite)
pbl.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="CodeHubot PBL System API",
    description="API for Project Based Learning System",
    version="1.0.0"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(projects.router, prefix="/api/v1/projects", tags=["projects"])

@app.get("/")
async def root():
    return {"message": "Welcome to CodeHubot PBL System API"}
