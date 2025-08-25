"""Database Models Module for LMS Platform.

This module defines the database models and connection setup for the LMS platform.
It includes the User model and database connection configuration.
"""

import os
from datetime import datetime
from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey, Text, LargeBinary, UniqueConstraint, SmallInteger, BigInteger
from sqlalchemy.orm import declarative_base, sessionmaker, relationship

# Load environment variables from .env if present
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

DATABASE_URL = os.environ.get("DATABASE_URL")
if not DATABASE_URL:
    try:
        from dotenv import load_dotenv
        load_dotenv()
    except ImportError:
        pass
    DATABASE_URL = os.getenv("DATABASE_URL")

#print(f"[DB] Using DATABASE_URL: {DATABASE_URL}")

# SQLAlchemy setup
Base = declarative_base()
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

class AuthUser(Base):
    __tablename__ = "auth_user"  # <-- changed this line
    userId = Column("user_id", Integer, primary_key=True, index=True)
    username = Column("username", String, unique=True, index=True)
    hashed_password = Column(String)

    
    
