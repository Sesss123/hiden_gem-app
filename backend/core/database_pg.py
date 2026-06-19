import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
import logging

logger = logging.getLogger("DatabasePG")

# Default URI if not provided in environment
DATABASE_URL = os.getenv("POSTGRES_URL", "postgresql+asyncpg://postgres:postgres@localhost/tripme")

# Create Async Engine
engine = create_async_engine(DATABASE_URL, echo=False, pool_pre_ping=True)

# Session Factory
async_session = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)

Base = declarative_base()

async def get_pg_session():
    """Dependency for getting PostgreSQL async session."""
    async with async_session() as session:
        try:
            yield session
        except Exception as e:
            logger.error(f"❌ PostgreSQL Session Error: {e}")
            await session.rollback()
            raise
        finally:
            await session.close()

async def init_pg_db():
    """Initialize PostgreSQL tables (can be used for migrations later)."""
    try:
        async with engine.begin() as conn:
            # For now, we just verify connection
            await conn.run_sync(Base.metadata.create_all)
        logger.info("✅ PostgreSQL Connection Verified & DB Initialized")
    except Exception as e:
        logger.error(f"❌ PostgreSQL Initialization Failed: {e}")
