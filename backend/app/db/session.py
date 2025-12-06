from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os

# Use environment variable or default to a local sqlite for development if not provided
# In production, this should come from env vars
SQLALCHEMY_DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "sqlite:///./pbl.db" 
)

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, 
    pool_pre_ping=True,
    # connect_args only for sqlite
    connect_args={"check_same_thread": False} if "sqlite" in SQLALCHEMY_DATABASE_URL else {}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
