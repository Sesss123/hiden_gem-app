import os
import sqlite3
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

load_dotenv()

# Fetch from environment or fallback to legacy tripme.db
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./tripme.db")

# Standardize URL for SQLAlchemy if coming from older env format
if SQLALCHEMY_DATABASE_URL.startswith("sqlite") and ":///" not in SQLALCHEMY_DATABASE_URL:
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("sqlite:", "sqlite:///")

# Determine DB path for direct sqlite3 connections
if SQLALCHEMY_DATABASE_URL.startswith("sqlite:///"):
    DB_PATH = SQLALCHEMY_DATABASE_URL.replace("sqlite:///", "")
else:
    DB_PATH = os.path.join(os.getcwd(), "tripme.db")

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db_connection():
    """Raw SQLite connection for legacy dictionary-like row access."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # Returns results as dict-like objects
    return conn

# Dependency
def get_db():
    """SQLAlchemy session dependency."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
